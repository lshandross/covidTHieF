covid_thief <- 
  function(df, ts_col, start_date, end_date, fips_vec, aggregate_levels, frequency, pi_levels) {
    library(tidyverse)
    library(lubridate)
    
    all_locs_df <- map_dfr(
      .x = fips_vec,
      .f = function(fips_code) {
        thief_wrapper(df, ts_col, start_date, end_date, fips_code, aggregate_levels, frequency, pi_levels, plot.aggregates = FALSE, plot.forecasts = FALSE) 
      }
    )
    return(all_locs_df)
  }
  