library(readr)
library(purrr)

files = list.files("~/Repositories/EEG_INNN_dataset/2-results/labels_oct/", full.names = TRUE, include.dirs = TRUE)

tf = function(path) {
  file = read_csv(paste(path, "/A1/label.csv",sep=""), col_types = cols(.default = col_logical()))
  ied = file$IED
  nTrue = sum(ied)
  nFalse = sum(!ied)
  dur = paste("~/Repositories/EEG_INNN_dataset/2-results/024-durations/",basename(path),sep="")
  sec = read_csv(dur, 
           col_names = FALSE, col_types = cols(.default = col_double()))
  if(file.exists(paste("~/Repositories/EEG_INNN_dataset/2-results/oct/cwt_cnn-4-4-Average-CWT/",basename(path), "/MC/perf.csv",sep=""))) {
    perf = read_csv(paste("~/Repositories/EEG_INNN_dataset/2-results/oct/cwt_cnn-4-4-Average-CWT/",basename(path), "/MC/perf.csv",sep=""), show_col_types=FALSE)
    test= map(perf$FPR, \(x) map(strsplit(x, split = ":"), as.double))
    mx = matrix(unlist(test), ncol = 5, byrow = TRUE)
    ans = (mx[6,4]*nFalse)/(sec/60)
    }
  else {
    ans = 0
    }
  }

reduce(map(files, tf), `+`)/(length(files)-1)

