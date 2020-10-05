#!/bin/bash

# s10_qc_and_filter.sh
# Alexey Larionov, 05Oct2020

#SBATCH -J s10_qc_and_filter
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake-himem
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --time=01:00:00
#SBATCH --output=s10_qc_and_filter.log
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
echo "Remove cases and variants with low call rates and select common autosomal variants"
date
echo ""

# Folders
base_folder="/rds/project/erf33/rds-erf33-medgen"
project_folder="${base_folder}/users/alexey/wecare/reanalysis_wo_danish_2020"

scripts_folder="${project_folder}/scripts/s05_pca"
cd "${scripts_folder}"

data_folder="${project_folder}/data/s05_pca"
source_folder="${data_folder}/s03_plink"
output_folder="${data_folder}/s04_autosomal_common"
rm -fr "${output_folder}"
mkdir "${output_folder}"

# Files
source_fileset="${source_folder}/wecare_biallelic_snps"
output_fileset="${output_folder}/wecare_biallelic_snps_autosomal_common"

# Plink
plink2="${base_folder}/tools/plink/plink2/plink2_alpha2.3/plink2"

# Selecting variants
"${plink2}" \
--bfile "${source_fileset}" \
--autosome \
--geno 0.1 \
--hwe 1e-10 \
--maf 0.05 \
--mind 0.1 \
--threads 4 \
--memory 48000 \
--make-bed \
--out "${output_fileset}"

# --autosome : select only autosomal variants
# --geno : maximal fraction of missed genotypes per variant 0.1 (minimal call_rate 0.9)
# --hwe : minimal HWE 1e-10
# --maf : minimal MAF 0.05
# --mind : maximal fraction of missed genotypes per individual 0.1 (minimal call_rate 0.9)

# Completion message
echo ""
echo "Done"
date
