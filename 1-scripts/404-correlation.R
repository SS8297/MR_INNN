library(readr)
library(ggplot2)
library(tidyverse)
library(gridExtra)
fft = read_csv("2-results/0025MF/Fp2-FFT", 
               col_names = FALSE)
aee = read_csv("2-results/0025MF/Fp2-AEE", 
               col_names = FALSE)
lbl = read_delim("2-results/0025MF.label", 
                 delim = "\t", escape_double = FALSE, 
                 trim_ws = TRUE,
                 show_col_types = FALSE)

fdf = as.data.frame(as.matrix(dist(fft, diag = TRUE, upper = TRUE)))
adf = as.data.frame(as.matrix(dist(aee, diag = TRUE, upper = TRUE)))

fdf$X=1:nrow(fdf)
adf$X=1:nrow(adf)

fdfl = gather(fdf, Y, Distance, 1:1802)
adfl = gather(adf, Y, Distance, 1:1802)

fdfl$Y = as.integer(fdfl$Y)
adfl$Y = as.integer(adfl$Y)


ied = rle(lbl$IED)
iedEnd = cumsum(ied$lengths)
iedStart = iedEnd - (ied$lengths - 1)
iedEnd = iedEnd[ied$values == 1]
iedStart = iedStart[ied$values == 1]

margin = 0
int = length(iedStart) -1
xStart = c()
yStart = c()
xEnd = c()
yEnd = c()
for (i in 1:length(iedStart)) {
  xStart = c(xStart, iedStart[-c(1:i)] - margin)
  yStart = c(yStart, rep(iedStart[i], int) - margin)
  xEnd = c(xEnd, iedEnd[-c(1:i)] + margin)
  yEnd = c(yEnd, rep(iedEnd[i], int) + margin)
  int = int -1
}



fp = ggplot(fdfl, aes(x = X, y = Y, fill = Distance)) +
  geom_raster() +
  annotate("segment", x = iedStart, xend = iedEnd, y = iedStart, yend = iedEnd, color="red", linewidth = 1.5, lineend = "round") +
  annotate("rect", xmin = xStart, xmax = xEnd, ymin = yStart, ymax = yEnd, alpha = 0, color="green") +
  theme_light() + 
  ggtitle("Fourier Transform Distance Matrix")

ap = ggplot(adfl, aes(x = X, y = Y, fill = Distance)) +
  geom_raster() +
  annotate("segment", x = iedStart, xend = iedEnd, y = iedStart, yend = iedEnd, color="red", linewidth = 1.5, lineend = "round") +
  annotate("rect", xmin = xStart, xmax = xEnd, ymin = yStart, ymax = yEnd, alpha = 0, color="green") +
  theme_light() + 
  ggtitle("Reconstruction Error Distance Matrix")

grid.arrange(fp, ap, ncol=2)
