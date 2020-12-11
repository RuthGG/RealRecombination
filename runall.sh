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
  download -a [hg19|hg38] [-s]        Download publicly available data.
  dbgap -d                            A tool that downloads, compresses and copies into Crick.
  preprocess -i -r [-s]               Prepare raw data to use it in the analysis commands.
  merge -i -r [-s]                    Make PCA data (joins .vcf.gz files)
  pca -f                              Run PCA analysis with QTL tools over the -f VCF file.
  pcaplot -f -p                       Plot PCA results.
  impute -f -x -r -m -i -c -g [-s]    Impute inversions listed in -f using the conditions in -x.
  imputetables -i -p -t               Make summary tables after imputation.
  tagsnps -f -x -i -c -g [-s]         Check if tag SNPs in -f are true in VCF in -i. 
  crossovers -f -c -x -n -m -b        Make recombination rates for given regions (win. size and CI in -x).
  "
  echo "Options:

    -h                                Show help.
    -s <screens>                      Set a number of screens to use. 
    -a [hg19|hg38]                    Set assembly to work with.
    -i <directory>                    Directory that contains files with test VCFs (sometimes needs index).
    -r <directory>                    Directory that contains reference genome files.
    -f <file>                         Path to file to use as input (vcf, inversion list, crossover list...).
    -p <file>                         Path to relevant population file.
    -d <dbGap ID>                     dbGap ID to download.
    -x <file>                         Path to file specifyig experimental conditions.
    -m <directory>                    Path to directory containing ref. recombination maps.
    -c <file>                         Path to inversion coordinates file.
    -g <file>                         Path to inversion genotypes file.
    -t <file>                         Path to inversion imputability file.
    -n <file>                         Path to individual sample size list.
    -b <file>                         Path to chromosome boundaries.
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
SCREENS=1         # -s Number of screens 
CURDIR=$(pwd)     # Current directory
STEP=00           # Steps

# Set empty mandatory variables
ASSEMBLY=""       # -a Assembly to work with
INDIR=""          # -i Directory that contains files with test VCFs indexed 
REFDIR=""         # -r Directory that contains reference genome files 
MAPDIR=""         # -m Path to directory containing reference recombination maps. 
FILE=""           # -f Path to file to use as input.  
POPFILE=""        # -p Path to relevant population file.
CONFILE=""        # -x Path to file specifyig experimental conditions.
DBGAP=""          # -d dbGap ID to download.
INVCOORD=""       # -c Path to inversion coordinates file. 
INVGENO=""        # -g Path to inversion genotypes file. 
INVTAG=""         # -t Path to inversion imputability file.
CELLS=""           # -n Path to individual sample size list.
BOUNDARIES=""


