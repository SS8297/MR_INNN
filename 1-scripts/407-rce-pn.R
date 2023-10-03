library(readr)
library(ggplot2)
library(plotly)
library(Rfast)

files = list.files(path="2-results/0025MF/", pattern = ".*-AEE", full.names=TRUE, recursive=FALSE)

lbl = read_delim("2-results/labels/0025MF", 
                      delim = "\t", escape_double = FALSE, 
                      col_types = cols(.default = col_logical()),
                      trim_ws = TRUE)

st_files = list.files(path = "2-results/hmm_25/", pattern = ".*_states.csv", full.names = TRUE, recursive = FALSE)

ied = lbl$IED
phs = ied != TRUE

iedSt = matrix(0, ncol = 256, nrow = length(files))
phsSt = matrix(0, ncol = 256, nrow = length(files))

st1 = matrix(0, ncol = 256, nrow = 21)
st2 = matrix(0, ncol = 256, nrow = 21)
st3 = matrix(0, ncol = 256, nrow = 21)
st4 = matrix(0, ncol = 256, nrow = 21)
st5 = matrix(0, ncol = 256, nrow = 21)

for (i in 1:length(files)){
  rce = read_csv(files[i], 
           col_names = FALSE,
           show_col_types = FALSE)
  iedSt[i,] = colMeans(rce[ied,])
  phsSt[i,] = colMeans(rce[phs,])
}
df = data.frame(IED = colMeans(iedSt), PHS = colMeans(phsSt))

for (i in 1:length(st_files)){
  stsp = read_csv(st_files[i], 
                 show_col_types = FALSE)
  st1[i,] = stsp$S1
  st2[i,] = stsp$S2
  st3[i,] = stsp$S3
  st4[i,] = stsp$S4
  st5[i,] = stsp$S5
}
df = data.frame(st1 = colMeans(st1), st2 = colMeans(st2), st3 = colMeans(st3), st4 = colMeans(st4), st5 = colMeans(st5))


p1 = ggplot(df) +
  geom_line(aes(x = 1:256, y=IED), color = "Red", linewidth = 1) +
  geom_line(aes(x = 1:256, y=PHS), color = "Blue", linewidth = 1) + 
  geom_ribbon(aes(x = 1:256, ymin = colMins(iedSt, value = TRUE), ymax = colMaxs(iedSt, value = TRUE)), alpha = 0.2, fill = "Red") +
  geom_ribbon(aes(x = 1:256, ymin = colMins(phsSt, value = TRUE), ymax = colMaxs(phsSt, value = TRUE)), alpha = 0.2, fill = "Blue") +
  theme_bw() +
  xlab("Reconstruction Error Sampling Point") +
  ylab("Average Error")

p2 = ggplot() +
  geom_line(data = data.frame(IED = iedSt[11,]), aes(x = 1:256, y=IED), color = "Red", linewidth = 1) +
  geom_line(data = data.frame(PHS = phsSt[11,]), aes(x = 1:256, y=PHS), color = "Blue", linewidth = 1) + 
  theme_bw() +
  xlab("Reconstruction Error Sampling Point") +
  ylab("Average Error Fp2")

p1
p2

p3 = ggplot(df) +
  geom_line(aes(x = 1:256, y=st1), color = "Red", linewidth = 1) +
  geom_line(aes(x = 1:256, y=st2), color = "Blue", linewidth = 1) + 
  geom_line(aes(x = 1:256, y=st3), color = "Yellow", linewidth = 1) +
  geom_line(aes(x = 1:256, y=st4), color = "Purple", linewidth = 1) + 
  geom_line(aes(x = 1:256, y=st5), color = "Green", linewidth = 1) +
  theme_bw()
  