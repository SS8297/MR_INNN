library(readr)
library(purrr)
library(plotly)
library(ggplot2)
library(tidyr)
library(ggplotify)
library(gridExtra)
library(GGally)
library(ggalt)
library(dplyr)
library(stringr)

perf = read_csv("2-results/003-initial/fourth-4-4-Average/0025MF/Fp2/perf.csv", 
                col_types = cols(Epoch = col_integer()))

Loss = matrix(0, ncol = 921, nrow = 25);
for (i in 1:25) {
  Loss[i,] = unlist(map(strsplit(perf$Loss[i], split = ':'), as.numeric))
}

f1 = matrix(0, ncol = 4, nrow = 25);
for (i in 1:25) {
  f1[i,] = unlist(map(strsplit(perf$FScore[i], split = ':'), as.numeric))
}
colnames(f1) = c("S2", "S3", "S4", "S5" )
pf1 = plot_ly(z = f1, type = "surface")

sens = matrix(0, ncol = 4, nrow = 25);
for (i in 1:25) {
  sens[i,] = unlist(map(strsplit(perf$Sensitivity[i], split = ':'), as.numeric))
}
psens = plot_ly(z = sens, type = "surface")

df = as.data.frame(t(Loss))
colnames(df) = 1:25
dfl = gather(df, Epoch, Loss)
dfl$Epoch = as.factor(as.numeric(dfl$Epoch))
p_loss = ggplot(dfl) +
  geom_violin(aes(x=Epoch, y=Loss), fill = "grey") +
  theme_classic()

mLoss = apply(df, 2, median)
lvf1 = cbind(f1, mLoss)
# lvf1w = as.data.frame(lvf1)
# lvf1l = gather(lvf1w, Metric, Value)
coeff = max(mLoss)
# colors = c("AE MSE" = "black","Two States" = "#83739E","Three States" = "#018F9C","Four States" = "#FE7B72","Five States" = "#FFE494") #FDC3BE
# colors = c("AE MSE" = "black","Two States" = "#86E3CE","Three States" = "#D0E6A5","Four States" = "#FFDD94","Five States" = "#FA897B") #CCABD8
colors = c("AE MSE" = "black","Two States" = "#5F9595","Three States" = "#F0BC68","Four States" = "#C4D7D1","Five States" = "#FFB6A3") #F5D1C3
 ppp = ggplot(as.data.frame(lvf1), aes(x = 1:nrow(lvf1))) +
  geom_line(aes(y=mLoss / coeff, color = "AE MSE"), size = 1.5) +
  geom_line(aes(y=S2, color = "Two States"), size = 1) +
  geom_line(aes(y=S3, color = "Three States"), size = 1) +
  geom_line(aes(y=S4, color = "Four States"), size = 1) +
  geom_line(aes(y=S5, color = "Five States"), size = 1) + 
  scale_y_continuous(
    name = "MCC",
    sec.axis = sec_axis(~.*coeff, name="Loss")
  ) +
  scale_x_continuous(name = "Epoch") +
  theme_classic() +
  labs( x = "test", y = "test2", color = "Legend") +
  scale_color_manual(values = colors)

 
f1electrode = function(path) {
  perf = read_csv(paste(path, "perf.csv", sep = "/"), 
                  col_types = cols(Epoch = col_integer()),
                  show_col_types = FALSE)
  f1 = matrix(0, ncol = 4, nrow = 25);
  for (i in 1:25) {
    f1[i,] = unlist(map(strsplit(perf$MCC[i], split = ':'), as.numeric))
  }
  f1[is.na(f1)] = 0
  colnames(f1) = c("S2", "S3", "S4", "S5" )
  f1 = as.data.frame(f1)
  f1$Epoch = 1:nrow(f1)
  f1 = gather(f1, State, F1, S2:S5)
  return(f1)
 }
 
f1sample = function(path) {
  files = list.files(path=path, full.names=TRUE, recursive=FALSE)
  f1list = map(files, f1electrode)
  f1 = data.frame(Epoch = f1list[[1]]$Epoch, State = f1list[[1]]$State, F1 = reduce(map(f1list, \(x) x$F1), `+`)/ length(f1list))
  return(f1)
}

