#!/usr/bin/env bash
#SBATCH -A sens2022521
#SBATCH -p core
#SBATCH -n 4
#SBATCH -t 00:15:00
#SBATCH -o /proj/sens2022521/1-shuai/9-logs/%u-slurm-%j.out
#SBATCH --mail-user shuai1997@hotmail.se
# set -euo pipefail

sample=$(basename ${1%.*})
julia --project "/proj/sens2022521/1-shuai/1-scripts/210-read-mind.jl"  \
  --input "${sample}.edf" \
  --inputDir "/proj/sens2022521/2-EEGcohortMX/" \
  --params "Parameters.jl" \
  --paramsDir "/proj/sens2022521/MindReader/src/" \
  --annotation "${sample}.xlsx" \
  --annotDir "/proj/sens2022521/2-EEGcohortMX/" \
  --outDir "/proj/sens2022521/1-shuai/2-results/019-gpu-rng/${sample}" \
  --additional "annotationCalibrator.jl,fileReaderXLSX.jl" \
  --addDir "/proj/sens2022521/EEG/src/annotation/functions/"
