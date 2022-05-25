covid_thief <- 
  function(df = NULL, ts_col = "value", start_date, end_date, fips_vec, aggregate_levels, frequency, pi_levels, transform.4root = FALSE) {
    library(tidyverse)
    library(lubridate)
    
    if (is.null(df)) {
      df <- load_truth("HealthData", 
                         "inc hosp", 
                         as_of = end_date,
                         temporal_resolution="daily",
                         data_location = "covidData")
    } else {
      df <- df
      warning("forecasts will be based on static truth data")
    }
    
    all_locs_list <- map(
      .x = fips_vec,
      .f = function(fips_code) {
        suppressWarnings(thief_wrapper(df=NULL, ts_col, start_date, end_date, fips_code, aggregate_levels, frequency, pi_levels, plot.aggregates = FALSE, plot.forecasts = FALSE, transform.4root))
      }
    )
    n <- length(fips_vec)
    all_locs_fc <- map_dfr(.x = 1:n, .f = function(i) {all_locs_list[[i]][[1]]})
    all_locs_mod <- map_dfr(.x = 1:n, .f = function(i) {all_locs_list[[i]][[2]]})
    
    return(list(all_locs_fc, all_locs_mod))
  }
  