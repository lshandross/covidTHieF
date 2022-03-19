compute_base_forecasts <-
  function(temporal_hierarchy, pi_levels = c(10 * (1:9), 95, 98)) {
    library(tidyverse)
    library(forecast)
    library(thief)
    
    # if temporal_hierarchy == NULL
    temporal_hierarchy <- temporal_hierarchy
    pi_levels <- pi_levels
    base_forecasts <- list()
    for(i in seq_along(temporal_hierarchy)){
      base_forecasts[[i]] <- 
        forecast(auto.arima(temporal_hierarchy[[i]]), 
                 h=frequency(temporal_hierarchy[[i]])*2, # necessary to avoid top-level producing NAs
                 level = pi_levels)
    }
    #return(base_forecasts)
    base_forecasts
  }
