library(umap)
library(readr)
library(ggplot2)
library(ggpubr)

# Initial run
# lbl = read_delim("2-results/labels/0025MF", 
#                  delim = "\t", escape_double = FALSE, 
#                  trim_ws = TRUE,
#                  show_col_types = FALSE)
# 
# aee = read_csv("2-results/0025MF/Fp2-AEE", 
#                col_names = FALSE,
#                show_col_types = FALSE)
# 
# fft = read_csv("2-results/0025MF/Fp2-FFT", 
#                col_names = FALSE,
#                show_col_types = FALSE)
# 
# state = read_csv("2-results/0025MFhmm/0025MF_Fp2_traceback.csv",
#                  show_col_types = FALSE)
# 
# ied = as.factor(cut(lbl$IED, breaks = 2, labels = c("Normal", "Epileptiform")))

################################################################################

nfft = read_csv("2-results/None/0025MF/Fp2/fft.csv", 
                col_names = FALSE,
                show_col_types = FALSE)

afft = read_csv("2-results/Average/0025MF/Fp2/fft.csv", 
               col_names = FALSE,
               show_col_types = FALSE)

bfft = read_csv("2-results/Bipolar/0025MF/Fp2-F4/fft.csv", 
               col_names = FALSE,
               show_col_types = FALSE)

lbl = read_csv("2-results/None/0025MF/Fp2/label.csv",
               show_col_types = FALSE)
ied = as.factor(cut(lbl$IED, breaks = 2, labels = c("Physiological", "Epileptiform")))

################################################################################

acfft = read_csv("2-results/Average/0025MF/C4/fft.csv", 
                col_names = FALSE,
                show_col_types = FALSE)

aofft = read_csv("2-results/Average/0025MF/O2/fft.csv", 
                col_names = FALSE,
                show_col_types = FALSE)

aafft = rbind(afft, acfft, aofft)

################################################################################

fft1 = read_csv("2-results/Average/0001LB/Fp2/fft.csv", 
                col_names = FALSE,
                show_col_types = FALSE)

fft74 = read_csv("2-results/Average/0074JR/Fp2/fft.csv", 
                col_names = FALSE,
                show_col_types = FALSE)

lbl1 = read_csv("2-results/Average/0001LB/Fp2/label.csv",
               show_col_types = FALSE)

lbl74 = read_csv("2-results/Average/0074JR/Fp2/label.csv",
               show_col_types = FALSE)

fft1ss = fft1[,1:floor(ncol(fft1)/2)]
ptfft = rbind(afft, fft1ss, fft74)
ptlbl = rbind(lbl, lbl1, lbl74)
ptied = as.factor(cut(ptlbl$IED, breaks = 2, labels = c("Physiological", "Epileptiform")))

################################################################################

fft26 = read_csv("2-results/Average/0026TS2015/Fp2/fft.csv", 
                col_names = FALSE,
                show_col_types = FALSE)

fft27 = read_csv("2-results/Average/0027TS2017/Fp2/fft.csv", 
                 col_names = FALSE,
                 show_col_types = FALSE)

fft28 = read_csv("2-results/Average/0028TS2019/Fp2/fft.csv", 
                 col_names = FALSE,
                 show_col_types = FALSE)

lbl26 = read_csv("2-results/Average/0026TS2015/Fp2/label.csv",
                show_col_types = FALSE)

lbl27 = read_csv("2-results/Average/0027TS2017/Fp2/label.csv",
                 show_col_types = FALSE)

lbl28 = read_csv("2-results/Average/0028TS2019/Fp2/label.csv",
                 show_col_types = FALSE)

rpfft = rbind(fft26, fft27, fft28)
rplbl = rbind(lbl26, lbl27, lbl28)
rpied = as.factor(cut(rplbl$IED, breaks = 2, labels = c("Physiological", "Epileptiform")))

################################################################################

ecs = function(matrix, origin, target) {
  sqrt(apply(abs(apply(matrix[,target, drop = FALSE], 2, cumsum)-cumsum(matrix[,origin]))^2, 2, sum))
}

eud = function(matrix, origin, target) {
  sqrt(apply((matrix[, target, drop = FALSE]-matrix[, origin])^2, 2, sum))
}

smi = function(matrix, origin, target) {
  1 - (apply(pmin(matrix[,target, drop = FALSE], matrix[,origin]), 2, sum))/(pmin(apply(matrix[,target, drop = FALSE], 2, sum), sum(matrix[,origin])))
}

