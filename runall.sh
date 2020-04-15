#!/bin/bash
# Ruth Gómez Graciani
# 01 04 2020

###############################################################################
# Description:                                                                
# Run all the analyses in this project                                        
###############################################################################

# SAVE HISTORY pt 1
# Save date and command 
# =========================================================================== #
HISTORY="$@"

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
  preprocess -i -r [-s]               Prepare raw data to use it in the analysis commands.
  "
  echo "Options:

    -h                                Show help.
    -s <screens>                      Set a number of screens to use. 
    -a [hg19|hg38]                    Set assembly to work with.
    -i <directory>                    Directory that contains files with test VCFs indexed.
    -r <directory>                    Directory that contains reference genome files.
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
CURDIR=$(pwd)

# Set empty mandatory variables
ASSEMBLY="";
INDIR="";
REFDIR="";

# Parse command optons
case "$COMMAND" in
  #Run all commands
  all ) 
    while getopts "s:a:i:" OPTIONS ; do
      case "$OPTIONS" in
        s)  SCREENS=${OPTARG} ;;
        a)  ASSEMBLY=${OPTARG} 
            [[ ! $ASSEMBLY =~ hg38|hg19 ]] && {
            echo "Incorrect options provided to -${OPTIONS}."
            usage; exit
          } ;;
        i)  INDIR=${OPTARG} ;;
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
    while getopts "s:i:r:" OPTIONS ; do
      case "$OPTIONS" in
        s)  SCREENS=${OPTARG} ;;
        i)  INDIR=${OPTARG} ;;
        r)  REFDIR=${OPTARG} ;;
      esac
    done
    shift $((OPTIND -1))
    ;;
esac

# Check that empty mandatory variables are full
if [ "$COMMAND" == "all" ]; then
  if [ -z "$ASSEMBLY" ] || [ -z "$INDIR" ]; then 
    echo "Remember that to use the '${COMMAND}' command, mandatory options are: -a, -i"; usage; exit
  fi
elif [ "$COMMAND" == "download" ]; then
  if [ -z "$ASSEMBLY" ]; then 
    echo "Remember that to use the '${COMMAND}' command, mandatory options are: -a"; usage; exit
  fi
elif [ "$COMMAND" == "download" ]; then
  if [ -z "$INDIR" ] || [ -z "$REFDIR" ]; then 
    echo "Remember that to use the '${COMMAND}' command, mandatory options are: -i, -r"; usage; exit
  fi
else 
  usage; exit
fi

# SAVE HISTORY pt 2
# Save date and command 
# =========================================================================== #
DATE=$(date +%F)
echo "${DATE}: $0 ${HISTORY}" >> project/history.txt

# SAVE LOG pt 2
# Save date and command 
# =========================================================================== #
  exec 3>&1 4>&2
  trap 'exec 2>&4 1>&3' 0 1 2 3
  exec 1>project/logfiles/${DATE} 2>&1

# DOWNLOAD RAW DATA
# All publicly available data is now downloaded to data/raw.
# =========================================================================== #
echo "## DOWNLOAD RAW DATA"

if [ "$COMMAND" == "all" ] || [ "$COMMAND" == "download" ]; then

  REFDIR=data/raw/1000genomes_${ASSEMBLY}
  mkdir -p $REFDIR

  # DOWNLOAD RAW DATA - 1000 genomes vcfs
  # --------------------------------------------------------------------------- #
  echo "# 1000 genomes vcfs"

  if [ "$ASSEMBLY" == "hg38" ]; then
    cd $REFDIR
 
    # for CHR in {1..22} X ; do # With X
    for CHR in {1..22}; do # Without X
      echo $CHR
      # wget http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/supporting/GRCh38_positions/ALL.chr${CHR}_GRCh38.genotypes.20170504.vcf.gz
      # wget http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/supporting/GRCh38_positions/ALL.chr${CHR}_GRCh38.genotypes.20170504.vcf.gz.tbi
    done
  
  elif [ "$ASSEMBLY" == "hg19" ]; then
    cd $REFDIR
 
     # for CHR in {1..22} X ; do # With X
    for CHR in {1..22}; do # Without X
      echo $CHR
      # wget http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/ALL.chr${CHR}.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz
      # wget http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/ALL.chr${CHR}.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz.tbi
    done
  
  fi

    cd $CURDIR
    echo "## 1000genomes_${ASSEMBLY}
    ${DATE}: **1000 genomes project ${ASSEMBLY} vcf data and their indexes**, that were downloaded from ebi.ac.uk via ftp service.
    " >> data/raw/README.md

