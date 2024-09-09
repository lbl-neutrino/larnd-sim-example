#!/bin/bash

# Check if the branch argument is provided
if [ -z "$1" ]; then
    echo "Error: No branch specified. Please provide a branch name (e.g., develop or post-hackathon2024)."
    exit 1
fi

branch_name=$1

# Load modules and activate environment
module unload python cudatoolkit 2>/dev/null
module load cudatoolkit/11.7
module load python/3.11
source /pscratch/sd/m/madan12/DUNE/nesap-develop/larnd-sim.venv/bin/activate

# Change to larnd-sim directory
cd /pscratch/sd/m/madan12/DUNE/nesap-develop/larnd-sim

# Check out the appropriate branch
git fetch origin
git checkout $branch_name
git pull origin $branch_name

# Set up simulation start time
sim_start_time=$(date '+%Y-%m-%d_%H:%M:%S')

# Read the file list into an array
mapfile -t file_names < /global/cfs/cdirs/dune/users/madan12/DUNE_nesap/nesap-develop-benchmark/DUNE_allfilelist_1000.txt

# Define directories
export out_dir=/global/cfs/cdirs/dune/users/madan12/DUNE_nesap/nesap-develop-benchmark/larnd-sim-output-80GB
mkdir -p "$out_dir"

# Retrieve the number of files each task should process
files_per_job=$(((desired_inputfiles_per_array + ($SLURM_NNODES * $SLURM_NTASKS_PER_NODE) - 1) / ($SLURM_NNODES * $SLURM_NTASKS_PER_NODE)))

# Calculate the base index for file processing
base_index=$((SLURM_ARRAY_TASK_ID * desired_inputfiles_per_array + SLURM_PROCID * files_per_job))

# Function to log GPU memory information
function log_gpu_memory {
    log_file=$1
    echo "GPU and Memory Info:" >> "$log_file"
    nohup nvidia-smi --query-gpu=memory.total,memory.free,memory.used,gpu_uuid --format=csv --loop-ms=5000 >> "$log_file" 2>&1 &
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

    timestamp=$(date '+%Y-%m-%d_%H:%M:%S')
    rand_seed=$(((RANDOM % 10000) + 1))
    host_name=$(hostname)

    output_filename="${out_dir}/$(basename "$input_filename" .hdf5)_${timestamp}_${rand_seed}_${SLURM_JOB_ID}.LARNDSIM.hdf5"
    log_filename="${out_dir}/$(basename "$input_filename" .hdf5)_${timestamp}_${rand_seed}_${SLURM_JOB_ID}.log"

    echo "Processing file: $input_filename, Simulation #$i, Sim Start Time: $sim_start_time, Task Start Time: $timestamp, Random Seed: $rand_seed, Host Name: $host_name, File index: $file_index, Job ID: ${SLURM_JOB_ID}, Log File: $log_filename, Output File: $output_filename" | tee -a "$log_filename"
    log_gpu_memory "$log_filename"

    default_config=2x2
    config=${LARNDSIM_CONFIG:-$default_config}

    # simulate_pixels.py \
    #     2x2_mod2mod_variation \
    simulate_pixels.py "$config" \
        --input_filename "$input_filename" \
        --output_filename "$output_filename" \
        --rand_seed $rand_seed 2>&1 | tee -a "$log_filename"

    log_gpu_memory "$log_filename"
    
    # Capture end time at the script's conclusion
    end_time=$(date '+%Y-%m-%d %H:%M:%S')
    echo "End Time: $end_time" >> "$log_filename"

done
