#!/bin/bash
# This script downloads all raw fastq files of
# 10X Genomics runs from the FlyCellAtlas
# Link: https://www.ebi.ac.uk/arrayexpress/experiments/E-MTAB-10519/

metaurl="https://www.ebi.ac.uk/arrayexpress/files/E-MTAB-10519/E-MTAB-10519.sdrf.txt"

# Show instruction if no argument is given
if [[ $# -eq 0 ]]; then
  echo "Please provide a tissue that you want to download from FlyCellAtlas"
  echo "(e.g., 'source 1_download.sh \"head\"')"
  echo ""
  echo "-n: Download file metadata from FlyCellAtlas"
  echo "    (e.g., 'source 1_download.sh -n'required for first run)"
  echo "-l: List available tissues in FlyCellAtlas"
  echo "    (e.g., 'source 1_download.sh -l')"
  return 1
fi

# Download file list to data if -n flag is passed
# Show tissue list if -l flag is passed
while getopts ":nl" opt; do
  case $opt in
    n)
      mkdir -p data/
      cd data
      wget ${metaurl}
      cd ..
      ;;
    l)
      awk -F "\t" 'NR!=1 {print $14}' data/E-MTAB-10519.sdrf.txt \
        | sort -u
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
    esac
done

# Error message if metadata file is not found
if [[ ! -f "data/E-MTAB-10519.sdrf.txt" ]]; then
  echo "FlyCellAtlas metadata (data/E-MTAB-10519.sdrf.txt) is not found."
  echo "If you have downloaded it already, please put it under ./data"
  echo "You can also do 'source 1_download.sh -n'. With a -n flag,"
  echo "the script will try to download it from ${metaurl}"
  return 1
fi

# The tab-separated metadata table contains the following information:
# Column 14 contains the tissue origin
# Column 56 contains the FTP URL to read 1
# Column 58 contains the FTP URL to read 2
tissue="${1}"

# Calculate the number of files to download
file_num=$(awk -F "\t" -v tissue="${tissue}" '$14==tissue {print $56 "\n" $58}' data/E-MTAB-10519.sdrf.txt | wc -l)

# Check if there are really URLs extracted from the metadata file
# If not, echo an error message and exit.
if [ ! ${file_num} -gt 1 ]; then
  echo "The url is very short, please check if grepping your metadata returns anything."
  echo "Here's what is extracted:"
  echo "$(awk -F "\t" -v tissue="${tissue}" '$14==tissue {print $56 "\n" $58}' data/E-MTAB-10519.sdrf.txt)"
  return 1
fi 

# Create a directory storing the fastq files
# Replace spaces with underscores in a path
dir_name=$(echo "${1}" | tr " " "_")
out_path=data/fastq/${dir_name}
mkdir -p ${out_path}

# Substract that number by 1 because array in base is zerobased.
array_end=$((${file_num} - 1))

# Run a SLURM array job to download every thing
sbatch --array=0-${array_end} ./jobscript/utils/sbatch_download.sh "${tissue}" "${out_path}"