# Parse command optons
case "$COMMAND" in
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
  #Download dbgap restricted data
  dbgap ) 
    while getopts "d:" OPTIONS ; do
      case "$OPTIONS" in
        d)  DBGAP=${OPTARG} ;;
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
  #Make PCA data
  merge ) 
    while getopts "s:i:r:" OPTIONS ; do
      case "$OPTIONS" in
        s)  SCREENS=${OPTARG} ;;
        i)  INDIR=${OPTARG} ;;
        r)  REFDIR=${OPTARG} ;;
      esac
    done
    shift $((OPTIND -1))
    ;;
  # Execute PCA
   pca ) 
    while getopts "f:" OPTIONS ; do
      case "$OPTIONS" in
        f)  FILE=${OPTARG} ;;
      esac
    done
    shift $((OPTIND -1))
    ;;
  # Execute PCA plot
   pcaplot ) 
    while getopts "f:p:" OPTIONS ; do
      case "$OPTIONS" in
        f)  FILE=${OPTARG} ;;
        p)  POPFILE=${OPTARG} ;;
      esac
    done
    shift $((OPTIND -1))
    ;;
  # Make inversion imputation
   impute ) 
    while getopts "f:x:r:m:i:c:g:s:" OPTIONS ; do
      case "$OPTIONS" in
        f)  FILE=${OPTARG} ;;
        x)  CONFILE=${OPTARG} ;;
        r)  REFDIR=${OPTARG} ;;
        m)  MAPDIR=${OPTARG} ;;
        i)  INDIR=${OPTARG} ;;
        c)  INVCOORD=${OPTARG} ;;
        g)  INVGENO=${OPTARG} ;;
        s)  SCREENS=${OPTARG} ;;
      esac
    done
    shift $((OPTIND -1))
    ;;
  # Make summary tables after imputation.
   imputetables ) 
    while getopts "i:p:t:" OPTIONS ; do
      case "$OPTIONS" in
        p)  POPFILE=${OPTARG} ;;
        i)  INDIR=${OPTARG} ;;
        t)  INVTAG=${OPTARG} ;;
      esac
    done
    shift $((OPTIND -1))
    ;;
  # Check if a list of inversions has tag SNPs
   tagsnps)
    while getopts "f:x:i:c:g:s:" OPTIONS ; do
      case "$OPTIONS" in
        f)  FILE=${OPTARG} ;;
        x)  CONFILE=${OPTARG} ;;
        i)  INDIR=${OPTARG} ;;
        c)  INVCOORD=${OPTARG} ;;
        g)  INVGENO=${OPTARG} ;;
        s)  SCREENS=${OPTARG} ;;
      esac
    done
    shift $((OPTIND -1))
    ;;
    # Execute PCA
   crossovers ) 
    while getopts "f:c:n:x:m:b:" OPTIONS ; do
      case "$OPTIONS" in
        f)  FILE=${OPTARG} ;;
        c)  INVCOORD=${OPTARG} ;;
        n)  CELLS=${OPTARG} ;;
        x)  CONFILE=${OPTARG} ;;
        m)  MAPDIR=${OPTARG} ;;
        b)  BOUNDARIES=${OPTARG} ;;
      esac
    done
    shift $((OPTIND -1))
    ;;
  esac

# Check that empty mandatory variables are full
if [ "$COMMAND" == "download" ]; then
  if [ -z "$ASSEMBLY" ]; then 
    echo "Remember that to use the '${COMMAND}' command, mandatory options are: -a"; usage; exit
  fi
elif [ "$COMMAND" == "dbgap" ]; then
  if [ -z "$DBGAP" ]; then 
    echo "Remember that to use the '${COMMAND}' command, mandatory options are: -d"; usage; exit
  fi
elif [ "$COMMAND" == "download" ] || [ "$COMMAND" == "merge" ] || [ "$COMMAND" == "preprocess" ] ; then
  if [ -z "$INDIR" ] || [ -z "$REFDIR" ]; then 
    echo "Remember that to use the '${COMMAND}' command, mandatory options are: -i, -r"; usage; exit
  fi
elif [ "$COMMAND" == "pca" ]; then
  if [ -z "$FILE" ] ; then 
    echo "Remember that to use the '${COMMAND}' command, mandatory options are: -f"; usage; exit
  fi
elif [ "$COMMAND" == "pcaplot" ]; then
  if [ -z "$FILE" ] || [ -z "$POPFILE" ] ; then 
    echo "Remember that to use the '${COMMAND}' command, mandatory options are: -f, -p"; usage; exit
  fi
elif [ "$COMMAND" == "impute" ]; then
  if [ -z "$FILE" ] || [ -z "$CONFILE" ] || [ -z "$REFDIR" ] || [ -z "$MAPDIR" ] || [ -z "$INDIR" ] || [ -z "$INVCOORD" ] || [ -z "$INVGENO" ] ; then 
    echo "Remember that to use the '${COMMAND}' command, mandatory options are: -f, -x, -r, -m, -i, -c, -g"; usage; exit
  fi
elif [ "$COMMAND" == "imputetables" ]; then
  if [ -z "$POPFILE" ] || [ -z "$INDIR" ] || [ -z "$INVTAG" ]  ; then 
    echo "Remember that to use the '${COMMAND}' command, mandatory options are: -i -p -t"; usage; exit
  fi
elif [ "$COMMAND" == "tagsnps" ]; then
  if [ -z "$FILE" ] || [ -z "$CONFILE" ] || [ -z "$INDIR" ] || [ -z "$INVCOORD" ] || [ -z "$INVGENO" ]  ; then 
    echo "Remember that to use the '${COMMAND}' command, mandatory options are: -f -x -i -c -g"; usage; exit
  fi
