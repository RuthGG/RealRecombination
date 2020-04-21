# Crick
## avery_SRA_key
A directory with prj_21579.ngc, the key to access to Bell et al. 2019 dbGap data.

## avery_SRA
Output directory for prefetch downloads from Bell et al. 2019 dbGap data.

## avery_fastq
Output directory for fastq-dump conversion from .SRA prefetch to fastq data from Bell et al. 2019 dbGap.

# Muscul and local
## avery_individuals
A directory with files obtained by personal communication by Avery Davis Bell. Copied manually. It contains 6 files:
 
* all14samps.qd3filter.snpsonly.recalibrated_snps99.9.dbsnpnamed.1kgph3only.paraloghwecensexcluded.vcf.gz (+.tbi)
* nc6nc22nc25nc26.snpsonly.qd3.recalibrated_snps99.9.dbsnpnamed.1kgph3only.paraloghwecensexcluded.vcf.gz (+.tbi)
* nc17nc18.qd3filter.snpsonly.recalibrated_snps99.9.dbsnpnamed.1kgph3only.paraloghwecensexcluded.vcf.gz (+.tbi)

## 1000genomes_hg19
    2020-04-15: **1000 genomes project hg19 vcf data and their indexes**, that were downloaded from ebi.ac.uk via ftp service.

    2020-04-17: **1000 genomes project hg19 population data**. Origin for each individual. 

## 1000genomes_hg19_maps 
	2020-04-21: **1000 genomes project hg19 recombination maps**, that were manually copied from the previous project. Only for autosomes.

## inversions_info
A directory with various information from inversions, obtained by personal communication from multiple sources. 

* genotypes: inversion genotype files from 3 sources, and a veru specific Rscript that joins all together. The result from this script is in `data/use/inversions_info`.
* jon_newinvs: all information from genotypes and imputability that jon provided. It has its own README.txt. An imputability summary is in `data/use/inversions_info`.
* TagVs_IVS_v4.7: a file that lists, for 45 inversions which are the reported tag SNPs present in different populations and its linkage disequilibrium with the inversion.