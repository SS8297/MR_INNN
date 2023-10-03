####################################################################################################

# load packages
begin
  import Pkg
  Pkg.activate("/proj/sens2022521/EEG")
  using MindReader
  using DataFrames
  using DelimitedFiles
  using XLSX
  using CSV
  using Glob
end;

######################################################################################$

# argument parser
include("Utilities/argParser.jl");

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

  sample = replace(shArgs["input"], ".edf" => "")
	for channel in glob("*_traceback.csv", string("/proj/sens2022521/1-shuai/2-results/002-all/", sample))
		ch_df = CSV.read(channel, DataFrame)
		ch_mx = Matrix(ch_df)
		ch_ar = ch_mx[:,1]
		ch_perf = performance(ch_ar, labelAr[:,3])      

		# write annotation track
		R=r"_(.{2,3})_"
		ch_name = match(R, channel)
		path=string("/proj/sens2022521/1-shuai/2-results/004-perf/", sample, "-", ch_name[1], ".perf")

		println(path)
		touch(path)
		writedlm(path, ch_perf)
	end
end
####################################################################################################
