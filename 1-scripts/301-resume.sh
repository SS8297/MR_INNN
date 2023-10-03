#!/usr/bin/env bash
#WARNING DO NOT USE
#TODO HANDLE REF AND BP ELECTRODE COUNT
sweep=$1
paths=$(find /proj/sens2022521/1-shuai/2-results/020-cpu-rng/${sweep} -mindepth 2 -maxdepth 2 -type d)

for path in $paths
do
    sample=$(basename ${path%.*})
    ewc=0
    case $sample in
        000[1-9A-Z]*)
        ewc=19
        ;;
        00[1-9A-Z]*)
        ewc=21
        ;;
    esac
    awc=ls $1/* | wc -l
    config=$(echo ${path} | awk -F/ '{print $(NF-1)}')
    param=$(echo ${config} | cut -f1 -d '-')
    winsze=$(echo ${config} | cut -f2 -d '-')
    binolp=$(echo ${config} | cut -f3 -d '-')
    montage=$(echo ${config} | cut -f4 -d '-')
    ! [ $ewc -eq $awc ] && sbatch 020-cpu-rng.sh $sweep $param $winsze $binolp $montage $sample
done