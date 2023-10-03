#!/usr/bin/env bash
#SBATCH -A sens2022521
#SBATCH -p core
#SBATCH -n 4
#SBATCH -t 01:00:00
#SBATCH -C gpu
#SBATCH --gpus-per-node 1
#SBATCH -o /proj/sens2022521/1-shuai/9-logs/%u-slurm-%j.out
#SBATCH --mail-user shuai1997@hotmail.se

for sample in /proj/sens2022521/1-shuai/2-results/016-max-mrr/*
do
    label=/proj/sens2022521/1-shuai/2-results/012-ann/$(basename $sample).label
    paste $label $sample > /proj/sens2022521/1-shuai/2-results/017-mrg-ann/$(basename $sample)
done