fi

# PREPROCESS RAW DATA
# Files common for any analysis are created only once and stored in data/use.
# =========================================================================== #
echo "## PREPROCESS RAW DATA"

if [ "$COMMAND" == "all" ] || [ "$COMMAND" == "preprocess" ]; then

  TMPDIR="tmp/${DATE}_preprocess_raw"
  INDIR_NAME=$(echo $INDIR| grep -o '[^/]\+$')
  OUTDIR="data/use/${INDIR_NAME}"
  mkdir -p $TMPDIR $OUTDIR
  echo "## ${INDIR}" >> data/use/README.md

  # PREPROCESS RAW DATA - Join all files found in INDIR - if necessary
  # --------------------------------------------------------------------------- #
  echo "# Join all files found in INDIR - if necessary"

  FILENUM=$(ls ${INDIR}/*.gz | wc -l)

  if [ $FILENUM -gt 1 ]; then

    ls ${INDIR}/*.gz > ${TMPDIR}/indlist.txt

    bcftools merge --missing-to-ref -Oz -l ${TMPDIR}/indlist.txt -o ${TMPDIR}/20ind.vcf.gz
    tabix -p vcf ${TMPDIR}/20ind.vcf.gz

    MERGED="${TMPDIR}/20ind.vcf.gz"

  else

    MERGED=$(ls ${INDIR}/*.gz)

  fi

  # PREPROCESS RAW DATA - Transform to hg19
  # --------------------------------------------------------------------------- #
  echo "# Transform to hg19"

  # Make chromosomes file
  # for CHR in {1..22} X; do echo ${CHR} >> ${TMPDIR}/chromlist.txt; done # With X 
  for CHR in {1..22}; do echo ${CHR} >> ${TMPDIR}/chromlist.txt; done # Without X 
  mkdir -p ${TMPDIR}/chromlist_part
  split --number=l/${SCREENS} ${TMPDIR}/chromlist.txt ${TMPDIR}/chromlist_part/chromlist --numeric-suffixes=1 --suffix-length=2

  # Run screens for changeAssembly
  # Parameters needed: parent directory, reference directory, tmp directory, out directory, file to transform, list of chromosomes
  # CAUTION! No filters are applied in this step besides strandness for it to be universal (i.e. to have all information for PCAs)

  sh code/bash/runScreens.sh ${SCREENS} preprocess "sh code/bash/changeAssembly.sh $CURDIR $REFDIR $TMPDIR $OUTDIR $MERGED ${TMPDIR}/chromlist_part/chromlistscreencode " delete

  while [ $(screen -ls  | wc -l | awk '{print $1-3}') -gt 0 ]; do
    screen -ls 
    sleep 60
  done

  echo "${DATE}: Ready-to-use files for ${INDIR}, in the same assembly as reference (in ${REFDIR}) and by chromosome. Also the corresponding .strand and .tbi files." >> data/use/README.md

  
  # PREPROCESS RAW DATA - Merge to do the PCA
  # --------------------------------------------------------------------------- #
  echo "# Merge to do the PCA"

  ls ${OUTDIR}/*.gz > ${TMPDIR}/filelist.txt

  bcftools concat -f ${TMPDIR}/filelist.txt -Oz -o ${OUTDIR}/20ind_ref_allchr.vcf.gz

  tabix -p vcf ${OUTDIR}/20ind_ref_allchr.vcf.gz

  echo "${DATE}: Concatenated chromosomes for ${INDIR}, in the same assembly as reference (in ${REFDIR}). Also the corresponding .tbi file." >> data/use/README.md

  # PREPROCESS RAW DATA - End of communication
  # --------------------------------------------------------------------------- #
  echo "" >> data/use/README.md
fi




