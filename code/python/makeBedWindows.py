#!/home/rgomez/anaconda3/envs/RealRecombination/bin/python
# -*- coding: utf-8 -*-

# Ruth Gómez Graciani
# 25 09 2020

# %% False arguments
class Arguments:
    def __init__(self, input, output, fixedWindow, windowMethod, propCIWindow, fixedCIWindow, amountCI, chromBoundaries):
        self.input = input
        self.output = output
        self.fixedWindow = fixedWindow
        self.windowMethod = windowMethod
        self.propCIWindow = propCIWindow
        self.fixedCIWindow = fixedCIWindow
        self.amountCI = amountCI
        self.chromBoundaries = chromBoundaries

args = Arguments("../../data/use/inversions_info/2020.08.inversions_hg38_G4.gff", "../../tmp/windows.bed", 100000, "fromCenter", 100, 100, 3, "../../data/use/assembly_hg38/minmax.gff")

###############################################################################
# Description:                                                 
# Script to make windows as required. Based on previous code chunks in bash      
###############################################################################

# MODULES
# Import modules as needed
# =========================================================================== #
import argparse  # Parser for command-line options, arguments and sub-commands; makes it easy to write user-friendly command-line
import pandas as pd # For dataframes: high-performance, easy-to-use data structures and data analysis tools 
import re 
import sys

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
  parser.add_argument("--chromBoundaries", type = str, required = True, help = "Chromosome start and end positions file.", metavar="FILE")

  # Required one of the following
  parser.add_argument("--fixedWindow", type = int, default = 0, help = "Window size (in bps) inside target", metavar = "BASEPAIRS")
  parser.add_argument("--propWindow", type = int, default = 0, help = "Window size (in percentage) inside target.", metavar = "PERCENTAGE")

  # Default arguments
  parser.add_argument("--fixedCIWindow", type = int, default = 0, help = "Window size (in bps) outside target.",  metavar = "BASEPAIRS")
  parser.add_argument("--propCIWindow", type = int, default = 0, help = "Window size (in percentage) outside tagert.",  metavar = "PERCENTAGE")
  parser.add_argument("--amountCI", type = int, default = 0, help = "Amount of windows to add to either side of target.", metavar = "NUMBER")
  parser.add_argument("--windowMethod", type = str, default = "fromLeft", choices=['fromLeft', 'fromCenter' ], help = "Method to calculate windows.", metavar = "'fromLeft' OR 'fromCenter' ")
  
  # Parsing common arguments
  args = parser.parse_args()

  if args.fixedWindow == 0 and args.propWindow == 0 :
    parser.error('To execute this script you must specify window size through either --fixedWindow <basepairs> or --propWindow <percentage>.')
  
  if args.amountCI > 0 and args.fixedCIWindow == 0 and args.propCIWindow == 0:
    parser.error('To apply a confidence interval you must specify CI size with either --fixedCIWindow or --propCIWindow.')

  if args.amountCI > 0 and args.fixedCIWindow > 0 and args.propCIWindow > 0:
    parser.error('Only --fixedCIWindow or --propCIWindow can be used.')

  # %% 
  # GET COORDINATES
  # Open file with inversion coordinates and make dataframe
  # =========================================================================== #
  data = pd.read_table(args.input, sep = "\t", header = None)
  boundaries = pd.read_table(args.chromBoundaries, sep = "\t", header = None)

  # MAKE WINDOWS TABLE
  # Make a table with required windows for each line
  # =========================================================================== #   
  
  # Initialize final dataframe
  bedFile = pd.DataFrame()

  for index, row in data.iterrows():

    # MAKE WINDOWS TABLE - Take inversion ID, chromosome, start and end
    # ------------------------------------------------------------------------- #
    invID = row[8]
    invID = re.sub(r'^.*Name=', '', invID)
    invID = re.sub(r';.*$', '', invID)

    chrom = row[0]
    start = row[3]
    end = row[4]+1 # Now is 0-based
    invSize = end-start

    # MAKE WINDOWS TABLE - Make inversion windows
    # ------------------------------------------------------------------------- #
    # Calculate window size inside inversion 
    if args.fixedWindow > 0 : 
      winSize = args.fixedWindow
    else: # else it is proportional
      winSize = invSize * (args.propWindow / 100 ) 
    
    # Calculate start points for windows inside inversion 
    if args.windowMethod == "fromCenter":
      center = start + (invSize / 2) # This will not be the exact center in odd numbers, but works well enough
      if (winSize > invSize) and (invSize < (2 * winSize)) : 
        starts = [ center - (winSize / 2) ]
      else: 
        rangeInvL=range(center, start, -winSize)
        rangeInvL=[ x-winSize for x in rangeInvL]
        rangeInvR=range(center, end, winSize)
        starts = rangeInvL+rangeInvR
    else:  # Else it is fromLeft
      starts = range(start, end, winSize)
            
    # Calculate end points for windows inside inversion
    ends =[ x+winSize for x in starts]
    names=[invID+"_inv_%d" % (x + 1) for x in range(len(starts))]

    # MAKE WINDOWS TABLE - Add confidence intervals
    # ------------------------------------------------------------------------- #
    # Calculate condifence interval size
    if args.amountCI > 0 :  
      if args.fixedCIWindow > 0 :
        winSizeCI = args.fixedCIWindow
      else: # else it is proportional
        winSizeCI = invSize * (args.propCIWindow / 100 )
    
      confInt = winSizeCI *  args.amountCI

      # Calculate start and endpoints for confidence intervals
      startCI = min(starts) - confInt
      endCI = max(ends) + confInt

      # Confidence interval starts
      startsCIL=range(startCI, min(starts), winSizeCI)
      startsCIR=range( max(ends), endCI, winSizeCI)
      
      # Confidence interval ends
      endsCIL=[ x+winSizeCI for x in startsCIL]
      endsCIR=[ x+winSizeCI for x in startsCIR]

      # Confidence interval names
      namesCIL=[invID+"_left_%d" % (x + 1) for x in range(len(startsCIL))]
      namesCIR=[invID+"_right_%d" % (x + 1) for x in range(len(startsCIR))]

    else:
      startsCIL = []
      startsCIR = []
      endsCIL = []
      endsCIR = []
      namesCIL = []
      namesCIR = []

    # MAKE WINDOWS TABLE - Add chromosome buffering for normalization
    # ------------------------------------------------------------------------- #
    
    if args.amountCI > 0 : 
      winSizeBuffer = winSizeCI
      endBufferL = min(startsCIL)
      startBufferR = max (endsCIR )
    else : 
      winSizeBuffer = winSize
      endBufferL = min(starts)
      startBufferR = max(ends)

    # Calculate start and endpoints for buffer intervals
    startBufferL = int(boundaries[boundaries[0] == chrom][3])
    endBufferR = int(boundaries[boundaries[0] == chrom][4])

    # Confidence interval starts
    startsBufferL=range(startBufferL, endBufferL, winSizeBuffer)
    startsBufferR=range( startBufferR, endBufferR, winSizeBuffer)
    
    # Confidence interval ends
    endsBufferL=[ x+winSizeBuffer for x in startsBufferL]
    endsBufferR=[ x+winSizeBuffer for x in startsBufferR]

    # Confidence interval names
    namesBufferL=[invID+"_buffl_%d" % (x + 1) for x in range(len(startsBufferL))]
    namesBufferR=[invID+"_buffr_%d" % (x + 1) for x in range(len(startsBufferR))]


    # MAKE WINDOWS TABLE - Create final table
    # ------------------------------------------------------------------------- #      
    rowWins = pd.DataFrame( 
      {'pos.leftbound' : startsBufferL+startsCIL+starts+startsCIR+startsBufferR,
        'pos.rightbound' : endsBufferL+endsCIL+ends+endsCIR+endsBufferR,
        'ID' : namesBufferL+namesCIL+names+namesCIR+namesBufferR
        }, columns=['pos.leftbound', 'pos.rightbound', 'ID']) # columns maintains my columns in place

    rowWins.insert(0, 'chr', chrom) # The 0 is to insert the column in the first place
    
    # Trim confidence intervals if necessary
    rowWins = rowWins[rowWins["pos.leftbound"] >= startBufferL]
    rowWins = rowWins[rowWins["pos.rightbound"] <= endBufferR]

    # Concatenate to final table
    bedFile = pd.concat([bedFile, rowWins])

  # CREATE FILE
  # Make a file with the table
  # =========================================================================== #   
  bedFile.to_csv(args.output,index=None, sep='\t', mode='w')
