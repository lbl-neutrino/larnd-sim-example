# larnd-sim example

This is a minimal example for running [larnd-sim](https://github.com/DUNE/larnd-sim) on Perlmutter at NERSC.

## Installing it

Note: CFS and `$HOME` tend to struggle with Python virtual environments, so I recommend that you do the following steps in a directory on `$PSCRATCH` (but commit/push any code changes that you don't want to fall victim to `$PSCRATCH`'s purge policy!).

Start by cloning and entering this repository:

``` bash
git clone https://github.com/lbl-neutrino/larnd-sim-example.git
cd larnd-sim-example
```

Then run the installer:

``` bash
./install_larnd_sim.sh
```

This will locally clone `larnd-sim` and create a Python virtual environment `larnd-sim.venv` for its dependencies. Since `larnd-sim` is installed with the `-e` option to `pip install`, you don't need to re-run `pip install` after modifying the code.

## Running

### Submit the Job
Submit the job using a specific branch name
``` bash
sbatch sbatch_run_larndsim_2x2.sh develop
```
The `sbatch_run_larnd_sim.sh` script uses the `wrapper_run_larndsim_2x2.sh` script or `wrapper_run_larnd_sim-m2m.sh` for `2x2_mod2mod_variation` mode, 
which is configured to run the DUNE simulations.

`DUNE_allfilelist_1000.txt` is a text file containing the full paths of the input files.

### Interactively
It's a good idea to grab a dedicated 80GB GPU:

``` bash
salloc -A dune -q interactive -C 'gpu&hbm80g' -t 30
```

30 minutes should be enough for a few runs of `larnd-sim`. The above will actually give you a whole node, with four GPUs, which is more than you need, but so be it. You can also grab a single GPU on a shared node:


``` bash
salloc -q shared -C 'gpu&hbm80g' -t 30 --gpus-per-task 1 --ntasks 1 -A dune_g
```

But the `shared` QOS typically will leave you waiting in the queue, while `interactive` is usually nearly instant.

Once you've got a GPU to yourself, launch the simulation:

``` bash
./run_larnd_sim.sh
```

You can override the default input file (i.e. the output from edep-sim) by passing a file on the command line (see the top of `run_larnd_sim.sh`). The output will end up in a timestamped file under `$SCRATCH/larnd-sim-output`.

## Validating the output

You can produce a PDF of validation plots as follows:

```
./make_plots.sh /path/to/output.hdf5
```

The PDF file will be produced in the same directory as the HDF5 file.

## Analysis (NESAP)
Jupyter notebook `Analysis.ipynb` in the `plots` folder performs analysis and generates visualizations stored in the same folder

Jupyter notebook `Analysis.ipynb` in the `plots_m2m` folder performs analysis and generates visualizations stored in the same folder for 2x2_mod2mod_variation
