import Pkg
Pkg.activate("/proj/sens2022521/EEG")
using XLSX
using DelimitedFiles
using DataFrames
using Glob

file = XLSX.readxlsx(ARGS[1], DataFrame) 
for sheet in XLSX.sheetnames(file)
	for i,j in file[sheet][:]
		
	
