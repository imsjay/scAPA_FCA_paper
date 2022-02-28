#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=8:00:00
#SBATCH --mem=256GB
#SBATCH --output=log/umidedup_slurm_%j.out


# This script dedup the merged bam with UMIs
# It can be very resource intensive for large bam files!
module purge
module load anaconda3/2020.07
module load samtools/intel/1.12

tissue=$1

to_dedup=$(awk -vline=${SLURM_ARRAY_TASK_ID} 'NR==line{print $1}' export_bam/${tissue}_to_dedup.txt)

############ SLURM-specific setting ############
# Force load personal .bashrc to use miniconda
# since umitools is installed via conda
source $HOME/.bashrc
conda activate $SCRATCH/.env/local
################################################

# Index merged bam file before de-duplication
samtools index export_bam/${tissue}/${to_dedup}

# De-duplication with umi_tools. Errors could happen due to resource limit
# and might need to adjust manually.
umi_tools dedup --extract-umi-method=tag \
	--umi-tag=UR \
	--cell-tag=CR \
	--stdin=export_bam/${tissue}/${to_dedup} --log=export_bam/${tissue}/log/${to_dedup}.log > export_bam/${1}/dedup_${to_dedup}

# Index individual deduplicated files
samtools index export_bam/${tissue}/dedup_${to_dedup}