################################################################################

i5 = diag(5)

ecs(i5, 1, 1:5)
eud(i5, 1, 1:5)
smi(i5, 1, 1:5)

################################################################################

conf_def = umap.defaults
conf_def$random_state = 1
conf_def$transform_state = 1
conf_def$n_neighbors = 12

conf_ecs = conf_def
conf_ecs$metric = ecs

conf_eud = conf_def
conf_eud$metric = eud

conf_smi = conf_def
conf_smi$metric = smi

################################################################################

umap.def = umap(aee, config = conf_def)
umap.eud = umap(aee, config = conf_eud)
umap.ecs = umap(aee, config = conf_ecs)
umap.smi = umap(aee, config = conf_smi)

aee.def = data.frame(Type = ied, UMAP1 = umap.def$layout[,1], UMAP2 = umap.def$layout[,2], state = as.factor(state$Fp2))
aee.eud = data.frame(Type = ied, UMAP1 = umap.eud$layout[,1], UMAP2 = umap.eud$layout[,2], state = as.factor(state$Fp2))
aee.ecs = data.frame(Type = ied, UMAP1 = umap.ecs$layout[,1], UMAP2 = umap.ecs$layout[,2], state = as.factor(state$Fp2))
aee.smi = data.frame(Type = ied, UMAP1 = umap.smi$layout[,1], UMAP2 = umap.smi$layout[,2], state = as.factor(state$Fp2))


aee.plot_def = ggplot(aee.def, aes(x=UMAP1, y=UMAP2, color = Type)) +
               geom_point(alpha = 0.8, size = 3) +
               theme_classic()
aee.plot_eud = ggplot(aee.eud, aes(x=UMAP1, y=UMAP2, color = Type)) +
               geom_point(alpha = 0.8, size = 3) +
               theme_classic()
aee.plot_ecs = ggplot(aee.ecs, aes(x=UMAP1, y=UMAP2, color = Type)) +
               geom_point(alpha = 0.8, size = 3) +
               theme_classic()
aee.plot_smi = ggplot(aee.smi, aes(x=UMAP1, y=UMAP2, color = Type)) +
               geom_point(alpha = 0.8, size = 3) +
               theme_classic()

grid.arrange(aee.plot_def, aee.plot_eud, aee.plot_ecs, aee.plot_smi, ncol=2)

################################################################################

umap.nfdef = umap(nfft, config = conf_def)
umap.nfeud = umap(nfft, config = conf_eud)
umap.nfecs = umap(nfft, config = conf_ecs)
umap.nfsmi = umap(nfft, config = conf_smi)

fft.ndef = data.frame(Type = ied, UMAP1 = umap.nfdef$layout[,1], UMAP2 = umap.nfdef$layout[,2])
fft.neud = data.frame(Type = ied, UMAP1 = umap.nfeud$layout[,1], UMAP2 = umap.nfeud$layout[,2])
fft.necs = data.frame(Type = ied, UMAP1 = umap.nfecs$layout[,1], UMAP2 = umap.nfecs$layout[,2])
fft.nsmi = data.frame(Type = ied, UMAP1 = umap.nfsmi$layout[,1], UMAP2 = umap.nfsmi$layout[,2])

  
fft.plot_ndef = ggplot(fft.ndef, aes(x=UMAP1, y=UMAP2, color = Type)) +
               geom_point(alpha = 0.3, size = 3) +
               ggtitle("Default Euclidean Distance") +
  ylab("\nUMAP2") +
               theme_classic()
fft.plot_neud = ggplot(fft.neud, aes(x=UMAP1, y=UMAP2, color = Type)) +
               geom_point(alpha = 0.3, size = 3) +
               ggtitle("Euclidean Distance") + 
  ylab("No Montage\nUMAP2") +
  scale_color_hue(direction = -1) +
               theme_classic()
fft.plot_necs = ggplot(fft.necs, aes(x=UMAP1, y=UMAP2, color = Type)) +
               geom_point(alpha = 0.3, size = 3) +
               ggtitle("Euclidean Distance of Cumulative Spectra") +
  ylab("\nUMAP2") +
  scale_color_hue(direction = -1) +
               theme_classic()
fft.plot_nsmi = ggplot(fft.nsmi, aes(x=UMAP1, y=UMAP2, color = Type)) +
               geom_point(alpha = 0.3, size = 3) +
               ggtitle("Smith Distance") +
  ylab("\nUMAP2") +
  scale_color_hue(direction = -1) +
               theme_classic()

