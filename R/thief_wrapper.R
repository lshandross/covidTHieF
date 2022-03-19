thief_wrapper <- 
  function(df, ts_col = "value", start_date, end_date, fips_code, aggregate_levels, frequency, pi_levels, model_name, plot.aggregates = TRUE, plot.forecasts = TRUE) {
    library(tidyverse)
    library(lubridate)
    
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
    # if aggregate_levels == NULL, stop "you have not provided any aggregate levels"
    # if pi_levels == NULL, warning "you have not provided any PI levels, using default levels"
    
    thief_aggregation <- aggregate_thief_df(df, ts_col, start_date, end_date, fips_code, aggregate_levels, frequency) 
    if (plot.aggregates == TRUE) {plot_thief_agg(thief_aggregation, start_date) }
    base_fc <- compute_base_forecasts(thief_aggregation, pi_levels)
    reconciled_fc <- reconcilethief(base_fc, aggregatelist = aggregate_levels)

    if (plot.forecasts == TRUE) {
      extended_agg <- extended_truth_data(df, ts_col, start_date, end_date, fips_code, aggregate_levels, frequency)
      ts_dates <- get_ts_dates(start_date, end_date, frequency = 56)
      plot_thief(base_fc, reconciled_fc, ts_dates, extended_agg)
    }
    
    hub_df <- transform_to_hub_df(reconciled_fc, model_name, end_date, fips_code, pi_levels)
    
    return(hub_df) 
  }