#!/usr/bin/env bash
#SBATCH -A sens2022521
#SBATCH -p node
#SBATCH -n 1
#SBATCH -t 8:00:00
#SBATCH -o /proj/sens2022521/1-shuai/9-logs/%u-slurm-%j.out
#SBATCH --mail-user shuai1997@hotmail.se
#SBATCH --mail-type=END
# set -euo pipefail
# Calls different batches

ml julia/1.7.2 gnuparallel/20180822

sweep=$1
param=$(basename ${2%.*})
winsze=$3
binolp=$4
montage=$5
batch=$6

#TODO: Append to parameter log file in parent directory

mkdir -p /proj/sens2022521/1-shuai/2-results/020-cpu-rng/${sweep}/${param}-${winsze}-${binolp}-${montage}/
parallel -j 16 . 020-cpu-rng.sh $sweep $param $winsze $binolp $montage :::: $batch

if ! test -f "/proj/sens2022521/1-shuai/2-results/020-cpu-rng/${sweep}/configs.csv"
then
    echo parameter,window,overlap,montage,path > /proj/sens2022521/1-shuai/2-results/020-cpu-rng/${sweep}/configs.csv
fi
echo ${param},${winsze},${binolp},${montage},/proj/sens2022521/1-shuai/2-results/020-cpu-rng/${sweep}/${param}-${winsze}-${binolp}-${montage}/ >> /proj/sens2022521/1-shuai/2-results/020-cpu-rng/${sweep}/configs.csv