elif [ "$COMMAND" == "crossovers" ]; then
  if [ -z "$FILE" ] || [ -z "$INVCOORD" ] || [ -z "$CONFILE" ] || [ -z "$CELLS" ] || [ -z "$BOUNDARIES" ] ; then 
    echo "Remember that to use the '${COMMAND}' command, mandatory options are: -f -c -x -n -m -b"; usage; exit
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
STEP=$(printf "%02d" $((${STEP}+1)))

if [ "$COMMAND" == "download" ]; then

  echo "## DOWNLOAD RAW DATA"

  REFDIR=data/raw/1000genomes_${ASSEMBLY}
  mkdir -p $REFDIR

  # DOWNLOAD RAW DATA - 1000 genomes vcfs
  # ------------------------------------------------------------------------- #
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

# DOWNLOAD DBGAP DATA
# A tool for the download of dbGap data.
# =========================================================================== #
# This step does not count in the step count. 

if [ "$COMMAND" == "dbgap" ]; then
    
  # Prefetch
  cd data/raw/
  prefetch --max_size 100000000 --ngc avery_SRA_key/prj_21579.ngc  $DBGAP
  awk -v OFS='\t' -v acc="${DBGAP}" '$2==acc{$3="PREFT"} {print $0}' ../../project/dbGapDataStatus.txt > ../../tmp/tmpDataStatus.txt && mv ../../tmp/tmpDataStatus.txt ../../project/dbGapDataStatus.txt
  cp -f ../../project/dbGapDataStatus.txt /run/user/1001/gvfs/sftp:host=crick.uab.cat,user=rgomez/home/rgomez/shared/ruth_fastqs/
 
  # Fastq conversion - I store it in local: 
  cd avery_SRA/sra/sra/
  fastq-dump --ngc ../../../avery_SRA_key/prj_21579.ngc  -O ../../../avery_fastq ${DBGAP}.sra
  awk -v OFS='\t' -v acc="${DBGAP}" '$2==acc{$3="LOCAL"} {print $0}' ../../../../../project/dbGapDataStatus.txt > ../../../../../tmp/tmpDataStatus.txt && mv ../../../../../tmp/tmpDataStatus.txt ../../../../../project/dbGapDataStatus.txt
  cp -f ../../../../../project/dbGapDataStatus.txt /run/user/1001/gvfs/sftp:host=crick.uab.cat,user=rgomez/home/rgomez/shared/ruth_fastqs/
  
  # Compression
  cd ../../../avery_fastq/
  bgzip ${DBGAP}.fastq
  awk -v OFS='\t' -v acc="${DBGAP}" '$2==acc{$3="COMPR"} {print $0}'  ../../../project/dbGapDataStatus.txt > ../../../tmp/tmpDataStatus.txt && mv ../../../tmp/tmpDataStatus.txt ../../../project/dbGapDataStatus.txt
  cp -f ../../../project/dbGapDataStatus.txt /run/user/1001/gvfs/sftp:host=crick.uab.cat,user=rgomez/home/rgomez/shared/ruth_fastqs/
  
  # Move to Crick
  mv ${DBGAP}.fastq.gz /run/user/1001/gvfs/sftp:host=crick.uab.cat,user=rgomez/home/rgomez/shared/ruth_fastqs
  awk -v OFS='\t' -v acc="${DBGAP}" '$2==acc{$3="CRICK"} {print $0}'  ../../../project/dbGapDataStatus.txt > ../../../tmp/tmpDataStatus.txt && mv ../../../tmp/tmpDataStatus.txt ../../../project/dbGapDataStatus.txt
  cp -f ../../../project/dbGapDataStatus.txt /run/user/1001/gvfs/sftp:host=crick.uab.cat,user=rgomez/home/rgomez/shared/ruth_fastqs/
fi

# PREPROCESS RAW DATA
# Files common for any analysis are created only once and stored in data/use.
# =========================================================================== #
STEP=$(printf "%02d" $((${STEP}+1)))

