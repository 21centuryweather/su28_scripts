# Check metadata for all datasets 

dataset_list <- basename(Sys.glob("/g/data/jt48/aus-ref-clim-data-nci/frogs/data/1DD_V1/*"))


meta <- purrr::map(dataset_list, function(d) {
  dataset <- d
  
  message(paste("Checking... ", dataset))
  
  file_list <- Sys.glob(paste0("/g/data/jt48/aus-ref-clim-data-nci/frogs/data/1DD_V1/", dataset, "/*"))
  
  meta <- GlanceNetCDF(file_list[1])
  
  variable <- names(meta$vars)[1]
  
  list(
    dataset = dataset,
    variable = variable,
    unit =meta$vars[[variable]]$units
  )
  
  
}) |> data.table::rbindlist()


# All dataset have "rain" in mm/day --> same preprosessing for all!