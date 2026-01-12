#!/usr/bin/env bash
#SBATCH -N 1
#SBATCH -C gpu&hbm40g
#SBATCH -q regular  # debug, regular
#SBATCH -J dune_sim_40GB_2x2_darshan
#SBATCH -A dune #nstaff #dune
#SBATCH -t 0:29:00
#SBATCH --ntasks-per-node=4
#SBATCH --gpus-per-task=1
#SBATCH --array=0
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --error=logs/%x_%A_%a.err
##SBATCH --array=0-5

set -euo pipefail
mkdir -p logs

# -------------------------
# User knobs
# -------------------------
desired_inputfiles_per_array=4  # for 4 input files
export desired_inputfiles_per_array

# Your existing workflow knobs
export LARNDSIM_DISABLE_CUPY_MEMPOOL=1
# export LARNDSIM_MAX_EVENTS=20

# Optional: enable only for short tests (extra overhead)
# export DXT_ENABLE_IO_TRACE=1

# -------------------------
# Darshan (non-MPI injection)
# -------------------------
module load darshan
DARSHAN_PRELOAD="${DARSHAN_BASE_DIR}/lib/libdarshan.so"

# Calculate total tasks based on nodes and tasks per node
total_tasks=$(( SLURM_NNODES * SLURM_NTASKS_PER_NODE ))

# Check if the branch argument is provided
if [[ $# -lt 1 ]]; then
    echo "Usage: sbatch $0 <branch_name>"
    echo "Example: sbatch $0 develop"
    exit 1
fi
branch_name="$1"

# -------------------------
# Repo paths (edit if needed)
# -------------------------
BASE="/pscratch/sd/m/madan12/DUNE/darshan_try/larnd-sim-example"
LARNDSIM_REPO="${BASE}/larnd-sim"

# Git commands to pull the appropriate branch
cd "${LARNDSIM_REPO}"
git fetch origin
git checkout "${branch_name}"
git pull origin "${branch_name}"

# Move out to larnd-sim-example root (so wrapper paths match)
cd "${BASE}"

echo "=== Job info ==="
echo "JobID: ${SLURM_JOB_ID}  ArrayTask: ${SLURM_ARRAY_TASK_ID:-NA}"
echo "Branch: ${branch_name}"
echo "Nodes: ${SLURM_NNODES}  Tasks/Node: ${SLURM_NTASKS_PER_NODE}  Total tasks: ${total_tasks}"
echo "Darshan preload: ${DARSHAN_PRELOAD}"
echo "DARSHAN_LOGS: ${DARSHAN_LOGS:-<not set?>}"
echo "==============="

# Run the simulations across nodes and GPUs (Darshan injected only into launched app)
srun --ntasks="${total_tasks}" \
     --kill-on-bad-exit=0 \
     --cpu_bind=cores \
     --gpu-bind=single:1 \
     --export=ALL,DARSHAN_ENABLE_NONMPI=1,LD_PRELOAD="${DARSHAN_PRELOAD}" \
     ./wrapper_run_larndsim_2x2_sc25_darshan.sh

echo "Run finished."
echo "To find your Darshan log (check the date directory in DARSHAN_LOGS):"
echo "  module load darshan"
echo "  d=\$(date +%Y/%m/%d)"
echo "  ls -lt \${DARSHAN_LOGS}/\${d}/\${USER}_*_${SLURM_JOB_ID}_*.darshan*"
echo "Then:"
echo "  darshan-parser <logfile> | head"
echo "  module load texlive && darshan-job-summary.pl <logfile>"
