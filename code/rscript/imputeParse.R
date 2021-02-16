#!/usr/bin/env Rscript
# Ruth Gómez Graciani
# 25 04 2020

###############################################################################
# Description:                                                                
# Make summary tables from IMPUTE2 imputation results                                     
###############################################################################

# LOAD ARGUMENTS 
# =========================================================================== #
args = commandArgs(trailingOnly=TRUE)

# # Test if there is at least one argument: if not, return an error
if (length(args)<4) {
  stop("Not enough input files.", call.=FALSE)
}

# Example
#  
# args[1]<-"analysis/2021-02-16_06_imputation_merged" # Directory with imputation results in .vcf
# args[2]<-"data/use/avery_individuals/samples_population.txt"  # Test individuals population
# args[3]<-"data/use/inversions_info/Inversions_imputability.txt" # Inversions imputability
# args[4]<-"tmp/test" # output directory



# LOAD PACKAGES
# =========================================================================== #

# First specify the packages of interest
packages = c("stringr", "reshape2", "naniar")

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

# BASIC TABLE PARSING - Imputation results
# --------------------------------------------------------------------------- #

# Set it as a function to limit stored intermediate objects
# directory<-args[1]
  parsedir<-function(directory){
    
  # Previous parameters
    files<-list.files(directory, pattern = "*.vcf", full.names=TRUE)
    filelist<-list()
    control_list<-c()
    test_list<-c()

  # Parsing loop
    for (filename in files) {
    trim_filename<-sub( ".*\\/", "", filename)
    trim_filename<-sub( "_readSum.vcf", "", trim_filename)
    table<-read.table( filename, sep = "\t", stringsAsFactors = FALSE, comment.char = "" , skip = 2, header = TRUE, check.names = FALSE )
  
    vcf<-table[,c(3,10:length(table))]
    
    vcf_melted<-reshape2::melt(vcf, id.vars = "ID")
    
    vcf_melted$Inversion<-str_split_fixed(vcf_melted$ID, ";", 2)[,1]
    vcf_melted<-cbind(vcf_melted[,c("Inversion", "variable")], str_split_fixed(vcf_melted$value, ":", 2), stringsAsFactors=FALSE)
    
    # vcf_merged<-merge(vcf_melted, populations , by.x = "variable", by.y = "sample", all.x = TRUE)
    if (grepl("ALL", trim_filename)) {
      defname<-str_split_fixed(trim_filename, "_", 2)[2]
      test_list<-c(test_list, trim_filename)
    }else{
      defname<-"con"
      control_list<-c(control_list, trim_filename)
    }
    colnames(vcf_melted)<-c("Inversion", "Individual", paste( "Genotype", defname, sep="_"), paste( "Probability", defname, sep="_"))
    
    
    filelist[[trim_filename]]<-vcf_melted
    
  }
  
  # Merge controls
    filelist[["control"]]<-do.call("rbind", filelist[control_list])
  
  # Merge all
    all_3c<-Reduce(function(x, y) merge(x, y, by=c("Inversion", "Individual"), all = TRUE), filelist[c(test_list, "control")] )
  
  # Replace "" by NA
    indivs_vector<-all_3c$Individual
    all_3c<- all_3c %>% replace_with_na_all(condition = ~.x == "")
    all_3c<-as.data.frame(all_3c)
    all_3c$Individual<-indivs_vector
    
  # Return table
    return(all_3c)
}

# Apply function
  all_3c<-parsedir(args[1])

# BASIC TABLE PARSING - Add extra info
# --------------------------------------------------------------------------- #
  
# Populations
  populations<-  read.table(args[2], header = TRUE, stringsAsFactors = FALSE)[,c(1,3)]
  colnames(populations)<-c("Individual", "Population")
  
  all_3c<-merge(all_3c, populations, all = TRUE)

# Inversion inputability (sorted factor)
  imputability<-read.table(args[3], header = TRUE)
  imputability$GLB<-factor(imputability$GLB, levels = c("No_Polymorphic", "Tagged", "Imputable", "No_Imputable"))
  imputability$EUR<-factor(imputability$EUR, levels = c("No_Polymorphic", "Tagged", "Imputable", "No_Imputable"))
  imputability$AFR<-factor(imputability$AFR, levels = c("No_Polymorphic", "Tagged", "Imputable", "No_Imputable"))

  all_3c<-merge(all_3c,imputability, all.x = TRUE)

