#!/usr/bin/env bash
#SBATCH -N 5
#SBATCH -C gpu&hbm80g
#SBATCH -q regular #debug, regular
#SBATCH -J dune_sim_80GB
#SBATCH -A dune
#SBATCH -t 05:30:00
#SBATCH --ntasks-per-node=4
#SBATCH --gpus-per-task=1  # Assign one GPU per task
#SBATCH --array=0-4 #5 array
##SBATCH --array=0 #1 array

# Set the desired number of files per job
desired_inputfiles_per_array=200 # 20 tasks ($SLURM_NNODES * $SLURM_NTASKS_PER_NODE) submitted simultaneously per array so 10 submission cycles per array.
#desired_inputfiles_per_array=100 #12 tasks ($SLURM_NNODES * $SLURM_NTASKS_PER_NODE) submitted simultaneously per array so (104/12 ~ ) 9 submission cycles per array.

export desired_inputfiles_per_array

# Calculate total tasks based on nodes and GPUs per node
total_tasks=$(($SLURM_NNODES * $SLURM_NTASKS_PER_NODE))

# Run the simulations across nodes and GPUs
srun --ntasks=$total_tasks --kill-on-bad-exit=0 --cpu_bind=cores ./wrapper_run_larnd_sim.sh