#!/bin/bash

#sim_start_time=$(date -u +%Y%m%dT%H%M%S%3N)
sim_start_time=$(date '+%Y-%m-%d_%H:%M:%S')
#echo "Sim Start Time: $sim_start_time" >> "$log_filename"

# Read the file list into an array
#mapfile -t file_names < /pscratch/sd/m/madan12/DUNE/larnd-sim-example/40GB_FailedJob_100.txt
mapfile -t file_names < /global/cfs/cdirs/dune/users/madan12/DUNE_nesap/nesap-develop-benchmark/DUNE_10file.txt

# Define directories
#export out_dir=$SCRATCH/DUNE/nesap-develop/larnd-sim-output-80GB
export out_dir=/global/cfs/cdirs/dune/users/madan12/DUNE_nesap/nesap-develop-benchmark/larnd-sim-output-80GB-10files
mkdir -p "$out_dir"

# Load modules and activate environment
module unload python cudatoolkit 2>/dev/null
module load cudatoolkit/11.7
module load python/3.11
source /pscratch/sd/m/madan12/DUNE/nesap-develop/larnd-sim.venv/bin/activate

#Function to log GPU memory information
function log_gpu_memory {
    log_file=$1
    echo "GPU and Memory Info:" >> "$log_file"
    nohup nvidia-smi --query-gpu=memory.total,memory.free,memory.used,gpu_uuid --format=csv --loop-ms=5000 >> "$log_file" 2>&1 &
}

# For each array job, process two input files 100 times each
start_index=$(($SLURM_ARRAY_TASK_ID * 2))
end_index=$(($start_index + 2))

for ((file_index=$start_index; file_index<$end_index; file_index++)); do
    input_filename="${file_names[$file_index]}"  # Corrected variable name

    for ((i=0; i<=$SLURM_NTASKS_PER_NODE; i++)); do

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

        simulate_pixels.py \
            2x2_mod2mod_variation \
            --input_filename "$input_filename" \
            --output_filename "$output_filename" \
            --rand_seed $rand_seed 2>&1 | tee -a "$log_filename"

        # Log end time at the end of the loop for better traceability
        end_time=$(date '+%Y-%m-%d_%H:%M:%S')
        echo "End Time: $end_time" >> "$log_filename"
    done
done
