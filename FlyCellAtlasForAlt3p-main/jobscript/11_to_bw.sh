#!/bin/bash
# This is a wrapper script to determine the job array size to convert
# to bigwig files and send the real slurm job for it.

tissue=${1}

# Replace spaces with underscores
dir_name=$(echo ${tissue} | tr " " "_")

# Check if convert table exists
if [[ ! -f export_bam/${dir_name}_to_bw.txt ]]; then
  echo "Cannot find export_bam/${dir_name}_to_bw.txt"
  echo "Did you run prepare_bw_convert_list.R?"
  exit 1
fi

# Count array length
array_end=$(wc -l export_bam/${dir_name}_to_bw.txt | cut -d " " -f 1)

# Send error message if there's nothing to convert in the table
if [[ ${array_end} -lt 1 ]]; then
  echo "I did not find bam files to convert in the table : "
  echo "export_bam/${dir_name}_to_bw.txt}"
  echo "Please check if you have deduplicated bam files in the directory."
  echo "Exiting..."
  exit 1
fi

# Send sbatch job
sbatch --array=1-${array_end} ./jobscript/utils/to_bw.sh ${dir_name}