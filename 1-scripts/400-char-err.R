library(readr)
library(stringr)
library(dplyr)
library(ggplot2)
library(ggforce)
library(googlesheets4)
library(tidyr)
library(ggridges)
library(gridExtra)
data = read_csv("2-results/005-comp-perf.csv")
type = numeric(nrow(data))
for (i in 1:nrow(data)) {
  type[i]=strtoi(str_remove(data$Patient[i], "^0+"))
}
type = cut(type, breaks=c(0,20,50,60,105), labels=c("Normal","General","Vegetal","Focal"), right=TRUE)
data$Type=type
type_mean=data %>% group_by(Type) %>% summarize(mean(MCC), mean(Sensitivity), mean(Specificity)) 
type_median=data %>% group_by(Type) %>% summarize(median(MCC), median(Sensitivity), median(Specificity)) 
type_iqr=data %>% group_by(Type) %>% summarize(IQR(MCC,na.rm =TRUE), IQR(Sensitivity,na.rm =TRUE), IQR(Specificity,na.rm =TRUE))
lobe_mean=data[data$Type!="Normal",] %>% group_by(Lobe) %>% summarize(mean(MCC), mean(Sensitivity), mean(Specificity)) 
lobe_median=data[data$Type!="Normal",] %>% group_by(Lobe) %>% summarize(median(MCC), median(Sensitivity), median(Specificity))
lobe_iqr=data[data$Type!="Normal",] %>% group_by(Lobe) %>% summarize(IQR(MCC), IQR(Sensitivity), IQR(Specificity))
signal_iqr=data[data$Type!="Normal",] %>% group_by(Lobe, Number) %>% summarize(IQR(MCC), IQR(Sensitivity), IQR(Specificity))
daniel=data
daniel$Signal=paste(data$Lobe, data$Number, sep="")
daniel= daniel %>% select(c("Signal","Type","MCC","Sensitivity","Specificity"))
# daniel=gather(daniel, Metric, Value, Specificity, Sensitivity, MCC, factor_key=TRUE)
# daniel$Graph=paste(daniel$Signal,daniel$Metric,sep="-")

plot1 = ggplot(daniel) + 
  geom_density_ridges(aes(x = Specificity, y = Signal, group = interaction(Signal,Type),fill = Type, point_color = Type, point_fill = Type, point_shape = Type),
                      alpha = 0.4, point_alpha=0.6, bandwidth = 0.05) +
  theme(legend.position = "none", panel.background = element_blank())  +
  xlim(0,1) +
  scale_fill_manual(values=c("firebrick2","limegreen","cornflowerblue"))+
  labs(y = "")
plot2 = ggplot(daniel) + 
  geom_density_ridges(aes(x = Sensitivity, y = Signal, group = interaction(Signal,Type),fill = Type, point_color = Type, point_fill = Type, point_shape = Type),
                      alpha = 0.4, point_alpha=0.6, bandwidth = 0.05) +
  theme(legend.position = "none", panel.background = element_blank()) +
  xlim(0,1) +
  scale_fill_manual(values=c("limegreen","cornflowerblue"))+
  labs(y = "")

plot3 = ggplot(daniel) + 
  geom_density_ridges(aes(x = MCC, y = Signal, group = interaction(Signal,Type),fill = Type, point_color = Type, point_fill = Type, point_shape = Type),
                      alpha = 0.4, point_alpha=0.6, bandwidth = 0.05) +
  theme(panel.background = element_blank()) +
  xlim(0,1) +
  scale_fill_manual(values=c("limegreen","cornflowerblue"))+
  labs(y = "")

grid.arrange(plot1, plot2, plot3, ncol=3)

plot4 = ggplot(daniel) + 
  geom_density_ridges(aes(x = Specificity, y = Signal, group = interaction(Signal,Type),fill = Type),
                      alpha = 0.7,bandwidth = 0.05) +
  theme_classic()  +
  xlim(0,1) +
  scale_fill_manual(values=c("firebrick2","limegreen","cornflowerblue"))+
  labs(y = "")

################################################################################