################################################################################

umap.afdef = umap(afft, config = conf_def)
umap.afeud = umap(afft, config = conf_eud)
umap.afecs = umap(afft, config = conf_ecs)
umap.afsmi = umap(afft, config = conf_smi)

fft.adef = data.frame(Type = ied, UMAP1 = umap.afdef$layout[,1], UMAP2 = umap.afdef$layout[,2])
fft.aeud = data.frame(Type = ied, UMAP1 = umap.afeud$layout[,1], UMAP2 = umap.afeud$layout[,2])
fft.aecs = data.frame(Type = ied, UMAP1 = umap.afecs$layout[,1], UMAP2 = umap.afecs$layout[,2])
fft.asmi = data.frame(Type = ied, UMAP1 = umap.afsmi$layout[,1], UMAP2 = umap.afsmi$layout[,2])


fft.plot_adef = ggplot(fft.adef, aes(x=UMAP1, y=UMAP2, color = Type)) +
  geom_point(alpha = 0.3, size = 3) +
  ggtitle("") +
  ylab("\nUMAP2") +
  theme_classic()
fft.plot_aeud = ggplot(fft.aeud, aes(x=UMAP1, y=UMAP2, color = Type)) +
  geom_point(alpha = 0.3, size = 3) +
  ggtitle("") +
  ylab("Average Montage\nUMAP2") +
  scale_color_hue(direction = -1) +
  theme_classic()
fft.plot_aecs = ggplot(fft.aecs, aes(x=UMAP1, y=UMAP2, color = Type)) +
  geom_point(alpha = 0.3, size = 3) +
  ggtitle("") +
  ylab("\nUMAP2") +
  scale_color_hue(direction = -1) +
  theme_classic()
fft.plot_asmi = ggplot(fft.asmi, aes(x=UMAP1, y=UMAP2, color = Type)) +
  geom_point(alpha = 0.3, size = 3) +
  ggtitle("") +
  ylab("\nUMAP2") +
  scale_color_hue(direction = -1) +
  theme_classic()

################################################################################

umap.bfdef = umap(bfft, config = conf_def)
umap.bfeud = umap(bfft, config = conf_eud)
umap.bfecs = umap(bfft, config = conf_ecs)
umap.bfsmi = umap(bfft, config = conf_smi)

fft.bdef = data.frame(Type = ied, UMAP1 = umap.bfdef$layout[,1], UMAP2 = umap.bfdef$layout[,2])
fft.beud = data.frame(Type = ied, UMAP1 = umap.bfeud$layout[,1], UMAP2 = umap.bfeud$layout[,2])
fft.becs = data.frame(Type = ied, UMAP1 = umap.bfecs$layout[,1], UMAP2 = umap.bfecs$layout[,2])
fft.bsmi = data.frame(Type = ied, UMAP1 = umap.bfsmi$layout[,1], UMAP2 = umap.bfsmi$layout[,2])


fft.plot_bdef = ggplot(fft.bdef, aes(x=UMAP1, y=UMAP2, color = Type)) +
  geom_point(alpha = 0.3, size = 3) +
  ggtitle("") +
  ylab("\nUMAP2") +
  theme_classic()
fft.plot_beud = ggplot(fft.beud, aes(x=UMAP1, y=UMAP2, color = Type)) +
  geom_point(alpha = 0.3, size = 3) +
  ggtitle("") +
  ylab("Bipolar Montage\nUMAP2") +
  scale_color_hue(direction = -1) +
  theme_classic()
fft.plot_becs = ggplot(fft.becs, aes(x=UMAP1, y=UMAP2, color = Type)) +
  geom_point(alpha = 0.3, size = 3) +
  ggtitle("") +
  ylab("\nUMAP2") +
  scale_color_hue(direction = -1) +
  theme_classic()
fft.plot_bsmi = ggplot(fft.bsmi, aes(x=UMAP1, y=UMAP2, color = Type)) +
  geom_point(alpha = 0.3, size = 3) +
  ggtitle("") +
  ylab("\nUMAP2") +
  scale_color_hue(direction = -1) +
  theme_classic()

################################################################################


umap.fft_avg_ecs_ele = umap(aafft, config = conf_ecs)

