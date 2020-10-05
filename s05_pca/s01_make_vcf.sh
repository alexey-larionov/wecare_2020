#!/bin/bash

# s01_make_vcf.sh
# Select samples for PCA
# Alexey Larionov, 05Oct2020

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

echo "Selecting wecare samples ..."
echo ""
"${bcftools}" view "${source_vcf}" \
--samples-file "${samples_file}" \
--output-file "${wecare_vcf}" \
--trim-alt-alleles \
--output-type z \
--threads 4 \
&> "${wecare_log}"

# Removal of samples creates a number of non-polymorphic variant sites
# e.g. sites where all genotypes in the dataset are homozygous reference.
# --trim-alt-alleles puts "." to ALT alleles of such non-polymorphic sites;
# However such sites are not yet removed

# Index wecare vcf
"${bcftools}" index "${wecare_vcf}"

echo "Counts in the vcf file after samples filtering"
echo "(non-polymorphic sites are preserved with dot in ALT allele)"
"${bcftools}" +counts "${wecare_vcf}"
echo ""

# Completion message
echo "Done"
date
echo ""
