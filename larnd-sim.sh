#!/usr/bin/env bash

default_in_file="/global/cfs/cdirs/dune/www/data/2x2/simulation/productions/MiniRun5_1E19_RHC/MiniRun5_1E19_RHC.convert2h5/EDEPSIM_H5/0000000/MiniRun5_1E19_RHC.convert2h5.0000123.EDEPSIM.hdf5"
default_config="2x2"

# allow custom input file to be passed via command line
in_file=${LARNDSIM_INPUT_FILE:-$default_in_file}
config=${LARNDSIM_CONFIG:-$default_config}

extra_args=()

if [[ -n "$LARNDSIM_MAX_EVENTS" ]]; then
    extra_args+=("--n_events" "$LARNDSIM_MAX_EVENTS")
fi

now=$(date -u +%Y%m%dT%H%M%SZ)

out_file=$(basename "$in_file" .hdf5 | sed 's/convert2h5/larnd/' | sed 's/.EDEPSIM//')."$now".LARNDSIM.hdf5
out_dir=$SCRATCH/larnd-sim-output
mkdir -p "$out_dir"

# Prevent errors when multiple larnd-sims try to read the same input
export HDF5_USE_FILE_LOCKING=0

python3 larnd-sim/cli/simulate_pixels.py "$config" \
    --input_filename "$in_file" \
    --output_filename "$out_dir/$out_file" \
    --rand_seed 321 "${extra_args[@]}"
