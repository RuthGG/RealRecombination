## avery_individuals
2020-04-15: Ready-to-use files for data/raw/avery_individuals, in the same assembly as reference (in data/raw/1000genomes_hg19) and by chromosome. Also the corresponding .strand and .tbi files.

## conditions
A directory to put different manually or computationally created lists that are required for analysis runs. Example: list of inversions to impute, list of imputation conditions, etc. 

A copy of these conditions is stored in analysis/ once they are used, so they can be over-written. The reason to store them here is that we don't know which will be he analysis/ output file name before we run the script. 

## inversions_info

* `all_genotypes.csv` is a file with all reported genotypes for available inversions in tested individuals until now. Raw data of origin is in `data/raw/inversions_info/genotypes`
* `inversions_coordinates_hg19.csv` has coordinates for all the reported inversions until now. 
* `inversions_imputability.txt` is a manually-created file that summarized the imputaility information that Jon provided. Raw data of origin is in `data/raw/inversions_info/jon_newinvs`

