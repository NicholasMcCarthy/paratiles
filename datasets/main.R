# Script for feature analysis and accuracy tests of datasets.

## IMPORTS

library(gplots)
library(ggplot2)
library(gridExtra) # grid.arrange ~ subplot


## SETUP 

env = list()
env$root_dir = '/home/nick/git/paratiles/'
env$data_dir = '/home/nick/git/paratiles/datasets/'

dataset_name = 'TEX-HIST-CICM'
dataset_classes = c('G3', 'G34', 'G4', 'G45', 'G5')
dataset_combns = combn(dataset_classes, 2)

## ANON FUNCTIONS

func_ds_path = function(x) paste(env$data_dir, x, '_', dataset_name, '.csv', sep='')  #          Anonymous function to obtain csv path
func_labels_path = function(x) paste(env$data_dir, x, '_', dataset_name, '.labels.csv', sep='')  # Anonymous function to obtain label path
func_headers_path = function(x) paste(env$data_dir, x, '_', dataset_name, '.headers.csv', sep='')  # Anonymous function to obtain headers path

remove_outliers <- function(x, na.rm=TRUE, ...) {
   qnt = quantile(x, probs=c(.10, .90), na.rm=na.rm)
   H = 1.5 * IQR(x, na.rm=na.rm)
   y = x
   y[x < (qnt[1]-H)] <- NA
   y[x > (qnt[2]-H)] <- NA
   y
}
   


## MAIN LOOP

for (combo in 1:nrow(dataset_combns)) {
   
   C1 = dataset_combns[1, combo]
   C2 = dataset_combns[2, combo]
   
   
   ds <- rbind(read.csv(func_ds_path(C1), header=F, sep=","), read.csv(func_ds_path(C2), header=F, sep=","))
   
   labels <- rbind(read.csv(func_labels_path(C1), header=T, sep=","), read.csv(func_labels_path(C2), header=T, sep=","))
   
   n_obs = 3500;
   subset_idx <- c(sample(which(labels == C1), n_obs), sample(which(labels == C2), n_obs))
      
   pca = princomp(~ ., data=ds[subset_idx,], na.action=na.exclude)
      
   plot.data <- data.frame(pca$scores[,c("Comp.1", "Comp.2")], label=labels[subset_idx,])
      
   plot1 <- ggplot(plot.data, aes(x=Comp.1, y=Comp.2)) + geom_point(aes(shape=label, colour=label)) + ylab("PC1") + xlab("PC2") + theme_bw()
   
   plot2 <- ggplot(plot.data, aes(x=label, y=Comp.1, fill=label, colour=label)) + geom_boxplot() + theme_bw()
   
   # Remove 10 and 90th percentile outliers and replot PCA and boxplot 
   
   grid.arrange(plot1, plot2, ncol=2)    # Muuuuuultiplot!

   
}



path = dataset_paths[1]

ds = read.csv(path, sep=',', header=TRUE)

print dim(ds)



pca1 = princomp(ds)