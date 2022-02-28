#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --time=12:00:00
#SBATCH --mem=64GB
#SBATCH --job-name=cellranger
#SBATCH --output=log/cralign_slurm_%j.out

# This scripts aligns FlyCellAtlas data sequenced with
# 10X Genomics platform against a pre-compiled Dm6.28
# reference genome.

# The script is run on a HPC with Slurm job mananger
# and might need to be revised for use in other systems. 

# Use the first commandline argument to point to
# the directory containing all fastq.gz files of
# the same tissue.
tissue=$1

## Deal with spaces.
dir_name=$(echo ${tissue} | tr " " "_")


# Read a pre-processed list of sample IDs
# For details, see documentation for the
# --sample flag of cellranger
# Link: https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/using/count
sp=$(awk "NR==${SLURM_ARRAY_TASK_ID}" data/fastq/${dir_name}/samplelist.txt)

##### SLURM-specific ########
module purge
module load cellranger/6.0.1
#############################

# Let outputs go to data/bam/[tissue]
cd data/bam/${dir_name}/

cellranger count --id=${sp} \
                   --transcriptome=../../../../data/dm6.28_cellranger/ \
                   --fastqs=../../fastq/${dir_name}/ \
                   --sample=${sp} \
                   --localcores=16 \
                   --localmem=64