# IMPUTATION SUMMARIZATION
# Results of imputation are classified according to their reliability
# =========================================================================== #
  
# IMPUTATION SUMMARIZATION - Uniformity: are all results equal? 
# DEPRECATED 
# --------------------------------------------------------------------------- #
  
  # all_3c$Uniformity<-""
  # 
  # # Known populations
  # all_3c[which(all_3c$Genotype_100 != all_3c$Genotype_250 | all_3c$Genotype_250!= all_3c$Genotype_500 | all_3c$Genotype_250!= all_3c$Genotype_100),"Uniformity"]<-"bad"
  # all_3c[which(all_3c$Genotype_100 == all_3c$Genotype_con & all_3c$Uniformity == "" ), "Uniformity"]<-"good"
  # all_3c[all_3c$Uniformity == "", "Uniformity"]<-"alert"
  # # Unknown populations
  # all_3c[(all_3c$Genotype_100 != all_3c$Genotype_250 | all_3c$Genotype_250!= all_3c$Genotype_500 | all_3c$Genotype_250!= all_3c$Genotype_100) & all_3c$Population == "ALL","Uniformity"]<-"bad"
  # all_3c[ all_3c$Uniformity != "bad" & all_3c$Population == "ALL", "Uniformity"]<-"good"

# IMPUTATION SUMMARIZATION - Quality: do all results have a probability > 80%?
# DEPRECATED
# --------------------------------------------------------------------------- #  
  
  # all_3c$Quality<-""
  # 
  # #Known populations
  # all_3c[which(all_3c$Probability_100 > 0.8 & all_3c$Probability_250 > 0.8 & all_3c$Probability_500 > 0.8 & all_3c$Probability_con > 0.8 ),"Quality"]<-"good"
  # all_3c[which(all_3c$Probability_100 < 0.8 & all_3c$Probability_250 < 0.8 & all_3c$Probability_500 < 0.8 & all_3c$Probability_con < 0.8 ),"Quality"]<-"bad"
  # all_3c[ all_3c$Quality == "","Quality"]<-"alert"
  # #Unknown populations
  # all_3c[(all_3c$Probability_100 > 0.8 & all_3c$Probability_250 > 0.8 & all_3c$Probability_500 > 0.8 ) & all_3c$Population == "ALL","Quality"]<-"good"
  # all_3c[(all_3c$Probability_100 < 0.8 & all_3c$Probability_250 < 0.8 & all_3c$Probability_500 < 0.8 )& all_3c$Population == "ALL","Quality"]<-"bad"
  # all_3c[ !(all_3c$Quality %in% c("good", "bad")) & all_3c$Population == "ALL","Quality"]<-"alert"

# OUTPUT SPREADSHEET
# Results of imputation are included into a spreadsheet with two sheets
# =========================================================================== #
  
# OUTPUT SPREADSHEET - Sheet 1: Imputation Results
# DEPRECATED
# --------------------------------------------------------------------------- #   

  # sheet1<-all_3c[order(all_3c$GLB, all_3c$Individual),c("Inversion","Individual","Population","Genotype_con","Probability_con","Genotype_100","Probability_100","Genotype_250","Probability_250","Genotype_500","Probability_500","GLB","AFR","EUR","Uniformity","Quality")]  
  # write.csv(sheet1, paste0(args[4],"/imputationResults.csv"), row.names = FALSE)

