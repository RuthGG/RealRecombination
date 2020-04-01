#!/bin/bash
# Ruth Gómez Graciani
# 01 04 2020

###############################################################################
# Description:                                                                
# Run all the analyses in this project                                        
###############################################################################

# SAVE HISTORY
# Save date and command 
# =========================================================================== #
echo "$(date +"%Y%m%d") : runall.sh $*" >> project/history.txt

# GET INPUT
# Here parameters are parsed.
# =========================================================================== #

$RUN=$1

# Add here conditions to check for parameter dependencies. Don't forget to mention new options in README.md!!

# DOWNLOAD RAW DATA
# All publicly available data is now downloaded to data/raw.
# =========================================================================== #

# if [ "$RUN" == "download" ] || [ "$RUN" == "all" ]; do

# # Download file x
# # Origin, content and format in data/raw/README.md

# done

# PREPROCESS RAW DATA
# Files common for any analysis are created only once and stored in data/use.
# =========================================================================== #

# if [ "$RUN" == "preprocess" ] || [ "$RUN" == "all" ]; do

# Process file x to y
# Origin, content and format in data/use/README.md

# done



