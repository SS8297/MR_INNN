library(ggplot2)
library(ggpubr)
library(purrr)
x  =seq(-15, 55)
t = c()
m = c()
for (i in c(0, 10, 20, 30, 40)) {
  df = data.frame(X = x, Y = unlist(map(x, \(x) dnorm(x, mean = i, sd = 5))), M = rep(i, length(x))) 
  t = rbind(t, df)
}
for (i in c(1, 2, 3, 4, 5)) {
  df = data.frame(X = x, Y = unlist(map(x, \(x) dnorm(x, mean = 20, sd = 10) * i)), M = rep(i, length(x))) 
  m = rbind(m, df)
}
t$M = factor(t$M, levels = c("0", "10", "20", "30","40"))
m$M = factor(m$M, levels = c("5", "4", "3", "2","1"))
p1 = ggplot(t, aes(x = X, y = Y, group = M)) +
  geom_segment(aes(x=X, xend=X, y=0, yend=Y, color = M)) +
  geom_point(aes(color = M), size = 2) +
  theme_void() +
  scale_color_manual(values=c("grey20","grey40","grey60","grey80","red")) +
  theme(legend.position = "none")
p2 = ggplot(m, aes(x = X, y = Y, group = M)) +
  geom_segment(aes(x=X, xend=X, y=0, yend=Y, color = M)) +
  geom_point(aes(color = M), size = 2) +
  theme_void() +
  scale_color_manual(values=c("grey20","grey40","grey60","grey80","red")) +
  theme(legend.position = "none")

ggarrange(p1, p2, nrow = 2)
