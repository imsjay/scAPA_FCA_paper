# Do NOT run this script!!

## Download file metadata
./jobscript/1_download.sh -n

## Show available tissues
./jobscript/1_download.sh -l

# Download fastq files
./jobscript/1_download.sh "male reproductive gland"

# Show file names to decide sample name length
./jobscript/2_get_sample_list.sh "male reproductive gland"

# Generate sample list
./jobscript/2_get_sample_list.sh "male reproductive gland" 7

# Align
./jobscript/3_align_with_CR.sh "male reproductive gland"

# Extract cluster info
./jobscript/4_extract_cluster_bam_scanpy.R --tissue="male reproductive organ"

# Prepare for extraction
./jobscript/5_prepare_table_for_batch_exp.R --tissue="male reproductive gland"

# Extract cluster/lib-specific bams
./jobscript/6_split_bam.sh "male reproductive gland"

# Prepare for merging per cluster
./jobscript/7_prepare_bam_names_to_merge_per_cluster.R --tissue="male_reproductive_gland"

# Merge per cluster
./jobscript/8_merge_bam_by_cluster.sh "male reproductive gland"

# Deduplicate UMI
./jobscript/9_umi_dedup.sh "male reproductive gland"

# Convert to bigwig
./jobscript/10_prepare_bw_convert_list.R --tissue="male reproductive gland"
./jobscript/11_to_bw.sh "male_reproductive_gland"

### Last run: 2022-02-26