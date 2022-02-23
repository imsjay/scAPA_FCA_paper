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
  
  # Split the cell barcodes by cluster identity
  spcbc <- split(
    # Retrieve CBCs from @meta.data
    row.names(finalobj@meta.data), 
    # Retrieve cluster identity and split base on it
    finalobj[["FinalIdents"]]
  )
  
  # Save cell barcodes as text files
  export_path <- paste0(
    "int/cbc_per_cluster/",
    sub("\\.rds", "", object),
    "/"
  )
  
  for (cluster_name in names(spcbc)) {
    writeLines(
      # CBCs
      spcbc[[cluster_name]],
      # Saving path (under ./cbc_per_cluster)
      paste0(
        export_path,
        cluster_name,
        ".txt"
      )
    )
  }
}

