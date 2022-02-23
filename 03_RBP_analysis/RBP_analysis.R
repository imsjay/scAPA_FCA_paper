setwd("")
library(Seurat)
library(SeuratDisk)
library(dplyr)
library(Matrix)
library(ggplot2)
library(tidyverse)
library(pheatmap)
library(RColorBrewer)
library(ggridges)
library(cowplot)
library(tidyr)
library(ggrepel)
library(reshape)
library("AnnotationDbi")
library("org.Dm.eg.db")
library(data.table)
library(ComplexHeatmap)
library(circlize)
library(zoo)
library(ggsignif)
library(ggsci)


#load RBP list
rbp <- read.csv("./RBP_list_1633_EuRBP_added_82_FlyBase.csv")

#load seurat object
#load
tissueobj <- read_rds("")

#add clustering information to the seurat object
tissueobj@meta.data$annotation <- gsub(" ", "_", tissueobj@meta.data$annotation)
tissueobj@meta.data$annotation <- gsub(",", "_", tissueobj@meta.data$annotation)
tissueobj@meta.data$annotation <- gsub("/", "_", tissueobj@meta.data$annotation)
tissueobj@meta.data$annotation
Idents(tissueobj) <- tissueobj@meta.data$annotation

#normalize and scaling
tissueobj <- NormalizeData(tissueobj, normalization.method = "LogNormalize")
all.genes <- rownames(tissueobj)
tissueobj <- ScaleData(tissueobj, features = all.genes)

#export average expession for all genes
exp <- AverageExpression(tissueobj, assays = "RNA", features = NULL, return.seurat = FALSE, group.by = "ident", add.ident = NULL, slot = "scale.data")

rbp_exp <- exp %>% filter(X %in% rbp$Symbol)
rbp_exp <- rbp_exp %>% column_to_rownames(var = "X")
t <- as.data.frame(t(rbp_exp))
t <- t %>% 
  mutate(group = ifelse(grepl("nervous", rownames(t)), "nervous_system", "Others")) %>% 
  mutate(group = ifelse(grepl("neuron", rownames(t)), "neuron", group))

#annotation
anno <- data.frame(row.names = rownames(t), Group = t$group)
#annotation color
colourCount = length(unique(t$group))
getPalette = colorRampPalette(brewer.pal(9, "Set1"))  
annoCol <- getPalette(colourCount)
names(annoCol) <- unique(t$group)
annoCol <- list(Group = annoCol)

t <- t %>% dplyr::select(-group)
t[t > 1] <- 1
t[t < -1] <- -1

#group colors
t <- t(t)
p <- pheatmap(t, cluster_rows = T,cluster_cols = F, show_rownames = F, show_colnames = T, border_color = "NA", fontsize = 10, annotation_col = anno, annotation_colors = annoCol, na_col = "white", color = colorRampPalette(c("blue","white", "red"))(100))

ggsave("FCA_body_RBP_heatmap.pdf", p, limitsize = F, scale = 1, width = 7, height = 12, units = c("in"), useDingbats=FALSE)



#CNS and PNS vs others
t <- as.data.frame(t(rbp_exp))
t <- t %>% 
  mutate(group = ifelse(grepl("adult_ventral_nervous_system", rownames(t)), "CNS", "Others")) %>% 
  mutate(group = ifelse(grepl("adult_peripheral_nervous_system", rownames(t)), "PNS", group)) %>% 
  group_by(group) %>% 
  summarise_all(mean) %>% 
  ungroup() %>% 
  column_to_rownames(var = "group")
  
plot <- as.data.frame(t(t))
plot <- plot %>% 
  dplyr::mutate(FC = CNS-Others) %>% 
  rownames_to_column(var = "Symbol")

#top 20 
top20 <- plot %>% 
  dplyr::arrange(desc(FC)) %>% 
  dplyr::slice(1:20)

top_heat <- top20 %>% 
  dplyr::select(Symbol, CNS, Others) %>% 
  column_to_rownames(var = "Symbol")

