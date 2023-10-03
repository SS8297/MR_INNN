library(factoextra)
library(readr)
library(lattice)
library(SynchWave)
library(umap)
library(ggplot2)
library(ggfortify)
library(ggforce)
library(concaveman)
aee = read_csv("2-results/0025MF/Fp2-AEE", 
               col_names = FALSE,
               show_col_types = FALSE)
state = read_csv("2-results/0025MFhmm/0025MF_Fp2_traceback.csv",
                 show_col_types = FALSE)
lbl = read_delim("2-results/labels/0025MF", 
                 delim = "\t", escape_double = FALSE, 
                 trim_ws = TRUE,
                 show_col_types = FALSE)
freqs = read_csv("2-results/freqs.txt", 
                 col_names = FALSE)
hmms =  read_csv("2-results/hmm_25/0025MF_Fp2_states.csv")
colnames(aee) = ifftshift(freqs$X1)
data = aee

res.pca = prcomp(aee)
scl.pca = prcomp(aee, scale = TRUE)
data.umap = umap(aee)
aee$State = as.factor(state$Fp2)
aee$UMAP1 = data.umap$layout[,1]
aee$UMAP2 = data.umap$layout[,2]
aee$Class = as.factor(lbl$IED)
  
dt = cbind(as.data.frame(res.pca$x), state)
dt$Fp2 = as.factor(dt$Fp2)

hmms = t(hmms)
colnames(hmms) = freqs$X1
hmms_pca = as.data.frame(predict(res.pca, hmms))

hmms.pca = prcomp(hmms)
em = as.data.frame(predict(hmms.pca, data))
em$state = dt$Fp2

ggplot(em, aes(x=PC1, y=PC2)) +
  geom_point(aes(color = state)) +
  theme_bw() +
  geom_point(data = as.data.frame(hmms.pca$x), aes(x = PC1, y = PC2))

ggplot(dt, aes(x = PC1, y = PC2)) +
  geom_point()+
  geom_mark_hull(aes(fill = Fp2), alpha =0.4, expand = 0.01, radius = 0.01)+
  theme_bw()+
  geom_point(data = hmms_pca, aes(x = PC1, y = PC2), size = 2, color = "red")
  

fviz_eig(res.pca)
fviz_pca_ind(res.pca,
             col.ind = "cos2", # Color by the quality of representation
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     # Avoid text overlapping
)
fviz_pca_var(scl.pca,
             geom = c("point","text"),
             col.var = "contrib", # Color by contributions to the PC
             gradient.cols = c("#6DCAEF", "#EEBC13", "#A90000"),
             repel = TRUE     # Avoid text overlapping
)
fviz_pca_biplot(res.pca, repel = TRUE,
                col.var = "#2E9FDF", # Variables color
                col.ind = "#696969"  # Individuals color
)
groups = as.factor(aee$State)
fviz_pca_ind(res.pca,
             col.ind = groups, # color by groups
             addEllipses = TRUE, # Concentration ellipses
             ellipse.type = "confidence",
             legend.title = "Groups",
             repel = TRUE
)

# splom(as.data.frame(res.pca$x),
#       col=aee$State, cex=2, pch='*')

#TODO change colmn name to freq 
#se contrib = size col = freq?

ggplot(aee, aes(x=UMAP1, y=UMAP2, color = State, shape = Class, alpha = 0.8, size = 1)) +
  geom_point() +
  scale_shape_manual(values=c(10, 16))
