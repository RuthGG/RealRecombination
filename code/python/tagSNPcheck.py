#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Ruth Gómez Graciani
# 10 12 2020

# ###############################################################################
# Description:                                                 
# Script to check genotype according to tagSNPs when possible      
###############################################################################


# %% 
# MODULES
# Import modules as needed
# =========================================================================== #
import argparse  # Parser for command-line options, arguments and sub-commands; makes it easy to write user-friendly command-line
import pandas as pd # For dataframes: high-performance, easy-to-use data structures and data analysis tools 
import numpy as np
import re

# %% 
# ARGUMENTS
# Process arguments
# =========================================================================== #
if __name__ == "__main__": # if file was called and not imported

  # Start parser object
  parser = argparse.ArgumentParser(description="Script to infer genotypes from tagSNPs")
  
  # Required arguments
  parser.add_argument("--reference", type = str, required = True, help = "Genotype for tagSNPs in reference dataset.", metavar="FILE")
  parser.add_argument("--sample", type = str, required = True, help = "Genotype for tagSNPs in sample dataset.", metavar="FILE")
  parser.add_argument("--template", type = str, required = True, help = "Genotype for inversions in reference dataset.", metavar="FILE")
  parser.add_argument("--output", type = str, required = True, help = "Output location.", metavar="FILE")

  # Parsing common arguments
  args = parser.parse_args()


  # %%
  # IMPORT DATA
  # Import tables
  # =========================================================================== #

  ref_table  = pd.read_csv(args.reference , sep = "\t")
  sample_table = pd.read_csv( args.sample , sep = "\t")
  template = pd.read_csv(args.template, sep = "\t",  names=["ID", "GENOTYPE"])

  # %%
  # MAKE TEMPLATE TABLE
  # Parse template and genotypes to know which SNP genotypes correspond o each inv orientation
  # =========================================================================== #
  
  # List which genotypes we have available (e.g. STD, INV, HET)
  gen_sih_av = template.GENOTYPE.value_counts().index.tolist()

  # Clean colnames for ref_table
  colnames = list(ref_table.columns)
  colnames = [re.sub("\[\d+\]", '', file) for file in colnames]
  colnames = [re.sub(':GT', '', file) for file in colnames]
  ref_table.columns = colnames

  # Initiate template dataframe
  headlist = [ "# CHROM", "POS", "ID"  ]
  templateParsed = pd.DataFrame() 

  # Make a template columns for each genotype (gen_sih)
  for gen_sih in gen_sih_av:

    # Make a list of individuals' ID with the required genotype
    indlist = template[template.GENOTYPE == gen_sih]["ID"]
    
    if len(indlist) == 0:
      continue

    # Filter indlist to include only those that are present in the reference table
    indlist = indlist[ indlist.isin(ref_table.columns)]
    
    # Subset reference table for these individuals with required genotype
    columns = headlist+list(indlist)
    subset = ref_table[columns]
  
    #  Make temporary dataframe to store template for this gen_sih
    templateParsed_part = pd.DataFrame( columns = headlist+[gen_sih] ) 

    # For each SNP, check if all individuals are equal, because sometimes there is an outlayer
    for index, row in subset.iterrows():

      # Store all SNP genotypes that should be a consensus
      consensus = list(subset.iloc[index,3:len(columns)])
      
      consensus = [re.sub('1\|0', '0|1', geno )  for geno in consensus] # Just in case heterozygous inds

      # If there is actually a consensus, add to templateParsed_part
      if ( consensus[:-1] == consensus[1:]) :
        templateParsed_part = templateParsed_part.append( { headlist[0] : row[0],
                          headlist[1] : row[1],
                          headlist[2] : row[2],
                          gen_sih : consensus[0]
                      } , ignore_index=True)

    # Add templateParsed_part for one gen_sih to templateParsed. We want all SNPs, even those useful only for one orientation. 
    try:
      templateParsed = pd.merge(templateParsed, templateParsed_part, how='outer', on = headlist)
    except KeyError:
      templateParsed = templateParsed_part
      
    
  # %%
  # APPLY TEMPLATE
  # Calculate inversion genotype for each individual according to template
  # =========================================================================== #
    
  # Clean colnames for sample_table
  colnames = list(sample_table.columns)
  colnames = [re.sub('\[\d+\]\d*\.*', '', file) for file in colnames]
  colnames = [re.sub(':GT', '', file) for file in colnames]
  sample_table.columns = colnames

  # Make empty dataframe for the results 
  genotypedSamples = pd.DataFrame( columns = ["Ind", "Genotype", "Probability", "Coverage"] ) 

  # Change genotypes to match template pattern
  sample_table = sample_table.replace(to_replace ='/', value = '|', regex = True) 

  # Merge samples to pattern to compare
  compare  = pd.merge(templateParsed, sample_table , how = 'inner')
  
  # For each individual
  for ind in compare.columns[ ~compare.columns.isin(templateParsed.columns)] : 
    
    # Make subset only for this individual 
    compare_part = compare[gen_sih_av +[ind]].copy()
    compare_part[ind] = [re.sub('1\|0', '0|1', geno )  for geno in compare_part[ind]] # Just in case heterozygous inds

    # Create empty column for final genotype
    compare_part['genotype'] = ""

    # For each genotype (gen_sih), compare sample to template
    for gen_sih in gen_sih_av:
      compare_part.loc[compare_part[gen_sih] == compare_part[ind], ['genotype']] = gen_sih


    # Calculate how many genotypes of each were found
    ranking = compare_part['genotype'].value_counts(normalize = True)

    # Add info to genotypedSamples table
    genotypedSamples = genotypedSamples.append( { 'Ind' : ind,
                                              'Genotype' : ranking.index.tolist()[0],
                                              'Probability': ranking[0],
                                              'Avail.Tagsnps' : compare_part[compare_part['genotype'] != ""]['genotype'].count(),
                                              'Exist.Tagsnps': templateParsed.shape[0]
                                            } , ignore_index=True)

  # %%
  # SAVE TABLE
  # Save table in specified output location
  # =========================================================================== #
  
  genotypedSamples.to_csv(args.output,index=None, sep='\t', mode='w')