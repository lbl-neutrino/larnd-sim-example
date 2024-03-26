#!/usr/bin/env bash

in_file=$1; shift

if [[ -z "$in_file" ]]; then
    echo "Usage: $0 IN_FILE"
    exit 1
fi

in_file=$(realpath "$in_file")

source larnd-sim.venv/bin/activate

script=$(realpath larndsim_validation.py)

cd "$(dirname "$in_file")"

"$script" --sim_file "$in_file"

echo "Plots written to $(dirname "$in_file")/$(basename "$in_file" .hdf5)_validations.pdf"
