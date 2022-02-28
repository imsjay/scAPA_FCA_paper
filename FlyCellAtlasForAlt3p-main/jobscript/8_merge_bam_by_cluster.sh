#!/bin/bash
# This is a wrapper script to calculate the job array length
# and call the sbatch script to merge.

tissue=${1}
# Replace spaces with underscores
dir_name=$(echo ${tissue} | tr " " "_")

if [[ ! -f export_bam/${dir_name}_idv.txt ]]; then
  echo "export_bam/${dir_name}_idv.txt does not exist."
  echo "Did you run prepare_bam_names_to_merge_per_cluster.R?"
  exit 1
fi

# Calculate the length of array by cluster number
array_end=$(wc -l export_bam/${dir_name}_idv.txt | cut -d " " -f 1)

# Run array job
sbatch --array=1-${array_end} ./jobscript/utils/merge_bam_by_cluster.sh ${dir_name}
