####################################################################################################

# load packages
begin
  using MindReader
  using HiddenMarkovModelReaders
  using DelimitedFiles
  using CUDA
  using DataFrames
  using XLSX
end;

####################################################################################################

# import flux
import Flux: cpu, gpu, flatten, leakyrelu, ADAM, params, train!, mse

####################################################################################################

# import parameters
import Parameters: @with_kw

####################################################################################################

# argument parser
include("/proj/sens2022521/MindReader/src/Utilities/argParser.jl");

####################################################################################################

# load parameters
include(string(shArgs["paramsDir"], shArgs["params"]))

####################################################################################################

# include additional protocols
if haskey(shArgs, "additional") && haskey(shArgs, "addDir")
  for ι ∈ split(shArgs["additional"], ",")
    include(string(shArgs["addDir"], ι))
  end
end

####################################################################################################

#  read data
begin
  @info string(shArgs["outDir"])
  # read edf file
  edfDf, startTime, recordFreq = getSignals(shArgs)
  function remontage(edfDf::DataFrame, montage::String; reference::String = "Cz")
    if(montage == "None")
      return edfDf
    end
    if(montage == "Referential")
      ref = edfDf[!,Symbol(reference)]
      mapcols!(col -> col .- ref, edfDf)
      select!(edfDf, Not(reference))
      return edfDf
    end
    if(montage == "Average")
      avg = reduce(+, eachcol(edfDf)) ./ ncol(edfDf)
      mapcols!(col -> col .- avg, edfDf)
      return edfDf
    end
    # if(montage == "Laplacian")
    #   return edfDf
    # end
    if(montage == "Bipolar")
      bpm = DataFrame()
      ltc = ["Fp1", "F7", "T3", "T5", "O1"]
      lpsc = ["Fp1", "F3", "C3", "P3", "O1"]
      cc =  ["Fz", "Cz", "Pz"]
      rpsc = ["Fp2", "F4", "C4", "P4", "O2"]
      rtc = ["Fp2", "F8", "T4", "T6", "O2"]
      for chain in [ltc, lpsc, cc, rpsc, rtc]
        ccp = copy(chain) #Unnecessary?
        local re; local ae
        while(length(ccp) > 0)
          (@isdefined re) && (ae = re)
          re = popfirst!(ccp)
          (@isdefined ae) && (bpm[!,Symbol(ae * "-" * re)] = edfDf[!, Symbol(ae)] .- edfDf[!, Symbol(re)])
        end
      end
      return bpm
    end

    if(montage == "tBipolar")
      bpm = DataFrame()
      fpc = ["F7", "Fp1", "Fp2", "F8"]
      fc = ["F7", "F3", "Fz", "F4", "F8"]
      cc =  ["T3", "C3", "Cz", "C4", "T4"]
      pc = ["T5", "P3", "Pz", "P4", "T6"]
      oc = ["T5", "O1", "O2", "T6"]
      for chain in [fpc, fc, cc, pc, pc]
        ccp = copy(chain) #Unnecessary?
        local re; local ae
        while(length(ccp) > 0)
          (@isdefined re) && (ae = re)
          re = popfirst!(ccp)
          (@isdefined ae) && (bpm[!,Symbol(ae * "-" * re)] = edfDf[!, Symbol(ae)] .- edfDf[!, Symbol(re)])
        end
      end
      return bpm
    end

    if(montage == "hatband")
      bpm = DataFrame()
      ltc = ["Fp1", "F7", "T3", "T5", "O1", "O2"]
      lpsc = ["Fp1", "F3", "C3", "P3", "O1"]
      cc =  ["Fz", "Cz", "Pz"]
      rpsc = ["Fp2", "F4", "C4", "P4", "O2"]
      rtc = ["Fp1", "Fp2", "F8", "T4", "T6", "O2"]
      for chain in [ltc, lpsc, cc, rpsc, rtc]
        ccp = copy(chain) #Unnecessary?
        local re; local ae
        while(length(ccp) > 0)
          (@isdefined re) && (ae = re)
          re = popfirst!(ccp)
          (@isdefined ae) && (bpm[!,Symbol(ae * "-" * re)] = edfDf[!, Symbol(ae)] .- edfDf[!, Symbol(re)])
        end
      end
      return bpm
    end
  end

  edfDf = remontage(edfDf, shArgs["montage"])

  # calculate FFT
  shArgs["window-size"] = Int(recordFreq[1]*shArgs["window-size"])
  if (shArgs["spectra"] == "FFT") freqDc = extractFFT(edfDf, shArgs) end
  if (shArgs["spectra"] == "STFT") freqDc = extractFFT(edfDf, shArgs, window = true, onlyAbs = false) end
  if (shArgs["spectra"] == "DWT") freqDc = extractDWT(edfDf, shArgs) end
  if (shArgs["spectra"] == "CWT") freqDc = extractCWT(edfDf, shArgs) end

  xDF = xread(shArgs)
  # calibrate annotations
  labelAr = annotationCalibrator(xDF;
  startTime = startTime,
  recordFreq = recordFreq,
  signalLength = size(edfDf, 1),
  shParams = shArgs,
  )
