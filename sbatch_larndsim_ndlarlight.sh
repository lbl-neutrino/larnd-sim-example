#!/usr/bin/env bash
#SBATCH -N 5
#SBATCH -C gpu&hbm80g
#SBATCH -q regular  # debug, regular
#SBATCH -J dune_sim_80GB_ndlar
#SBATCH -A dune #nstaff #dune
#SBATCH -t 7:29:00 ## #feature/smarter-batching # 06:00:00 ModByMod-RHC  # 04:00:00 # feature_simple_jagged  #05:00:00 for develop
#SBATCH --ntasks-per-node=4
#SBATCH --gpus-per-task=1
#SBATCH --array=0-4

## #SBATCH --array=0-5

# Set the desired number of files per job
#desired_inputfiles_per_array=20 # for 124 input files
# desired_inputfiles_per_array=40 # for 252 input files
# desired_inputfiles_per_array=200 # for 1000 input files

# Export the environment variable
export LARNDSIM_DISABLE_CUPY_MEMPOOL=1

desired_inputfiles_per_array=20 # for ndlar test with one node input files
export desired_inputfiles_per_array

# Calculate total tasks based on nodes and GPUs per node
total_tasks=$(($SLURM_NNODES * $SLURM_NTASKS_PER_NODE))

# Check if the branch argument is provided
if [ -z "$1" ]; then
    echo "Error: No branch specified. Please provide a branch name (e.g., develop or feature_simple_jagged )."
    exit 1
fi

branch_name=$1

# Git commands to pull the appropriate branch
cd /larnd-sim
git fetch origin
git checkout $branch_name
git pull origin $branch_name

# Move out of the larnd-sim directory
cd ..

# Run the simulations across nodes and GPUs
#srun --ntasks=$total_tasks --kill-on-bad-exit=0 --cpu_bind=cores ./wrapper_run_larndsim_2x2.sh
srun --ntasks=$total_tasks --kill-on-bad-exit=0 --cpu_bind=cores --gpu-bind=single:1 ./wrapper_larndsim_ndlarlight.sh
