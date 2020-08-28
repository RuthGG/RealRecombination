#!/usr/bin/env Rscript
# Ruth Gómez Graciani
# 09 07 2020

###############################################################################
# Description:                                                                
# Aggregate crossover tables               
###############################################################################

# LOAD ARGUMENTS 
# =========================================================================== #
args = commandArgs(trailingOnly=TRUE)

# # Test if there is at least one argument: if not, return an error
if (length(args)<3) {
  stop("One input file, one number of samples file, one output directory", call.=FALSE)
}

# Example
# args[1]<-"tmp/2020-07-29_09_crossovers/windows_x_crossovers_weighted.txt" # Directory with crossover results
# args[2]<-"report/2020-04-29_statisticalPreliminary/numofsamples.txt"  # Number of cells per sample
# args[3]<-"analysis/2020-07-08_09_crossovers_inv10kb/recMap.Rdata" # Exit file

# LOAD PACKAGES
# =========================================================================== #

# First specify the packages of interest
packages = c("tidyr")

# Now load or install&load all
lapply(packages,FUN = function(x) {
  if (!require(x, character.only = TRUE)) {
    install.packages(x, dependencies = TRUE)
    library(x, character.only = TRUE)
  }
})

# BASIC TABLE PARSING
# Recombination rates are calculated for each category
# =========================================================================== #

  # BASIC TABLE PARSING - Load files
  # --------------------------------------------------------------------------- #
  
  # Load crossover file
  weightMap<-read.table(args[1])
  colnames(weightMap)<-c("chr_w", "start_w", "end_w", "inv","chr_e", "start_e", "end_e", "ind", "overlap", "score")
  
  # Clean individual names from crossover file
  weightMap$ind<-sub("_.*$","", weightMap$ind)
  
  # Load number of samples
  numofsamples<-read.table(args[2], stringsAsFactors = FALSE)
  colnames(numofsamples)<-c("ind", "samples")

  # BASIC TABLE PARSING - Table aggregation
  # --------------------------------------------------------------------------- #
  
  # Sum scores for each window, individual and inversion. Coordinates also included to maintain them in the final table
  weightMap.agg<-aggregate(score ~ chr_w+start_w+end_w+ind+inv, data=weightMap, FUN=sum)
  
  # Now I want to make sure that all cases are included - even those with 0 crossovers found
  weightMap.com<-weightMap.agg %>% complete(ind, nesting(inv, chr_w, start_w, end_w), fill = list(score=0))
  weightMap.com<-weightMap.com[weightMap.com$ind != ".",]
  
  # BASIC TABLE PARSING - Recombination rate calculation
  # --------------------------------------------------------------------------- #
  
  # Control by number of samples  
  recMap<-merge(weightMap.com, numofsamples, all.x = TRUE)
  
  # Make centiMorgans (genetic distance)
  recMap$cM<-(recMap$score/recMap$samples)*100
  
  # Make rate (recombination rate)
  recMap$cM.Mb<-(1-exp((-2*recMap$cM)/100))/2
  
  # Adjust rate
  recMap$winsize<-recMap$end_w-recMap$start_w
  recMap$cM.Mb<- recMap$cM.Mb*(1000000/recMap$winsize)
   
  

# STORE TABLE
# Store table as Rdata
# =========================================================================== #

save(recMap, file=args[3])  