end

####################################################################################################

# build autoencoder & train hidden Markov model -- single channel analysis
#
args = NNParams()
opt = ADAM(args.η)
####################################################################################################
hmmDc = Dict{String, HMM}()
@info "annotations done"
if (shArgs["params"] == "dwt_dnn.jl")
  @info "if condition successful"
  begin

    # create empty dictionary


    for (κ, υ) in freqDc

      # add channel patch
      if κ == "-" continue end

      print()
      @info κ

      # Serialize
      path = shArgs["outDir"] * string(κ) * "/"
      mkpath(path)
      writedlm(path * "label.csv", labelAr, ',')
      # writedlm(path * "fft.csv", shifter(υ), ',')


      #  build & train autoencoder
      freqAr = shifter(υ)

      model = buildAutoencoder(
        length(freqAr[1]);
        nnParams = NNParams,
      ) |> gpu

      #TODO Expand
      # modelTrain!(
      #   model,
      #   freqAr;
      #   nnParams = NNParams,
      # )


      # @info "Loading data..."
      trainAr = args.device.(freqAr)
      loss(χ) = args.loss(model(χ), χ)
      # training
      # evalcb = throttle(() -> @show(loss(trainAr[1])), args.throttle)
      for e in 1:args.epochs
        @info "Epoch " * string(e)
        train!(loss, params(model), zip(trainAr), opt)
        ####################################################################################################

        # calculate post autoencoder
        postAr = cpu(model).(freqAr)

        # autoencoder error
        aErr = reshifter(postAr - freqAr) |> π -> flatten(π) |> π -> permutedims(π)

        # Serialize
        # writedlm(path * "rce.csv", aErr, ',')

        ####################################################################################################

        begin
          # TODO: add hmm iteration settings
          function iterHMM(aErr::Matrix{Float64}, iter::Int64)
            # setup
            hmm = setup(aErr)
            # process
            for _ ∈ 1:(iter-1)
              _ = process!(
                  hmm,
                aErr,
                true;
                params = hmmParams,
              )
            end

            # final
            for _ ∈ 1:2
              _ = process!(
                hmm,
                aErr,
                false;
                params = hmmParams,
              )
            end
            return hmm
          end

          st_values = []
          st_header = []

          hmm = undef
          for i in 2:hmmParams.states
            #TODO: retrieve max iter from settings, calculate performance after each iteration
            hmm = iterHMM(aErr, i)
            pc = convert(Vector{Bool}, hmm.traceback .> 1)
            tc = convert(Vector{Bool}, labelAr[2:end,9])

            cm  = Matrix{Int64}(undef, 2, 2)
            cm[1,1] = sum(tc .& pc)
            cm[1,2] = sum(.!tc .& pc)
            cm[2,1] = sum(tc .& .!pc)
            cm[2,2] = sum(.!tc .& .!pc)
            perf = performance(cm)
            # @info string(i) * ", Sens: " * string(perf["Sensitivity"]) * ", Spec: " * string(perf["Specificity"]) * ", F1: " * string(perf["FScore"])

            header = []
            values = []
            for (k, v) in perf
              push!(header, k)
              push!(values, v)
            end
              st_header = header
              st_values != [] ? st_values = hcat(st_values, values) : st_values = values
          end
          # record hidden Markov model
          hmmDc[κ] = hmm
        end

        ####################################################################################################

        #  read data
        begin
          file = path * "perf.csv"
          if !isfile(file)
          writedlm(file, permutedims(pushfirst!(pushfirst!(st_header, "Loss"), "Epoch")), ',')
          end
          prev = open(file, "a")
          writedlm(prev, permutedims(pushfirst!(pushfirst!(mapslices(x -> join(x, ":"), st_values, dims=2)[:,1], join(loss.(trainAr), ":")), string(e))), ',')
          close(prev)
        end
        ####################################################################################################
      end
    end
  end;
  ####################################################################################################
  # write traceback & states
  writeHMM(hmmDc, shArgs)


  ##########################################################################################################

  # build autoencoder & train hidden Markov model -- multi-channel analysis
