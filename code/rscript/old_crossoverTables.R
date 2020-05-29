#!/usr/bin/env Rscript
# Ruth Gómez Graciani
# 05 05 2020

###############################################################################
# Description:                                                                
# Make tables used in report to make statistical analyses                     
###############################################################################

# LOAD ARGUMENTS 
# =========================================================================== #
args = commandArgs(trailingOnly=TRUE)

# # Test if there is at least one argument: if not, return an error
if (length(args)<3) {
  stop("One input file, one genotypes file and one output file.", call.=FALSE)
}

# Example
# args[1]<-"tmp/2020-05-05_08_crossovers/crossovers_x_inversions.txt" # Directory with imputation results in .vcf
# args[2]<-"analysis/2020-04-26_07_imputationTables/new_genotypes.csv"  # Test individuals population
# args[3]<-"analysis/2020-05-05_08_crossovers" # Inversions imputability

# LOAD PACKAGES
# =========================================================================== #

# First specify the packages of interest
packages = c("reshape2", "stringr")

# Now load or install&load all
lapply(packages,FUN = function(x) {
  if (!require(x, character.only = TRUE)) {
    install.packages(x, dependencies = TRUE)
    library(x, character.only = TRUE)
  }
})

# BASIC TABLE PARSING
# Results of imputation and extra info are all grouped into a table 
# =========================================================================== #

# BASIC TABLE PARSING - Inversions with crossovers
# --------------------------------------------------------------------------- #
  croxinv<-read.table(args[1], sep = "\t" , stringsAsFactors = FALSE)
  croxinv<-croxinv[croxinv$V3 == "inversion" & croxinv$V10 != ".",]
  croxinv$V9<-sub("ID=\\d+;Name=", "", croxinv$V9)
  croxinv$V9<-sub(";.*$", "", croxinv$V9)
  croxinv<-cbind(croxinv, str_split_fixed(croxinv$V13, "_", 2))
  
  croxinv<-croxinv[,c(9,1,4,5,14,15,11, 12 )]
  colnames(croxinv)<-c("inversion", "chromosome", "bp1s", "bp2e", "individual", "sample", "start", "end")

  
# BASIC TABLE PARSING - Incorporate imputation results
# --------------------------------------------------------------------------- #
  genotypes<-read.table(args[2], stringsAsFactors = FALSE, header=TRUE)
  genotypes<-melt(genotypes, id.vars = "Individual")
  genotypes$Individual<-sub("^.*\\.", "", genotypes$Individual)
  genotypes$Individual<-sub("nc", "NC", genotypes$Individual)
  genotypes$Individual<-sub("ab", "", genotypes$Individual)
  genotypes$variable<-as.character(genotypes$variable)

  croxinv<-merge(croxinv, genotypes, by.x = c("individual", "inversion"), by.y = c("Individual", "variable"), all = TRUE)
  colnames(croxinv)[colnames(croxinv) == "value"]<-"genotype"

# STORE TABLE
# Store table as Rdata
# =========================================================================== #

save(croxinv, file=args[3])  












