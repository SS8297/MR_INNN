#!/usr/bin/env bash
# set -euo pipefail
cd /proj/sens2022521/MindReader
julia --project "/proj/sens2022521/MindReader/src/ReadMind.jl" \
  --input "0001LB.edf" \
  --inputDir "/proj/sens2022521/EEGcohortMX/" \
  --params "Parameters.jl" \
  --paramsDir "/proj/sens2022521/MindReader/src/" \
  --annotation "0001LB.xlsx" \
  --annotDir "/proj/sens2022521/EEGcohortMX/" \
  --outDir "/proj/sens2022521/1-shuai/2-results/" \
  --additional "annotationCalibrator.jl,fileReaderXLSX.jl" \
  --addDir "/proj/sens2022521/EEG/src/annotation/functions/"
cd /proj/sens2022521/1-shuai/1-scripts
