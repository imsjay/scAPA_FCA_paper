setwd("")
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

#load LABRAT result
sum <- read.csv("./FCA_LABRAT_all.csv")
#split clusters
split <- sum$tissue
sum <- sum %>% dplyr::select(-tissue)
t <- as.data.frame(t(sum))
t <- t %>% 
  rownames_to_column(var="Gene")
t$Gene <- as.character(t$Gene)
t$Symbol <- mapIds(org.Dm.eg.db, 
                        keys=t$Gene, 
                        column="SYMBOL", 
                        keytype="FLYBASE",
                        multiVals="first")
t2 <- t %>% 
  mutate(Symbol = ifelse(is.na(Symbol), Gene, Symbol)) %>% 
  dplyr::select(-Gene)

#make a annotation track
track <- as.data.frame(rownames(t(t2)))
colnames(track) <- c("type")
track <- track %>% 
  dplyr::filter(type != "Symbol")
track <- track %>% mutate(group = if_else(str_detect(type, "sper"), "testis", "others")) %>% 
  mutate(group = if_else(str_detect(type, "test"), "testis", group)) %>% 
  mutate(group = if_else(str_detect(type, "cyst"), "testis", group)) %>% 
  mutate(group = if_else(str_detect(type, "follicle"), "ovary", group)) %>% 
  mutate(group = if_else(str_detect(type, "germline"), "ovary", group)) %>% 
  mutate(group = if_else(str_detect(type, "ovarian"), "ovary", group)) %>% 
  mutate(group = if_else(str_detect(type, "oviduct"), "ovary", group)) %>% 
  mutate(group = if_else(str_detect(type, "escort"), "ovary", group)) %>% 
  mutate(group = if_else(str_detect(type, "germ"), "ovary", group)) %>% 
  mutate(group = if_else(str_detect(type, "ovary"), "ovary", group)) %>% 
  mutate(group = if_else(str_detect(type, "neuron"), "neuron", group)) %>% 
  mutate(group = if_else(str_detect(type, "nervous"), "neuron", group))
table(track$group)
track <- track$group

#find a gene
t3 <- as.data.frame(t(t2))
t3 <- t3 %>% 
  rownames_to_column(var = "type")
t3 <- t3 %>% mutate(group = if_else(str_detect(type, "sper"), "testis", "others")) %>% 
  mutate(group = if_else(str_detect(type, "test"), "testis", group)) %>% 
  mutate(group = if_else(str_detect(type, "cyst"), "testis", group)) %>% 
  mutate(group = if_else(str_detect(type, "follicle"), "ovary", group)) %>% 
  mutate(group = if_else(str_detect(type, "germline"), "ovary", group)) %>% 
  mutate(group = if_else(str_detect(type, "ovarian"), "ovary", group)) %>% 
  mutate(group = if_else(str_detect(type, "oviduct"), "ovary", group)) %>% 
  mutate(group = if_else(str_detect(type, "escort"), "ovary", group)) %>% 
  mutate(group = if_else(str_detect(type, "germ"), "ovary", group)) %>% 
  mutate(group = if_else(str_detect(type, "ovary"), "ovary", group)) %>% 
  mutate(group = if_else(str_detect(type, "neuron"), "neuron", group)) %>% 
  mutate(group = if_else(str_detect(type, "nervous"), "neuron", group)) %>% 
  mutate(group = if_else(str_detect(type, "Symbol"), "Symbol", group))
t4 <- t3 %>% 
  dplyr::filter(group == "neuron" | group == "testis" | group == "ovary" | group == "Symbol") %>% 
  dplyr::select(-type)

neuron <- t4 %>% 
  dplyr::filter(group == "neuron") %>% 
  dplyr::select(-group)
neuron <- mutate_all(neuron, function(x) as.numeric(as.character(x)))
neuron <- neuron %>% 
  summarise_all(mean, na.rm = T)
neuron <- t(neuron)

testis <- t4 %>% 
  dplyr::filter(group == "testis") %>% 
  dplyr::select(-group)
testis <- mutate_all(testis, function(x) as.numeric(as.character(x)))
testis <- testis %>% 
  summarise_all(mean, na.rm = T)
testis <- t(testis)

ovary <- t4 %>% 
  dplyr::filter(group == "ovary") %>% 
  dplyr::select(-group)
ovary <- mutate_all(ovary, function(x) as.numeric(as.character(x)))
ovary <- ovary %>% 
  summarise_all(mean, na.rm = T)

ovary <- t(ovary)
all <- cbind(neuron, testis, ovary)
colnames(all) <- c("neuron", "testis", "ovary")
all <- as.data.frame(all)
all <- all %>% 
  rownames_to_column(var = "Symbol")

all <- all %>% 
  dplyr::mutate(d_testis = neuron-testis,
                d_ovary = neuron-ovary,
                d_testis_ovary = ovary-testis)

testis_apa <- all %>% 
  dplyr::filter(d_testis > 0.2 | d_testis < -0.2)
testis_apa <- testis_apa$Symbol
ovary_apa <- all %>% 
  dplyr::filter(d_ovary > 0.2 | d_ovary < -0.2)
ovary_apa <- ovary_apa$Symbol
two_apa <- all %>%
  dplyr::filter(d_testis_ovary > 0.2 | d_testis_ovary < -0.2)
two_apa <- two_apa$Symbol

feature <- Reduce(union, list(testis_apa, ovary_apa, two_apa))

#######
t3 <- t2 %>% 
  dplyr::filter(Symbol %in% feature) %>% 
  column_to_rownames(var="Symbol")
t4 <- as.data.frame(t(t3))
na <- as.data.frame(t(colSums(is.na(t4))))
rownames(na) <- "n_na"
t5 <- rbind(t4, na)
t5 <- as.data.frame(t(t5))

#cluster rows 
library(stats)
column_od = hclust(dist(t6), method = "average")$order
#method = "centroid")

#make a table for inner plot
inner <- t2 %>% 
  dplyr::filter(Symbol %in% feature) %>% 
  column_to_rownames(var="Symbol")
inner <- as.data.frame(t(inner))

t7 <- as.data.frame(t(t6))

####heatmap
pdf("FCA_LABRAT_circular_heatmap.pdf", width = 20, height = 20) 
col_fun1 = colorRamp2(c(0, 0.5, 1), c("blue", "gold", "red"))
col_fun2 = c("neuron" = "red", "testis" = "blue", "ovary" = "purple", "others" = "grey")
circos.par(gap.after = c(2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 10))
circos.heatmap(t7[ ,column_od], split = factor(split, levels = c("body", "bodywall", "fatbody", "gut", "haltere", "heart", "leg", "male_reproductive_glands", "malpighian_tube", "oenocyte", "trachea", "wing", "proboscis", "antenna", "head", "testis", "ovary")),
               col = col_fun1,
               show.sector.labels = T,
               rownames.side = "outside",
               dend.side = "inside",
               cluster = T)
circos.heatmap(track, col = col_fun2, track.height = 0.01)
row_mean = rowMeans(inner, na.rm=TRUE)
circos.track(ylim = range(row_mean), panel.fun = function(x, y) {
  y = row_mean[CELL_META$subset]
  y = y[CELL_META$row_order]
  circos.lines(CELL_META$cell.xlim, c(0.41, 0.41), lty = 2, col = "black")
  circos.lines(CELL_META$cell.xlim, c(0.60, 0.60), lty = 2, col = "black")
}, cell.padding = c(0.02, 0, 0.02, 0))
lgd = Legend(title = "PSI", col_fun = col_fun1)
grid.draw(lgd)

circos.clear()
dev.off()