f1config = function(path) {
  files = list.files(path=path, full.names=TRUE, recursive=FALSE)
  f1list = map(files, f1sample)
  # epo = f1list[[1]]$Epoch
  # print(epo)
  # sta = f1list[[1]]$State
  # print(sta)
  # red = reduce(map(f1list, \(x) x$F1), `+`)
  # print(red)
  f1 = data.frame(Epoch = f1list[[1]]$Epoch, State = f1list[[1]]$State, F1 = reduce(map(f1list, \(x) x$F1), `+`)/ length(f1list))
  config = strsplit(basename(path), split = "-")
  ncols = cbind(c("LatFrac","Window","Overlap", "Montage"), config[[1]])
  for (i in 1:nrow(ncols)){
    f1[ncols[i,1]] = rep(ncols[i,2], nrow(f1))
  }
  return(f1)
}

files = list.files(path="2-results/003-initial/", full.names=TRUE, recursive=FALSE)
sweepp = reduce(map(files, f1config), rbind)
#no epochs
#sweepp = sweepp[sweepp$Epoch==15] 
#sweepp = subset(sweepp, select = -c(Epoch))
# sweep = sweepp[, c(7, 4, 5, 6, 1, 2, 3)]
sweep = sweepp[, c(5, 6, 2, 4, 1, 7, 3)]
sweep$Montage = as.factor(sweep$Montage)
sweep$LatFrac = as.factor(sweep$LatFrac)
sweep$Window = as.factor(sweep$Window)
sweep$Overlap = as.factor(sweep$Overlap)
sweep$Epoch = as.factor(sweep$Epoch)
sweep$State = as.factor(sweep$State)
  
scatter = map(sweep, \(x) if(is.factor(x)) unique(x) else x)
scatter$F1 = round(scatter$F1, digits = 5)
sdfl = data.frame()

for (i in 1:ncol(sweep)){
  col  = sweep[,i]
  enum = scatter[[i]]
  name = scatter[[i]]
  if (is.factor(col)){
    #fnames = c(fnames, c(colnames(sweep)[i]=paste(col, collapse = ':')))
    levels(sweep[,i]) = seq(0,1, length.out=nlevels(col))
    enum = seq(0,1, length.out=nlevels(col))
    name = levels(scatter[[i]])
  }
  sdfl = rbind(sdfl, cbind(rep(i, length(scatter[[i]])), enum, name ))
}

colnames(sdfl)[1] = "para"
sdfl$para = as.double(sdfl$para)
sdfl$enum = as.double(sdfl$enum)

#TODO https://stackoverflow.com/questions/34059017/replace-factors-with-a-numeric-value

sweep2 = mutate_all(sweep, \(x) as.numeric(as.character(x)))
sweep2$F1 = minmax(sweep2$F1)
tempsweep = as.data.frame(t(sweep2))
tempsweep$X = rownames(tempsweep)
xlabels = rownames(tempsweep)
tempsweep$X = as.factor(tempsweep$X)
tempsweep$X = 1:nlevels(tempsweep$X)
#sweep_long = gather(tempsweep, Run, ParamVal, V1:V1200)


cosip = function(yx, n) {
  ip=c()
  for (i in 1:(nrow(yx) - 1)) {
    end = yx[i+1,2]-yx[i,2]
    mu = seq(0, end, by=sign(end)/n)
    ip = c(head(ip,-1), unlist(map(mu, costep, yx[i,1], yx[i+1,1])))
  }
  #TODO FIX BELOW
  return(cbind(ip, seq(1,nrow(yx), length.out=length(ip))))
}

costep = function(mu, y1, y2) {
  mu2 = (1-cos(mu*pi))/2
  return(y1*(1-mu2)+y2*mu2)
}

minmax = function(x) {
  (x - min(x)) / (max(x)-min(x))
}


yx = map(tempsweep[,-ncol(tempsweep)], cbind, tempsweep[ncol(tempsweep)])
axes = map(yx, cosip, 20)
#mx = reduce(axes, \(i, j) merge(i, j, by = "V2"))
dx = as.data.frame(cbind(axes[[1]][,2], unlist(reduce(map(axes, \(x) x[,1]), cbind))))
colnames(dx) = 1:ncol(dx)
dxl = gather(dx, Run, ParamVal, 2:ncol(dx))
colnames(dxl)[1] = "X"

