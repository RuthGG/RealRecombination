#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)

  # test if there is at least one argument: if not, return an error
  if (length(args)<2) {
    stop("The required arguments are input .pca, and output file name.", call.=FALSE)
  } 


pca<-read.table(args[1], sep = " ", header = TRUE, row.names = 1)

save(pca, file=args[2])


