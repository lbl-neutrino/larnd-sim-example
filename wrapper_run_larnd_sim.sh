#!/bin/bash

#sim_start_time=$(date -u +%Y%m%dT%H%M%S%3N)
sim_start_time=$(date '+%Y-%m-%d_%H:%M:%S')
#echo "Sim Start Time: $sim_start_time" >> "$log_filename"

# Read the file list into an array
mapfile -t file_names < DUNE_allfilelist_1000.txt
#mapfile -t file_names < /pscratch/sd/m/madan12/DUNE/nesap-develop/DUNE_allfilelist_1000.txt

# Define directories
export out_dir=$SCRATCH/DUNE/nesap-develop/larnd-sim-output-80GB
mkdir -p "$out_dir"

# Load modules and activate environment
module unload python cudatoolkit 2>/dev/null
module load cudatoolkit/11.7
module load python/3.11
source larnd-sim.venv/bin/activate

# Define simulation parameters
detector_properties="larnd-sim/larndsim/detector_properties/2x2.yaml"
pixel_layout="larnd-sim/larndsim/pixel_layouts/multi_tile_layout-2.4.16.yaml"
response_file="larnd-sim/larndsim/bin/response_44.npy"
light_lut_filename="/dvs_ro/cfs/cdirs/dune/www/data/2x2/simulation/larndsim_data/light_LUT_M123_v1/lightLUT_M123.npz"
light_det_noise_filename="larnd-sim/larndsim/bin/light_noise_2x2_4mod_July2023.npy"
simulation_properties="larnd-sim/larndsim/simulation_properties/2x2_NuMI_sim.yaml"

# Retrieve the number of files each task should process
# And also ensures when divided by the total number of tasks, any remainder would push the division result to the next integer, achieving a ceiling effect.
files_per_job=$(((desired_inputfiles_per_array + ($SLURM_NNODES * $SLURM_NTASKS_PER_NODE) - 1) / ($SLURM_NNODES * $SLURM_NTASKS_PER_NODE)))
# e.g, files_per_job=$(((200 + (5 * 4) - 1) / (5 * 4))) --> (((200 + 20 - 1) / 20)) --> ((219 / 20)) --> 10

# Calculate the base index for file processing
base_index=$((SLURM_ARRAY_TASK_ID * desired_inputfiles_per_array + SLURM_PROCID * files_per_job))

#Function to log GPU memory information
function log_gpu_memory {
    log_file=$1
    echo "GPU and Memory Info:" >> "$log_file"
    nohup nvidia-smi --query-gpu=memory.total,memory.free,memory.used,gpu_uuid --format=csv --loop-ms=5000 >> "$log_file" 2>&1 &
}

# The for loop efficiently manages file processing by dynamically calculating file indices and ensuring valid file access within a specified job.
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

    #timestamp=$(date -u +%Y%m%dT%H%M%S%3N)
    timestamp=$(date '+%Y-%m-%d_%H:%M:%S')
    rand_seed=$(((RANDOM % 10000) + 1))
    host_name=$(hostname)

    output_filename="${out_dir}/$(basename "$input_filename" .hdf5)_${timestamp}_${rand_seed}_${SLURM_JOB_ID}.LARNDSIM.hdf5"
    log_filename="${out_dir}/$(basename "$input_filename" .hdf5)_${timestamp}_${rand_seed}_${SLURM_JOB_ID}.log"

    echo "Processing file: $input_filename, Simulation #$i, Sim Start Time: $sim_start_time, Task Start Time: $timestamp, Random Seed: $rand_seed, Host Name: $host_name, File index: $file_index, Job ID: ${SLURM_JOB_ID}, Log File: $log_filename, Output File: $output_filename" | tee -a "$log_filename"
    log_gpu_memory "$log_filename"

    simulate_pixels.py \
        --input_filename "$input_filename" \
        --output_filename "$output_filename" \
        --detector_properties "$detector_properties" \
        --pixel_layout "$pixel_layout" \
        --response_file "$response_file" \
        --light_lut_filename "$light_lut_filename" \
        --light_det_noise_filename "$light_det_noise_filename" \
        --simulation_properties "$simulation_properties" \
        --rand_seed $rand_seed 2>&1 | tee -a "$log_filename"

    log_gpu_memory "$log_filename"
    
    # Capture end time at the script's conclusion
    end_time=$(date '+%Y-%m-%d %H:%M:%S')
    echo "End Time: $end_time" >> "$log_filename"

done

