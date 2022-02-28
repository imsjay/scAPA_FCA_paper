#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --time=1:00:00
#SBATCH --mem=16GB
#SBATCH --job-name=bw
#SBATCH --output=log/to_bw_slurm_%j.out
#SBATCH --job-name=BWconvert

# This script converts a list of bam files
# to a list of bigwig files with strands separated
module purge
module load deeptools/3.5.0
module load samtools/intel/1.12

tissue=$1

bam=$(awk -vline=${SLURM_ARRAY_TASK_ID} 'NR==line{print $1}' export_bam/${tissue}_to_bw.txt)
foutpath=$(awk -vline=${SLURM_ARRAY_TASK_ID} 'NR==line{print $2}' export_bam/${tissue}_to_bw.txt)
routpath=$(awk -vline=${SLURM_ARRAY_TASK_ID} 'NR==line{print $3}' export_bam/${tissue}_to_bw.txt)

# echo $bam
# echo $foutpath
# echo $routpath
samtools index -@ 4 ${bam}

bamCoverage --bam ${bam} \
-o ${foutpath} \
--normalizeUsing CPM \
--ignoreForNormalization X\
--outFileFormat bigwig \
--minMappingQuality 30 \
--samFlagExclude 16 \
--binSize 1 \
-p max

bamCoverage --bam ${bam} \
-o ${routpath} \
--normalizeUsing CPM \
--ignoreForNormalization X\
--outFileFormat bigwig \
--minMappingQuality 30 \
--samFlagInclude 16 \
--binSize 1 \
-p max
