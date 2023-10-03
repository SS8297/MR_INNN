library(readr)
library(purrr)


perf_mat = function(file) {
  perf = read_csv(file, show_col_types=FALSE)
  print(perf)
  test= map(perf$MCC, \(x) map(strsplit(x, split = ":"), as.double))
  mx = matrix(unlist(test), ncol = 5, byrow = TRUE)
  if(nrow(mx) != 10) {
    print("WARNING: check data")
  }
  mx
}
perf_sens = function(file) {
  perf = read_csv(file, show_col_types=FALSE)
  test= map(perf$Sensitivity, \(x) map(strsplit(x, split = ":"), as.double))
  mx = matrix(unlist(test), ncol = 5, byrow = TRUE)
  if(nrow(mx) != 10) {
    print("WARNING: check data")
  }
  mx
}
perf_spec = function(file) {
  perf = read_csv(file, show_col_types=FALSE)
  test= map(perf$Specificity, \(x) map(strsplit(x, split = ":"), as.double))
  mx = matrix(unlist(test), ncol = 5, byrow = TRUE)
  if(nrow(mx) != 10) {
    print("WARNING: check data")
  }
  mx
}
perf_fpr = function(file) {
  perf = read_csv(file, show_col_types=FALSE)
  test= map(perf$FPR, \(x) map(strsplit(x, split = ":"), as.double))
  mx = matrix(unlist(test), ncol = 5, byrow = TRUE)
  if(nrow(mx) != 10) {
    print("WARNING: check data")
  }
  mx
}

files = list.files("2-results/oct/cwt_cnn-4-4-Average-CWT", pattern = ".csv", recursive = TRUE, full.names = TRUE)
sum = reduce(map(files, perf_mat), `+`)
average = sum/length(files)
cc_sum_sens = reduce(map(files, perf_sens), `+`)
cc_avg_sens = cc_sum_sens/length(files)
cc_sum_spec = reduce(map(files, perf_spec), `+`)
cc_avg_spec = cc_sum_spec/length(files)
cc_sum_fpr = reduce(map(files, perf_fpr), `+`)
cc_avg_fpr = cc_sum_fpr/length(files)
max(average)


dwt_cnn = list.files("2-results/oct/dwt_cnn-4-4-Average-DWT", pattern = ".csv", recursive = TRUE, full.names = TRUE)
dc_sum = reduce(map(dwt_cnn, perf_mat), `+`)
dc_avg = dc_sum/length(dwt_cnn)
max(dc_avg)

stft_cnn = list.files("2-results/oct/stft_cnn-4-4-Bipolar-STFT", pattern = ".csv", recursive = TRUE, full.names = TRUE)
sc_sum = reduce(map(stft_cnn, perf_mat), `+`)
sc_avg = sc_sum/length(stft_cnn)
max(sc_avg)


dwt_dnn = list.files("2-results/oct/files", full.names = TRUE)
dd_sum = reduce(map(dwt_dnn, perf_samp), `+`)
dd_avg = dd_sum/length(dd_sum)
max(dd_avg)

perf_samp = function(file) {
  samp = list.files(file, pattern = "mcc.txt", recursive = TRUE, full.names = TRUE)
  perf = reduce(map(samp, perf_tabl), `+`)
  mx = perf/length(samp)
  mx
}
perf_tabl = function(file) {
  mx = read.table(file, sep = ":")
  mx[is.na(mx)] = 0
  if(nrow(mx) != 15) {
    print("WARNING: check data")
    print(nrow(mx))
  }
  mx
}