p <- pheatmap(top_heat, cluster_rows = F,cluster_cols = F, show_rownames = T, show_colnames =T, border_color = "NA", fontsize = 10, color = colorRampPalette(c("blue","white", "red"))(100))
p
ggsave("CNS_Others_top20_heatmap.pdf", p, limitsize = F, scale = 1, width = 2, height = 4 , units = c("in"), useDingbats=FALSE)

plot <- plot %>% 
  dplyr::mutate(group = ifelse(Symbol %in% top20$Symbol, "TOP20", "NO"))
plot$group <- factor(plot$group, levels = c("TOP20", "NO"))
plot <- plot  %>% arrange(desc(group))

#plotting
c <- ggplot(plot, aes(x=Others, y=PNS, color = group)) +
  geom_point(size = 4) +
  geom_abline(intercept = 0.6, slope = 1, size = 0.5, linetype = "dashed") +
  geom_abline(intercept = -0.6, slope = 1, size = 0.5, linetype = "dashed") +
  scale_color_manual(values = c('red', 'grey')) + 
  theme(legend.position="none") +
  labs(x="Expression (Others)", y="Expression (PNS)") +
  theme_classic() +
  theme(legend.position="none") +
  xlim(-0.6, 0.8) +
  ylim(-0.6, 2.5) +
  coord_fixed(ratio = 1)
c

p <- c + geom_text_repel(
  data = subset(plot, group == "TOP20"),
  aes(label = Symbol),
  size = 4,
  color = 'black',
  box.padding = unit(0.35, "lines"),
  point.padding = unit(0.3, "lines"),
  max.overlaps = Inf
)

ggsave("PNS_Others_top20.pdf", p, limitsize = TRUE, scale = 1, width = 7, height = 7, units = c("in"), useDingbats=FALSE)

#jitter plot
plot <- as.data.frame(t(t))
plot <- plot %>% 
  dplyr::mutate(FC_CNS = CNS-Others) %>% 
  dplyr::mutate(FC_PNS = PNS-Others) %>% 
  rownames_to_column(var = "Symbol") %>% 
  dplyr::select(Symbol, FC_CNS, FC_PNS)

plot <- melt(plot)
plot <- plot %>% 
  dplyr::mutate(group = ifelse(variable == "FC_CNS", ifelse(value > 0.8, "CNS_UP", "NO"), "NO"),
                group = ifelse(variable == "FC_PNS", ifelse(value > 0.8, "PNS_UP", group), group))

plot$variable <- factor(plot$variable, levels = c("FC_PNS", "FC_CNS"))
plot$group <- factor(plot$group, levels = c("CNS_UP", "PNS_UP", "NO"))

p <-ggplot(plot, aes(x = variable, y = value, color = group, group = variable)) +
  geom_jitter(position=position_jitter(width = 0.3, seed = 1, height = 0.1), size = 1.5) +
  scale_color_manual(values=c('red3', 'tomato3', 'grey')) +
  geom_hline(yintercept = -0.8, linetype = "dashed", color = "red") +
  geom_hline(yintercept = 0.8, linetype = "dashed", color = "red") +
  coord_flip() +
  theme_classic() +
  theme(legend.position = "none") +
  ylim(-3, 3) +
  ylab("Averge Difference") 
p

c <- p + geom_text_repel(
  data = subset(plot, plot$Symbol == "elav" | plot$Symbol == "fne" | plot$Symbol == "Rbp9"),
  aes(label = Symbol),
  size = 4,
  color = 'black',
  box.padding = unit(0.35, "lines"),
  point.padding = unit(0.3, "lines"),
  max.overlaps = Inf
)
ggsave("jitterr.pdf", c, limitsize = TRUE, scale = 1, width = 5, height = 3, units = c("in"), useDingbats=FALSE)


#neurons vs others dot plot
t <- as.data.frame(t(rbp_exp))
t <- t %>% 
  mutate(group = ifelse(grepl("nervous", rownames(t)), "neuron", "Others")) %>% 
  mutate(group = ifelse(grepl("neuron", rownames(t)), "neuron", group)) %>% 
  group_by(group) %>% 
  summarise_all(mean) %>% 
  ungroup() %>% 
  column_to_rownames(var = "group")

