#!/usr/bin/env bash

#SBATCH -A sens2022521
#SBATCH -p node
#SBATCH -n 1
#SBATCH -t 12:00:00
#SBATCH -C gpu
#SBATCH --gpus-per-node 2
#SBATCH -o /proj/sens2022521/1-shuai/9-logs/%u-slurm-%j.out
#SBATCH --mail-user shuai1997@hotmail.se
#SBATCH --mail-type=END
# set -euo pipefail
# Calls different batches

ml julia/1.7.2 gnuparallel/20180822


# Calls different parameters
sweep=$1
params=$(find ../4-params/shape_oct/ -type f | sort)
batches=$(find ../2-results/000-batches/oct/ -type f | sort)
winsze=(4)
binolp=(4)
montages=(Average Average Average Bipolar)
spectra=(CWT DWT DWT STFT)
mkdir -p /proj/sens2022521/1-shuai/2-results/022-shape/${sweep}/
parallel -v -j 1 . 122-shape.sh ::: $sweep  ::: ${winsze[@]} ::: ${binolp[@]} ::: $params :::+ ${montages[@]} :::+ ${spectra[@]} ::: $batches

##