#!/usr/bin/env Rscript
# This scripts prepare a meta file
# That provides:
# 1. Where the cbc files are
# 2. Which bam to extract from
# 3. Which path to store the output

suppressPackageStartupMessages(library(R.utils))
library(methods)

# Read arguments from commandline
commandline_input <- commandArgs(asValues = TRUE, trailingOnly = TRUE)

# Check if commandline arguments is provided
if (!"tissue" %in% names(commandline_input)) {
  stop(
    paste0(
      "Please provide tissue name via --tissue=[tissue name]\n",
      "(e.g., --tissue='head').\n",
      "=====================================================\n",
      "Please note that the following files are expected:\n",
      "Sample list at data/fastq/[tissue]/samplelist.txt;\n",
      "CellRanger outputs under data/fastq/[tissue]/."
    )
  )
}

if ("debug" %in% names(commandline_input)) {
  # Print out captured command line arguments
  print(commandline_input)
}

# Get tissue information from command line
tissue <- gsub(" ", "_", commandline_input$tissue)

# Get sample name length from the sample name list
samplelist_path <- paste0(
  "./data/fastq/", tissue, "/samplelist.txt"
)

# Check if sample list exists
if (!file.exists(samplelist_path)) {
  stop(
    paste0(
      "Cannot find ", samplelist_path,
      ". Did you generate a sample list with get_sample_list.sh?"
    )
  )
}

# Load sample list and check names
samplelist <- readLines(samplelist_path)
# Split sample names by underscore and count
sample_name_split <- strsplit(samplelist[1], "_")
sample_name_length <- length(unlist(sample_name_split))

# Checking for cell barcodes per cluster
cbc_path <- paste0("data/cbc/", tissue)

# List the cbc files
ind_cbc <- list.files(
  cbc_path,
  full.names = TRUE
)

# Check if cell barcode files are found
if (!dir.exists(cbc_path) | length(ind_cbc) == 0) {
  stop(
    paste0(
      "Cannot find cbc files under", cbc_path, "."
    )
  )
}

# Create output bam path by cluster
outfile <- sapply(
  # Cluster name is expected at the 4th field
  # if split by slashes ("/")
  # e.g., data/cbc/head/[cluster].txt
  strsplit(ind_cbc, "/"),
  function(x) sub("\\.txt", "", x[4])
)

outpath <- paste0(
  "export_bam/",
  tissue,
  "/",
  outfile,
  ".bam"
)

# Create bam path to split
# *They are the output from CellRanger
bam_p <- paste0(
  "data/bam/",
  tissue,
  "/",
  sapply(
    strsplit(outfile, "_"),
    function(x) paste(x[1:sample_name_length], collapse = "_")
  ),
  "/outs/",
  "possorted_genome_bam.bam"
)

# Generate a table for later use in which
# cbc = txt files containing cell barcodes
# bam = path to CellRanger bam
# out = path to sort per cluster bam per library
out_tbl <- data.frame(
  cbc = ind_cbc,
  bam = bam_p,
  out = outpath
)

# Create a directory to store splitted bam files
message(
  paste0(
    "Creating an output directory at ",
    "export_bam/", tissue
  )
)
dir.create(
  paste0(
    "export_bam/",
    tissue
  )
)

write.table(
  out_tbl,
  paste0(
    "data/",
    tissue,
    "_bam_extract.txt"
  ),
  sep = "\t",
  col.names = FALSE,
  row.names = FALSE,
  quote = FALSE
)