plot <- as.data.frame(t(t))
plot <- plot %>% 
  dplyr::mutate(FC = neuron-Others) %>% 
  dplyr::mutate(group = ifelse(FC > 0.6, "UP", "NO"),
                group = ifelse(FC < -0.6, "DOWN", group)) %>% 
  rownames_to_column(var = "Symbol")

#plotting
c <- ggplot(plot, aes(x=Others, y=neuron, color = group)) +
  geom_point(size = 4) +
  geom_abline(intercept = 0.6, slope = 1, size = 0.5, linetype = "dashed") + 
  geom_abline(intercept = -0.6, slope = 1, size = 0.5, linetype = "dashed") +
  scale_color_manual(values = c('grey', 'grey', 'red')) + 
  theme(legend.position="none") +
  labs(x="Expression (Others)", y="Expression (neuron)") +
  theme_classic() +
  theme(legend.position="none") +
  xlim(-0.5, 0.6) +
  ylim(-0.5, 2) +
  coord_fixed(ratio = 1)
c

p <- c + geom_text_repel(
  data = subset(plot, FC > 0.8 | FC < -0.8),
  aes(label = Symbol),
  size = 4,
  color = 'black',
  box.padding = unit(0.35, "lines"),
  point.padding = unit(0.3, "lines"),
  max.overlaps = Inf
)

p
ggsave("neuron_others_dot3.pdf", p, limitsize = TRUE, scale = 1, width = 7, height = 7, units = c("in"), useDingbats=FALSE)

#neurons vs others (including CNS PNS) plots for average violin >>>>> non scaled data
#load average expression
rbp_exp <- exp %>% filter(X %in% rbp$Symbol)
rbp_exp <- rbp_exp %>% column_to_rownames(var = "X")

t <- as.data.frame(t(rbp_exp))
t <- t %>% 
  mutate(group = ifelse(grepl("nervous", rownames(t)), "neuron", "Others")) %>% 
  mutate(group = ifelse(grepl("neuron", rownames(t)), "neuron", group))

t2 <- melt(t)
plot <- t2 %>% 
  dplyr::filter(variable %in% vnc_pns_overlap) %>% 
  dplyr::filter(variable == "elav" | variable == "fne" | variable == "Rbp9")

plot$variable <- factor(plot$variable, levels = c("elav", "fne", "Rbp9", "bru3", "trv", "aPKC", "CG10077", "CG12071", "CG12605", "CG34354"))
plot$variable <- factor(plot$variable, levels = c("elav", "fne", "Rbp9"))

#plotting
library(ggsignif)
library(rstatix)
library(ggpubr)

stat.test <- plot %>%
  group_by(variable) %>%
  t_test(value ~ group) %>%
  adjust_pvalue(method = "bonferroni") %>%
  add_significance()
stat.test 

c <- ggplot(plot, aes(x=variable, y=value, color = group, fill = group, facet.by = "variable")) +
  geom_boxplot(color = 'black', alpha = 1, coef = 10, width = 0.8) +
  geom_violin(trim = T, color = 'black') +
  geom_abline(intercept = 0.6, slope = 1, size = 0.5, linetype = "dashed") +
  geom_abline(intercept = -0.6, slope = 1, size = 0.5, linetype = "dashed") +
  scale_fill_manual(values = c('red', 'blue')) + 
  theme(legend.position="none") +
  labs(x="", y="log10 normalized count") +
  theme_classic() +
  theme(legend.position="right") +
  facet_grid(cols = vars(variable), scales = "free",  space = "free")
  ylim(0, 35)
  geom_signif(aes(group=value), test="wilcox.test", comparisons = list(c("neuron", "Others"), c("neuron", "Others"), c("neuron", "Others")), map_signif_level = T, y_position = c(100, 100, 100))
c

ggsave("box_EFR.pdf", c, limitsize = TRUE, scale = 1, width = 6, height = 5, units = c("in"), useDingbats=FALSE)