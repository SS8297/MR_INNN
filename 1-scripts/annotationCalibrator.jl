####################################################################################################

# load packages
begin
  using Dates
end;

####################################################################################################

"""

    annotationReader(path::S, summaryFile::S; verbose::B = false)
      where S <: String
      where B <: Bool

# Description
Extract anomaly events from summary file [physionet]. Return a dictionary with files as keys.


See also: [`annotationCalibrator`](@ref), [`labelParser`](@ref)
"""
function annotationReader(path::S, summaryFile::S; verbose::B = false) where S <: String where B <: Bool

  # verbose
  if verbose @info "Reading annotations..." end

  annotDc = Dict{String, Vector{Tuple{Second, Second}}}()
  lastFile = ""
  startTime = Second(0)
  endTime = Second(0)
  timeVc = [(startTime, endTime)]
  ç = 0
  ϟ1 = false
  ϟ2 = false

  # read file by lines
  for ł ∈ eachline(string(path, summaryFile))

    # identify lines
    if contains(ł, "File Name")
      lastFile = getSeizureFile(ł)
      ϟ1 = true
    elseif contains(ł, "Number of Seizures")
      ç = getSeizureNo(ł)
    elseif contains(ł, "Seizure") && contains(ł, "Start Time")
      startTime = getSeizureSec(ł)
    elseif contains(ł, "Seizure") && contains(ł, "End Time")
      endTime = getSeizureSec(ł)
      push!(timeVc, (startTime, endTime))
      if length(timeVc) == ç + 1
        ϟ2 = true
      end
    end

    # collect on switches
    if ϟ1 && ϟ2
      ϟ2 = false
      annotDc[lastFile] = timeVc[2:end]
      timeVc = [(startTime, endTime)]
    end

  end

  return annotDc
end

####################################################################################################

"""

annotationCalibrator(annotations::VT;
recordFreq::V, signalLength::I, shParams::D, verbose::B = false)
where VT <: Vector{Tuple{Sc, Sc}}
where Sc <: Second
where V <: Vector{N}
where N <: Number
where I <: Int64
where D <: Dict
where B <: Bool

# Description
Calibrate timestamp from summary file [physionet].

# Arguments
`annotations` annotations summary [physionet].

`recordFreq` recording frecuency.

`signalLength` recording length.

`shParams` dictionary with command line arguments to extract: `binSize` window bin size and `binOverlap` overlap.

`verbose` set verbosity.


See also: [`annotationReader`](@ref), [`labelParser`](@ref)
"""
function annotationCalibrator(annotations::VT; recordFreq::V, signalLength::I, shParams::D, verbose::B = false) where VT <: Vector{Tuple{Sc, Sc}} where Sc <: Second where V <: Vector{N} where N <: Number where I <: Int64 where D <: Dict where B <: Bool

  # verbose
  if verbose @info "Calibrating annotations..." end

  # collect recording frecuency
  recFreq = begin
    recAv = (sum(recordFreq)) / (length(recordFreq))
    recAv |> π -> convert(Int64, π)
  end

  # generate signal holder
  signalVec = zeros(signalLength)

  # collect annotations
  for α ∈ annotations
    emSt = α[1].value * recFreq
    emEn = (α[2].value * recFreq) + recFreq
    signalVec[emSt:emEn, :] .= 1
  end

  # binned signal
  binVec = begin
    binVec = extractSignalBin(signalVec, binSize = shParams["window-size"], binOverlap = shParams["bin-overlap"])
    binVec = sum(binVec, dims = 2)
    replace!(ρ -> ρ >= 1 ? 1 : 0, binVec)
    binVec[:, 1]
  end

  return binVec
end

####################################################################################################

