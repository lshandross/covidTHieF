#' Compute temporal hierarchical (base) forecasts
#'
#' @param temporal_hierarchy A list of (hierarchical) time series.
#' @param pi_levels A vector of prediction interval levels to calculate. Defaults to the levels that correspond to the 23 US Forecast Hub-specified quantiles.
#'
#' @return An object of class \code{forecast}.
#' @export
#'
#' @examples
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
    return(base_forecasts)
  }
