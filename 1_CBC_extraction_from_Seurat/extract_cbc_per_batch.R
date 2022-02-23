library(Seurat)

object_list <- list.files("ObjectsForSubmission/")

for (object in object_list) {
  # Generate object file path for loading
  objpath <- paste0(
    "ObjectsForSubmission/",
    object
  )
  
  # Load objects
  finalobj <- readRDS(objpath)
  
  # Read cell barcodes
  cbc <- row.names(finalobj@meta.data)
  
  # Split cell barcodes and suffix
  cbc_list <- strsplit(cbc,
                       split = "_")
  
  # Decide which one is batch number
  first_item <- as.numeric(cbc_list[[1]])
  batch_id <- which(!is.na(first_item))
  cbc_id <- which(is.na(first_item))
  
  # Make barcodes and suffix a data.frame
  cbc_df <- data.frame(
    cbc = sapply(cbc_list, function(x) x[[cbc_id]]),
    suffix = sapply(cbc_list, function(x) x[[batch_id]])
  )
  
  # Split CBC by batch
  cbc_batch <- split(cbc_df$cbc,
                     cbc_df$suffix)
  
  # Save cbc per barch
  for (cbc_name in names(cbc_batch)) {
    cbc_to_save <- cbc_batch[[cbc_name]]
    file_name <- paste0(sub("\\.rds", "", object),
                        "_",
                        cbc_name,
                        ".txt")
    save_path <- paste0("int/cbc_per_batch/", file_name)
    writeLines(cbc_to_save, save_path)
  }
  
}

