#!/usr/bin/env bash
#SBATCH -A sens2022521
#SBATCH -p core
#SBATCH -n 4
#SBATCH -t 01:00:00
#SBATCH -C gpu
#SBATCH --gpus-per-node 1
#SBATCH -o /proj/sens2022521/1-shuai/9-logs/%u-slurm-%j.out
#SBATCH --mail-user shuai1997@hotmail.se

for sample in /proj/sens2022521/1-shuai/2-results/014-app-mrr/*
do
output=/proj/sens2022521/1-shuai/2-results/015-bin-mrr/$(basename $sample)
sed '2,$s/1/0/g' $sample > $output
sed -i '2,$s/[2-5]/1/g' $output
done