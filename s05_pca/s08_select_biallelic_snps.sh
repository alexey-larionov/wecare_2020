#!/bin/bash

# s08_select_biallelic_snps.sh
# Select biallelic SNPs for PCA
# Alexey Larionov, 05Oct2020

# Note:
# Because the multialelics had been split earlier,
# we are not actually select true bialelics ...

#SBATCH -J s08_select_biallelic_snps
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --time=01:00:00
#SBATCH --output=s08_select_biallelic_snps.log
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
echo "Select biallelic snps"
date
echo ""

# Folders
base_folder="/rds/project/erf33/rds-erf33-medgen"
project_folder="${base_folder}/users/alexey/wecare/reanalysis_wo_danish_2020"

scripts_folder="${project_folder}/scripts/s05_pca"
cd "${scripts_folder}"

data_folder="${project_folder}/data/s05_pca"
source_folder="${data_folder}/s01_vcf"
output_folder="${data_folder}/s02_biallelic_snps"
rm -fr "${output_folder}"
mkdir -p "${output_folder}"

# Files
source_vcf="${source_folder}/wecare_altok_filltags_polymorphic_only.vcf.gz"
output_vcf="${output_folder}/wecare_biallelic_snps.vcf.gz"
output_log="${output_folder}/wecare_biallelic_snps.log"

# Bcftools
bcftools="${base_folder}/tools/bcftools/bcftools-1.10.2/bin/bcftools"

echo "Source vcf counts"
echo ""
"${bcftools}" +counts "${source_vcf}"
echo ""

echo "Selecting biallelic SNPs ..."
"${bcftools}" view "${source_vcf}" \
--min-alleles 2 \
--max-alleles 2 \
--types snps \
--threads 4 \
--output-type z \
--output-file "${output_vcf}" \
&> "${output_log}"

echo "Indexing ..."
"${bcftools}" index "${output_vcf}"
echo ""

echo "Output vcf counts"
echo ""
"${bcftools}" +counts "${output_vcf}"
echo ""

# Completion message
echo "Done"
date