else
  @info "Multichannel analysis"
  begin
    avg = Dict(
      "F7"  => [2,1],
      "T3"  => [3,1],
      "T5"  => [4,1],

      "Fp1" => [1,2],
      "F3"  => [2,2],
      "C3"  => [3,2],
      "P3"  => [4,2],
      "O1"  => [5,2],

      "Fz"  => [2,3],
      "Pz"  => [3,3],
      "Cz"  => [4,3],

      "Fp2" => [1,4],
      "F4"  => [2,4],
      "C4"  => [3,4],
      "P4"  => [4,4],
      "O2"  => [5,4],

      "F8"  => [2,5],
      "T4"  => [3,5],
      "T6"  => [4,5]
      )

    bp = Dict(
      "Fp1-F7"  => [1],
      "F7-T3"   => [2],
      "T3-T5"   => [3],
      "T5-O1"   => [4],

      "P3-O1"   => [5],
      "C3-P3"   => [6],
      "F3-C3"   => [7],
      "Fp1-F3"  => [8],

      "Fz-Cz"   => [9],
      "Cz-Pz"   => [10],

      "P4-O2"   => [11],
      "C4-P4"   => [12],
      "F4-C4"   => [13],
      "Fp2-F4"  => [14],

      "Fp2-F8"  => [15],
      "F8-T4"   => [16],
      "T4-T6"   => [17],
      "T6-O2"   => [18]
      )

    # NOT IN USE
    hb1 = Dict(
      "Fp1-F7"  => [1],
      "F7-T3"   => [2],
      "T3-T5"   => [3],
      "T5-O1"   => [4],

      "P3-O1"   => [5],
      "C3-P3"   => [6],
      "F3-C3"   => [7],
      "Fp1-F3"  => [8],

      "Fp1-Fp2" => [9],
      "Fz-Cz"   => [10],
      "Cz-Pz"   => [11],
      "O1-O2"   => [12],

      "P4-O2"   => [13],
      "C4-P4"   => [14],
      "F4-C4"   => [15],
      "Fp2-F4"  => [16],

      "Fp2-F8"  => [17],
      "F8-T4"   => [18],
      "T4-T6"   => [19],
      "T6-O2"   => [20]
      )

    hb2 = Dict(
      "Fp1-F7"  => [1,1],
      "F7-T3"   => [2,1],
      "T3-T5"   => [3,1],
      "T5-O1"   => [4,1],

      "Fp1-F3"  => [1,2],
      "F3-C3"   => [2,2],
      "C3-P3"   => [3,2],
      "P3-O1"   => [4,2],

      "Fp1-Fp2" => [1,3],
      "Fz-Cz"   => [2,3],
      "Cz-Pz"   => [3,3],
      "O1-O2"   => [4,3],

      "Fp2-F4"  => [1,4],
      "F4-C4"   => [2,4],
      "C4-P4"   => [3,4],
      "P4-O2"   => [4,4],

      "Fp2-F8"  => [1,5],
      "F8-T4"   => [2,5],
      "T4-T6"   => [3,5],
      "T6-O2"   => [4,5]
      )
      @info "Creating channel dicts"
    end
  ############################################################################################################
  shArgs["params"] == "stft_cnn.jl" && begin
    @info "using stft_cnn.jl"
    train = zeros(Float32, length(bp), shArgs["window-size"], 2, size(collect(values(freqDc))[1],3))
    map(x -> train[bp[x][1], :, :, :] = permutedims(freqDc[x][:,:,:], [2,1,3]), collect(keys(freqDc)))
  end

  shArgs["params"] == "dwt_cnn.jl" && begin
    @info "using dwt_cnn.jl"
    train = zeros(Float32, 5, 5, shArgs["window-size"], size(collect(values(freqDc))[1],3))
    map(x -> x in keys(avg) && (train[avg[x][1], avg[x][2], :,:] = freqDc[x][1,:,:]), collect(keys(freqDc)))
  end

  shArgs["params"] == "cwt_cnn.jl" && begin
    @info "using cwt_cnn.jl"
    train = convert.(Float32, reshape(reduce(hcat, collect(values(freqDc))), (recordFreq[1], recordFreq[1], freqDc.count, size(collect(values(freqDc))[1],3))))
  end

  ############################################################################################################
  # Serialize

  cnn_path = shArgs["outDir"] * "MC" * "/"
  mkpath(cnn_path)
  # writedlm(cnn_path * "transform.csv", train, ',')
  # writedlm(cnn_path * "label.csv", labelAr, ',')

  ###########################################################################################################
  #  build & train autoencoder
  @info "building autoencoder"
  cnn = buildAutoencoder(
    nnParams = NNParams,
  ) |> gpu


  @info "Loading data..."
  trainMx = args.device.([train])

  @info "constructing loss function"
  loss(χ) = mse(cnn(χ), χ)

  # training
  # evalcb = throttle(() -> @show(loss(trainAr[1])), args.throttle)
  for e in 1:args.epochs
    @info "Epoch " * string(e)
    train!(loss, params(cnn), trainMx, opt)
    ####################################################################################################
