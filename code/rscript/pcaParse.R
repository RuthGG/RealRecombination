#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)

  # test if there is at least one argument: if not, return an error
  if (length(args)<2) {
    stop("The required arguments are input .pca, and output file name.", call.=FALSE)
  } 

# library(ggplot2)
# library(ggrepel)

# make_plot<-function(pca){
#   out <- as.data.frame(t(pca), stringsAsFactors = FALSE)
#   out[] <- lapply(out, type.convert, as.is = TRUE)
#   
#   colnames(out)<-data.table::transpose(strsplit(colnames(out), "_"))[[8]]
#   
#   new<-rownames(out)[! (rownames(out) %in% rownames(pop))]
#   content<-matrix(rep(c("Unknown", "Unknown", "male"), length(new)), byrow = TRUE, ncol = 3)
#   rownames(content)<-new
#   colnames(content)<-colnames(populations)
#   populations<-rbind(pop, content)
#   
#   out$super_pop<-populations[rownames(out),"super_pop"]
#   
#   incognita<-out[out$super_pop == "Unknown",]
#   incognita$individual<-rownames(incognita)
#   
#   ggplot(out)+geom_point(aes(x = PC1, y = PC2, color = super_pop))+ 
#     geom_text_repel(data=incognita,
#                     aes(x = PC1,y = PC2,label=individual))
# }
# 
# args<-list()
# args[1]<-"analysis/2020-04-16_mergePca/final_vcf.vcf.gz"


pca<-read.table(args[1], sep = " ", header = TRUE, row.names = 1)

save(pca, file=args[2])



# pop<-read.table(args[2], row.names = 1, stringsAsFactors = FALSE, header = TRUE)

# make_plot(pca)

# rownames(out)

