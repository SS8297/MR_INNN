#!/usr/bin/env bash
#SBATCH -A sens2022521
#SBATCH -p core
#SBATCH -n 1
#SBATCH -t 08:00:00
#SBATCH -o /proj/sens2022521/1-shuai/9-logs/%u-slurm-%j.out
#SBATCH --mail-user shuai1997@hotmail.se
# set -euo pipefail
# Calls different samples

sweep=$1
param=$2
sample=$(basename ${7%.*})

if [ ! -d /proj/sens2022521/1-shuai/2-results/022-shape/${sweep}/${param}-${3}-${4}-${5}-${6}/${sample}/ ]
then
mkdir -p /proj/sens2022521/1-shuai/2-results/022-shape/${sweep}/${param}-${3}-${4}-${5}-${6}/${sample}/
#changed cores from 8 to 4
julia -t 4 --project "/proj/sens2022521/1-shuai/1-scripts/214-shape.jl"  \
  --input "${sample}.edf" \
  --inputDir "/proj/sens2022521/2-EEGcohortMX/" \
  --params "${param}.jl" \
  --paramsDir "/proj/sens2022521/1-shuai/4-params/shape/" \
  --annotation "${sample}.xlsx" \
  --annotDir "/proj/sens2022521/2-EEGcohortMX/" \
  --outDir "/proj/sens2022521/1-shuai/2-results/022-shape/${sweep}/${param}-${3}-${4}-${5}-${6}/${sample}/" \
  --additional "annotationCalibrator.jl,fileReaderXLSX.jl" \
  --addDir "/proj/sens2022521/1-shuai/1-scripts/" \
  --window-size $3 \
  --bin-overlap $4 \
  --montage $5 \
  --spectra $6
fi
#####
