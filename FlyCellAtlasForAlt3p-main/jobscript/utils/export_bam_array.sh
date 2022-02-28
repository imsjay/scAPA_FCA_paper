#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --time=1:00:00
#SBATCH --mem=12GB
#SBATCH --output=log/bamex_slurm_%j.out

# This script reads a metadata table
# (generated from prepare_table_for_batch_exp.R)
# and split CellRanger output bam files to a file per cluster per library
module purge
module load samtools/intel/1.12

tissue=$1

# Read the $SLURM_ARRAY_TASK_ID line of the metadata file
cbc=$(awk -vline=${SLURM_ARRAY_TASK_ID} 'NR==line{print $1}' data/${tissue}_bam_extract.txt)
bam=$(awk -vline=${SLURM_ARRAY_TASK_ID} 'NR==line{print $2}' data/${tissue}_bam_extract.txt)
out=$(awk -vline=${SLURM_ARRAY_TASK_ID} 'NR==line{print $3}' data/${tissue}_bam_extract.txt)

# Split bam files with cell barcodes (CR: field in the bam)
# per cluster per library
samtools view -bq 30 -@ 8 -D CR:${cbc} ${bam}> ${out}
