# Extract bam files for each cluster from FlyCellAtlas

Last successful test run: 2022-02-26

## Assumptions

- *Drosophila melanogaster* genome is precompiled and placed in
`../data/dm6.28_cellranger/

- Analysis is run on a Linux platform with
[Slurm Workload Manager](https://slurm.schedmd.com) and the following
dependency:
  - `bash`: The scripts should be portable but only tested on `bash`.
  - `wget`
  - `awk`
  - `cellranger`
  - `R`
  - `Python`
  - `Scanpy`
  - `umi_tools`
  - `bamtools`
  - `deeptools`

- Scripts are given executable permission with `chmod +x [the script]`.
  - In all messages in README and from scripts, `[text]` refers to something
  that you need to replace with your need. Do **not** keep the square brackets
  after replacement.

- All scripts are placed in `./jobscripts` and executed at `./`.

- The user has permission and available space to create directories in the
current wording directory to save the intermittent files and results.

## Steps

### 1. Download

This script download the raw sequencing reads from ArrayExpress. If you are
running it the first time, `./jobscript/1_download.sh -n` will try to download
the file metadata table from FlyCellAtlas. If you want to know the tissues that
are present in the table, `./jobscript/1_download.sh -l` will print them out.

To download raw data, `./1_download.sh [tissue]`. **Please note that if the
tissue To download raw data, `./1_download.sh [tissue]`.** Please note that if
the tissue e.g., `./jobscript/1_download.sh "male reproductive gland)` will run,
but `./jobscript/1_download.sh male reproductive gland` will fail.)

### 2. Generate sample list

This script reproduces a sample list that contain sample names as in
`bcl2fastq` naming convention (for details, see
[Cellranger documentation](https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/using/tutorial_ct)). `cellranger count` need this
information to know which files to align.

You need to provide the tissue name to the script (e.g.,
`./jobscript/2_get_sample_list.sh "fatbody"`). Running this will
show a few file names, and you will need to count the number of fields that
belongs to the sample name.

For example, in `FCA46_Female_fatbodyGFP_adult_3dcgGAL4LamGFPT_Jasper_sample1_S14_L001_R2_001.fastq.gz`,
`FCA46_Female_fatbodyGFP_adult_3dcgGAL4LamGFPT_Jasper_sample1` is the sample
name, and it contains 7 fields.

In this example, run `./jobscript/2_get_sample_list.sh "fatbody" 7` to generate
a sample list.

### 3. Align with `cellranger count`

Run `./jobscript/3_align_with_CR.sh [tissue]` to align the fastq files and store
results in `./data/bam/[tissue]`.

Please note that alignment is a resource and time intensive process and might
fail in your personal computer.

### 4. Retrieve cell barcode-cluster table

To learn the identity of a cell, we need the annotation from FlyCellAtlas. To
run this step, you need to first download the `h5ad` object from the
[FlyCellAtlas website](https://flycellatlas.org) and save them as
`./data/h5ad/[tissue].h5ad` . Please note that:

- Please replace spaces with underscores.
e.g., `male_reproductive_organ.h5ad` instead of
`male reproductive organs.h5ad`.
- Some of the links from FlyCellAtlas is wrong and you will end up downloading
a loom file instead of an h5ad file. Please check if you have the correct
format or the script will fail.

Run
`./jobscript/4_extract_cluster_bam_scanpy.R --tissue=[tissue]` will store cell
barcodes per cluster per library in `data/cbc/[tissue]`.

### 5. Prepare for bam extraction

Run
`./jobscript/5_prepare_table_for_batch_exp.R --tissue=[tissue]`
will prepare a table for bam-per-cluster-per-library extraction.

### 6. Extract bam per library per cluster

Run `./jobscript/6_split_bam.sh [tissue]` to split `cellranger`-aligned bam
files. This step can take long.

### 7. Merge bam files from the same cluster but from different libraries

Some tissues in FlyCellAtlas contain multiple samples, so we need to merge
bam files from the same cluster.

Run `./jobscript/7_prepare_bam_names_to_merge_per_cluster.R --tissue=[tissue]`
to prepare a list of clusters to merge.

Then, run `./jobscript/8_merge_bam_by_cluster.sh [tissue]` to merge.

### 8. De-duplicate by UMI

Unique molecular identifiers (UMIs) help correct quantitative bias in even bulk
RNA-seq (e.g., see [Fu *et al.* 2018](https://bmcgenomics.biomedcentral.com/articles/10.1186/s12864-018-4933-1)).
Therefore, it is favorable to take advantage of UMI information in cluster
pseudobulk if computational resource allows.

Run `./jobscript/9_umi_dedup.sh [tissue]` to start de-duplication. This step
is very resource intensive for larger bam files, so it might need supervision
and troubleshoot even on an HPC.

### 9. Convert de-duplicated bam files to cluster-specific bigwig tracks

For visualization purpose, bigwig files are lighter than bam files. Run
`./jobscript/10_prepare_bw_convert_list.R --tissue=[tissue]` to prepare, and
then run `./jobscript/11_to_bw.sh [tissue]` to start conversion.

Since the library construction in 10X Genomics platform preserves some strand
information that bigwig format is not representing, two bigwig files
respectively storing forward and reverse strand coverage will be saved in
`export_bw/[tissue]`.

## Testing

You can find the script I used to test in `test_run.sh`. Please note that the
test file is manually run step-by-step. It won't wait for `slurm` jobs to
complete so if it is executed, the pipeline will fail.