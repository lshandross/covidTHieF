transform_to_hub_df <- function(forecast_list, model_name = "model", end_date, fips_code, pi_levels) {
  library(tidyverse)
  library(lubridate)
  library(forecast)
  library(thief)
  library(covidHubUtils)
  
  # If forecast_list == NULL, stop "you have not provided any forecasts"
  # if forecast_list is not a a data frames, stop "Please provide a a data frames"
  # if fips_code == NULL, stop "you have not provided a"
  # if fips_code! %in% state_fips_codes, stop "Please provide the fips code of a US location"
    
  thief_forecast <- forecast_list
  model_name <- model_name
  fips_code <- fips_code

  # Lower Forecasts
  low_fc <- as_tibble(thief_forecast[[1]][["lower"]]) # Change TS object to tibble
  low_fc[low_fc < 0] <- 0 # Ensure all negative values are changed to 0
    
  old_col_names <- colnames(low_fc)
  new_col_names <- rep("string", length(old_col_names))
  for (i in 1:length(old_col_names)) {
    new_col_names[i] <- as.character(((100-pi_levels[i])/2)/100)
  }
  colnames(low_fc) <- c(new_col_names)
  
  # Higher Forecasts
  high_fc <- as_tibble(thief_forecast[[1]][["upper"]]) # Change TS object to tibble
  high_fc[high_fc < 0] <- 0 # Ensure all negative values are changed to 0
    
  old_col_names <- colnames(high_fc)
  new_col_names <- rep("string", length(old_col_names))
  for (i in 1:length(old_col_names)) {
    new_col_names[i] <- as.character((100-((100-pi_levels[i])/2))/100)
  }
  colnames(high_fc) <- c(new_col_names)
  
  
  # Point Forecasts
  point_fc <- as_tibble(thief_forecast[[1]][["mean"]]) %>% # Change TS object to tibble
    transmute(`0.5`= as.numeric(x))
  point_fc[point_fc < 0] <- 0 # Ensure all negative values are changed to 0


  # Join forecasts together
  hub_df <- cbind(low_fc, point_fc, high_fc) %>%
    mutate(forecast_date = end_date, 
           horizon = as.numeric(rownames(low_fc)),
           temporal_resolution = "day",
           target_end_date = forecast_date + days(horizon)) %>%
    pivot_longer(1:(2*length(pi_levels) + 1), "quantile", "value") %>%
    arrange(target_end_date, quantile) %>%
    mutate(model = model_name,
           location = fips_code, 
           type = "quantile",
           target_variable = "inc hosp",
           quantile = as.numeric(quantile)) %>%
    select(model, location, forecast_date, horizon, temporal_resolution, 
           target_variable, target_end_date, type, quantile, value) %>%
    filter(horizon <= 35) %>%
    left_join(filter(hub_locations, fips == fips_code), by = c("location" = "fips"))
  
    hub_df

}
