####################################################################################################

# load packages
begin
  using MindReader
  using HiddenMarkovModelReaders
  using DelimitedFiles
  using CUDA
end;

####################################################################################################

# import flux
import Flux: cpu, gpu, flatten, leakyrelu

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
  # read edf file
  edfDf, startTime, recordFreq = getSignals(shArgs)

  # calculate fft
  freqDc = extractFFT(edfDf, shArgs)

  # Serialize
  for (signal, data) in freqDc
    path = shArgs["outDir"]  * "/"
    mkpath(path)
    writedlm(path * signal * "-FFT", shifter(data), ',')
  end
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

    #  build & train autoencoder
    freqAr = shifter(υ)

    model = buildAutoencoder(
      length(freqAr[1]);
      nnParams = NNParams,
    ) |> gpu

    modelTrain!(
      model,
      freqAr;
      nnParams = NNParams,
    )

    ####################################################################################################

    # calculate post autoencoder
    postAr = cpu(model).(freqAr)

    # autoencoder error
    aErr = reshifter(postAr - freqAr) |> π -> flatten(π) |> π -> permutedims(π)

    # Serialize
    path = shArgs["outDir"] * "/" 
    writedlm(path * κ * "-AEE", aErr, ',')
    
    ####################################################################################################

    begin
      # TODO: add hmm iteration settings
      @info "Creating Hidden Markov Model..."

      # setup
      hmm = setup(aErr)

      # process
      for _ ∈ 1:4
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

      # record hidden Markov model
      hmmDc[κ] = hmm
    end

    ####################################################################################################

  end

  print()
end;

####################################################################################################

# write traceback & states
writeHMM(hmmDc, shArgs)

####################################################################################################
