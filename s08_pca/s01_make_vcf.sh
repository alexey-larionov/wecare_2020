#!/bin/bash

----------------------------------------
The script still need updates before run
----------------------------------------
- remove Danish, NFE etc
- remove non-polymorphic sites (all types: hom-Ref, hom-ALT and HET)
- recalculating AC, AN, AF etc tags

# s01_make_vcf.sh
# Select samples for PCA
# Alexey Larionov, 07Oct2020

#SBATCH -J s01_make_vcf
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --time=01:00:00
#SBATCH --output=s01_make_vcf.log
#SBATCH --qos=INTR

## Modules section (required, do not remove)
. /etc/profile.d/modules.sh
module purge
module load rhel7/default-peta4

## Set initial working folder
cd "${SLURM_SUBMIT_DIR}"

## Report settings and run the job
echo "Job id: ${SLURM_JOB_ID}"
echo "Allocated node: $(hostname)"
echo "$(date)"
echo ""
echo "Job name: ${SLURM_JOB_NAME}"
echo ""
echo "Initial working folder:"
echo "${SLURM_SUBMIT_DIR}"
echo ""
echo " ------------------ Job progress ------------------ "
echo ""

# Stop at runtime errors
set -e

# Start message
echo "Started s01_make_vcf"
date
echo ""

# Folders
base_folder="/rds/project/erf33/rds-erf33-medgen"

project_folder="${base_folder}/users/alexey/wecare/reanalysis_wo_danish_2020"

output_folder="${project_folder}/data/s05_pca/s01_vcf"
rm -fr "${output_folder}"
mkdir -p "${output_folder}"

scripts_folder="${project_folder}/scripts/s05_pca"
cd "${scripts_folder}"

# Files
source_vcf="${project_folder}/data/s02_annotate/wecare_nfe_nov2016_vqsr_shf_split_clean_tag_ac_id_clinvar_vep_split_rm.vcf.gz"
samples_file="${project_folder}/data/s04_add_phenotypes/s02_selected_samples.txt"

wecare_vcf="${output_folder}/wecare.vcf.gz"
wecare_log="${output_folder}/wecare.log"

filltags_vcf="${output_folder}/wecare_filltags.vcf.gz"
filltags_log="${output_folder}/wecare_filltags.log"

polymorphic_vcf="${output_folder}/wecare_filltags_polymorphic.vcf.gz"
polymorphic_log="${output_folder}/wecare_filltags_polymorphic.log"

# Bcftools
bcftools="${base_folder}/tools/bcftools/bcftools-1.10.2/bin/bcftools"

echo "Counts in the source vcf file"
"${bcftools}" +counts "${source_vcf}"
echo ""

####################################################################
# Removal of samples
# Note: as a side-effect it creates a number of sites without ALT allele
# i.e. sites where all genotypes in the dataset are homozygous reference.
# --trim-alt-alleles puts "." to ALT alleles of such non-polymorphic sites;
# However the sites are not yet removed at this step

echo "Selecting wecare samples ..."
echo ""
"${bcftools}" view "${source_vcf}" \
--samples-file "${samples_file}" \
--output-file "${wecare_vcf}" \
--trim-alt-alleles \
--output-type z \
--threads 4 \
&> "${wecare_log}"

# Index wecare vcf
"${bcftools}" index "${wecare_vcf}"

echo "Counts in the vcf file after samples filtering"
"${bcftools}" +counts "${wecare_vcf}"
echo ""

####################################################################
# Removal of non-polymorphic homosygous reference sites with "." in ALT
# Removal of samples creates a number of sites without ALT allele
# i.e. sites where all genotypes in the dataset are homozygous reference.
# --trim-alt-alleles puts "." to ALT alleles of such non-polymorphic sites;
# Now these sites are removed
# Note that non-polymorphic heterozygous or homozygous ALT are still kept

# Files
source_vcf="${data_folder}/wecare.vcf.gz"
output_vcf="${data_folder}/wecare_altok.vcf.gz"
output_log="${data_folder}/wecare_altok.log"

echo "Removing dot-Alt sites ..."
echo ""
"${bcftools}" view "${source_vcf}" \
--exclude 'ALT="."' \
--output-file "${output_vcf}" \
--output-type z \
--threads 4 \
&> "${output_log}"

# Index wecare vcf
"${bcftools}" index "${output_vcf}"

echo "Counts in the vcf file after removal of sites with dot in ALT"
"${bcftools}" +counts "${output_vcf}"
echo ""

####################################################################
# Recalculating TAGs
# Removal of samples creates may mess with thhe AC, AN, AF etc
# Here we recalculate these tags

# Files
source_vcf="${data_folder}/wecare_altok.vcf.gz"
output_vcf="${data_folder}/wecare_altok_filltags.vcf.gz"
output_log="${data_folder}/wecare_altok_filltags.log"

echo "Recalculating tags after samples removal (AC,AN,AF etc) ..."
"${bcftools}" +fill-tags "${source_vcf}" \
--output "${output_vcf}" \
--output-type z \
--threads 4 \
&> "${output_log}"

# Index wecare vcf
"${bcftools}" index "${output_vcf}"

echho ""
echo "Counts in the vcf file after recalculating tags"
"${bcftools}" +counts "${output_vcf}"
echo ""

####################################################################
# Removal of non-polymorphic HETs and hom-ALT sites

# The non-polymorphic sites without ALT allele < (COUNT(GT="het")=0 & COUNT(GT="AA")=0) >
# should not be present in the file already (removed as dots in ALT).  However, this clause
# is included in the filter for comletness.

# This filtering does not consider a possibility of hemi-zygous and alt2 non-polymorphic variants.
# However, its OK for this case because only common autosomal variants will be used for PCA analysis
# and no alt2 could be present after splitting of multi-allelic sites.
# Also, a separate in-house R script confirmed the number of polymorphic sites after the samples removal

# Files
source_vcf="${data_folder}/wecare_altok_filltags.vcf.gz"
output_vcf="${data_folder}/wecare_altok_filltags_polymorphic.vcf.gz"
output_log="${data_folder}/wecare_altok_filltags_polymorphic.log"

echo "Filtering ..."
"${bcftools}" view "${source_vcf}" \
--output-file "${output_vcf}" \
--exclude '(COUNT(GT="RR")=0 & COUNT(GT="AA")=0) | (COUNT(GT="het")=0 & COUNT(GT="RR")=0) | (COUNT(GT="het")=0 & COUNT(GT="AA")=0)' \
--output-type z \
--threads 4 \
&> "${output_log}"

# Index the vcf file with new tags
"${bcftools}" index "${output_vcf}"

echo ""
echo "Counts in the vcf file with polymorphic sites only"
"${bcftools}" +counts "${output_vcf}"
echo ""

# Completion message
echo "Done"
date
echo ""
