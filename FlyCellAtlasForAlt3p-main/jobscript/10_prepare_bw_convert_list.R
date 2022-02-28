#!/usr/bin/env Rscript
# This script generates a list of bam files to
# convert to bw files
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

# Get a list of deduplicated bam files to convert to bigwig tracks
bam <- list.files(
  paste0(
    "export_bam/",
    tissue
  ), pattern = "^dedup.*bam$"
)

# Remove file name extensions
base_name <- sub("\\.bam", "", bam)


# Create a table in which
# bam = the path to a deduped bam to convert
# fout = the forward-strand bigwig output path
# rout = the reverse-strand bigwig output path
out_tbl <- data.frame(
  bam = paste0("export_bam/", tissue, "/", bam),
  fout = paste0("export_bw/", tissue, "/", base_name, "_f.bw"),
  rout = paste0("export_bw/", tissue, "/", base_name, "_r.bw")
)

# Create a directory to store converted files
dir.create(
  path = paste0(
    "export_bw/",
    tissue
  ),
  recursive = TRUE
)

# Save the table and prepare for conversion
write.table(
  out_tbl,
  paste0(
    "export_bam/",
    tissue,
    "_to_bw.txt"
  ),
  sep = "\t",
  row.names = FALSE,
  col.names = FALSE,
  quote = FALSE
)
