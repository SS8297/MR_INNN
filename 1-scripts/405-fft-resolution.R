library(SynchWave)
library(readr)
library(ggplot2)
library(plotly)

origin = read_csv("2-results/origin.csv", 
                   col_names = FALSE)
padded = read_csv("2-results/padded.csv", 
                   col_names = FALSE)
p768 = read_csv("2-results/768.txt", 
                  col_names = FALSE)
p768_1 = read_csv("2-results/768-1.txt", 
                col_names = FALSE)
p0_1 = read_csv("2-results/0-1.txt", 
                  col_names = FALSE)
p3840_1 =  read_csv("2-results/3840-1.txt", 
                    col_names = FALSE)

ox = ifftshift(seq(-64, by=0.5, length.out = 256))
px = ifftshift(seq(-64, by=0.25, length.out = 512))
x768 = ifftshift(seq(-64, by=128/1024, length.out = 1024))
x0_1 = ifftshift(seq(-128, by=256/256, length.out = 256))
x768_1 = ifftshift(seq(-128, by=256/1024, length.out = 1024))
x3840_1 = ifftshift(seq(-128, by=256/4096, length.out = 4096))

# plot(x768_1, log(p768_1$X1),type="l",col="red")
# lines(x0_1,log(p0_1$X1), col="blue")
# lines(x3840_1,log(p3840_1$X1), col="green")
# 
# lines(px,log(padded$X1),col="green")
# lines(x768, log(p768$X1), col="blue")
# lines(ox,log(origin$X1), col="pink")

odf = as.data.frame(cbind(ox, log(origin$X1)))
pdf = as.data.frame(cbind(px, log(padded$X1)))
o1df = as.data.frame(cbind(x0_1, log(p0_1$X1)))
p1df = as.data.frame(cbind(x768_1, log(p768_1$X1)))





plot_100 = ggplot(NULL) +
                geom_line(data = odf, color = "red", aes(ox, V2)) +
                geom_line(data = pdf, color = "blue", aes(px, V2)) +
                theme_bw()
ggplotly(plot_100)


plot_1 =  ggplot(NULL) +
  geom_line(data = o1df, color = "red", aes(x0_1, V2)) +
  geom_line(data = p1df, color = "blue", aes(x768_1, V2)) +
  theme_bw()
ggplotly(plot_1)
