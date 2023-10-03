#!/usr/bin/env bash
outfile="/proj/sens2022521/1-shuai/2-results/"$2
touch $outfile
if [ ! -s $outfile ]; then
	header="Patient,Lobe,Number,"
	header=$header$(cat $1 | awk '{printf $1 ","}')
	echo ${header%?} >> $outfile
fi
re='([0-9]{4})[A-Z]{2}[0-9]{0,4}-([A-Za-z]{1,2})([0-9z]).'
[[ $1 =~ $re ]]
line=${BASH_REMATCH[1]}","${BASH_REMATCH[2]}","${BASH_REMATCH[3]}","
line=$line$(cat $1 | awk '{printf $2 ","}')
echo ${line%?} >> $outfile
