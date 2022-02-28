#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --time=1:00:00
#SBATCH --mem=16GB
#SBATCH --output=log/bammerge_slurm_%j.out


# This script merges the bam files for each cluster
# for the testis samples
module purge
module load samtools/intel/1.12

tissue=$1

fca_num=$(awk -vline=${SLURM_ARRAY_TASK_ID} 'NR==line{print $1}' export_bam/${tissue}_idv.txt)
samtools merge export_bam/${tissue}/${fca_num} export_bam/${tissue}/*${fca_num} -@ 8
