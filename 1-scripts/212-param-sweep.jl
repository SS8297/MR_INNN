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
  end

  edfDf = remontage(edfDf, shArgs["montage"])

  # calculate FFT
  shArgs["window-size"] = Int(recordFreq[1]*shArgs["window-size"])
  freqDc = extractFFT(edfDf, shArgs)

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

# build autoencoder & train hidden Markov model
begin

  # create empty dictionary
  hmmDc = Dict{String, HMM}()


  for (κ, υ) in freqDc

    # add channel patch
    if κ == "-" continue end

    print()
    @info κ

    # Serialize
    path = shArgs["outDir"] * string(κ) * "/"
    mkpath(path)
    writedlm(path * "fft.csv", shifter(υ), ',')
    writedlm(path * "label.csv", labelAr, ',')

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

    ɒ = freqAr
    args = NNParams()
    # @info "Loading data..."
    trainAr = args.device.(ɒ)
    loss(χ) = args.loss(model(χ), χ)
    opt = ADAM(args.η)
    # training
    # evalcb = throttle(() -> @show(loss(trainAr[1])), args.throttle)
    ael = Array{String}(undef, args.epochs)
    for e in 1:args.epochs
      @info "Epoch " * string(e)
      train!(loss, params(model), zip(trainAr), opt)
      ####################################################################################################
      
      # calculate post autoencoder
      postAr = cpu(model).(freqAr)

      # autoencoder error
      aErr = reshifter(postAr - freqAr) |> π -> flatten(π) |> π -> permutedims(π)

      # Serialize
      writedlm(path * "rce.csv", aErr, ',')

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

####################################################################################################