#daniel$f1 = 2*daniel$
scatter=data
scatter$Signal=paste(data$Lobe, data$Number, sep="")
scatter= scatter %>% select(c("Signal", "Lobe", "Patient","Type","MCC","Sensitivity","Specificity"))
scatter$n1=rep(0, nrow(scatter))
scatter$n2=rep(0, nrow(scatter))
scatter$n3=rep(0, nrow(scatter))
#scatter$sleep=rep(0, nrow(scatter))
scatter$hv=rep(0, nrow(scatter))
scatter$ph=rep(0, nrow(scatter))
scatter$eo=rep(0, nrow(scatter))
scatter$mv=rep(0, nrow(scatter))
#scatter$man=rep(0, nrow(scatter))

files = list.files(path = "stats/", full.names = FALSE)
for (file in files){
  label = read_delim(paste("stats/", file, sep =""), delim = "\t", 
                     escape_double = FALSE, col_types = cols(AWAKE = col_logical(), 
                     `SLEEP N1` = col_logical(), `SLEEP N2` = col_logical(), 
                     `SLEEP N3` = col_logical(), HYPERVENTILATION = col_logical(), 
                     PHOTIC = col_logical(), `EYES OPEN` = col_logical(), 
                     MOVEMENT = col_logical(), IED = col_logical()), 
                     trim_ws = TRUE)
  
  ln = length(label$IED)
  sleep = label$`SLEEP N1` | label$`SLEEP N2` | label$`SLEEP N3`
  label$AWAKE[!sleep] = TRUE
  scatter$n1[scatter$Patient == file] = length(label$`SLEEP N1`[label$`SLEEP N1`==TRUE])/ln
  scatter$n2[scatter$Patient == file] = length(label$`SLEEP N2`[label$`SLEEP N2`==TRUE])/ln
  scatter$n3[scatter$Patient == file] = length(label$`SLEEP N3`[label$`SLEEP N3`==TRUE])/ln
  #scatter$sleep[scatter$Patient == file] = length(sleep[sleep==TRUE])/ln
  
  man = label$HYPERVENTILATION | label$PHOTIC | label$`EYES OPEN` | label$MOVEMENT
  scatter$hv[scatter$Patient == file] = length(label$HYPERVENTILATION[label$HYPERVENTILATION==TRUE])/ln
  scatter$ph[scatter$Patient == file] = length(label$PHOTIC[label$PHOTIC==TRUE])/ln
  scatter$eo[scatter$Patient == file] = length(label$`EYES OPEN`[label$`EYES OPEN`==TRUE])/ln
  scatter$mv[scatter$Patient == file] = length(label$MOVEMENT[label$MOVEMENT==TRUE])/ln
  #scatter$man[scatter$Patient == file] = length(man[man == TRUE])/ln
}
point = scatter %>% select(c("Patient","Signal","Lobe","Type","MCC","n1","n2","n3","hv","ph","eo","mv"))
point_long = gather(point, Disturbance, Duration, n1:eo)
point1 = ggplot(point_long, aes(x=MCC, y=Duration, colour=Lobe, shape = Type)) +
         geom_point(alpha=0.8) +
         #scale_shape_manual(values=c(0,1,2)) +
         #geom_text(check_overlap = TRUE, aes(label=Signal), size=3, fontface = "bold") +
         xlim(1,0)+
         ylim(0,1)+
         theme_classic()

# point_gr_patient = point %>%
#   group_by(Patient) %>%
#   summarise_at(vars(MCC, n1, n2, n3, hv, ph, eo), mean)

point_gr_patient = point_long %>%
  group_by(Patient,Type,Disturbance) %>%
  summarise_at(vars(MCC, Duration), mean)




point2 = ggplot(point_gr_patient, aes(x=MCC, y=Duration, colour=Disturbance, shape = Type)) +
  geom_point(alpha=0.8, , size = 3) +
  #scale_shape_manual(values=c(0,1,2)) +
  #geom_text(check_overlap = TRUE, aes(label=Signal), size=3, fontface = "bold") +
  scale_x_reverse()+
  ylim(0,1)+
  theme_classic()

point_gr_signal = point_long %>%
  group_by(Signal,Lobe,Disturbance) %>%
  summarise_at(vars(MCC, Duration), mean)

point3 = ggplot(point_gr_signal, aes(x=MCC, y=Duration, colour=Lobe, shape = Disturbance)) +
  geom_point(alpha=0.8) +
  #scale_shape_manual(values=c(0,1,2)) +
  #geom_text(check_overlap = TRUE, aes(label=Signal), size=3, fontface = "bold") +
  scale_x_reverse()+
  ylim(0,1)+
  theme_classic()

