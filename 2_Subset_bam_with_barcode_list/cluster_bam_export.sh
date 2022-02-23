# This script requires samtools to run
# http://www.htslib.org


# This part was originally done as a job array to run in parallel
# The following awk codes gets the ${SLURM_ARRAY_TASK_ID}th line from a text file
# and extract the nth column with $n ($1 selects the first column)
cbc=$(awk -vline=${SLURM_ARRAY_TASK_ID} 'NR==line{print $1}' int/extract_bam_per_cluster_meta.txt)
bam=$(awk -vline=${SLURM_ARRAY_TASK_ID} 'NR==line{print $2}' int/extract_bam_per_cluster_meta.txt)
out=$(awk -vline=${SLURM_ARRAY_TASK_ID} 'NR==line{print $3}' int/extract_bam_per_cluster_meta.txt)
targetdir=$(awk -vline=${SLURM_ARRAY_TASK_ID} 'NR==line{print $4}' int/extract_bam_per_cluster_meta.txt)

# extract_bam_per_cluster_meta.txt is a file containing 4 columns (see the file in the folder)
# The first column is the path to a text file in which each row is a cell barcode
# The second column is the path to the bam file to subset from
# The third column is the path the per-column & per-batch bam files to be saved
# The forth column is folder to create for output if not yet created

mkdir -p ${targetdir}
samtools view -D CB:${cbc} ${bam} -b > ${out}

