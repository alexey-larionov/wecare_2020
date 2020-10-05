#!/bin/bash

# s11_check_related.sh
# Calculate KING coefcient and remove relatives
# Alexey Larionov, 05Oct2020

# Expected KING coefficients for relatives
# 0.5 (2^-1) Duplicates (identical tweens)
# 0.25 (2^-2) First-degree relatives (parent-child, full siblings)
# 0.125 (2^-3) 2-nd degree relatives (example?)
# 0.0625 (2^-4) 3-rd degree relatives (example?)
# Parameter 0.0441941738241592=1/2^-4.5 was used here (e.g. like in Preve 2020)

# References
# http://www.cog-genomics.org/plink/2.0/distance#make_king
# https://www.cog-genomics.org/plink/2.0/formats#kin0

#SBATCH -J s11_check_related
#SBATCH -A TISCHKOWITZ-SL2-CPU
#SBATCH -p skylake-himem
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --time=01:00:00
#SBATCH --output=s11_check_related.log
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
echo "Detect and remove related cases (if any) using KING coefficient"
date
echo ""

# Folders
base_folder="/rds/project/erf33/rds-erf33-medgen"
project_folder="${base_folder}/users/alexey/wecare/reanalysis_wo_danish_2020"

scripts_folder="${project_folder}/scripts/s05_pca"
cd "${scripts_folder}"

data_folder="${project_folder}/data/s05_pca"
source_folder="${data_folder}/s04_autosomal_common"
output_folder="${data_folder}/s05_relatedness_check"
rm -fr "${output_folder}"
mkdir "${output_folder}"

# Files
source_fileset="${source_folder}/wecare_biallelic_snps_autosomal_common"
output="${output_folder}/wecare_biallelic_snps_autosomal_common_norel"

# Plink
plink2="${base_folder}/tools/plink/plink2/plink2_alpha2.3/plink2"

# Calculate and remove related samples
"${plink2}" \
--bfile "${source_fileset}" \
--allow-extra-chr \
--make-king-table \
--king-table-filter 0.0441941738241592 \
--make-bed \
--king-cutoff 0.0441941738241592 \
--silent \
--threads 4 \
--memory 48000 \
--out "${output}"

# Completion message
echo ""
echo "Done"
date
