#!/usr/bin/env bash
#SBATCH -N 5
#SBATCH -C gpu&hbm80g
#SBATCH -q regular # debug, regular
#SBATCH -J dune_sim_80GB_ndar
#SBATCH -A dune
#SBATCH -t 05:00:00 #06:00:00 (post-hackathon2024) , 04:30:00 (develop), 00:29:00 (debug)
#SBATCH --ntasks-per-node=4
#SBATCH --gpus-per-task=1
#SBATCH --array=0-6

# Set the desired number of files per job
desired_inputfiles_per_array=20
#desired_inputfiles_per_array=200
export desired_inputfiles_per_array

# Calculate total tasks based on nodes and GPUs per node
total_tasks=$(($SLURM_NNODES * $SLURM_NTASKS_PER_NODE))

# Check if the branch argument is provided
if [ -z "$1" ]; then
    echo "Error: No branch specified. Please provide a branch name (e.g., develop or post-hackathon2024)."
    exit 1
fi

branch_name=$1

# Git commands to pull the appropriate branch
cd /mscratch/sd/m/madan12/DUNE_sim/CUDA12p4/larnd-sim-example/larnd-sim
git fetch origin
git checkout $branch_name
git pull origin $branch_name

# Move out of the larnd-sim directory
cd ..

# Run the simulations across nodes and GPUs
#srun --ntasks=$total_tasks --kill-on-bad-exit=0 --cpu_bind=cores ./wrapper_run_larndsim_2x2.sh
srun --ntasks=$total_tasks --kill-on-bad-exit=0 --cpu_bind=cores ./wrapper_run_larndsim_ndlar.sh
