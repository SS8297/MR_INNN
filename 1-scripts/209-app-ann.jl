using EDF
using CSV
using DataFrames

label = ARGS[1]
file = split(label, "/")[end]
sample = split(file, ".")[1]
edf = "/proj/sens2022521/2-EEGcohortMX/" * sample * ".edf"
outpath = "/proj/sens2022521/1-shuai/2-results/013-app-ann/" * sample * "-ANN.edf"

function realtimeAnnotations(ann::String; recordFreq::Vector{Int64}=[128], windowSize::Int64=256, binOverlap::Int64=4)
    freq = -1
    if (!all(x -> x==recordFreq[1], recordFreq))
        @warn "Not all frecording frequencies are equal!"
        @warn "Aborting!"
        return
    else
        freq = recordFreq[1]
    end
    stepSize = floor(Int64, windowSize / binOverlap)

    annotations = CSV.read(ann, DataFrame)
    tals = []
    for (text, type) in pairs(eachcol(annotations))
        prev = false
        eventStart = -1
        eventDuration = 0
        for i in 1:length(type)
            #TODO REVERSE DIRECTION
            bins = collect(i:-1:(i - (binOverlap-1)))
            bins = bins[bins.>0]
            call = sum(type[bins]) >= length(bins)
            if (call && !prev)
                eventStart = (i-1) * stepSize / freq
                eventDuration += stepSize / freq
            elseif (call && prev)
                eventDuration += stepSize / freq
            elseif (!call && prev)
                # @info "Pushed annotation!"
                # @info string([EDF.TimestampedAnnotationList(eventStart, eventDuration, [String(text)])])
                push!(tals, EDF.TimestampedAnnotationList(eventStart, eventDuration, [String(text)]))
                eventStart = -1
                eventDuration = 0
            end
            prev = call
        end
    end
    return convert(Vector{EDF.TimestampedAnnotationList}, tals)

end

function appendAnnotations(tals::Vector{EDF.TimestampedAnnotationList}, edf::String)
    sample = EDF.read(edf)
    sigs = sample.signals
    #TODO DON'T ASSUME FIRST SIGNAL IS STANDARD EEG
    freq = sigs[1].header.samples_per_record
    vvTAL = [[EDF.TimestampedAnnotationList(t, nothing, [""])] for t=0.:(length(sigs[1].samples)/freq - 1)]
    spr = 300
    ann = ""
    annIndex = -1
    for i in 1:length(sigs)
        if (typeof(sigs[i]) == EDF.AnnotationsSignal)
            ann = sigs[i]
            annIndex = i
        end
    end
    if(annIndex != -1)
        while(length(tals) > 0)
            tal = pop!(tals)
            recTime = floor(Int64, tal.onset_in_seconds)
            @info recTime
            push!(vvTAL[recTime + 1], tal)
        end
        #sample.signals[annIndex] = EDF.AnnotationsSignal(spr, vvTAL)
        pop!(sample.signals)
        push!(sample.signals, EDF.AnnotationsSignal(spr, vvTAL))
    #TODO FIX DATE COMPLIANCE WITH EDF+
    else
        push!(sample.signals, EDF.AnnotationsSignal(spr, vvTAL))
    end
    return sample
end

begin
    tals = realtimeAnnotations(label)
    newEDF = appendAnnotations(tals, edf)
    EDF.write(outpath, newEDF)
end
