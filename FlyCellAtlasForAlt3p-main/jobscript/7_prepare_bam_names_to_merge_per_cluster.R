#!/usr/bin/env Rscript
# This script prepares a list of individual bam files to merge
# from different libraries but the same cluster
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

# Get the list of individual bam files that pend merging
ind_bam <- list.files(
  paste0("export_bam/", tissue)
)

# Extract cluster label from file names
ind_id <- sapply(
  strsplit(ind_bam, "_"),
  function(x) {
    paste(x[(sample_name_length + 1):length(x)], collapse = "_")
  }
)
uni_id <- unique(ind_id)

# Write unique cluster names to export_bam/[tissue]_idv.txt
message(
  paste0(
    "Writing cluster label list pending merege to: ",
    "export_bam/", tissue, "_idv.txt"
  )
)

writeLines(uni_id,
           paste0(
             "export_bam/",
             tissue,
             "_idv.txt"
           ))
