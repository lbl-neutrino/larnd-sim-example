#!/usr/bin/env bash

# Unload existing modules if any
module unload python 2>/dev/null
module unload cudatoolkit 2>/dev/null

# Load necessary modules
module load cudatoolkit/11.7
module load python/3.11

# Create and activate a virtual environment
python3 -m venv larnd-sim.venv
source larnd-sim.venv/bin/activate

# Install dependencies
pip install --upgrade pip setuptools wheel
pip install matplotlib awkward

# Clone larnd-sim without specifying a branch (you will switch branches later)
if [ ! -d "larnd-sim" ]; then
    git clone https://github.com/DUNE/larnd-sim
fi

# Install cupy-cuda11x and setup larnd-sim
cd larnd-sim
pip install cupy-cuda11x
SKIP_CUPY_INSTALL=1 pip install -e .
