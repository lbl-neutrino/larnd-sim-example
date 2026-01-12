#!/bin/bash

# Export the environment variable
export LARNDSIM_DISABLE_CUPY_MEMPOOL=1
export LARNDSIM_MAX_EVENTS=20

# Load necessary modules and activate the virtual environment
# module unload python cudatoolkit 2>/dev/null
# module load cudatoolkit/11.7
# module load python/3.11
source /pscratch/sd/m/madan12/DUNE/darshan_try/larnd-sim-example/setup.inc.sh

# Activate the existing virtual environment
source /pscratch/sd/m/madan12/DUNE/darshan_try/larnd-sim-example/larnd-sim.cuda12.venv/bin/activate

# Set up simulation start time
sim_start_time=$(date '+%Y-%m-%d_%H:%M:%S')

# Read the file list into an array
mapfile -t file_names < /pscratch/sd/m/madan12/DUNE/darshan_try/larnd-sim-example/DUNE_2x2filelist_4.txt

# export batchsize
export LARNDSIM_PIXEL_BATCH_SIZE="3200" # Or "800", "1600", "2400", "3200"

# Define directories for output
export out_dir=/pscratch/sd/m/madan12/DUNE/darshan_try/larnd-sim-example/output_2x2_benchmark_darshan
#export out_dir="/pscratch/sd/m/madan12/DUNE/pixel_sub_batching/output_pixel_subbatching_FSD_${LARNDSIM_PIXEL_BATCH_SIZE}bs"
mkdir -p "$out_dir"

# Retrieve the number of files each task should process
files_per_job=$(((desired_inputfiles_per_array + ($SLURM_NNODES * $SLURM_NTASKS_PER_NODE) - 1) / ($SLURM_NNODES * $SLURM_NTASKS_PER_NODE)))

# Calculate the base index for file processing
base_index=$((SLURM_ARRAY_TASK_ID * desired_inputfiles_per_array + SLURM_PROCID * files_per_job))

# Function to log GPU memory information to a separate file
function log_gpu_memory {
    log_file=$1
    gpu_mem_log="${log_file%.log}.gpu_mem.log"
    echo "GPU and Memory Info:" > "$gpu_mem_log"
    nohup nvidia-smi --query-gpu=memory.total,memory.free,memory.used,gpu_uuid --format=csv --loop-ms=5000 >> "$gpu_mem_log" 2>&1 &
    echo $!  # Return the PID of the nohup process
}

# Loop through the files to process
for ((i=0; i<files_per_job; i++)); do
    file_index=$((base_index + i))
    if [ $file_index -ge ${#file_names[@]} ]; then
        break
    fi
    input_filename="${file_names[$file_index]}"

    if [ ! -f "$input_filename" ]; then
        echo "Error: Input file does not exist - $input_filename"
        continue
    fi

    # Set up timestamps and random seed
    timestamp=$(date '+%Y-%m-%d_%H:%M:%S')
    rand_seed=321
    # rand_seed=$(((RANDOM % 10000) + 1))
    host_name=$(hostname)
    File_index=$file_index

    output_filename="${out_dir}/$(basename "$input_filename" .hdf5)_${timestamp}_${rand_seed}_${host_name}_${SLURM_JOB_ID}_${File_index}.LARNDSIM.hdf5"
    log_filename="${out_dir}/$(basename "$input_filename" .hdf5)_${timestamp}_${rand_seed}_${host_name}_${SLURM_JOB_ID}_${File_index}.log"

    # echo "Processing file: $input_filename, Simulation #$i, Sim Start Time: $sim_start_time, Task Start Time: $timestamp, Random Seed: $rand_seed, Host Name: $host_name, File index: $file_index, Job ID: ${SLURM_JOB_ID}, Log File: $log_filename, Output File: $output_filename" | tee -a "$log_filename"
    
    echo "Processing file: $input_filename, Simulation #$i, Sim Start Time: $sim_start_time, Task Start Time: $timestamp, Random Seed: $rand_seed, Host Name: $host_name, File index: $file_index, Job ID: ${SLURM_JOB_ID}, Log File: $log_filename, Output File: $output_filename, Uptime: $(uptime)" | tee -a "$log_filename"

    # # --- Added system uptime logging for reference ---
    # echo "System Uptime: $(uptime)" >> "$log_filename"
    # # ---------------------------------------------------

    # Log GPU memory before the simulation to a separate file
    gpu_mem_pid=$(log_gpu_memory "$log_filename")

    # Get configuration or use default
    default_config=2x2
    # default_config=ndlar_light
    config=${LARNDSIM_CONFIG:-$default_config}

    # Run the simulation
    simulate_pixels.py "$config" \
    --input_filename "$input_filename" \
    --output_filename "$output_filename" \
    --rand_seed $rand_seed 2>&1 | tee -a "$log_filename"

    # Kill the GPU memory logger after simulation
    kill $gpu_mem_pid

    # Capture end time at the script's conclusion
    end_time=$(date '+%Y-%m-%d %H:%M:%S')
    echo "End Time: $end_time" >> "$log_filename"
done