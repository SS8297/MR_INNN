#!/usr/bin/env bash
#SBATCH -A sens2022521
#SBATCH -p core
#SBATCH -n 4
#SBATCH -t 4:00:00
#SBATCH -o /proj/sens2022521/1-shuai/9-logs/%u-slurm-%j.out
#SBATCH --mail-user shuai1997@hotmail.se
#SBATCH --mail-type=END
# set -euo pipefail

ml julia/1.7.2 gnuparallel
parallel -j 4 . 008-init-perf.sh ::: /proj/sens2022521/2-EEGcohortMX/*.xlsx
