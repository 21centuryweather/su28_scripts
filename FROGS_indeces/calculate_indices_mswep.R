# ------------------------------------------------
# Rx1day
# ------------------------------------------------

library(climdex.pcic.ncdf)
library(rcdo)
library(metR)

args <- commandArgs(trailingOnly = TRUE)

dataset <- "mswep"
idate <- 2001
edate <- 2013
cores <- 12

file_list <- Sys.glob(paste0("/g/data/jt48/aus-ref-clim-data-nci/", dataset, "/data/day/*.nc"))

grid <- "/g/data/jt48/aus-ref-clim-data-nci/frogs/data/1DD_V1/IMERG_V07B_FC/IMERG_V07B_FC.1DD.2019.nc"

future::plan(future::multisession, workers = 6)

temp_file <- furrr::future_map(file_list, function(f) {
  cdo_remapbil(f, grid) |> 
    cdo_execute(options = "-L")
}) |> 
  cdo_mergetime() |> 
  cdo_chname(oldname = "precipitation", newname = "rain") |> 
  cdo_setattribute(attributes = 'rain@units="kg m-2 d-1"') |>
  cdo_execute(options = "-L")

infiles <- temp_file

# list of variable names according to above file(s)
vars <- c(prec = "rain", tmax = "tmax", tmin = "tmin")

# output directory. Will be created if it does not exist.
outdir <- "/g/data/su28/FROGS_indeces_TEMP"

# Output filename format. Must use CMIP5 filename convention. i.e. "var_timeresolution_model_scenario_run_starttime-endtime.nc"
file.template <- paste0("var_daily_", dataset, "_historical_NA_2000-2023.nc")

# author data
author.data <- list(institution = "21st Century Weather")

# reference period
base.range <- c(idate, edate)

# list of indices to calculate, or NULL to calculate all.
indices <- c("rx1day", "rx5day", "sdii", "r10mm", "r20mm", "cdd", "cwd", "r95p", "r99p", "prcptot",
             "rxdday", "rnnmm", "r95ptot", "r99ptot", "spei", "spi")	#c("hw","tnn")

# input threshold file to use, or NULL for none.
# thresholds.files <- paste0("/g/data/su28/FROGS_indeces_TEMP/thresholds/thresholds_", dataset, "_", paste0(base.range, collapse = "-"), ".nc")
thresholds.files <- NULL

# Directory where Climpact is stored. Use full pathname. Leave as NULL if you are running this script from the Climpact directory (where this script was initially stored).
root.dir <- "/g/data/su28/tools/climpact-master/"


#######################################################
# Esoterics below, do not modify without a good reason.

# definition used for Excess Heat Factor (EHF). "PA13" for Perkins and Alexander (2013). "NF13" for Nairn and Fawcett (2013), this is the default.
EHF_DEF <- "NF13"

# axis to split data on. For chunking up of grid, leave this.
axis.name <- "Y"

# Number of data values to process at once. If you receive "Error: rows.per.slice >= 1 is not TRUE", try increasing this to 20. You might have a large grid.
maxvals <- 10

# output compatible with FCLIMDEX. Leave this.
fclimdex.compatible <- FALSE

# Call the package.
create.indices.from.files(root.dir,
                          infiles,
                          outdir,
                          file.template,
                          author.data,
                          climdex.vars.subset = indices,
                          climdex.time.resolution = c("all", "annual", "monthly"),
                          variable.name.map = vars,
                          axis.to.split.on = axis.name,
                          fclimdex.compatible = fclimdex.compatible,
                          base.range = base.range,
                          parallel = cores,
                          verbose = TRUE,
                          thresholds.files = thresholds.files,
                          thresholds.name.map = c(r95thresh = "r95thresh", r99thresh = "r99thresh"),
                          max.vals.millions = maxvals,
                          cluster.type = "SOCK",
                          rxnday_n = 7, #rx7day
                          rnnmm_n = 30, #r20mm
                          ehfdef = EHF_DEF
)


# Fix file names
file_list <- Sys.glob(paste0(outdir, "/*", dataset, "*"))

purrr::map(file_list, function(f) {
  
  meta <- unglue::unglue(basename(f), "{i}_{freq}_{dataset}_{idate}-{edate}.nc")
  
  newname <- paste0(outdir, "/", meta[[1]][["i"]], "_", meta[[1]][["freq"]], "_", dataset, "_", paste0(base.range, collapse = "-"), ".nc")
  
  file.rename(f, newname)
})
