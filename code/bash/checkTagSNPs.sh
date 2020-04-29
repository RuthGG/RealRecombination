#!/bin/bash
# Ruth Gómez Graciani
# 21 04 2020

###############################################################################
# Description:                                                                
# Check which tag SNPs has alist of inversions.                                       
###############################################################################

# TAKE PARAMETERS
# They should be provided by runall.sh, so no need of fancy parsing 
# =========================================================================== #

  # Conditions
  CONFILE=$1 # condition list (it takes POP)
  INVFILE=$2 # list of inversions <-- THIS CHANGES WITH SCREENS
 
  # Test individuals
  INDIR=$3

  # Inversions info
  INVCOORD=$4 # Inversion coordinates
  INVGENO=$5 # inversion genotypes

  # Output
  TMP=$6 # output directory of this script is tmp


# START LOOPING
# Loop over conditions and inversions
# =========================================================================== #

  # START LOOPING - Loop over conditions
  # ------------------------------------------------------------------------- #
  
  # Make conditions list
  CONLIST=$(cut  -d$'\n' -f1 ${CONFILE} )

  # Iterate over conditions list
  for LINE in $CONLIST ; do 

    # Take conditions
    POP=$(echo "$LINE")

    # Make output directory
    OUTDIR=${TMP}/${POP}
    mkdir -p ${OUTDIR} 

    # START LOOPING - Loop over inversions
    # ------------------------------------------------------------------------- #
    INVLIST=$(cut -f1 ${INVFILE})

    # Iterate over inversions list
    for INV in $INVLIST; do # For each inversion

      # SET SCENARIO
      # Prepare directories, logfiles, log header, inversion position.
      # =========================================================================== #
      
        # Current directory
        CURDIR="${OUTDIR}/${INV}"
        mkdir -p $CURDIR
        
        # Logfiles
        exec 3>&1 4>&2
        trap 'exec 2>&4 1>&3' 0 1 2 3
        exec 1>${CURDIR}/log.out 2>&1  

        # Header
        echo  "-------------------------------------------------------------------------"
        echo $INV
        echo  "-------------------------------------------------------------------------"

        # Set position markers
        CHR=$(grep -e "${INV}" ${INVCOORD} | cut -f2)
        CHR_NUM=$(echo ${CHR} | sed 's/chr//g' )
        INV_START=$(grep -e "${INV}" ${INVCOORD} | cut -f3) # Inversion region
        INV_END=$(grep -e "${INV}" ${INVCOORD} | cut -f6)
        POS=$(($(($INV_START+$INV_END))/2))

      # GENOTYPES FILE
      # Genotypes for the inversion of interest.
      # =========================================================================== #
        STEP=0
        STEP=$((${STEP}+1))
        echo "## ${STEP} GENOTYPES FILE: genotypes for the inversion of interest ############"

        # Get inversion genotypes 
        INV_COLUMN=$(head -1 $INVGENO | tr "\t" "\n" | cat -n | grep $INV | cut -f1 | tr -d " ")
        cut -f1,$INV_COLUMN $INVGENO | tail -n+2 | awk '$2!="NA"'  | awk '$2!="ND"' | awk '$2!="Del"' | awk '$2!="."'  >  ${CURDIR}/genotypes_file.txt
       
      # INPUT FILE
      # Individuals + Inversion in this population
      # =========================================================================== #
        STEP=$((${STEP}+1))
        echo "## ${STEP} INPUT FILE: individuals (samples), in population of interest #######"


        # INPUT FILE - common individuals (samples), in population of interest
        # ------------------------------------------------------------------------- #
        echo "## Common individuals (samples), in population of interest ##############"
       
        # Common 1KGP individuals filtered by populations + Inversion individuals
        SAMPLES_INV=$(cut -f1 ${CURDIR}/genotypes_file.txt)
       
        # Get population file
        POPFILE=$(ls ${INDIR}/*.txt)

        if [ $POP = "ALL" ]; then
          SAMPLES_IN=$(tail -n +2 ${POPFILE}|cut -f1 )
        else
          SAMPLES_IN=$(grep ${POP} ${POPFILE} | cut -f1)
        fi
      
      	# Combine
        SAMPLES_REF=$(echo $SAMPLES_INV $SAMPLES_IN | tr " " "\n" | sort | uniq -d)

        # INPUT FILE - create input VCF
        # ------------------------------------------------------------------------- #
        echo "## Create input VCF #####################################################"

        # Select chromosome and samples of interest. This step is kind of useless when population is "ALL"
        # Sometimes the directory may contain an all-chromosomes file instead of by-chromosome information - check this
        FILENUM=$(ls ${INDIR}/*.gz | wc -l)

        if [ $FILENUM -gt 1 ]; then
          VCF_FILE=$(ls $INDIR | grep "${CHR}\..*gz$")
        else
          VCF_FILE=$(ls $INDIR | grep "gz$")
        fi

        bcftools view  --regions ${CHR_NUM} -s $(echo $SAMPLES_REF | tr " " ",")   -Ov ${INDIR}/${VCF_FILE}  -o ${CURDIR}/haplotypes.vcf
        
        # INPUT FILE - take inversion genotypes for common individuals
        # ------------------------------------------------------------------------- #
        echo "## Take inversion genotypes for common individuals ######################"

        # Genotypes in STD|INV
        GENOTYPES_SI=$(for SAMPLE in $SAMPLES_REF; do grep $SAMPLE ${CURDIR}/genotypes_file.txt | cut -f2; done)

        # Genotypes in 0|1
        GENOTYPES_01=$(echo $GENOTYPES_SI | sed 's/STD/0\|0/gI' | sed 's/INV/1\|1/gI'| sed 's/HET/0\|1/gI')

        # Create VCF line
        echo -e "${CHR_NUM}\t${POS}\t${INV}\tA\tT\t.\tPASS\t\tGT\t$(echo ${GENOTYPES_01} | tr ' ' '\t')" > ${CURDIR}/inversions.vcf

        # REFERENCE FILE - add inversion genotypes to 1000 KGP VCF
        # ------------------------------------------------------------------------- #
        echo "## Add inversion genotypes to 1000 KGP VCF ##############################"

        # Concatenate both files 
        cat ${CURDIR}/haplotypes.vcf ${CURDIR}/inversions.vcf > ${CURDIR}/input_unsorted.vcf
        
        # Sort to put inversion in place
        bcftools sort ${CURDIR}/input_unsorted.vcf -Ov -o ${CURDIR}/input_sorted.vcf
        
      # PLINK FORMAT
      # Change input to Plink format
      # =========================================================================== #
        STEP=$((${STEP}+1))
        echo "## ${STEP} PLINK FORMAT: change input to Plink format #########################"

        vcftools --vcf ${CURDIR}/input_sorted.vcf --plink --chr ${CHR_NUM} --out ${CURDIR}/input_plink
		    plink --file ${CURDIR}/input_plink --r2 --ld-snp ${INV} --ld-window-kb 1000000 --ld-window 999999 --ld-window-r2 0 --noweb --out ${CURDIR}/output_plink
		done
	done