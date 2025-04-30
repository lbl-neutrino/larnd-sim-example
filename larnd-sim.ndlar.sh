#!/usr/bin/env bash

# See https://malleable-august-e41.notion.site/8f9307245c5342aab0563630b4e4332c?v=8e3c9b8c045e484b8ebe6f29fad43813
# for Alex Booth's ND-LAr productions

# default_in_file="/global/cfs/cdirs/dune/users/abooth/nd-production/MicroProdN1p1/output/run-convert2h5/MicroProdN1p1_NDLAr_1E18_RHC.convert2h5.nu/EDEPSIM_H5/0000000/MicroProdN1p1_NDLAr_1E18_RHC.convert2h5.nu.0000082.EDEPSIM.hdf5"
# default_in_file="/global/cfs/cdirs/dune/users/abooth/nd-production/MicroProdN1p2/output/run-convert2h5/MicroProdN1p2_NDLAr_1E18_RHC.convert2h5.nu/EDEPSIM_H5/0000000/MicroProdN1p2_NDLAr_1E18_RHC.convert2h5.nu.0000023.EDEPSIM.hdf5"
default_in_file="/global/cfs/cdirs/dune/users/abooth/nd-production/MicroProdN3p1/output/run-convert2h5/MicroProdN3p1_NDLAr_2E18_FHC.convert2h5.nu/EDEPSIM_H5/0000000/MicroProdN3p1_NDLAr_2E18_FHC.convert2h5.nu.0000079.EDEPSIM.hdf5"

default_config="ndlar_light"

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

log_file=$out_file.log
log_dir=$out_dir/log
mkdir -p "$log_dir"

# Prevent errors when multiple larnd-sims try to read the same input
export HDF5_USE_FILE_LOCKING=0

/usr/bin/time -f "%P %M %E" simulate_pixels.py "$config" \
    --input_filename "$in_file" \
    --output_filename "$out_dir/$out_file" \
    --rand_seed 321 "${extra_args[@]}" 2>&1 | tee -a "$log_dir/$log_file"
