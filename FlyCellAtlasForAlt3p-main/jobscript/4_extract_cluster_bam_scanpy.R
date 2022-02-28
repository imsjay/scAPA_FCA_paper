#!/usr/bin/env Rscript
# This script uses reticulate to read .h5ad files from FlyCellAtlas.
# While SeuratDisk provides similar functinality, there might have been
# version differences from AnnData package in Python, so SeuratDisk
# fails to convert many of the FlyCellAtlas h5ad files.

suppressPackageStartupMessages(library(R.utils))
library(methods)
library(reticulate)

# Read arguments from commandline
commandline_input <- commandArgs(asValues = TRUE, trailingOnly = TRUE)

# Check if commandline arguments is provided
if (!"tissue" %in% names(commandline_input)) {
  stop(
    paste0(
      "Please provide tissue name via --tissue=[tissue name]\n",
      "(e.g., --tissue='head').\n",
      "The .h5ad file is expected in data/h5ad/[tissue].h5ad."
    )
  )
}

if ("debug" %in% names(commandline_input)) {
  # Print out captured command line arguments
  print(commandline_input)
}

# Get tissue information from command line
tissue <- gsub(" ", "_", commandline_input$tissue)
print(tissue)

# Throw an error if the h5ad file is not found
h5adpath <- paste0("data/h5ad/", tissue, ".h5ad")

if (!file.exists(h5adpath)) {
  stop(
    paste0(
      "Cannot find ", h5adpath,
      ". Did you downloaded it from FlyCellAtlas and ",
      "put it in the above path?"
    )
  )
}

# Load scanpy from python
message("Start loading scanpy...")
sc <- import("scanpy", convert = FALSE)

# Load h5ad
message("Load h5ad object...")
tissueobj <- sc$read_h5ad(h5adpath)

# If with --test flag, point output folder with a _mock suffix
# to prevent overwriting in test runs.
if ("test" %in% names(commandline_input)) {
  tissue <- paste(tissue, "test")
}

# Extract obs attribute to extract cell barcodes by cluster
meta_tbl <- py_to_r(tissueobj$obs)

# Sample identity (for correspondence with the bam files stored on ArrayExpress)
# They are stored in the row.names of the meta.data
# CBC and metadata are split by __
# Example: AAACCCACACGGCGTT-6e669170__FCA59_Male_ovary_adult_1dWT_Fuller_sample1
message("Process cell barcodes per cluster")
sample_id <- vapply(
  strsplit(row.names(meta_tbl), split = "__"),
  function(x) x[2],
  FUN.VALUE = character(1)
)

# Also keep CBCs for later use to split bam files by identity
cbc <- vapply(
  strsplit(row.names(meta_tbl), split = "__"),
  function(x) x[1],
  FUN.VALUE = character(1)
)

# Remove hash and keep barcode sequence only
# Example: AACAACCTCTAGTGAC-6e853dd2
# Remove things after the hyphen
cbc <- vapply(
  strsplit(cbc, split = "-"),
  function(x) x[1],
  FUN.VALUE = character(1)
)

# Take cluser identity from the meta.data
ann <- as.character(meta_tbl$annotation)

# Prepare a factor for later splitting cell barcodes by
# cluster and library
to_split <- paste(sample_id, ann, sep = "_")

# Split and write cbc file
cbc_split <- split(cbc, to_split)

## Deal with special characters in cluster names
## Rename all special characters to underscores ("_")
names(cbc_split) <- gsub(" ", "_", names(cbc_split))
names(cbc_split) <- gsub(",", "_", names(cbc_split))
names(cbc_split) <- gsub("/", "_", names(cbc_split))
names(cbc_split) <- gsub("\\*", "_asterisk", names(cbc_split))
names(cbc_split) <- gsub("\\+", "_plus", names(cbc_split))

# Remove cell barcodes that were not assigned an identity in FlyCellAtlas
cbc_split <- cbc_split[!grepl("^NA", names(cbc_split))]

# The cell barcodes per cluster are stored as a txt file
# per cluster in ./data/cbc
cbc_path <- paste0("data/cbc/", tissue)
message(
  paste0("Saving cell barcodes to ", cbc_path)
)
dir.create(cbc_path)

# Save cell barcode per cluster to the assigned path
for (item in names(cbc_split)) {
  writeLines(
    cbc_split[[item]],
    paste0("data/cbc/", tissue, "/", item, ".txt")
  )
}
