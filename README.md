# RealRecombination

Created by Ruth Gómez Graciani

## About

Give project objective, description and scope

## Structure

* `analysis`: a directory for each new run should be created, with the parameter files for that run if necessary.
* `code`: `software/` is for external code and the others are original code.
* `data`: `raw/` for data as-is and `use/` for preprocessed data that is the same regardless of analysis parameters. Please explain origin, content and format of each file in `raw/` to make it reproducible. 
* `project`: papers and other useful bibliography, project history.  Project history should have all pushed tests, even if they were discarded. Discarded tests should be added a comment about why they were discarded. 
* `report`: reports, power points, etc. each in its directory. Final, sent files should be in deliver/ subdirectories.
* `tmp`: temporary files, organized as in `analysis`. 

## Prerequisites

This project should be associated with a conda environment of the same name. To activate it, do:

```conda activate RealRecombination```

## Running the tests

`run_example.sh` runs the analyses with part of the data. 

The analysis is divided in different parts, that are options in `runall.sh`. Each of them could have its own requirements:

* `runall download` downloads available raw data (`data/raw`).
* `runall dbgap` downloads data from dbgap given an ID (Crick).
* `runall preprocess` processes raw data to use it (`data/use`).
* `runall merge` merges test and reference data for all chromosomes in preparation to do the PCA. 
* `runall pca` performs the pca analysis.
* `runall pcaplot` makes the plot for the pca results. It is separated from pca to allow independent adjustments in plots. 
* `runall impute` imputes a list of invesions in a list of individuals with IMPUTE2. 
* `runall imputetables` makes summary tables for the imputation results.
* `runall tagsnps` is to check which tag snps has an inversion given a group of individuals (usually a population).
* `runall crossovers` merges genotype information with crossovers information for the statistical analysis. 

## A note on code comment structure

The header: 
```
#!/bin/bash
# Ruth Gómez Graciani
# 01 04 2020

###############################################################################
# Description:                                                                
#                                         
###############################################################################
```

The levels of code:

```
# MAIN BLOCK
# Description
# =========================================================================== #

# MAIN BLOCK - SUB BLOCK
# --------------------------------------------------------------------------- #

# Normal comment

```

Note the 4-3-2-1 lines in the different comments.

