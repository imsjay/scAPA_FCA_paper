#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=8:00:00
#SBATCH --mem=1GB
#SBATCH --job-name=download
#SBATCH --output=log/download_slurm_%j.out

# The tab-separated metadata table contains the following information:
# Column 14 contains the tissue origin
# Column 56 contains the FTP URL to read 1
# Column 58 contains the FTP URL to read 2
tissue="${1}"

urls=($(awk -F "\t" -v tissue="${tissue}" '$14==tissue {print $56 "\n" $58}' data/E-MTAB-10519.sdrf.txt))

# Download 
cd "${2}"
wget ${urls[${SLURM_ARRAY_TASK_ID}]}