"""

    annotationCalibrator(xDf;
    startTime::Tm, recordFreq::V, signalLength::X, shParams::D, verbose::B = false)
      where Tm <: Time
      where V <: Vector{N}
      wher N <: Number
      where X <: Int64
      where D <: Dict
      where B <: Bool

# Description
Calibrate annotations from XLSX.

# Arguments
`xDf` annotations from XLSX file.

`startTime` signal start time.

`recordFreq` recording frecuency.

`signalLength` recording length.

`shParams` dictionary with command line arguments to extract: `binSize` window bin size and `binOverlap` overlap.

`verbose` set verbosity.


See also: [`annotationReader`](@ref), [`labelParser`](@ref)
"""
function annotationCalibrator(xDf; startTime::Tm, signalLength::X, recordFreq::V, shParams::D, verbose::B = false) where Tm <: Time where X <: Int64 where V <: Vector{N} where N <: Number where D <: Dict where B <: Bool

  # verbose
  if verbose @info "Calibrating annotations..." end

  # collect recording frecuency
  recFreq = begin
    recAv = (sum(recordFreq)) / (length(recordFreq))
    recAv |> π -> convert(Int64, π)
  end

  # fields to check
  fields = ["ST", "MA", "EM"]
  stepSize = floor(Int64, shParams["window-size"] / shParams["bin-overlap"])
  signalSteps = 1:stepSize:signalLength
  binArr = Matrix{Int64}(undef, length(signalSteps), 0)
  headerVec = Array{String}(undef, 1, 0)
  endTime= startTime + Dates.Second(signalLength/recFreq)

  for ο ∈ eachindex(fields)
    κ = fields[ο]

    # purge missing records on all columns
    toSupress = begin
      [ismissing(xDf[κ][j, i]) for j ∈ 1:size(xDf[κ], 1) for i ∈ 1:size(xDf[κ], 2)] |>
      π -> reshape(π, size(xDf[κ], 2), size(xDf[κ], 1)) |>
      π -> sum(π, dims = 1)
    end

    delete!(xDf[κ], (toSupress' .== size(xDf[κ], 2))[:, 1])

    # generate signal holder
    if ((κ=="ST") | (κ=="MA"))
      signalVec = zeros(signalLength, 4)
      re = r"(\d{1})=([A-Z\s0-9]+)"
      str = names(xDf[κ])[1]
      match = collect(eachmatch(re, str))
      for m in match
        headerVec = [headerVec m[2]]
      end
    else
      signalVec = zeros(signalLength)
      headerVec = [headerVec "IED"]
    end
    # collect annotations
    for ι ∈ 1:size(xDf[κ], 1)
      if (typeof(xDf[κ][ι, :START]) == Dates.Time) & (typeof(xDf[κ][ι, :END]) == Dates.Time)
        if (xDf[κ][ι, :START] > startTime) & (xDf[κ][ι, :END] < endTime)
          emSt = xDf[κ][ι, :START] - startTime |> π -> convert(Dates.Second, π) |> π -> π.value * recFreq + 1
          emEn = xDf[κ][ι, :END] - startTime |> π -> convert(Dates.Second, π) |> (π -> π.value * recFreq) |> π -> π + recFreq
          if (κ == "EM")
            if verbose @info "Reading EM sheet" end
            signalVec[emSt:emEn] .= 1
          end
          if (κ == "ST")
            if verbose @info "Reading ST sheet" end
            xDf[κ][ι, :START]
            state = "Uncaught error in state annotation!"
            if (ismissing(xDf[κ][ι, :"STATE 1=AWAKE, 2=SLEEP N1, 3=SLEEP N2, 4=SLEEP N3"]))
              state = 1
            else
              state = xDf[κ][ι, :"STATE 1=AWAKE, 2=SLEEP N1, 3=SLEEP N2, 4=SLEEP N3"]
              if verbose @info string(state) end
            end
            signalVec[emSt:emEn, state] .= 1
          end
          if (κ == "MA")
            if verbose @info "Reading MA sheet" end
            if verbose @info string(xDf[κ][ι, :"MANEUVER 1=HYPERVENTILATION, 2=PHOTIC, 3=EYES OPEN, 4=MOVEMENT"]) end
            signalVec[emSt:emEn, xDf[κ][ι, :"MANEUVER 1=HYPERVENTILATION, 2=PHOTIC, 3=EYES OPEN, 4=MOVEMENT"]] .= 1
          end
        elseif xDf[κ][ι, :START] < startTime
          @warn "Annotations occuring before start time found in " * string(κ) * " line " * string(ι)
        elseif xDf[κ][ι, :END] > endTime
          @warn "Annotations occuring after end time found in " * string(κ) * " line " * string(ι)
        else
          @warn "Event at start or end of " * string(κ) * " line " * string(ι)
          @warn "Start Time: " * string(startTime) * ", Index Start Time: " * string(xDf[κ][ι, :START]) * ", End Time: " * string(endTime) * ", Index End Time: " * string(xDf[κ][ι, :END])
        end
      end
      if ismissing(xDf[κ][ι, :START])
        @warn "Annotation start time is missing in " * string(κ) * " line " * string(ι)
      elseif typeof(xDf[κ][ι, :START]) != Dates.Time
        @warn "Invalid start time format in " * string(κ) * " line " * string(ι)
      end
      if ismissing(xDf[κ][ι, :END])
        @warn "Annotation end time is missing in " * string(κ) * " line " * string(ι)
      elseif typeof(xDf[κ][ι, :END]) != Dates.Time
        @warn "Invalid end time format in " * string(κ) * " line " * string(ι)
      end
    end

    # binned signal
    for i in 1:size(signalVec,2)
      binVec = begin
        binVec = extractSignalBin(signalVec[:,i], binSize = shParams["window-size"], binOverlap = shParams["bin-overlap"])
        binVec = sum(binVec, dims = 2)
        replace!(ρ -> ρ >= 1 ? 1 : 0, binVec)
        binVec = convert.(Int64, binVec)
        binVec[:, 1]
      end
      binArr = [binArr binVec]
    end
  end
  return [headerVec; binArr]
end

####################################################################################################

"""

    labelParser(ɒ::M;
    verbose::B = false)
      where M <: Matrix{N}
      where N <: Number
      where B <: Bool

# Description
Parse three-column array into binary encoding.


See also: [`annotationReader`](@ref), See also: [`annotationCalibrator`](@ref)
"""
function labelParser(ɒ::M; verbose::B = false) where M <: Matrix{N} where N <: Number where B <: Bool

  # verbose
  if verbose @info "Parsing annotations..." end

  lbSz = size(ɒ, 1)
  tmpAr = Array{String}(undef, lbSz, 1)
  for ι ∈ 1:lbSz
    tmpAr[ι, 1] = string(ɒ[ι,  1], ɒ[ι, 2], ɒ[ι, 3],)
  end
  Ω = parse.(Int64, tmpAr, base = 2)
  Ω = reshape(Ω, (size(Ω, 1),))

  return Ω
end

####################################################################################################

"""

    annotationSummaryChannels(path::S, summaryFile::S)
      where S <: String

# Description
Extract channels from summary file [physionet]. Return a vector of strings.


See also: [`annotationCalibrator`](@ref), [`labelParser`](@ref)
"""
function annotationSummaryChannels(path::S, summaryFile::S; lineCount = 50) where S <: String
  Ω = Vector{String}(undef, 0)
  ç = 0
  for ł ∈ eachline(string(path, summaryFile))
    ç += 1
    if contains(ł, "Channel ") && ç <= lineCount
      push!(Ω, split(ł, " ")[end])
    end
  end
  return Ω
end

####################################################################################################

"obtain seizure time [physionet]"
function getSeizureSec(annot::S) where S <: String
  annot |> π -> findfirst(':', π) |> π -> getindex(annot, π + 2:length(annot)) |> π -> replace(π, " seconds" => "") |> Second
end

"obtain number seizure events [physionet]"
function getSeizureNo(annot::S) where S <: String
  annot |> π -> replace(π, "Number of Seizures in File: " => "") |> π -> parse(Int64, π)
end

"obtain file name [physionet]"
function getSeizureFile(annot::S) where S <: String
  annot |> π -> replace(π, "File Name: " => "") |> π -> replace(π, ".edf" => "")
end

####################################################################################################
