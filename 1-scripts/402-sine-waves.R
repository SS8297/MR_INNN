range = seq(0, by=1/128, length.out = 256)

write.table(sin(60*1:(128*2)), "60-hz.txt", row.names=FALSE, col.names=FALSE)
write.table(sin(128*1:1000), "128-hz.txt", row.names=FALSE, col.names=FALSE)
write.table(sin(60*1:1000), "60-hz.txt", row.names=FALSE, col.names=FALSE)
write.table(sin(256*1:1000), "128-hz.txt", row.names=FALSE, col.names=FALSE)
write.table(sin(range * 2 * pi), "1-hz.txt", row.names=FALSE, col.names=FALSE)

library(readr)
fft60 = read_csv("2-results/fft60hz", 
                    col_names = FALSE)
fft1 = read_csv("2-results/fft1hz", 
                 col_names = FALSE)
fft1freq = read_csv("2-results/fft1hzfreq", 
                col_names = FALSE)