dxl$F1 = rep(0, nrow(dxl))
dxl$F2 = rep(0, nrow(dxl))
dxl$Run = as.integer(dxl$Run)
for (i in 1:nrow(dxl)){
  dxl$F1[i] = sweep$F1[(dxl$Run[i] - 1)]
}
for (i in 1:nrow(dxl)){
  dxl$F2[i] = sweep2$F1[(dxl$Run[i] - 1)]
}

dxls = dxl[order(dxl$F1),]
dxls$Run = factor(dxls$Run, levels = unique(dxls$Run))
#dxls$F1 = factor(round(dxls$F1, digits = 4), levels = unique(round(dxls$F1, digits = 4)))
v = dxls[(dxls$Run == 958 | dxls$Run == 158 | dxls$Run == 2),]
sdfl2 = sdfl
sdfl2[sdfl$para==7,]$name =  ""
sdfl3 = sdfl[sdfl$para != 7,]

sdf = data.frame(val = seq(0, 1, by = 0.005))
points = 5
sdf2 = data.frame(x = rep(7.08, points + 2), y = round(sort(c(seq(max(sweep$F1), min(sweep$F1), length.out = points), digits = 5), 2, ), decreasing = TRUE))

ggplot() +
  geom_line(data = dxls, aes(x = X, y = ParamVal, group = Run, color = F2, size = 1/F1, alpha = F2), inherit.aes = FALSE)+
  #stat_smooth(aes(x=X, y=ParamVal, group = Run), size = 0.1, alpha = 0.2, se=F) +
  theme_void() +
  theme(panel.grid.major.x  = element_line(color = "grey",
                                           size = 0.5,
                                           linetype = 1)) +
  #geom_text(aes(x=X,y=ParamVal, label = ParamVal)) +
  geom_text(data = sdfl3 ,aes(x=para,y=enum, label = name), hjust = 0, vjust = -1, size = 7.5) +
  geom_point(data = sdfl3 ,aes(x=para, y=enum)) +
  theme(
    axis.text.x = element_text(),
    legend.position = "none",
    text = element_text(size=21)
  ) +
  # scale_x_discrete(limits = c("Montage","LatFrac","Window","Overlap","Epoch","State","F1")) +
  scale_x_discrete(limits = c("Window","Overlap","State","LatFrac","Epoch","Montage","MCC")) +
  # sweep = sweepp[, c(7, 4, 5, 6, 1, 2, 3)]
  # sweep = sweepp[, c(5, 6, 2, 4, 1, 7, 3)]
  scale_color_distiller(palette = "RdGy") +
  geom_segment(data = sdf, aes( y = val, yend = val, color = val), x = 7, xend = 7.1, lwd = 2, , inherit.aes = FALSE) +
  geom_text(data = sdf2, aes(x = x, y = c(1, 0.75, 0.5, 0.25, 0), label = y), hjust = 0, nudge_x = 0.05, vjust = 0.5, size = 7.5)
  #geom_tile(data = dxls, aes(x=7, y=F1, fill=F1))



      # theme(legend.key.height = unit(7.5, 'cm'),
    #       legend.box.spacing = unit(-9, 'cm')
    #       )



# scale_colour_gradient2(
#   low = "#C4D7D100",
#   mid = "#F0BC6840",
#   high = "#FFB6A3E6",
#   midpoint = 0,
#   space = "Lab",
#   guide = "colourbar",
#   aesthetics = "colour"
# )
# scale_colour_gradient2(
#   low = "#ffffcc",
#   mid = "#a1dab4",
#   high = "#2c7fb8",
#   midpoint = 0.65,
#   guide = "colourbar",
#   limits = c(0, 1)
# )
 tdata = matrix(sample.int(10, 20, TRUE), 4, 5)
 tdata = as.data.frame(data)
 tdata$x = c("one","two","thee","four")
 dl = gather(tdata, key, value, V1:V5)
 ggplot(dl) +
   stat_smooth(aes(x=x, y=value, color = key, group = key), size = 1) +
   theme_void() +
   theme(panel.grid.major.x  = element_line(color = "grey",
                                            size = 0.5,
                                            linetype = 1)) +
   geom_text(aes(x=x,y=value, label = value), hjust = -1, vjust = -0.5) +
   geom_point(aes(x=x, y=value)) + 
   theme(
     axis.text.x = element_text()
   ) +
   guides(line)
 
