#!/usr/bin/env bash
# Calls different parameters
sweep=$1
params=$(find ../4-params/ecs/ -type f)
batches=$(find ../2-results/000-batches/hyper/ -type f)
winsze=(4)
binolp=(4)
montages=(Average)

mkdir -p /proj/sens2022521/1-shuai/2-results/${sweep}/

parallel sbatch 120-cpu-rng.sh ::: $sweep ::: $params ::: ${winsze[@]} ::: ${binolp[@]} ::: ${montages[@]} ::: $batches