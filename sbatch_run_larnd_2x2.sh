#!/usr/bin/env bash
#SBATCH -N 5
#SBATCH -C gpu&hbm80g
#SBATCH -q regular
#SBATCH -J dune_sim_80GB
#SBATCH -A dune
#SBATCH -t 04:30:00
#SBATCH --ntasks-per-node=4
#SBATCH --gpus-per-task=1
#SBATCH --array=0-4

# Set the desired number of files per job
desired_inputfiles_per_array=200
export desired_inputfiles_per_array

# Calculate total tasks based on nodes and GPUs per node
total_tasks=$(($SLURM_NNODES * $SLURM_NTASKS_PER_NODE))

# Specify the branch name here or pass it via an argument when submitting
branch_name="develop"

# Run the simulations across nodes and GPUs
srun --ntasks=$total_tasks --kill-on-bad-exit=0 --cpu_bind=cores ./wrapper_run_larndsim_2x2.sh $branch_name
