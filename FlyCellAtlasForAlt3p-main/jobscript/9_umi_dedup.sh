#!/bin/bash

# This is a wrapper that automatically determine the array job number to
# de-duplicate reads by UMI.

tissue=${1}

# Replace spaces with underscores
dir_name=$(echo ${tissue} | tr " " "_")

# Pre-merge files are prepended by "FCA"
# if there's any left, remove first.
if [[ -n $(find export_bam/${dir_name} -maxdepth 1 -name "FCA*" -print -quit) ]]; then
  rm export_bam/${dir_name}/FCA*
fi

# Generate a list of bam files to dedup
find export_bam/${dir_name} -maxdepth 1 -name "*.bam" \
  | cut -d "/" -f 3 > export_bam/${dir_name}_to_dedup.txt

array_end=$(wc -l export_bam/${dir_name}_to_dedup.txt | cut -d " " -f 1)

if [[ ${array_end} -lt 1 ]]; then
  echo "I did not find bam files to de-duplicate in: "
  echo "export_bam/${dir_name}"
  echo "Please check if you have merged bam files in the directory."
  echo "Exiting..."
  exit 1
fi

# Prepare de-dup log directory for troubleshooting
mkdir -p export_bam/${dir_name}/log

# Run array job
sbatch --array=1-${array_end} ./jobscript/utils/umi_dedup.sh ${dir_name}
