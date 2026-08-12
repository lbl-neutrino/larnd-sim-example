module unload python 2>/dev/null
module load python/3.11

if [[ -n "$CUDA_HOME" ]]; then
    cuda_ver=$(basename "$CUDA_HOME" | awk '{print int($1)}')
    venv_tag=.cuda$cuda_ver
fi

venv_name=larnd-sim$venv_tag.venv
