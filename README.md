# covidTHieF

<!-- badges: start -->
[![R-CMD-check](https://github.com/lshandross/covidTHieF/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/lshandross/covidTHieF/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

This repository contains the data and code for the following paper:
> Li Shandross, Evan L. Ray, Benjamin W. Rogers, Nicholas G. Reich. Forecasting COVID-19 Hospitalizations with Temporal Hierarchies. *medRxiv: The pre-print server for health sciences* (2025). doi: https://doi.org/10.1101/2025.06.26.25330355

## Contents

The R Weave source document `covid_thief.Rmd` (as well as a fully rendered version suitable for reading), can be found in the [:file_folder: paper](/analysis/paper) directory. Figures can also be found here.

The data used in this analysis can be found within the [:file_folder: data](/data) directory. Predictions are stored both as R data objects and individual CSV files for the THieF and ARIMA models in named directories.

Functions used to generate the forecasts can be found in the [:file_folder: R](/R) directory.

## Setup

The code for this paper has been written using the statistical programming language R. We use a combination of renv (for package versioning) and targets (for a system agnostic make-like pipeline) to build the manuscript and supplement.

Begin by setting up the development environment by running the following command in an R session in the project:
```
renv::restore()
```

Next, run the targets pipeline with the following command (note this does not render the manuscript):
```
targets::tar_make()
```

To build the manuscript, open the source file `analysis/paper/covid_thief.rnw` in RStudio and click the render button. (The supplement can be built in the same way, or using `rmarkdown::render("analysis/paper/covid_thief_supplement.rmd")`.)
