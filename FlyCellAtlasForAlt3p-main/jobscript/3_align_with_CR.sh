#!/bin/bash
# This scripts aligns FlyCellAtlas data sequenced with
# 10X Genomics platform against a pre-compiled Dm6.28
# reference genome

tissue=${1}
## Deal with spaces.
dir_name=$(echo ${tissue} | tr " " "_")

# Check if file exists or error out
if [[ ! -f "data/fastq/${dir_name}/samplelist.txt" ]]; then
  echo "I can't find data/fastq/${dir_name}/samplelist.txt."
  echo "Did you downloaded the files and generated a sample list?"
  exit 1
fi

# Create output folde
mkdir -p data/bam/${dir_name}/

# Figure out how many samples are there for this tissue
sample_num=$(wc -l data/fastq/${dir_name}/samplelist.txt | cut -d " " -f 1)

# Run an array job to align every sample
sbatch --array=1-$sample_num jobscript/utils/cr_align_array_job.sh "${tissue}"