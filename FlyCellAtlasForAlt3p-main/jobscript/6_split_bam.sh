#!/bin/bash
# This is a shell script that wraps the real bam splitting script.

tissue=${1}

# Replace spaces with underscores
dir_name=$(echo ${tissue} | tr " " "_")

# Show error message if no arguement is given
if [[ $# -eq 0 ]]; then
  echo "Please provide an arugment for the tissue to process."
  echo "e.g., source 6_split_bam.sh 'head'."
  exit 1
fi

# Show error if file not found
if [[ ! -f data/${dir_name}_bam_extract.txt ]]; then
  echo "data/${dir_name}_bam_extract.txt is not found."
  echo "Did you run prepare_table_for_batch_exp.R?"
  exit 1
fi

# Count the lines in the metadata table
array_end=$(wc -l data/${dir_name}_bam_extract.txt | cut -d " " -f 1)

# Submit realy array job
sbatch --array=1-${array_end} ./jobscript/utils/export_bam_array.sh "${dir_name}"