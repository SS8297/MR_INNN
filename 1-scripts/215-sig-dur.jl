using EDF
using DataFrames
using DelimitedFiles

path = "/proj/sens2022521/2-EEGcohortMX/"
edfs = filter(x->occursin(".edf", x), readdir(path))
durations = map(x -> begin header = EDF.read(path * x).header; [x, header.record_count * header.seconds_per_record] end, edfs)
secs = reduce(+, map(x -> x[2], durations[21:end]))
secs/60 = mins

for name, seconds in durations[21:end]
    writedlm(splitext(name)[1], seconds)
end
#dwt_dnn-4-4-Average-DWT]$ cat binary.txt |uniq -c | grep '\s0' | sed 's/\s0//' |  awk '{s+=$1} END {print s}'
# 1369880