@info "train completed, loss was " * string(loss(train))
    # calculate post autoencoder
    postAr = cpu(cnn)(train)

    # autoencoder error
    if (shArgs["params"] == "stft_cnn.jl")
      aErr = permutedims(mapslices(x -> reduce(max, x), abs.(postAr[:,:,1,:] - train[:,:,1,:]), dims =  1), [3,1,2])
    elseif (shArgs["params"] == "cwt_cnn.jl")
      aErr = permutedims(dropdims(mapslices(x -> reduce(max, x), abs.(postAr - train), dims =  3), dims  = 3), [3,1,2])
    elseif (shArgs["params"] == "dwt_cnn.jl")
      aErr = permutedims(dropdims(mapslices(x -> reduce(max, x), abs.(postAr - train), dims =  [1,2]), dims  = 1), [3,1,2])
    end

@info "calculated error"
    # Serialize
    # writedlm(cnn_path * "rce.csv", aErr, ',')

    ####################################################################################################

    begin
      # TODO: add hmm iteration settings
      function iterHMM(aErr::Array{Float32, 3}, iter::Int64)
        # setup
        hmm = setup(aErr)
        # process
        for _ ∈ 1:(iter-1)
          _ = process!(
              hmm,
            aErr,
            true;
            params = hmmParams,
          )
        end

        # final
        for _ ∈ 1:2
          _ = process!(
            hmm,
            aErr,
            false;
            params = hmmParams,
          )
        end
        return hmm
      end
@info "beginning hmm"
      st_values = []
      st_header = []

      hmm = undef
      for i in 2:hmmParams.states
        #TODO: retrieve max iter from settings, calculate performance after each iteration
        hmm = iterHMM(aErr, i)
        pc = convert(Vector{Bool}, hmm.traceback .> 1)
        tc = convert(Vector{Bool}, labelAr[2:end,9])

        cm  = Matrix{Int64}(undef, 2, 2)
        cm[1,1] = sum(tc .& pc)
        cm[1,2] = sum(.!tc .& pc)
        cm[2,1] = sum(tc .& .!pc)
        cm[2,2] = sum(.!tc .& .!pc)
        perf = performance(cm)
        @info string(i) * ", Sens: " * string(perf["Sensitivity"]) * ", Spec: " * string(perf["Specificity"]) * ", MCC: " * string(perf["MCC"])
@info "calculated performance"
        header = []
        values = []
        for (k, v) in perf
          push!(header, k)
          push!(values, v)
        end
          st_header = header
          st_values != [] ? st_values = hcat(st_values, values) : st_values = values
      end
      hmmDc["Multi"] = hmm
    end
@info "serialized hmm"
    ####################################################################################################

    #  read data
    begin
      file = cnn_path * "perf.csv"
      if !isfile(file)
      writedlm(file, permutedims(pushfirst!(pushfirst!(st_header, "Loss"), "Epoch")), ',')
      end
      prev = open(file, "a")
      writedlm(prev, permutedims(pushfirst!(pushfirst!(mapslices(x -> join(x, ":"), st_values, dims=2)[:,1], join(loss.(trainMx), ":")), string(e))), ',')
      close(prev)
    end
    ####################################################################################################
  end
end