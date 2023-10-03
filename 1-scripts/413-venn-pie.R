library(ggvenn)
library(readr)
library(purrr)
library(dplyr)
library(ggpubr)



read = function(path) {
  label = read_csv(path,
                   col_types = cols(.default = "l"))
  
  tb = read_csv(paste(dirname(path), "/traceback.csv", sep = ""), 
                        col_types = cols(.default = col_integer()))
  colnames(tb) = c("State")
  label$State = tb$State
  label
}

files = list.files(path="2-results/eighth-1-1-None/", pattern = "label.csv", full.names=TRUE, recursive=TRUE)
label = reduce(map(files, \(x) read(x)), rbind)

################################################################################

subset = data.frame(IED = label$IED, Sleep = (label$`SLEEP N1` | label$`SLEEP N2` | label$`SLEEP N3`), EOG_EMG = (label$MOVEMENT | label$`EYES OPEN`), Evoked = (label$HYPERVENTILATION | label$PHOTIC), State = label$State)
ggvenn(subset, c("IED", "EOG_EMG", "Evoked", "Sleep"))

s

unique = subset %>% group_by_all %>% count

# ggplot(unique, aes(x = "", y = n, fill = n)) +
#   geom_bar(stat = "identity", width = 1, color = "white") +
#   coord_polar("y", start = 0) +
#   theme_void()

unique$Group = rep("", nrow(unique))
unique$Group[!unique$IED & !unique$EOG_EMG & !unique$Sleep & !unique$Evoked] = "Physiological"
unique$Group[unique$IED & !unique$EOG_EMG & !unique$Sleep & !unique$Evoked] = "Epileptiform"
unique$Group[!unique$IED & unique$EOG_EMG & !unique$Sleep & !unique$Evoked] = "Phys. EOG/EMG"
unique$Group[!unique$IED & !unique$EOG_EMG & unique$Sleep & !unique$Evoked] = "Phys. Asleep"
unique$Group[!unique$IED & !unique$EOG_EMG & !unique$Sleep & unique$Evoked] = "Phys. Evoked"
unique$Group[!unique$IED & ((unique$EOG_EMG + unique$Sleep + unique$Evoked) > 1)] = "Phys. Mixed"
unique$Group[unique$IED & (unique$EOG_EMG | unique$Sleep | unique$Evoked)] = "Epil. w/ Dist."

unique$Annotation = factor(unique$Group, levels = c("Epileptiform","Epil. w/ Dist.","Physiological","Phys. EOG/EMG","Phys. Asleep","Phys. Evoked","Phys. Mixed"))

p1 = ggplot(unique[unique$State == 1,], aes(x = "", y = n, fill = Annotation)) +
  geom_bar(position = "fill", stat = "identity") +
  theme_classic() +
  scale_fill_manual(values=c("tomato2","tomato3","darkolivegreen1","darkolivegreen2","darkolivegreen3","darkolivegreen4","darkolivegreen")) + 
  coord_polar("y", start = 0) +
  ggtitle("HMM State 1") +
  theme_void()

p2 = ggplot(unique[unique$State == 2,], aes(x = "", y = n, fill = Annotation)) +
  geom_bar(position = "fill", stat = "identity") +
  theme_classic() +
  scale_fill_manual(values=c("tomato2","tomato3","darkolivegreen1","darkolivegreen2","darkolivegreen3","darkolivegreen4","darkolivegreen")) + 
  coord_polar("y", start = 0) +
  ggtitle("HMM State 2") +
  theme_void()

p3 = ggplot(unique[unique$State == 3,], aes(x = "", y = n, fill = Annotation)) +
  geom_bar(position = "fill", stat = "identity") +
  theme_classic() +
  scale_fill_manual(values=c("tomato2","tomato3","darkolivegreen1","darkolivegreen2","darkolivegreen3","darkolivegreen4","darkolivegreen")) + 
  coord_polar("y", start = 0) +
  ggtitle("HMM State 3") +
  theme_void()

p4 = ggplot(unique[unique$State == 4,], aes(x = "", y = n, fill = Annotation)) +
  geom_bar(position = "fill", stat = "identity") +
  theme_classic() +
  scale_fill_manual(values=c("tomato2","tomato3","darkolivegreen1","darkolivegreen2","darkolivegreen3","darkolivegreen4","darkolivegreen")) + 
  coord_polar("y", start = 0) +
  ggtitle("HMM State 4") +
  theme_void()

p5 = ggplot(unique[unique$State == 5,], aes(x = "", y = n, fill = Annotation)) +
  geom_bar(position = "fill", stat = "identity") +
  theme_classic() +
  scale_fill_manual(values=c("tomato2","tomato3","darkolivegreen1","darkolivegreen2","darkolivegreen3","darkolivegreen4","darkolivegreen")) + 
  coord_polar("y", start = 0) +
  ggtitle("HMM State 5") +
  theme_void()

a1 = ggarrange(p1, p2, p3, p4, p5, ncol=5, common.legend = TRUE, legend = "right", labels="d")
annotate_figure(a1, top = "Annotation Composition of Final HMM States")
