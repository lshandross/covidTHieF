#' (Seasonal) ARIMA forecasting for COVID-19 incident hospitalizations for multiple locations
#'
#' @param df A data frame containing the desired truth data as one of the columns. Used to create the forecasts. Defaults to NULL in which hospitalization truth data is sourced as of the user-specified \code{end_date}.
#' @param ts_col The name of the column containing the truth data. This column is coerced into a time series object of class \code{ts} and thus should be a numeric type.
#' @param start_date A date from which the truth data begins.
#' @param end_date A date where the truth data ends and the forecasts begin. If \code{df=NULL}, also specifies the date from which the hospitalization truth data sourced.
#' @param fips_vec A vector of one or more 2-digit codes specifying a United States state or territory, of class \code{char}.
#' @param frequency Integer seasonal period. Defaults to a value of 1, indicating no seasonality.
#' @param pi_levels A vector of prediction interval levels to calculate.
#' @param transform.4root \code{logical} that specifies whether a variance stabilizing fourth root transformation should be performed on the data. (This data transformation is undone after all of the forecasts are reconciled and re-formatted into a data frame.)
#'
#' @return A list with a number of items equivalent to the length of \code{fips_vec}. Each item is also a list that contains the following two elements: a data frame containing COVID-19 incident hospitalization forecasts with a US COVID-19 Forecast Hub format and a data frame containing the forecast object with other relevant identifying information.
#' @export
#'
#' @examples
covid_sarima <-
  function(df = NULL, ts_col = "value", start_date, end_date, fips_vec, frequency = 1, pi_levels, transform.4root = FALSE) {
    library(tidyverse)
    library(lubridate)
    library(covidHubUtils)
    
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
    
    # obtain most recent date truth data was obtained from
    most_recent_date <- df %>%
      slice_max(target_end_date, n=1, with_ties=FALSE) %>%
      pull(target_end_date)
    if (as.numeric(end_date - most_recent_date) > 1) {
      warning(paste("Forecasts will be made as of", most_recent_date + 1, "due to insufficient truth data."))
    }

    all_locs_list <- map(
      .x = fips_vec,
      .f = function(fips_code) {
        suppressWarnings(sarima_wrapper(df=NULL, ts_col, start_date, end_date, fips_code, frequency, pi_levels, plot.forecasts = FALSE, transform.4root))
      }
    )
    n <- length(fips_vec)
    all_locs_fc <- map_dfr(.x = 1:n, .f = function(i) {all_locs_list[[i]][[1]]})
    all_locs_mod <- map_dfr(.x = 1:n, .f = function(i) {all_locs_list[[i]][[2]]})

    return(list(all_locs_fc, all_locs_mod))
  }