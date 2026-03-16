## Libraries loading 

library(vegan)
library(ggplot2)
library(tidyverse)
library(FactoMineR)
library(factoextra)
##Data importation 

dataset <- read.csv("~/Projet IA/Datasets/ES_data.csv",
                    sep = ";", header = TRUE)

##Data exploration 

summary(dataset)

dataset <- dataset %>% 
  mutate(carbon_ha = carbon / area, 
         awy_ha = awy/area) %>% 
  select(-c(awy, carbon))

##Data splitting 

es_data <- dataset %>% 
  select(awy_ha, carbon_ha, ws_id)

env_data <- dataset %>% 
  select(-c(carbon_ha, awy_ha))

##Data preprocessing 

rownames(es_data) <- es_data$ws_id 

es_data$ws_id <- NULL

rownames(env_data) <- env_data$ws_id 

env_data$ws_id <- NULL

## DCA analysis 

rda_model <-  rda(es_data ~ ed + forest_cover + precip + area + ndwi, data = env_data, scale = TRUE)

summary(rda_model)

## VIF analysis 
vif.cca(rda_model)

## Scores extractions 

sites_df <- data.frame(scores(rda_model, display = "sites"))

var_df <- data.frame(scores(rda_model, display = "bp"))

es_df <- data.frame(scores(rda_model, display = "sp"))

##Graphics 

plot1 <- ggplot() +
  geom_point(data = sites_df, aes(x = RDA1,
                                  y= RDA2),
             color = "black", alpha = 0.6) +
  geom_segment(data = var_df, 
               aes(x = 0, y = 0, 
                   xend = RDA1,
                   yend = RDA2),
               arrow = arrow(length = unit(0.2, "cm")),
               color = "blue", linewidth = 0.8) +
  geom_text(data = var_df, aes(x = RDA1, y = RDA2, label = rownames(var_df)), 
            color = "blue", vjust = -0.5, size = 3.5) +
  geom_segment(data = es_df, 
               aes(x = 0, y = 0, xend = RDA1, yend = RDA2), 
               arrow = arrow(length = unit(0.2, "cm")), 
               color = "red", linetype = "dashed") +
  geom_text(data = es_df, aes(x = RDA1, y = RDA2, label = rownames(es_df)), 
            color = "red", fontface = "bold", vjust = 1.5) +
  geom_hline(yintercept = 0, linetype = "dotted") +
  geom_vline(xintercept = 0, linetype = "dotted") +
  theme_minimal() +
  labs(title = "RDA analysis on Ecosystem Services",
       x = "RDA1 (18.4%)", y = "RDA2 (3.9%)")



## PCA_analysis 

data_pca <- dataset %>% 
  select(-c(ws_id)) ##Id delete 

data_pca <- scale(data_pca) #Standardization 

res.pca <- PCA(data_pca, graph =FALSE) ##PCA analysis for dimension reduction

summary(res.pca) ##PCA analysis results

plot2 <- fviz_pca_var(res.pca, col.var = "contrib") #Correlation circle

## HCPC on PCA results 

res.hcpc <- HCPC(res.pca, graph = FALSE, nb.clust =  -1) ##Clustering on components 

res.hcpc$desc.var ##Cluster descriptions 

##Cluster additions to sites_df 

sites_df$cluster <- res.hcpc$data.clust$clust

## Final graphics 

plot3 <- ggplot() +
  geom_point(data = sites_df, aes(x = RDA1, y = RDA2, color = cluster), size = 2)+
  geom_segment(data = var_df, 
               aes(x = 0, y = 0, xend = RDA1,
                   yend = RDA2), 
               arrow = arrow(length = unit(0.2, "cm")), 
               color = "black") +
  geom_segment(data = es_df, 
               aes(x = 0, y = 0, xend = RDA1,
                   yend = RDA2), 
               arrow = arrow(length = unit(0.2, "cm")), 
               color = "red", linetype = "dashed")+
  geom_text(data = var_df, aes(x = RDA1, y = RDA2, label = rownames(var_df))) +
  geom_text(data = es_df, aes(x = RDA1, y = RDA2, label = rownames(es_df)))+
  theme_bw()+
  labs(title = "Typology of sub-catchment")

##Graphics exportations 

ggsave("correlation.jpeg", plot2, height = 5)

ggsave("last_gra.jpeg", plot3, height = 5)
