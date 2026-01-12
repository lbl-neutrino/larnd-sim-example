#!/usr/bin/env bash
set -euo pipefail


# Export the environment variable
# export LARNDSIM_DISABLE_CUPY_MEMPOOL=1
# export LARNDSIM_MAX_EVENTS=10

# Load necessary modules and activate the virtual environment
source setup.inc.sh

# Activate the existing virtual environment
source "$venv_name/bin/activate"

# default_in_file="/global/cfs/cdirs/dune/www/data/2x2/simulation/productions/MiniRun5_1E19_RHC/MiniRun5_1E19_RHC.convert2h5/EDEPSIM_H5/0000000/MiniRun5_1E19_RHC.convert2h5.0000123.EDEPSIM.hdf5"
# default_config="2x2"

default_in_file="/dvs_ro/cfs/cdirs/dunepro/people/abooth/nd-production/output/MiniProdN5/run-convert2h5/MiniProdN5p1_NDComplex_FHC.convert2h5.full.sanddrift/EDEPSIM_H5/0000000/MiniProdN5p1_NDComplex_FHC.convert2h5.full.sanddrift.0000672.EDEPSIM.hdf5"
default_config="ndlar_light"

# -------------------------
# Darshan injection (non-MPI) so Python I/O is captured
# -------------------------
module load darshan

# Darshan preload library (provided by the module)
DARSHAN_PRELOAD="${DARSHAN_BASE_DIR}/lib/libdarshan.so"
export DARSHAN_ENABLE_NONMPI=1
export LD_PRELOAD="${DARSHAN_PRELOAD}"

# DARSHAN_LOGS is usually set by the module; keep default if present
export DARSHAN_LOGS="${DARSHAN_LOGS:-/pscratch/darshanlogs}"

# Optional: reduce record explosion from python/venv imports to avoid "incomplete data"
# (you can comment this out if you want EVERYTHING tracked)
#export DARSHAN_EXCLUDE_DIRS="${DARSHAN_EXCLUDE_DIRS:-/proc,/sys,/var,/usr,/opt,${HOME}/.cache,${HOME}/.local}"

echo "INFO: Darshan enabled (non-MPI)"
echo "INFO: LD_PRELOAD=$LD_PRELOAD"
echo "INFO: DARSHAN_LOGS=$DARSHAN_LOGS"
#echo "INFO: DARSHAN_EXCLUDE_DIRS=$DARSHAN_EXCLUDE_DIRS"
echo "INFO: Logs will appear at job exit under: \${DARSHAN_LOGS}/YYYY/MM/DD/"

# -------------------------
# allow custom input/config via env vars (original logic)
# -------------------------
in_file=${LARNDSIM_INPUT_FILE:-$default_in_file}
config=${LARNDSIM_CONFIG:-$default_config}

extra_args=()
if [[ -n "${LARNDSIM_MAX_EVENTS:-}" ]]; then
    extra_args+=("--n_events" "$LARNDSIM_MAX_EVENTS")
fi

now=$(date -u +%Y%m%dT%H%M%SZ)

out_file=$(basename "$in_file" .hdf5 | sed 's/convert2h5/larnd/' | sed 's/.EDEPSIM//')."$now".LARNDSIM.hdf5
out_dir=$SCRATCH/larnd-sim-output
mkdir -p "$out_dir"

# Prevent errors when multiple larnd-sims try to read the same input
export HDF5_USE_FILE_LOCKING=0

simulate_pixels.py "$config" \
    --input_filename "$in_file" \
    --output_filename "$out_dir/$out_file" \
    --rand_seed 321 "${extra_args[@]}"
