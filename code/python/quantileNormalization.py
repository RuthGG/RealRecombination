#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Ruth Gómez Graciani
# 01 10 2020

# %% False arguments
# class Arguments:
#     def __init__(self, input, output, recMap):
#         self.input = input
#         self.output = output
#         self.recMap = recMap

# args = Arguments("../../analysis/2020-09-30_09_crossovers_invsG3/crossoverResult.Rdata", "tmp/", "../../analysis/2020-09-30_09_crossovers_invsG3/crossoverResult.Rdata")

def quantile_normalize(df):
    """
    input: dataframe with numerical columns
    output: dataframe with quantile normalized values
    """
    #  Order values in each column (np.sort)
    df_sorted = pd.DataFrame(np.sort(df.values, axis=0), index=df.index, columns=df.columns)
    #  Compute row means
    df_mean = df_sorted.mean(axis=1)
    # Rank means. Our index starts at 1, reflecting that it is a rank
    df_mean.index = np.arange(1, len(df_mean) + 1)
    # Rank each column independently to replace it with average values
    df_qn =df.rank(method="min").stack().astype(int).map(df_mean).unstack()

    return(df_qn)

###############################################################################
# Description:                                                 
# Script to make windows as required. Based on previous code chunks in bash      
###############################################################################

# MODULES
# Import modules as needed
# =========================================================================== #
import argparse  # Parser for command-line options, arguments and sub-commands; makes it easy to write user-friendly command-line
import pandas as pd # For dataframes: high-performance, easy-to-use data structures and data analysis tools 
import numpy as np
# import sys

# %% 
# ARGUMENTS
# Process arguments
# =========================================================================== #
if __name__ == "__main__": # if file was called and not imported

  # Start parser object
  parser = argparse.ArgumentParser(description="Script to create a bedfile with windows to analyze inside and around a target region.")
  
  # Required arguments
  parser.add_argument("--input", type = str, required = True, help = "Input file.", metavar="FILE")
  parser.add_argument("--output", type = str, required = True, help = "Output file.", metavar="FILE")

  # Optional arguments arguments
  parser.add_argument("--recMap", type = str, default=0, help = "Recombination map to make better normalization",  metavar = "FILE")

  # Parsing common arguments
  args = parser.parse_args()


  # %% 
  # GET COORDINATES
  # Open file with inversion coordinates and make dataframe
  # =========================================================================== #
  data = pd.read_table(args.input, sep = "\t", header = 0)
  
  if args.recMap != 0 :
    recMap = pd.read_table(args.recMap, sep = "\t", header = 0)
  
  # PARSE TABLE
  # Make modifications to original table as needed
  # =========================================================================== #   
  
  # Split inversion name, position and ID
  data[["inv", "position"]] = data["idWin"].str.split("_", n = 2, expand = True)[[0, 1]]
  
  # Make inversion list
  invList = data["inv"].unique()

  
# %%
  # NORMALIZE EACH INVERSION
  # Loop over inversions to normalize its result
  # =========================================================================== #   
    # Initialize final dataframe
  normalized = pd.DataFrame()

  for invName in invList:

    # NORMALIZE EACH INVERSION - Make a table to normalize
    # ------------------------------------------------------------------------- #
   
    # Take inversion chromosome
    invSubset = data[data["inv"] == invName]
    invChrom = invSubset.iloc[0, 6]

    # Remove inversion chromosome from recombination map
    invGenome = recMap[recMap["chrWin"] != invChrom]
        
    # Join both 
    invRecMap = pd.concat([invSubset[["idWin", "ind", "cM.Mb"]], invGenome[["idWin", "ind", "cM.Mb"]]])

    # From long to wide
    invQNtable = pd.pivot_table(invRecMap, values='cM.Mb', index=['idWin'], columns=['ind'], aggfunc=np.mean)

    # NORMALIZE EACH INVERSION - Make quantile normalization
    # ------------------------------------------------------------------------- #
   
    invQNnormed = quantile_normalize(invQNtable)

    # NORMALIZE EACH INVERSION - Return table to usual position
    # ------------------------------------------------------------------------- #

    # From wide to long
    invQNnormed["idWin"] = invQNnormed.index
    invQNnormed= pd.melt(invQNnormed, id_vars = 'idWin', value_name = "cM.Mb.QN")
    
    # NORMALIZE EACH INVERSION - Add result to original dataframe
    # ------------------------------------------------------------------------- #
    invSubset = invSubset.merge(invQNnormed, how = "left", on = ["idWin", "ind"])

    # Concatenate to final table
    normalized = pd.concat([normalized, invSubset])

  # FINAL NORMALIZED TABLE
  # Export table
  # =========================================================================== #   

  # Filter unwanted windows
  normalized_filtered = normalized[ ~normalized["position"].isin(["buffl", "buffr"])]

  # Save table 
  normalized_filtered.to_csv(args.output,index=None, sep='\t', mode='w')