# ggparcoord(data, columns = 1:5, groupColumn = 5) +
#   theme_void() +
#   theme(legend.key.height = unit(4.6, 'cm'),
#         legend.box.spacing = unit(0, 'cm')
#         ) +
#   geom_point(aes(x=rep(1, 4), y=V1))
 
################################################################################
 spElectrode = function(path) {
   perf = read_csv(paste(path, "perf.csv", sep = "/"), 
                   col_types = cols(Epoch = col_integer()),
                   show_col_types = FALSE)
   sp = matrix(0, ncol = 4, nrow = 25);
   for (i in 1:25) {
     sp[i,] = unlist(map(strsplit(perf$Specificity[i], split = ':'), as.numeric))
   }
   sp[is.na(sp)] = 0
   colnames(sp) = c("S2", "S3", "S4", "S5" )
   sp = as.data.frame(sp)
   sp$Epoch = 1:nrow(sp)
   sp = gather(sp, State, Specificity, S2:S5)
   return(sp)
 }
 
 spSample = function(path) {
   files = list.files(path=path, full.names=TRUE, recursive=FALSE)
   splist = map(files, spElectrode)
   sp = data.frame(Epoch = splist[[1]]$Epoch, State = splist[[1]]$State, Specificity = reduce(map(splist, \(x) x$Specificity), `+`)/ length(splist))
   return(sp)
 }
 
 spConfig = function(path) {
   files = list.files(path=path, full.names=TRUE, recursive=FALSE)
   splist = map(files, spSample)
   sp = data.frame(Epoch = splist[[1]]$Epoch, State = splist[[1]]$State, Specificity = reduce(map(splist, \(x) x$Specificity), `+`)/ length(splist))
   config = strsplit(basename(path), split = "-")
   ncols = cbind(c("LatFrac","Window","Overlap", "Montage"), config[[1]])
   for (i in 1:nrow(ncols)){
     sp[ncols[i,1]] = rep(ncols[i,2], nrow(sp))
   }
   return(sp)
 }
 
nfiles = list.files(path="2-results/003-normal/", full.names=TRUE, recursive=FALSE)
sp = reduce(map(files, spConfig), rbind)


################################################################################
durations <- read_delim("2-results/durations.csv", 
                        delim = "\t", escape_double = FALSE, 
                        col_names = FALSE, trim_ws = TRUE)
num = as.numeric(str_remove(substr(durations$X1, 1, 4), "^0+"))
durations$Type = cut(num, breaks = c(0,20,60,105), labels = c("Normal", "General", "Focal"))

ggplot(durations) +
  geom_point(aes(y = X2, x = X1, color = Type))
################################################################################
 #
 # TEST
 #
tdf = data.frame(
                  x = rep(c(1,2,3,4,5) , 5),
                  y = rep(c(1,2,3,4,5) , 5),
                  gr = unlist(reduce(map(c(1,2,3,4,5),\(x) rep(x, 5)), c)),
                  sc = unlist(reduce(map(c(0.2,0.9,0.3,0.7,0.4),\(x) rep(x, 5)), c))
                  )
 tdf = tdf[order(tdf$sc),]
  #tdf$sc = factor(tdf$sc, levels = unique(tdf$sc)) 
  tdf$gr = factor(tdf$gr, levels = unique(tdf$gr))
  sdf = data.frame(val = seq(min(tdf$sc), max(tdf$sc), by = 0.01))
ggplot() +
  geom_line(data = tdf, aes(x = x, y = y, group = gr, color = sc)) +
  geom_segment(data = sdf, aes( y = val, yend = val, color = val), x = 5.01, xend = 5.51, size = 2)
