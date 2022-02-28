#!/bin/bash
# This script list the files in a directory
# and generates a sample list if provided
# with the part of file names to retain.
tissue=${1}
fields_to_keep=${2}

# Replace spaces with underscores
dir_name=$(echo ${tissue} | tr " " "_")

# Show example file names if no field number is provided.
if [[ ${fields_to_keep} -eq 0 ]]; then
  # Show a few files to help decide field number
  echo "The file names looks like this:"
  ls data/fastq/${dir_name}/ | grep "gz$" | head
  
  # Show a brief instruction to help myself in the future.
  printf "\n"
  echo "Sample names in 10X is usually defined as "
  printf "\n"
  echo "[Sample names]_S#_L#_R#_#.fastq.gz"
  printf "\n"
  echo "Please count the number of underscore separated regions"
  echo "there are in the sample names and use it as the second argument."
  printf "\n"
  echo "E.g., if the file is test_sample_S01_L001_R1_001.fastq.gz"
  echo "The region number is 2 (*test* and *sample*)"
  echo "Run 'source jobscript/2_get_sample_list.sh test 2' to generate a sample list"
  exit 1
fi

# Get sample name parts and then keep unique names to decide
# how many libraries are there.
ls data/fastq/${dir_name}/ | grep "gz$" | cut -d "_" -f 1-${fields_to_keep} \
  | sort -u > data/fastq/${dir_name}/samplelist.txt