fft.avg_ecs_ele = data.frame(Label = rep(ied, 3), Electrode = as.factor(c(rep("Fp2", nrow(afft)), rep("C4", nrow(acfft)), rep("O2", nrow(aofft)))), UMAP1 = umap.fft_avg_ecs_ele$layout[,1], UMAP2 = umap.fft_avg_ecs_ele$layout[,2])
fft.avg_ecs_ele$Type = factor(paste(fft.avg_ecs_ele$Electrode, "_", fft.avg_ecs_ele$Label, sep = ""), levels = c("Fp2_Physiological", "Fp2_Epileptiform", "C4_Physiological", "C4_Epileptiform", "O2_Physiological", "O2_Epileptiform"))
fft.plot_aaecs = ggplot(fft.avg_ecs_ele, aes(x=UMAP1, y=UMAP2, color = Type, shape = Label, alpha = Label, size = Label)) +
  geom_point(stroke = 1.1) +
  ggtitle("Interelectrode Variance") +
  ylab("\nUMAP2") +
  scale_color_brewer(palette = "Paired") +
  scale_shape_manual(values=c(19, 4), guide = 'none')+
  scale_size_manual(values=c(3, 2), guide = 'none')+
  scale_alpha_manual(values=c(0.1, 0.6), guide = 'none') +
  theme_classic()

################################################################################

umap.pt = umap(ptfft, config = conf_ecs)

fft.pt = data.frame(Label = ptied, Patient = as.factor(c(rep("General", nrow(afft)), rep("Normal", nrow(fft1ss)), rep("Focal", nrow(fft74)))), UMAP1 = umap.pt$layout[,1], UMAP2 = umap.pt$layout[,2])
fft.pt$Type = factor(paste(fft.pt$Patient, "_", fft.pt$Label, sep = ""), levels = c("Normal_Physiological", "Normal_Epileptiform", "General_Physiological", "General_Epileptiform", "Focal_Physiological", "Focal_Epileptiform"))
fft.plot_pt = ggplot(fft.pt, aes(x=UMAP1, y=UMAP2, color = Type, shape = Label, alpha = Label, size = Label)) +
  geom_point(stroke = 1.1) +
  ggtitle("Interpatient Variance") +
  ylab("\nUMAP2") +
  scale_color_brewer(palette = "Paired", drop=FALSE) +
  scale_shape_manual(values=c(19, 4), guide = 'none', drop=FALSE)+
  scale_size_manual(values=c(3, 2), guide = 'none', drop=FALSE)+
  scale_alpha_manual(values=c(0.1, 0.6), guide = 'none', drop=FALSE) +
  theme_classic()

################################################################################

umap.rp = umap(rpfft, config = conf_ecs)

fft.rp = data.frame(Label = rpied, Year = as.factor(c(rep("2015", nrow(fft26)), rep("2017", nrow(fft27)), rep("2019", nrow(fft28)))), UMAP1 = umap.rp$layout[,1], UMAP2 = umap.rp$layout[,2])
fft.rp$Type = factor(paste(fft.rp$Year, "_", fft.rp$Label, sep = ""), levels = c("2015_Physiological", "2015_Epileptiform", "2017_Physiological", "2017_Epileptiform", "2019_Physiological", "2019_Epileptiform"))
fft.plot_rp = ggplot(fft.rp, aes(x=UMAP1, y=UMAP2, color = Type, shape = Label, alpha = Label, size = Label)) +
  geom_point(stroke = 1.1) +
  ggtitle("Intersample Variance") +
  ylab("\nUMAP2") +
  scale_color_brewer(palette = "Paired", drop=FALSE) +
  scale_shape_manual(values=c(19, 4), guide = 'none', drop=FALSE)+
  scale_size_manual(values=c(3, 2), guide = 'none', drop=FALSE)+
  scale_alpha_manual(values=c(0.1, 0.6), guide = 'none', drop=FALSE) +
  theme_classic()

fft.plot_aaecs
umap.pt
fft.plot_rp

################################################################################

grid.arrange(fft.plot_neud, fft.plot_nsmi, fft.plot_necs, fft.plot_aeud, fft.plot_asmi, fft.plot_aecs, fft.plot_beud, fft.plot_bsmi, fft.plot_becs, ncol=3)
ggarrange(fft.plot_neud, fft.plot_nsmi, fft.plot_necs, fft.plot_aeud, fft.plot_asmi, fft.plot_aecs, fft.plot_beud, fft.plot_bsmi, fft.plot_becs, ncol=3, nrow=3, common.legend = TRUE, legend = "bottom", labels="a")
ggarrange(fft.plot_aaecs, fft.plot_rp, fft.plot_pt, nrow=3, common.legend = FALSE, legend = "right", labels="b")
 
