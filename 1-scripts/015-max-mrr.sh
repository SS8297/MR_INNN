#!/usr/bin/env bash
#SBATCH -A sens2022521
#SBATCH -p core
#SBATCH -n 4
#SBATCH -t 01:00:00
#SBATCH -C gpu
#SBATCH --gpus-per-node 1
#SBATCH -o /proj/sens2022521/1-shuai/9-logs/%u-slurm-%j.out
#SBATCH --mail-user shuai1997@hotmail.se

for sample in /proj/sens2022521/1-shuai/2-results/015-bin-mrr/*
do
awk -F'\t' 'BEGIN{call=false; OFS=FS}
    {
        if (NR==1)
            $(NF+1)="All";
        else {
            for(i=1; i<=NF; i++) {
                call = call || $i;
            }
            $(NF+1) = call;
            call=false;
        }
        print
    }' $sample > /proj/sens2022521/1-shuai/2-results/016-max-mrr/$(basename $sample)
done