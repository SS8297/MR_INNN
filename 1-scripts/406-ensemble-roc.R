library(readr)
library(ggplot2)
library(pROC)
library(tidyr)
library(Rfast)
library(matrixStats)

roc = function(path){
  s25 = read_delim(path, 
                        delim = "\t", escape_double = FALSE, 
                        col_types = cols(.default = col_logical()),
                        trim_ws = TRUE)
  if ("A1" %in% colnames(s25)) {
    eltrd = subset(s25, select = A1:T6)
  }
  else {
    eltrd = subset(s25, select = C3:T6)
  }

  res = matrix(ncol = ncol(eltrd), nrow = nrow(eltrd))
  for (i in 1:nrow(eltrd)) {
    call = rep(0,ncol(eltrd))
    for (n in 1:ncol(eltrd)) {
      if (sum(eltrd[i,]) >= n) {
        call[n] = TRUE
      }
    }
    res[i,] = call
  }
  tpr = rep(0, ncol(eltrd) +2)
  fpr = rep(0, ncol(eltrd) +2)
  tpr[length(tpr)] = 1
  fpr[length(fpr)] = 1
  for (t in 1:ncol(eltrd)) {
    cm = matrix(0, ncol = 2, nrow = 2)
    for (i in 1:length(s25$IED)){
     if ((s25$IED[i] == TRUE) && (res[i, t] == TRUE)) {
       cm[1,1] = cm[1,1] + 1
     }
      else if ((s25$IED[i] == TRUE) && (res[i, t] == FALSE)) {
        cm[2,1] = cm[2,1] + 1
      }
      else if ((s25$IED[i] == FALSE) && (res[i, t] == TRUE)) {
        cm[1,2] = cm[1,2] + 1
      }
      else {
        cm[2,2] = cm[2,2] + 1
      }
    }
    tpr[t+1] = cm[1,1]/(cm[1,1]+cm[2,1])
    fpr[t+1] = cm[1,2]/(cm[1,2]+cm[2,2])
  }
  data = as.data.frame(cbind(tpr,fpr))
}

files = list.files(path="2-results/labels/", full.names=TRUE, recursive=FALSE)
# wide = matrix(0,nrow=21, ncol=2)
long  = c()
for (i in 21:length(files)){
  print(i)
  data = roc(files[i])
  data$sample = rep(basename(files[i]), nrow(data))
  long = rbind(long, data)
  # wide[,1] = wide[,1] + data$fpr
  # wide[,2] = wide[,2] + data$tpr
  # plot = plot + geom_line(data=data, aes(x=fpr, y=tpr))
}
# wide=wide/length(files)

axes = matrix(0, ncol = 81, nrow = 101)
for (i in 1:length(unique(long$sample))){
  print(i)
  v=long[long$sample==unique(long$sample)[i],]
  values = approx(x=v$fpr, y=v$tpr,n=101)
  axes[,1]=values$x
  axes[,i] = values$y
}
# long = gather(as.data.frame(axes), sample, value)
axes[,77] = rowMins(axes[,2:75], value = TRUE)
axes[,78] = rowMeans(axes[,2:75])
axes[,79] = rowMaxs(axes[,2:75], value = TRUE)
qt = rowQuantiles(axes[,2:75])
axes[,80] = qt[,2]
axes[,81] = qt[,4]
plot = ggplot(data = as.data.frame(axes), aes(x = V1))  +
  theme_bw() +
  xlab("False Positive Rate") +
  ylab("True Positive Rate") +
  geom_ribbon( aes(ymin=V77, ymax=V79), alpha = 0.4) +
  geom_ribbon( aes(ymin=V80, ymax=V81), alpha = 0.4) +
  annotate(geom = "segment", x = 0, xend = 1, y = 0, yend = 1, color="red", linetype=2, linewidth = 1.5) +
  geom_line(aes(y = V78), color = "blue", linewidth = 1)

