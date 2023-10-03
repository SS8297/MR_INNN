#!/usr/bin/env bash
#SBATCH -A sens2022521
#SBATCH -p node
#SBATCH -n 1
#SBATCH -t 20:00:00
#SBATCH -o /proj/sens2022521/1-shuai/9-logs/%u-slurm-%j.out
#SBATCH --mail-user shuai1997@hotmail.se
# set -euo pipefail

ml julia gnuparallel

cd /proj/sens2022521/MindReader
parallel -j 4 . /proj/sens2022521/1-shuai/1-scripts/006-init-any.sh ::: /proj/sens2022521/EEGcohortMX/*.edf
cd /proj/sens2022521/1-shuai/1-scripts
