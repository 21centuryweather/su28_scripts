
template <- r"(
#!/bin/bash

#PBS -P gb02
#PBS -q normal
#PBS -l ncpus=12
#PBS -l mem=48GB
#PBS -l walltime=03:00:00
#PBS -l wd
#PBS -l jobfs=100GB
#PBS -o logs/
#PBS -e logs/
#PBS -l storage=gdata/jt48+gdata/su28+gdata/gb02+scratch/gb02
#PBS -N climpact_{dataset}

# Load module, always specify version number.
module load R/4.3.1
module load cdo/2.4.3

# Run R application

cd /g/data/su28/tools/su28_scripts/FROGS_indeces/

Rscript calculate_indices.R {dataset} {idate} {edate} 12 > logs/climpact_{dataset}.log
)"


dataset_list <- basename(Sys.glob("/g/data/jt48/aus-ref-clim-data-nci/frogs/data/1DD_V1/*"))


for (dataset in dataset_list) {
  script <- glue::glue(here::here("pbs/build_{dataset}.sh"))
  
  idate <- 2001
  edate <- 2013
  
  writeLines(glue::glue(template), script)
  system(glue::glue("qsub {script}"))
  
  message(paste(dataset, "submited."))
}