# OUTPUT SPREADSHEET - Sheet 2: Summary by inversion
# DEPRECATED
# --------------------------------------------------------------------------- #   
# 
#   # Store as function to avoid intermediate objects
#   summarize<-function(all_3c){
#   
#     # List populations
#     my.pops<-c(unique(all_3c$Population))
#   
#     # Start list
#     res_list<-list()
#     
#     for (pop in my.pops) {
#       
#       cols<-10
#       colist<-c("Population", "Imputability","Good_Geno" , "P_pop", "P_100",  "P_250","P_500", "Summary", "Heteros")
#       
#       invs<-unique(all_3c$Inversion)
#       
#       tmp<-data.frame(matrix(vector(), nrow = length(invs), ncol=cols, dimnames = list(c(1:length(invs)), c("Inversion",colist))), stringsAsFactors = FALSE )
#       tmp$Inversion<-invs
#       
#       # For each inversion and population, make a summary
#       for (inv in tmp$Inversion) {
#         
#         tmp_2<-all_3c[all_3c$Inversion == inv & all_3c$Population == pop,]
#         
#         if(pop %in% "ALL"){
#           imput<-as.character(tmp_2[1,"GLB"])
#           popmean<-NA
#         }else if(pop %in% c("EUR", "AFR")){
#           imput<-as.character(tmp_2[1,pop])
#           popmean<- mean(as.numeric(tmp_2$Probability_con))
#         }else{
#           imput<-NA
#           popmean<- mean(as.numeric(tmp_2$Probability_con))
#         }
#         
#         # Content of the summary
#         content<-c(
#           pop,
#           imput,
#           table(tmp_2$Uniformity)["good"]/sum(table(tmp_2$Uniformity)),
#           popmean,
#           mean(as.numeric(tmp_2$Probability_100)),
#           mean(as.numeric(tmp_2$Probability_250)),
#           mean(as.numeric(tmp_2$Probability_500)) ,
#           sum(table(tmp_2[tmp_2$Uniformity == "good","Genotype_100"]) > 0),
#           table(tmp_2[tmp_2$Uniformity == "good","Genotype_100"])["HET"] 
#         )
#         
#         tmp[tmp$Inversion == inv, colist] <- content
#         
#       }
#       
#       res_list[[pop]]<-tmp
#       # rm(tmp, tmp_2, content)
#     }
#     
#     inversion_summary<-do.call(rbind, res_list)
#     inversion_summary<-inversion_summary[order(inversion_summary$Inversion),]
#     
#     inversion_summary[is.na(inversion_summary$Heteros),"Heteros"]<-0
#     
#     return(inversion_summary)
#   }
#   
#   sheet2<-summarize(all_3c)
#   write.csv(sheet2,   paste0(args[4],"/summaryByInversion.csv"), row.names = FALSE) 

# OUTPUT GENOTYPES FILE
# Automatically selected genotypes that can be considered good quality
# =========================================================================== #
  
# OUTPUT GENOTYPES FILE - Definitive accepted genotypes
# --------------------------------------------------------------------------- #  

  # # Take imputable inversions
  # imputable<-as.character(imputability[!(imputability$GLB %in% c("No_Imputable")|imputability$AFR%in% c("No_Imputable")|imputability$EUR%in% c("No_Imputable")), "Inversion"])
  # 
  # # Make it as a function to avoid intermediate variables
  # makeGenotypes<-function(all_3c, imputable){
  #   
  #   # Take interesting inversions
  #   part<-all_3c[all_3c$Inversion %in% imputable, ]
  # 
  #   # Make a case marker
  #   part$accepted<-NA
  # 
  #   # Accepted case 1: good uniformity and good probability
  #   part[part$Uniformity == "good" & 
  #          part$Quality == "good" , "accepted" ]<-"yes"
  #   
  #   # Accepted case 2: good uniformity and alert probability but good probability in population-specific
  #   part[is.na(part$accepted) & part$Uniformity == "good" & part$Quality == "alert" & 
  #          part$Probability_con > 0.8  &  !is.na(part$Probability_con ), "accepted" ]<-"yes"
  #   
  #   # Accepted case 3: FOR LESS STRICT FILTERING - all with good uniformity
  #   part[is.na(part$accepted) & part$Uniformity == "good" , "accepted" ]<-"yes"
  #   
  #   # Accepted case 4: FOR LESS STRICT FILTERING - bad uniformity but good probability in population-specific
  #   part[is.na(part$accepted) & part$Uniformity != "good" & 
  #          part$Probability_con > 0.8  & !is.na(part$Probability_con), "accepted"]<-"pop"
  #   
  #   # Transform to genotypes table
  #   p1<-part[part$accepted %in% c("yes"),c("Inversion", "Individual", "Genotype_100")]
  #   p2<-part[part$accepted %in% c("pop"),c("Inversion", "Individual", "Genotype_con")]
  #   colnames(p1)<-colnames(p2)
  #   p<-rbind(p1,p2 )
  #   w<-reshape2::dcast(p, Individual ~ Inversion)
  #   
  #   return(w)
  # }
  
  # genotypes<-makeGenotypes(all_3c, imputable)
  write.table(all_3c,   paste0(args[4],"/new_genotypes.csv"), quote = FALSE, sep = "\t", na = ".", row.names = FALSE, col.names = TRUE) 
  
  