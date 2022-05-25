thief_wrapper <- 
  function(df = NULL, ts_col = "value", start_date, end_date, fips_code, aggregate_levels, frequency, pi_levels, plot.aggregates = TRUE, plot.forecasts = TRUE, transform.4root = FALSE) {
    library(tidyverse)
    library(lubridate)
    
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

    thief_aggregation <- suppressWarnings(aggregate_thief_df(ts_col, start_date, end_date, fips_code, aggregate_levels, frequency, df))
    
    if (plot.aggregates == TRUE) {plot_thief_agg(thief_aggregation, start_date) }
    
    base_fc <- compute_base_forecasts(thief_aggregation, pi_levels)
    reconciled_fc <- reconcilethief(base_fc, aggregatelist = aggregate_levels)

    if (plot.forecasts == TRUE) {
      extended_agg <- extended_truth_data(df, ts_col, start_date, end_date, fips_code, aggregate_levels, frequency)
      ts_dates <- get_ts_dates(start_date, end_date, frequency = 56)
      plot_thief(base_fc, reconciled_fc, ts_dates, extended_agg)
    }
    
    hub_df <- transform_to_hub_df(reconciled_fc, end_date, fips_code, pi_levels, transform.4root)
    model_info <- tibble(model = model_name, forecast_date = end_date, location = fips_code, 
                         base_fc_obj = base_fc, rec_fc_obj = reconciled_fc)
    
    return(list(hub_df, model_info)) 
  }