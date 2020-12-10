#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Ruth Gómez Graciani
# 30 09 2020

# %% False arguments
# class Arguments:
#     def __init__(self, input, numofsamples):
#         self.input = input
#         self.numofsamples = numofsamples
      

# args = Arguments("../../tmp/2020-09-26_09_crossovers/comparison.txt", "../../report/2020-04-29_statisticalPreliminary/numofsamples.txt")

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
import re

# ARGUMENTS
# Process arguments
# =========================================================================== #
if __name__ == "__main__": # if file was called and not imported

  # Start parser object
  parser = argparse.ArgumentParser(description="Script to create a bedfile with windows to analyze inside and around a target region.")
  
  # Required arguments
  parser.add_argument("--input", type = str, required = True, help = "Input file.", metavar="FILE")
  parser.add_argument("--numofsamples", type = str, required = True, help = "File with number of samples.", metavar="FILE")
  parser.add_argument("--output", type = str, required = True, help = "Output file.", metavar="FILE")

  # Parsing common arguments
  args = parser.parse_args()
  
  # GET INPUT FILES
  # Open file with inversion vs. crossovers and with individual number of samples
  # =========================================================================== #

  # Inversion vs. crossovers comparison
  data = pd.read_csv(args.input, sep = "\t", names = ["chrWin", "startWin", "endWin", "idWin", "chrXs" , "startXs", "endXs", "ind", "overlap"])
  # Number of samples data
  numofsamples = pd.read_csv(args.numofsamples, sep = " ", names = ["ind", "samples"])

  # MAKE RECOMBINATION RATES    
  # Calculate the recombination rate in cM per Mb
  # =========================================================================== #

  # MAKE RECOMBINATION RATES  - Basic table parsing
  # --------------------------------------------------------------------------- #


  # Replace points by numbers to avoid dividing by 0
  data['startXs'] = np.where((data.overlap == 0),1,data.startXs)
  data['endXs'] = np.where((data.overlap == 0),2,data.endXs)

  # MAKE RECOMBINATION RATES  - Make scores for each window and individual
  # --------------------------------------------------------------------------- #

  # Make scores for each event with an overlap
  data['overlapScore'] = data['overlap'] / (data['endXs'] - data['startXs'] )

  # Sum scores for each window, individual and inversion.
  grouped = data.groupby(['idWin', 'ind'], as_index = False)
  recMap = grouped[['overlapScore']].sum()

  # Now I want to make sure that all cases are included - even those with 0 crossovers found
  recMap = recMap.set_index( [ 'idWin', 'ind' ] )
  mux = pd.MultiIndex.from_product([recMap.index.levels[0], recMap.index.levels[1]],names=['idWin', 'ind'])
  recMap = recMap.reindex(mux, fill_value=0).reset_index()

  recMap = recMap[recMap.ind != "."]

  # MAKE RECOMBINATION RATES  - Convert scores to recombination rates
  # --------------------------------------------------------------------------- #
  
  # Control by number of samples 
  recMap = recMap.merge(numofsamples)
 
  # Make centiMorgans
  recMap['cM'] = ( recMap['overlapScore'] / recMap['samples'] )  * 100

  # Make rate (recombination rate)
  recMap['cM.Mb'] = (1-np.exp((-2*recMap['cM'])/100))/2

  # Add coordinates and calculate window size
  coordinates =  data[['chrWin', 'startWin', 'endWin', 'idWin']].copy()
  coordinates  = coordinates.drop_duplicates() 
  recMap = recMap.merge(coordinates)

  recMap["winsize"] = recMap['endWin']-recMap['startWin']

  # Adjust recombination rate depending on window size
  recMap['cM.Mb'] =  recMap['cM.Mb']*(1000000/ recMap["winsize"])

  # CREATE FILE
  # Make a file with the table
  # =========================================================================== #   

  recMap.to_csv(args.output,index=None, sep='\t', mode='w')