if [ "$COMMAND" == "preprocess" ]; then

  echo "## PREPROCESS RAW DATA"
  INDIR_NAME=$(echo $INDIR| grep -o '[^/]\+$')

  TMPDIR="tmp/${DATE}_${STEP}_preprocessRaw/${INDIR_NAME}"
  OUTDIR="data/use/${INDIR_NAME}"

  if [ -d "$OUTDIR" ]; then rm -Rf $OUTDIR; fi
  if [ -d "$TMPDIR" ]; then rm -Rf $TMPDIR; fi

  mkdir -p $TMPDIR $OUTDIR ${OUTDIR}/log/

  # PREPROCESS RAW DATA - Join all files found in INDIR - if necessary
  # DEPRECATED - TO REVISIT IF I WANT TO PROCESS MULTIPLE FILES AGAIN	
  # ------------------------------------------------------------------------- #
  # echo "# Join all files found in INDIR - if necessary"

  FILENUM=$(ls ${INDIR}/*.gz | wc -l)

  # if [ $FILENUM -gt 1 ]; then



    # ls ${INDIR}/*.gz > ${TMPDIR}/indlist.txt



    # bcftools merge --missing-to-ref -Ov -l ${TMPDIR}/indlist.txt -o ${TMPDIR}/allind_chr.vcf
    # awk '{gsub(/^chr/,""); print}' ${TMPDIR}/allind_chr.vcf > ${TMPDIR}/allind.vcf

    # echo "## Summary for merged file: $MERGED"  >> ${OUTDIR}/log/logfiles.txt
    # echo "#By chromosome:" >> ${OUTDIR}/log/logfiles.txt
    # grep -v "#" ${TMPDIR}/${INDIR_NAME}.vcf | cut -f1 | uniq -c >> ${OUTDIR}/log/logfiles.txt
    # grep -v "#" ${TMPDIR}/${INDIR_NAME}.vcf | cut -f1 | uniq | grep -v "X" | grep -v "Y" > ${TMPDIR}/chromlist.vcf

    # bgzip ${TMPDIR}/allind.vcf 
    # tabix -p vcf ${TMPDIR}/allind.vcf.gz

    # MERGED="${TMPDIR}/allind.vcf.gz"

  # else
    # bcftools view -Ov $(ls ${INDIR}/*.gz) -o ${TMPDIR}/${INDIR_NAME}.vcf 
  #   awk '{gsub(/^chr/,""); print}' ${TMPDIR}/${INDIR_NAME}_chr.vcf > ${TMPDIR}/${INDIR_NAME}.vcf
    
    # echo "# Summary for original file: ${TMPDIR}/${INDIR_NAME}.vcf "  >> ${OUTDIR}/log/logfiles.txt
    # echo "## By chromosome:" >> ${OUTDIR}/log/logfiles.txt
    # grep -v "#" ${TMPDIR}/${INDIR_NAME}.vcf | cut -f1 | uniq -c  >> ${OUTDIR}/log/logfiles.txt
    VCFILE=$(ls ${INDIR}/*.gz)
    gunzip -c $VCFILE | grep -v "#" | cut -f1 | uniq | grep -v "X" | grep -v "Y" > ${TMPDIR}/chromlist.txt
    

  #   bgzip ${TMPDIR}/${INDIR_NAME}.vcf 
  #   tabix -p vcf ${TMPDIR}/${INDIR_NAME}.vcf.gz
    
  #   MERGED="${TMPDIR}/${INDIR_NAME}.vcf.gz"

  # fi

 
  # echo "#Total"  >> ${OUTDIR}/log/logfiles.txt
  # bcftools plugin counts ${MERGED} >> ${OUTDIR}/log/logfiles.txt

# PREPROCESS RAW DATA - Transform to ref file assembly
#   ------------------------------------------------------------------------- #


	for CHR in $(cat ${TMPDIR}/chromlist.txt); do 

		echo "
		#--------------- CHROMOSOME ${CHR} ---------------#
		"

		bcftools view -r $CHR $VCFILE > ${TMPDIR}/${CHR}.vcf
		picard LiftoverVcf I=${TMPDIR}/${CHR}.vcf \
						   O=${TMPDIR}/${CHR}_newAssembly.vcf \
						   CHAIN=data/raw/chains/hg38ToHg19.over.chain \
						   REJECT=${OUTDIR}/${CHR}_rejected_variants.vcf \
						   R=data/raw/chains/${CHR}.fa \
						   RECOVER_SWAPPED_REF_ALT=true
		sed "s/^chr//g" ${TMPDIR}/${CHR}_newAssembly.vcf > ${OUTDIR}/${CHR}_newAssembly.vcf
		bgzip ${OUTDIR}/${CHR}_newAssembly.vcf
		tabix -p vcf ${OUTDIR}/${CHR}_newAssembly.vcf.gz
		
  # Make chromosomes file
  # mkdir -p ${TMPDIR}/chromlist_part
  # split --number=l/${SCREENS} ${TMPDIR}/chromlist.txt ${TMPDIR}/chromlist_part/chromlist --numeric-suffixes=1 --suffix-length=2

  # Run screens for changeAssembly
  # Parameters needed: parent directory, reference directory, tmp directory, out directory, file to transform, list of chromosomes
  # CAUTION! No filters are applied in this step besides strandness for it to be universal (i.e. to have all information for PCAs)

  # sh code/bash/runScreens.sh ${SCREENS} preprocess "sh code/bash/changeAssembly.sh $CURDIR $REFDIR $TMPDIR $OUTDIR $MERGED ${TMPDIR}/chromlist_part/chromlistscreencode " delete

  # while [ $(screen -ls  | wc -l | awk '{print $1-3}') -gt 0 ]; do
  #   screen -ls 
  #   sleep 60
  # done

  # echo "${DATE}: Ready-to-use files for ${INDIR}, in the same assembly as reference (in ${REFDIR}) and by chromosome. Also the corresponding .strand and .tbi files." >> data/use/README.md

  # PREPROCESS RAW DATA - End of communication
  # ------------------------------------------------------------------------- #
  # cat ${OUTDIR}/log/*  >> ${OUTDIR}/log/logfiles.txt

	done
fi

# MERGE FOR PCA
# Prepare data for executing PCA with all chromosomes present in a directory.
# =========================================================================== #
STEP=$(printf "%02d" $((${STEP}+1)))

if [ "$COMMAND" == "merge" ]; then

  echo "## MERGE FOR PCA"

  TMPDIR="tmp/${DATE}_${STEP}_mergePca"
  OUTDIR="analysis/${DATE}_${STEP}_mergePca"
  mkdir -p $TMPDIR $OUTDIR

  #*******************************************************************************#
  # IMPORTANT NOTE: Chromosomes will be sorted alphabetically, not numerically.   #
  #                 However, since both files will have the same order, it is ok. #
  #*******************************************************************************#

  # MERGE FOR PCA - Merge files
  # ------------------------------------------------------------------------- #
  echo "# Merge files"

  ls -v1 ${INDIR}/*.gz > ${TMPDIR}/filelist.txt

  bcftools concat -f ${TMPDIR}/filelist.txt --threads $SCREENS -Oz -o ${TMPDIR}/file_allchr.vcf.gz

  tabix -p vcf ${TMPDIR}/file_allchr.vcf.gz

  # MERGE FOR PCA - Merge references
  # ------------------------------------------------------------------------- #
  echo "# Merge references"

  ls -v1 ${REFDIR}/*.gz > ${TMPDIR}/reflist.txt

  bcftools concat -f ${TMPDIR}/reflist.txt --threads $SCREENS -Oz -o ${TMPDIR}/ref_allchr.vcf.gz

  tabix -p vcf ${TMPDIR}/ref_allchr.vcf.gz

  # MERGE FOR PCA - Merge files+references
  # ------------------------------------------------------------------------- #
  echo "# Merge files+references"

  bcftools isec -p ${TMPDIR} -Oz --threads $SCREENS -n +2 ${TMPDIR}/file_allchr.vcf.gz ${TMPDIR}/ref_allchr.vcf.gz

  # bgzip ${TMPDIR}/0000.vcf
  tabix -p vcf ${TMPDIR}/0000.vcf.gz

  # bgzip ${TMPDIR}/0001.vcf
  tabix -p vcf ${TMPDIR}/0001.vcf.gz

  bcftools merge ${TMPDIR}/0000.vcf.gz ${TMPDIR}/0001.vcf.gz --threads $SCREENS -Oz -o ${OUTDIR}/final_vcf.vcf.gz
  tabix -p vcf ${OUTDIR}/final_vcf.vcf.gz
fi


# RUN PCA ANALYSIS
# Execute PCA with QTLTOOLS.
# =========================================================================== #
STEP=$(printf "%02d" $((${STEP}+1)))

if [ "$COMMAND" == "pca" ]; then

  echo "## MAKE PCA"

  TMPDIR="tmp/${DATE}_${STEP}_runPca"
  OUTDIR="analysis/${DATE}_${STEP}_runPca"
  mkdir -p $TMPDIR $OUTDIR

  code/software/QTLtools_1.2_source/bin/QTLtools pca --vcf ${FILE} --scale --center --maf 0.05 --distance 50000 --out ${TMPDIR}/pcaResult_genotypes

  Rscript code/rscript/pcaParse.R ${TMPDIR}/pcaResult_genotypes.pca ${OUTDIR}/pcaResult.Rdata

fi


# MAKE PCA PLOTS
# Execute Rscript to make PCA plot.
# =========================================================================== #
STEP=$(printf "%02d" $((${STEP}+1)))

if [ "$COMMAND" == "pcaplot" ]; then

  echo "## MAKE PCA PLOT"

  OUTDIR="analysis/${DATE}_${STEP}_plotPca"
  mkdir -p $OUTDIR

  Rscript code/rscript/pcaPlot.R $FILE $POPFILE $OUTDIR

fi


# MAKE IMPUTATION
# Execute scripts to impute inversions.
# =========================================================================== #
STEP=$(printf "%02d" $((${STEP}+1)))


if  [ "$COMMAND" == "impute" ]; then

  TMPDIR="tmp/${DATE}_${STEP}_imputation"
  OUTDIR="analysis/${DATE}_${STEP}_imputation"
  mkdir -p $TMPDIR $OUTDIR

  # MAKE IMPUTATION - Register conditions in analysis results
  # ------------------------------------------------------------------------- #
  cp ${CONFILE} ${OUTDIR}
  cp ${FILE} ${OUTDIR}

  # MAKE IMPUTATION - Divide inversion into n lists where n is # of screens
  # ------------------------------------------------------------------------- #
  mkdir -p $TMPDIR/invlist_part 
  split --number=l/${SCREENS} ${FILE} $TMPDIR/invlist_part/invlist --numeric-suffixes=1 --suffix-length=2

  # MAKE IMPUTATION - Run imputation in # of screens
  # ------------------------------------------------------------------------- #
  mkdir -p $TMPDIR/imputationProcess
  sh code/bash/runScreens.sh ${SCREENS} imputation "sh code/bash/runImputation.sh $CONFILE $TMPDIR/invlist_part/invlistscreencode $REFDIR $MAPDIR $INDIR $INVCOORD $INVGENO $TMPDIR/imputationProcess" delete

  while [ $(screen -ls  | wc -l | awk '{print $1-3}') -gt 0 ]; do
    screen -ls 
    sleep 60
  done

  # MAKE IMPUTATION - Once finished, make summary output files.
  # ------------------------------------------------------------------------- #
  mkdir -p project/logfiles/${DATE}_${STEP}_imputation
  # Take first inversion to make header
  FIRST=$(head -n1 ${FILE})

  # Make a summary file for each experimental condition
  for DIR in $(ls $TMPDIR/imputationProcess); do

    head -n 3 "$TMPDIR/imputationProcess/${DIR}/${FIRST}/output_readable.vcf" > ${OUTDIR}/${DIR}_readSum.vcf

    for DIRINV in $(ls $TMPDIR/imputationProcess/${DIR}); do

      cat $TMPDIR/imputationProcess/${DIR}/${DIRINV}/log.out >> project/logfiles/${DATE}_${STEP}_imputation/log_${DIR}.txt
      sed -n 4p "$TMPDIR/imputationProcess/${DIR}/${DIRINV}/output_readable.vcf" >> ${OUTDIR}/${DIR}_readSum.vcf

    done 

  done

fi

# MAKE IMPUTATION SUMMARY TABLES
# Execute Rscript to make imputation summary tables.
# =========================================================================== #
STEP=$(printf "%02d" $((${STEP}+1)))

if [ "$COMMAND" == "imputetables" ]; then

  echo "## MAKE IMPUTATION SUMMARY TABLES"

  OUTDIR="analysis/${DATE}_${STEP}_imputationTables"
  mkdir -p $OUTDIR

  Rscript code/rscript/imputeParse.R $INDIR $POPFILE $INVTAG $OUTDIR

fi


# MAKE TAG SNPS CHECK
# Execute scripts to check tag SNPs
# =========================================================================== #
STEPB=$((${STEP}+1))
STEP=$(printf '%02d' $((${STEP}+1)))


if  [ "$COMMAND" == "tagsnps" ]; then

  TMPDIR="tmp/${DATE}_${STEP}_tagsnps"
  OUTDIR="analysis/${DATE}_${STEP}_tagsnps"
  mkdir -p $TMPDIR $OUTDIR

  # MAKE TAG SNPS CHECK - Register conditions in analysis results
  # ------------------------------------------------------------------------- #
  cp ${CONFILE} ${OUTDIR} # Populations 
  tail -n+2 ${FILE} | cut -f1   | sort | uniq > ${OUTDIR}/invlist.txt # List of inversions
  awk -v OFS="\t" 'NR>1{print $2, $3}' ${FILE} | grep -v "chrY" | grep -v "chrX" | sed 's/^chr//g'  > ${OUTDIR}/regions.txt # SNPs to check

  # MAKE TAG SNPS CHECK - Divide inversion into n lists where n is # of screens
  # ------------------------------------------------------------------------- #
  mkdir -p $TMPDIR/invlist_part 
  split --number=l/${SCREENS} ${OUTDIR}/invlist.txt $TMPDIR/invlist_part/invlist --numeric-suffixes=1 --suffix-length=2

  # MAKE TAG SNPS CHECK - Take only the interesting SNPs from total VCF file
  # ------------------------------------------------------------------------- #
  # This could be improved to take into account that indir can have one file for all chromosomes or one file per chromosome
  VCF=$(ls $INDIR | grep "gz$")
  bcftools view --regions-file  ${OUTDIR}/regions.txt  -Oz ${INDIR}/$VCF -o ${TMPDIR}/interestingSNP.vcf.gz
  tabix ${TMPDIR}/interestingSNP.vcf.gz

  # MAKE TAG SNPS CHECK - Copy population file
  # ------------------------------------------------------------------------- #
  cp ${INDIR}/*.txt ${TMPDIR}

  # MAKE TAG SNPS CHECK - Run imputation in # of screens
  # ------------------------------------------------------------------------- #
  mkdir -p $TMPDIR/tagsnpsProcess
  sh code/bash/runScreens.sh ${SCREENS} tagsnp "sh code/bash/checkTagSNPs.sh $CONFILE $TMPDIR/invlist_part/invlistscreencode $TMPDIR $INVCOORD $INVGENO $TMPDIR/tagsnpsProcess" delete

  while [ $(screen -ls  | wc -l | awk '{print $1-3}') -gt 0 ]; do
    screen -ls 
    sleep 60
  done

  # MAKE TAG SNPS CHECK - Once finished, make summary output files.
  # ------------------------------------------------------------------------- #
  mkdir -p project/logfiles/${DATE}_${STEP}_tagsnps

  FIRST=$(head -n1 ${OUTDIR}/invlist.txt)

  # Make a summary file for each experimental condition
   for DIR in $(ls $TMPDIR/tagsnpsProcess); do

    head -n 1 "$TMPDIR/tagsnpsProcess/${DIR}/${FIRST}/output_plink.ld" > ${OUTDIR}/${DIR}_output_plink.ld

    for DIRINV in $(ls $TMPDIR/tagsnpsProcess/${DIR}); do

      cat $TMPDIR/tagsnpsProcess/${DIR}/${DIRINV}/log.out >> project/logfiles/${DATE}_${STEP}_tagsnps/log_${DIR}.txt
      tail -n +2 "$TMPDIR/tagsnpsProcess/${DIR}/${DIRINV}/output_plink.ld" >> ${OUTDIR}/${DIR}_output_plink.ld

    done 

  done

fi

# DATA FOR CROSSOVERS ANALYSIS WITH OUR INVERSIONS
# Create data used in the statistical analysis of crossovers
# =========================================================================== #
STEP=$(printf '%02d' $((${STEPB}+1)))

if  [ "$COMMAND" == "crossovers" ]; then

  TMPDIR="tmp/${DATE}_${STEP}_crossovers"
  OUTDIR="analysis/${DATE}_${STEP}_crossovers"
  mkdir -p "$TMPDIR" "$OUTDIR"

  # DATA FOR CROSSOVERS ANALYSIS WITH OUR INVERSIONS - Register conditions & copy in analysis results
  # ------------------------------------------------------------------------- #
  # Window size and confidence interval
  WINSIZE=$(head -n 1 "${CONFILE}")
  INTERVAL=$(sed '2q;d' "${CONFILE}")
  AMOUNTCI=$((${INTERVAL}/${WINSIZE}))

  cp "${CONFILE}" "${OUTDIR}" 

  # Crossover files to bed
  zcat "$FILE" |awk -v OFS="\t" '{print $3, $4, $5, $1}' > "${TMPDIR}/allcrossovers.bed"
  
  echo "Conditions registered and analysis results copied"
  # DATA FOR CROSSOVERS ANALYSIS WITH OUR INVERSIONS - Make or search recombination map
  # ------------------------------------------------------------------------- #

  #  If no mapdir is given, will be created in tmp/
  if [ -z "$MAPDIR" ] ; then 
    MAPDIR="${TMPDIR}/recMap"
  fi
  
  # MAPDIR contains directory for recombination map. If map required does not exist, it is created and stored into MAPDIR
  FILENUM=$(ls "${MAPDIR}/"*"_${WINSIZE}".txt | wc -l)

  if [ "$FILENUM" -lt 1 ]; then
    echo "Recombination map will be created in ${MAPDIR}"
    # Make map with chromosome boundaries
    mkdir -p "${TMPDIR}/recMap/"
    # Makes bedfile with windows/regions list
    python code/python/makeBedWindows.py --input "${BOUNDARIES}" --output "${TMPDIR}/recMap/windows.bed" --fixedWindow "${WINSIZE}"  --windowMethod "fromLeft" --chromBoundaries "${BOUNDARIES}"

    # Intersect windows with crossovers
    bedtools intersect -wao -a "${TMPDIR}/recMap/windows.bed"  -b "${TMPDIR}/allcrossovers.bed" > "${TMPDIR}/recMap/comparison.txt"

    # Make scores, recombination rates and parse table
    python code/python/makeRecRates.py --input "${TMPDIR}/recMap/comparison.txt" --output "${MAPDIR}/recMap_${WINSIZE}.txt" --numofsamples  "$CELLS" 
   
    
  fi

  MAP=$(ls "${MAPDIR}"/*_"${WINSIZE}".txt)
  echo "Recombination map acquired"
  # Around 50 seconds up until here

  # DATA FOR CROSSOVERS ANALYSIS WITH OUR INVERSIONS - Crossovers in inversions and their chromosomes
  # ------------------------------------------------------------------------- #
  
  # Make list of inversion positions and IDs
  grep -v 'chrX' "$INVCOORD" | grep -v 'chrY' | grep 'inversion'  > "${OUTDIR}/invcoord_noXY.gff"

  # Makes bedfile with windows/regions list
  python code/python/makeBedWindows.py --input "${OUTDIR}/invcoord_noXY.gff" --output "${TMPDIR}/windows.bed" --fixedWindow "${WINSIZE}" --fixedCIWindow "${WINSIZE}" --amountCI "${AMOUNTCI}" --windowMethod "fromCenter" --chromBoundaries "${BOUNDARIES}"
  
  # Intersect windows with crossovers
  bedtools intersect -wao -a "${TMPDIR}/windows.bed"  -b "${TMPDIR}/allcrossovers.bed" > "${TMPDIR}/comparison.txt"

  # Make scores, recombination rates and parse table
  python code/python/makeRecRates.py --input "${TMPDIR}/comparison.txt" --output "${TMPDIR}/crossoverResult.txt" --numofsamples  "$CELLS"

  # Around 20 seconds if map exists up until here

  echo "Inversion recombination rates registered"

  # DATA FOR CROSSOVERS ANALYSIS WITH OUR INVERSIONS - Make normalization
  # ------------------------------------------------------------------------- #
  python code/python/quantileNormalization.py --input "${TMPDIR}/crossoverResult.txt" --output "${OUTDIR}/crossoverResult_QN.txt" --recMap "${MAP}"
  echo "Inversion recombination rates normalized"
  # Normalization alone is around 20 seconds 
fi