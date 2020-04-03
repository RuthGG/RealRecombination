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
DATE=$(date +%F)
echo "${DATE}: runall.sh $*" >> project/history.txt

# USAGE 
# Help message. Don't forget to mention new options in README.md!!  
# =========================================================================== #

usage()
{
  echo "Usage: 

  $(basename $0) <COMMAND> [OPTIONS]
  "
  echo "Commands:

  all [OPTIONS]                       Run all commands (requires mandatory options).
  download -a [hg19|hg38] [-s]        Download publicly available data.
  preprocess [-s]                     Prepare raw data to use it in the analysis commands.
  "
  echo "Options:

    -h                                Show help.
    -s <screens>                      Set a number of screens to use. 
    -a [hg19|hg38]                    Set assembly to work with.
  "

}

# PARSE OPTIONS
# Parse options and get help 
# =========================================================================== #

# Parse help message
while getopts "h" OPT; do
   case "$OPT" in
      h)  usage; exit 1 ;;
   esac
done
shift $((OPTIND -1))

# Save command, if any
COMMAND=$1; shift

# Set default optional variables
SCREENS=1;

# Set empty mandatory variables
ASSEMBLY="";

# Parse command optons
case "$COMMAND" in
  #Run all commands
  all ) 
    while getopts "s:a:" OPTIONS ; do
      case "$OPTIONS" in
        s)  SCREENS=${OPTARG} ;;
        a)  ASSEMBLY=${OPTARG} 
            [[ ! $ASSEMBLY =~ hg38|hg19 ]] && {
            echo "Incorrect options provided to -${OPTIONS}."
            usage; exit
          } ;;
      esac
    done
    shift $((OPTIND -1)) 
    ;;
  #Download public data
  download ) 
    while getopts "s:a:" OPTIONS ; do
      case "$OPTIONS" in
        s)  SCREENS=${OPTARG} ;;
        a)  ASSEMBLY=${OPTARG} 
            [[ ! $ASSEMBLY =~ hg38|hg19 ]] && {
            echo "Incorrect options provided to -${OPTIONS}."
            usage; exit 
          } ;;
      esac
    done
    shift $((OPTIND -1))
    ;;
  #Prepare raw data
  preprocess ) 
    while getopts "s:" OPTIONS ; do
      case "$OPTIONS" in
        s)  SCREENS=${OPTARG} ;;
      esac
    done
    shift $((OPTIND -1))
    ;;
esac

# Check that empty mandatory variables are full
if [ "$COMMAND" == "all" ]; then
  if [ -z "$ASSEMBLY" ]; then 
    echo "Remember that to use the '${COMMAND}' command, mandatory options are: -a"; usage; exit
  fi
elif [ "$COMMAND" == "download" ]; then
  if [ -z "$ASSEMBLY" ]; then 
    echo "Remember that to use the '${COMMAND}' command, mandatory options are: -a"; usage; exit
  fi
fi

# DOWNLOAD RAW DATA
# All publicly available data is now downloaded to data/raw.
# =========================================================================== #

if [ "$COMMAND" == "all" ] || [ "$COMMAND" == "download" ]; then

  cd data/raw

  # DOWNLOAD RAW DATA - 1000 genomes vcfs
  # --------------------------------------------------------------------------- #

    if [ "$ASSEMBLY" == "hg38" ]; then
    mkdir 1000genomes_hg38
    cd 1000genomes_hg38
    for CHR in {1..22} X ; do 
      echo $CHR
      # wget http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/supporting/GRCh38_positions/ALL.chr${CHR}_GRCh38.genotypes.20170504.vcf.gz
      # wget http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/supporting/GRCh38_positions/ALL.chr${CHR}_GRCh38.genotypes.20170504.vcf.gz.tbi
    done
    cd ../
    echo "${DATE}: \`1000genomes_hg38/\` contains **1000 genomes project hg38 vcf data and their indexes**, that were downloaded from ebi.ac.uk via ftp service." >> README.md
  elif [ "$ASSEMBLY" == "hg19" ]; then
    mkdir 1000genomes_hg19
    cd 1000genomes_hg19
    for CHR in {1..22} X ; do 
      echo $CHR
      wget http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/ALL.chr${CHR}.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz
      wget http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/ALL.chr${CHR}.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz.tbi
    done
    cd ../
    echo "${DATE}: \`1000genomes_hg19/\` contains **1000 genomes project hg19 vcf data and their indexes**, that were downloaded from ebi.ac.uk via ftp service." >> README.md
  fi 

  cd ../../

fi



# PREPROCESS RAW DATA
# Files common for any analysis are created only once and stored in data/use.
# =========================================================================== #

# if [ "$COMMAND" == "all" ] || [ "$COMMAND" == "preprocess" ]; then
# # Process file x to y
# # Origin, content and format in data/use/README.md
# fi




