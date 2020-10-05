#!/bin/bash

# s09_make_plink.sh
# Alexey Larionov, 05Oct2020

#SBATCH -J s09_make_plink
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake-himem
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --time=01:00:00
#SBATCH --output=s09_make_plink.log
#SBATCH --qos=INTR

# Available memory
# skylake: 23,920 MB = 4 * 5,980 MB
# skylake-himem: 48,120 MB = 4 * 12,030 MB

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
echo "Convert VCF file to plink bed-bim-fam fileset"
date
echo ""

# Folders
base_folder="/rds/project/erf33/rds-erf33-medgen"
project_folder="${base_folder}/users/alexey/wecare/reanalysis_wo_danish_2020"

scripts_folder="${project_folder}/scripts/s05_pca"
cd "${scripts_folder}"

data_folder="${project_folder}/data/s05_pca"
source_folder="${data_folder}/s02_biallelic_snps"
output_folder="${data_folder}/s03_plink"
rm -fr "${output_folder}"
mkdir "${output_folder}"

# Files
source_vcf="${source_folder}/wecare_biallelic_snps.vcf.gz"
output_plink="${output_folder}/wecare_biallelic_snps"

# Plink
plink2="${base_folder}/tools/plink/plink2/plink2_alpha2.3/plink2"

# Convert vcf to plink
"${plink2}" \
--vcf "${source_vcf}" \
--vcf-half-call "missing" \
--double-id \
--threads 4 \
--memory 48000 \
--silent \
--make-bed \
--out "${output_plink}"

# --vcf-half-call describes what to do with genotypes like 0/.
# --double-id puts sample name to both Family-ID and Participant-ID
# --make-bed requests making bed-bim-fam fileset
# --silent suppress printing to std out (keeps printing to the dedicated log)

# Completion message
echo "Done"
date
