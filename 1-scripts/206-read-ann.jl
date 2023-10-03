####################################################################################################

# load packages
begin
  import Pkg
  Pkg.activate("/proj/sens2022521/EEG")
  using MindReader
  using DataFrames
  using DelimitedFiles
  using XLSX
end;

######################################################################################$

# argument parser
include("/proj/sens2022521/MindReader/src/Utilities/argParser.jl");

# include additional protocols
if haskey(shArgs, "additional") && haskey(shArgs, "addDir")
  for ι ∈ split(shArgs["additional"], ",")
    include(string(shArgs["addDir"], ι))
  end
end

######################################################################################$

#  read data
begin
  # read edf file
  edfDf, startTime, recordFreq = getSignals(shArgs)

  xDF = xread(shArgs)
  # calibrate annotations
  labelAr = annotationCalibrator(xDF;
  startTime = startTime,
  recordFreq = recordFreq,
  signalLength = size(edfDf, 1),
  shParams = shArgs,
  )
  labelAr
  end

####################################################################################################

# write annotation track
path=string("/proj/sens2022521/1-shuai/2-results/020-ann-tst/", replace(shArgs["input"], ".edf" => ""), ".label")
println(path)
touch(path)
writedlm(path, labelAr)

####################################################################################################
