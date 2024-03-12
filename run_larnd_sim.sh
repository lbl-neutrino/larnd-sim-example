#!/usr/bin/env bash

default_in_file="/global/cfs/cdirs/dune/www/data/2x2/simulation/mkramer_dev/larnd-sim-example/MiniRun5_1E19_RHC.convert2h5.00123.EDEPSIM.hdf5"

# allow custom input file to be passed via command line
in_file=${1:-$default_in_file}

module unload python 2>/dev/null
module unload cudatoolkit 2>/dev/null

module load cudatoolkit/11.7
module load python/3.11

cd $(dirname "${BASH_SOURCE[0]}")
source larnd-sim.venv/bin/activate

now=$(date -u +%Y%m%dT%H%M%SZ)

out_file=$(basename $in_file .hdf5 | sed 's/convert2h5/larnd/' | sed 's/.EDEPSIM//')."$now".LARNDSIM.hdf5
out_dir=$SCRATCH/larnd-sim-output
mkdir -p "$out_dir"

detector_properties="larnd-sim/larndsim/detector_properties/2x2.yaml"
pixel_layout="larnd-sim/larndsim/pixel_layouts/multi_tile_layout-2.4.16.yaml"
response_file="larnd-sim/larndsim/bin/response_44.npy"
light_lut_filename="/global/cfs/cdirs/dune/www/data/2x2/simulation/larndsim_data/light_LUT_M123_v1/lightLUT_M123.npz"
light_det_noise_filename="larnd-sim/larndsim/bin/light_noise_2x2_4mod_July2023.npy"
simulation_properties="larnd-sim/larndsim/simulation_properties/2x2_NuMI_sim.yaml"

simulate_pixels.py 2x2_mod2mod_variation \
    --input_filename "$in_file" \
    --output_filename "$out_dir/$out_file" \
    --detector_properties "$detector_properties" \
    --pixel_layout "$pixel_layout" \
    --response_file "$response_file" \
    --light_lut_filename "$light_lut_filename" \
    --light_det_noise_filename "$light_det_noise_filename" \
    --simulation_properties "$simulation_properties" \
    --rand_seed 321
