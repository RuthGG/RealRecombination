#!/bin/bash
# Ruth Gómez Graciani
# 21 04 2020

###############################################################################
# Description:                                                                
# Impute inversions from a list under another list of conditions.                                       
###############################################################################


# TAKE PARAMETERS
# They should be provided by runall.sh, so no need of fancy parsing 
# =========================================================================== #

  # Conditions
  CONFILE=$1 # condition list (it takes POP and IND)
  INVFILE=$2 # list of inversions <-- THIS CHANGES WITH SCREENS

  # Reference
  REFILE=$3 # directory with 1000 genomes information, included population
  MAPDIR=$4 # directory with recombination maps

  # Test
  INDIR=$5 # Directory with test individuals info

  # Inversions info
  INVCOORD=$6 # inversion coordinates
  INVGENO=$7 # inversion genotypes NOT ACTUALLY NEEDED, JUST A DUMMY VARIABLE TO AVOID MANY CHANGES

  # Output
  TMP=$8 # output directory of this script is tmp

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
    POP=$(echo "$LINE" | cut -f1 -d",")
    IND=$(echo "$LINE" | cut -f2 -d",")

    # The range is set here in the case future range modifications are necessary
    RANGE=500000

    # Make output directory
    OUTDIR=${TMP}/${POP}_${IND}
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
        mkdir $CURDIR
        
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
        START=$(($INV_START-$RANGE))     # Region we take for imputation
        END=$(($INV_END+$RANGE))
        # POS=$(($(($START+$END))/2))
        # CIPOS=$(($(($INV_END-$INV_START))/2))

      # GENOTYPES FILE
      # Genotypes for the inversion of interest.
      # =========================================================================== #
        STEP=0
        # STEP=$((${STEP}+1))
        # echo "## ${STEP} GENOTYPES FILE: genotypes for the inversion of interest ######"

        # # Get inversion genotypes 
        # INV_COLUMN=$(head -1 $INVGENO | tr "\t" "\n" | cat -n | grep $INV | cut -f1 | tr -d " ")
        # cut -f1,$INV_COLUMN $INVGENO | tail -n+2 | awk '$2!="NA"'  | awk '$2!="ND"' | awk '$2!="Del"' | awk '$2!="."' >  ${CURDIR}/genotypes_file.txt
        
      # REFERENCE FILE
      # 1KGP + Inversion in this population's individuals
      # =========================================================================== #
        STEP=$((${STEP}+1))
        echo "## ${STEP} REFERENCE FILE: Transform reference file to the desired format. ####"

        # REFERENCE FILE - take specified region from the reference file.
        # ------------------------------------------------------------------------- #
        echo "## Take a region according to inversion coordinates #####################"

        # Filter 1000 reference VCF to include only our interest region
        bcftools view -Ov -r ${CHR_NUM}:${START}-${END} --min-ac 2:minor -m2 -M2 ${REFILE}  > ${CURDIR}/reference_sorted.vcf
        
        POS=$(egrep -v '^\s*#' ${CURDIR}/reference_sorted.vcf  | grep $INV | cut -f2)
        
        # REFERENCE FILE - common individuals (samples), in population of interest
        # ------------------------------------------------------------------------- #
        # echo "## Common individuals (samples), in population of interest ##############"
       
        # Common 1KGP individuals filtered by populations + Inversion individuals
        # SAMPLES_INV=$(cut -f1 ${CURDIR}/genotypes_file.txt)
        # POPREFILE=$(ls ${REFDIR}/*.txt)

        # # Filter by population 
        # if [ $POP = "ALL" ]; then
        #   POP_FILTER=$(cut -f1 ${POPREFILE})
        # else
        #   POP_FILTER=$(grep ${POP} ${POPREFILE} | cut -f1)
        # fi
        
        # # Combine
        # SAMPLES_REF=$(echo $SAMPLES_INV $POP_FILTER | tr " " "\n" | sort | uniq -d)

        # # REFERENCE FILE - take 1KGP VCFs for common individuals
        # # ------------------------------------------------------------------------- #
        # echo "## Take 1KGP VCFs for common individuals ################################"
     
        # # 1000 genomes VCF 
        # VCF_PH3=$(ls $REFDIR | grep "${CHR}\..*gz$")
        
        # # Filter 1000 genomes VCF to include only reference samples in our interest region
        # bcftools view -Ov -r ${CHR_NUM}:${START}-${END} -s $(echo $SAMPLES_REF | tr " " ",") --min-ac 2:minor -m2 -M2 ${REFDIR}/${VCF_PH3}  > ${CURDIR}/haplotypes.vcf

        # # Optional loop to adjust genotypes if chromosome X (this will not be necessary yet, to take into account this situation the same adjustements need to be done in the INPUT file)
        # if [ $CHR_NUM = "X" ];  then
        #   # First filter
        #   sed 's/\t0\t/\t0\|0\t/g'  ${CURDIR}/haplotypes.vcf | sed 's/\t1\t/\t1\|1\t/g' |  sed 's/\t1$/\t1\|1/g'  | sed 's/\t0$/\t0\|0/g' > ${CURDIR}/haplotypes2.vcf
        #   # Count rows with incorrect genotypes
        #   ROW=$(grep -P "\t0\t" ${CURDIR}/haplotypes2.vcf | wc -l )
        #   # While such rows exist, apply filter
        #   while [ $ROW -gt 1 ] ; do
        #       sed 's/\t0\t/\t0\|0\t/g'  ${CURDIR}/haplotypes2.vcf | sed 's/\t1\t/\t1\|1\t/g' > ${CURDIR}/tmp
        #       rm ${CURDIR}/haplotypes2.vcf
        #       mv ${CURDIR}/tmp ${CURDIR}/haplotypes2.vcf
        #       ROW=$(grep -P "\t0\t" ${CURDIR}/haplotypes2.vcf | wc -l )
        #   done
        #   # Return to normality
        #   rm ${CURDIR}/rev_haplotypes.vcf
        #   mv ${CURDIR}/haplotypes2.vcf ${CURDIR}/haplotypes.vcf
        # fi

        # # Change name of temporary file
        # mv ${CURDIR}/haplotypes.vcf  ${CURDIR}/ref_haplotypes.vcf
        
        # # REFERENCE FILE - take inversion genotypes for common individuals
        # # ------------------------------------------------------------------------- #
        # echo "## Take inversion genotypes for common individuals ######################"

        # # Genotypes in STD|INV
        # GENOTYPES_SI=$(for SAMPLE in $SAMPLES_REF; do grep "${SAMPLE}\s" ${CURDIR}/genotypes_file.txt | cut -f2; done)

        # # Genotypes in 0|1
        # GENOTYPES_01=$(echo $GENOTYPES_SI | sed 's/STD/0\|0/gI' | sed 's/INV/1\|1/gI'| sed 's/HET/0\|1/gI')

        # # Create VCF line
        # echo -e "${CHR_NUM}\t${POS}\t${INV}\tA\tT\t.\tPASS\tCIPOS=${CIPOS}\tGT\t$(echo ${GENOTYPES_01} | tr ' ' '\t')" > ${CURDIR}/ref_inversion.vcf

        # # REFERENCE FILE - add inversion genotypes to 1000 KGP VCF
        # # ------------------------------------------------------------------------- #
        # echo "## Add inversion genotypes to 1000 KGP VCF ##############################"

        # # Concatenate both files 
        # cat ${CURDIR}/ref_haplotypes.vcf ${CURDIR}/ref_inversion.vcf > ${CURDIR}/reference_unsorted.vcf
        
        # # Sort to put inversion in place
        # bcftools sort ${CURDIR}/reference_unsorted.vcf -Ov -o ${CURDIR}/reference_sorted.vcf
        
        # REFERENCE FILE - make IMPUTE2 desired input 
        # ------------------------------------------------------------------------- #
        echo "## Make IMPUTE2 desired input ###########################################"

        code/software/vcf2impute_gen.pl -vcf ${CURDIR}/reference_sorted.vcf -gen ${CURDIR}/reference.gen

        # Remove temporary files
        # rm ${CURDIR}/reference_unsorted.vcf ${CURDIR}/reference_sorted.vcf ${CURDIR}/ref_inversion.vcf ${CURDIR}/ref_haplotypes.vcf ${CURDIR}/genotypes_file.txt
   
      # INPUT FILE
      # individuals (samples), in population of interest
      # =========================================================================== #
        STEP=$((${STEP}+1))
        echo "## ${STEP} INPUT FILE: individuals (samples), in population of interest ###"

        # INPUT FILE - individuals (samples), in population of interest
        # ------------------------------------------------------------------------- #
        echo "## Individuals (samples), in population of interest #####################"
        
        # Get population file
        POPFILE=$(ls ${INDIR}/*.txt)
 
        if [ $POP = "ALL" ]; then
          SAMPLES_IN=$(tail -n +2 ${POPFILE}|cut -f1 )
        else
          SAMPLES_IN=$(grep ${POP} ${POPFILE} | cut -f1)
        fi

        if [ -z "$SAMPLES_IN" ]; then echo "NO CORRECT POPULATION IN FILE"; fi
        # INPUT FILE - create input VCF
        # ------------------------------------------------------------------------- #
        echo "## Create input VCF #####################################################"

        # Select chromosome and samples and change chromosome names 
        # -m2 and -M2 select bialellic samples. Here I don't want to discard singletons etc. because sometimes I can have only one individual
        VCF_FILE=$(ls $INDIR | grep "${CHR}_.*gz$")

        bcftools view  --regions ${CHR_NUM}:${START}-${END} -s $(echo $SAMPLES_IN | tr " " ",") -m2 -M2 -Ov ${INDIR}/${VCF_FILE}  -o ${CURDIR}/input.vcf
     
        # UNFINISHED chromosome X code-----------------------------------------------------------------
        # if [ $chr = "X" ]
        # # then
        # # vcf="ALL.chrX.phase3_shapeit2_mvncall_integrated_v1b.20130502.genotypes.vcf.gz"
        # # else
        # # vcf="ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/ALL.chr${chr}.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz"
        # # #vcf="ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/supporting/shapeit2_scaffolds/hd_chip_scaffolds/OMNI.merged.chr11.phased_genotypes.20141111.vcf.gz"
        # fi
        # -----------------------------------------------------------------------------------------------

        # INPUT FILE - make IMPUTE2 desired input 
        # ------------------------------------------------------------------------- #
        echo "## Make IMPUTE2 desired input ###########################################"

        code/software/vcf2impute_gen.pl -vcf ${CURDIR}/input.vcf -gen ${CURDIR}/input.gen

        # Remove temporary files - This step was done independently to have the data always available
        rm  ${CURDIR}/input.vcf  

      # OTHER FILES
      # Recombination map and strand file
      # =========================================================================== #
        STEP=$((${STEP}+1))
        echo "## ${STEP} OTHER FILES: Recombination map and strand file ###############"

        # Recombination map location
        MAP=$(ls $MAPDIR | grep "${CHR}_.*txt$")

        # Strand file location
        STRAND=$(ls $INDIR | grep "${CHR}\.strand$")

      # IMPUTE2
      # Run imputation
      # =========================================================================== #
        STEP=$((${STEP}+1))
        echo "## ${STEP} IMPUTE2: Run imputation #######################################"

        code/software/impute_v2.3.2_x86_64_static/impute2 -g_ref ${CURDIR}/reference.gen.gz -g ${CURDIR}/input.gen.gz -int $POS $POS -k_hap ${IND} -o ${CURDIR}/output -m ${MAPDIR}/${MAP} #-strand_g  ${INDIR}/${STRAND}
      
      # SAVE RESULTS
      # In human-readable format
      # =========================================================================== #
        STEP=$((${STEP}+1))
        echo "## ${STEP} SAVE RESULTS: In human-readable format #######################"
      
        INDIVS=$(paste -s -d '\t' $CURDIR/input.gen.samples)
        mv $CURDIR/output $CURDIR/output.gen
        code/software/qctool/build/release/qctool_v2.0.7 -g $CURDIR/output.gen -og $CURDIR/output.vcf

        # GENO01=$(tail -n 1 ${INV}_${POP}_output.vcf | cut -f 10- | sed 's/\t/,/g' | awk  -F "," '{for (x=1;x<=NF;x += 3){y = x+1; z = x+2; print $x,$y,$z}}' | awk -v ORS="\t" '{if($1 > $2 && $1 > $3) print "0|0:" $1; else if($2 >$1 && $2 > $3) print "0|1:"$2; else if($3 > $1 && $3 > $2) print "1|1:" $3}')
        GENOSI=$(tail -n 1 $CURDIR/output.vcf | cut -f 10- | sed 's/\t/,/g' | awk  -F "," '{for (x=1;x<=NF;x += 3){y = x+1; z = x+2; print $x,$y,$z}}' | awk -v ORS="\t" '{if($1 > $2 && $1 > $3) print "STD:" $1; else if($2 >$1 && $2 > $3) print "HET:"$2; else if($3 > $1 && $3 > $2) print "INV:" $3; else print "?:"$1}')
        # TOTEST: probabilities only
        # GENOP=$(tail -n 1 ${INV}_${POP}_output.vcf | cut -f 10- | sed 's/\t/,/g' | awk  -F "," '{for (x=1;x<=NF;x += 3){y = x+1; z = x+2; print $x,$y,$z}}' | awk -v ORS="\t" '{if($1 > $2 && $1 > $3) print $1; else if($2 >$1 && $2 > $3) print $2; else if($3 > $1 && $3 > $2) print $3}')
        # # TOTEST: genotypes only
        # GENOG=$(tail -n 1 ${INV}_${POP}_output.vcf | cut -f 10- | sed 's/\t/,/g' | awk  -F "," '{for (x=1;x<=NF;x += 3){y = x+1; z = x+2; print $x,$y,$z}}' | awk -v ORS="\t" '{if($1 > $2 && $1 > $3) print "STD"; else if($2 >$1 && $2 > $3) print "HET"; else if($3 > $1 && $3 > $2) print "INV"}')
        

        # sed "s/FORMAT\t.*$/FORMAT\t${INDIVS}/" ${INV}_${POP}_output.vcf | sed "s/^\./${CHR_NUM}/g" | sed "s/\tGP\t.*$/\tGT:GP\t${GENO01}/g" > ${INV}_${POP}_output_01.vcf
        sed "s/FORMAT\t.*$/FORMAT\t${INDIVS}/" $CURDIR/output.vcf | sed "s/^\./${CHR_NUM}/g" | sed "s/\tGP\t.*$/\tGT:GP\t${GENOSI}/g" | sed "s/\t$//" > $CURDIR/output_readable.vcf
        # # TOTEST: probabilities only
        # sed "s/FORMAT\t.*$/FORMAT\t${INDIVS}/" ${INV}_${POP}_output.vcf | sed "s/^\./${CHR_NUM}/g" | sed "s/\tGP\t.*$/\tGP\t${GENOP}/g" > ${INV}_${POP}_output_GP.vcf
        # # TOTEST: genotypes only
        # sed "s/FORMAT\t.*$/FORMAT\t${INDIVS}/" ${INV}_${POP}_output.vcf | sed "s/^\./${CHR_NUM}/g" | sed "s/\tGP\t.*$/\tGT\t${GENOG}/g" > ${INV}_${POP}_output_GT.vcf
        
    done

  done 
