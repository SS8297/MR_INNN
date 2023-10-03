library(readr)
library(ggplot2)
library(tidyr)
library(RColorBrewer)
library(gridExtra)
library(SynchWave)

fp2_fft = read_csv("2-results/0025MF/Fp2-FFT", 
          col_names = FALSE,
          show_col_types = FALSE)

fp2_aee = read_csv("2-results/0025MF/Fp2-AEE", 
               col_names = FALSE,
               show_col_types = FALSE)



spectra = function(data, log) {
  factor = colnames(data)
  data$Time = 1:nrow(data)
  data_l = gather(data, Frequency, Amplitude, X1:X256)
  data_l$Frequency = factor(data_l$Frequency, levels = factor)
  data_l$Amplitude = abs(data_l$Amplitude)
  if(log) {
    data_l$Amplitude = log2(data_l$Amplitude)
  }
  
  lbl = read_delim("2-results/0025MF.label", 
                   delim = "\t", escape_double = FALSE, 
                   trim_ws = TRUE,
                   show_col_types = FALSE)
  
  state = read_csv("2-results/0025MFhmm/0025MF_Fp2_traceback.csv",
                   show_col_types = FALSE)
  
  fft1freq = read_csv("2-results/freqs.txt", 
                      col_names = FALSE)
  
  start = which(diff(lbl$IED)==1)+1
  end = which(diff(lbl$IED)==-1)
  if(lbl$IED[1] == 1) {
    start = c(1, start)
  }
  
  #TODO end = 1

  sE = which(diff(lbl$Fp2)==1)+1
  eE = which(diff(lbl$Fp2)==-1)
  if(lbl$Fp2[1] == 1) {
    sE = c(1, sE)
  }
  
  st = rle(state$Fp2)
  sthe = st$values - 1
  sten = cumsum(st$lengths)
  stst = sten - (st$lengths - 1)
  
  fp2 = rle(state$Fp2)
  fp2End = cumsum(fp2$lengths)
  fp2Start = fp2End - (fp2$lengths - 1)
  fp2End = fp2End[fp2$values > 1]
  fp2Start = fp2Start[fp2$values > 1]
  
  ggplot(data = data_l, aes(x=Time, y=Frequency, fill=Amplitude)) +
    geom_tile() +
    scale_fill_distiller(palette = "YlGnBu", trans = "reverse") +
    scale_y_discrete(expand=c(0,0), breaks = factor, labels=fft1freq$X1) +
    annotate("rect", xmin = start, xmax = end, ymin = -Inf, ymax = Inf, alpha = 0.01, color="green",
             label = "Interictal Epileptiform Discharges") +
    annotate("rect", xmin = sE, xmax = eE, ymin = -Inf, ymax = Inf, alpha = 0.01, color="blue",
             label = "MindReader Classification") +
    annotate("segment", x = stst, xend = sten, y = sthe/4*256, yend = sthe/4*256, color="red", size = 2,
             label = "Hidden Markov Model States")
}

p1 = spectra(fp2_fft, FALSE) +
  ggtitle("Fourier Transform Spectrogram")
p2 = spectra(fp2_aee, FALSE)  +
  ggtitle("Reconstruction Error Spectrogram")

grid.arrange(p1, p2)


