#!/usr/bin/env bash
#SBATCH -A sens2022521
#SBATCH -p core
#SBATCH -n 4
#SBATCH -t 01:00:00
#SBATCH -C gpu
#SBATCH --gpus-per-node 1
#SBATCH -o /proj/sens2022521/1-shuai/9-logs/%u-slurm-%j.out
#SBATCH --mail-user shuai1997@hotmail.se

for sample in /proj/sens2022521/1-shuai/2-results/002-all/*
do
    name=$(basename $sample)
    paste ${sample}/*_traceback.csv > /proj/sens2022521/1-shuai/2-results/014-app-mrr/${name}
done


