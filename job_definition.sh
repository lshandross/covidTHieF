#!/bin/bash
#BSUB -n 16 # how many cores we want for our job
#BSUB -R span[hosts=1] # ask for all the cores on a single machine
#BSUB -R rusage[mem=6000] # ask for memory
#BSUB -o job_log.out # log LSF output to a file
#BSUB -W 4:00 # run time (hh:mm)
#BSUB -q short  # which queue we want to run in
 
module load R/4.1.1
module load xz/5.2.3
module load binutils/2.37
module load cmake/3.17.3
module load bzip2/1.0.6_fPIC_lib
module load pcre/8.40
module load libtool/2.4.6

R CMD BATCH --vanilla '--args linux 16 generate_forecasts sarima 1 47' inst/generate_forecasts.R
