aggregate_thief_df <- # aggregate levels list should be in order of smallest to largest level
  function(df, ts_col = "value", start_date, end_date, fips_code, aggregate_levels = list(56, 28, 14, 7, 1), frequency = 56, transform.4root = FALSE) {
    library(tidyverse)
    library(lubridate)
    library(thief)
    
    # If df == NULL, stop "you have not provided a data frame"
    # if df is not a a data frames, stop "Please provide a a data frames"
    ts_col <- ts_col
    # if fips_code == NULL, stop "you have not provided a fips code", else
    fips_code <- fips_code
    # if fips_code! %in% state_fips_codes, stop "Please provide the fips code of a US location"
    # if (start_date == NULL) # first target_end_date, else
    start_date <- as.Date(start_date)
    # likewise for end_date, else
    end_date <- as.Date(end_date)
    
    agg_list <- aggregate_levels
    freq <- frequency
    
    hosp_truth <- df %>%
      dplyr::filter(target_end_date >= start_date,
                    target_end_date <= end_date,
                    location == fips_code) %>%
      arrange(target_end_date)

      # Construct time series      
      time_period <- as.numeric(end_date - start_date) + 1
      periods <- floor(time_period / freq)
      remainder <- time_period - (periods * freq)

      if (transform.4root == TRUE) {
        hosp_values <- pull(hosp_truth, ts_col)^0.25
      } else {
        hosp_values <- pull(hosp_truth, ts_col)
      }
      ht_day_ts_ <- ts(hosp_values, # difference
                       start = c(1, 1), end = c(periods+1, remainder), # difference
                       frequency = freq)
      
      # Construct temporal hierarchy
      day_agg_ <- tsaggregates(ht_day_ts_, m = freq, aggregatelist = agg_list)
      agg.names <- c("daily", "weekly", "2-weekly", "4-weekly", "8-weekly")
      for(i in seq_along(day_agg_)) { 
        names(day_agg_)[[i]] <- agg.names[i] 
      }
      
      return(day_agg_) # difference
  }


