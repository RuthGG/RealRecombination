#!/bin/bash
# Ruth Gómez Graciani
# 14 04 2020

###############################################################################
# Description:                                                                
# Transform data to the same assembly as reference. Make .strand files                                    
###############################################################################

# GET VARIABLES - there are examples commented
# =========================================================================== #
CURDIR=$1       # /home/rgomez/20200401_RealRecombination
REFDIR=$2     # data/raw/1000genomes_hg19
TMPDIR=$3     # tmp/${DATE}_preprocess_raw
OUTDIR=$4     # data/use/avery_individuals/
FILE=$5       # tmp/${DATE}_preprocess_raw/20ind_ori.vcf.gz
CHROMFILE=$6  # tmp/${DATE}_preprocess_raw/chromlist_part/chromlist01

# SET DERIVED VARIABLES 
# =========================================================================== #

# Name for outputs
FILENAME=$(echo $FILE| grep -o '[^/]\+$' | cut -f1 -d '.')

# tmp subdirectory
TMPDIR=${TMPDIR}/changeAssembly
mkdir -p ${TMPDIR}

# PREPROCESS RAW DATA
# Change assembly to reference. 
# =========================================================================== #	

cd $CURDIR

for CHR in $(cat $CHROMFILE); do 

  bcftools view --regions chr${CHR} $FILE > ${TMPDIR}/tmp_file_${CHR}.txt

  REFILE=$(ls $REFDIR | grep "chr${CHR}\..*gz$")

  zgrep "^${CHR}" ${REFDIR}/${REFILE} | cut -f -5 > ${TMPDIR}/tmp_ref_${CHR}.txt      
    
  # This line changes the coordinates to be like in the reference according to SNPID
  awk -v OFS="\t" -v FS="\t" '{if (NR==FNR) {a[$3]=$2;b[$3]=$4;c[$3]=$5; next } if ($3 in a && ( (b[$3]==$4 && c[$3]==$5) || (b[$3]==$5 && c[$3]==$4) ) ){$2 = a[$3]} else if ($1~/^#/){$1 = $1} else {$2 = 0}; if($2!=0){print} }'  ${TMPDIR}/tmp_ref_${CHR}.txt  ${TMPDIR}/tmp_file_${CHR}.txt > ${TMPDIR}/${FILENAME}_ref_chr${CHR}.vcf
  # This line checks that REF and ALT are the same as in reference (srand "+") and in case they are the same but reversed, it sabes the strand as "-". 
  awk -v OFS="\t" -v FS="\t" '{if (NR==FNR) {a[$3]=$4;b[$3]=$5; next } if ($3 in a && a[$3]==$4 && b[$3]==$5){$5 = "+"} else if ($3 in a && a[$3]==$5 && b[$3]==$4){$5 = "-"} else {$2 = 0};if($1~/^#/){$2 = 0} ;if($2!=0){print $2, $5} }' ${TMPDIR}/tmp_1KG_${CHR}.txt  ${TMPDIR}/tmp_AV_${CHR}.txt > ${OUTDIR}/${FILENAME}_chr${CHR}.strand

  bcftools sort ${TMPDIR}/${FILENAME}_ref_chr${CHR}.vcf -Oz -o ${OUTDIR}/${FILENAME}_ref_chr${CHR}.vcf.gz

  tabix -p vcf ${OUTDIR}/${FILENAME}_ref_chr${CHR}.vcf.gz

done