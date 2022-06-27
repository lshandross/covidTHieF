#' Creation of time series object of COVID-19 truth data stored as a data frame
#'
#' @param df A data frame containing the desired truth data as one of the columns. Defaults to NULL in which hospitalization truth data is sourced as of the user-specified \code{end_date}.
#' @param ts_col The name of the column containing the truth data. This column is coerced into a time series object of class \code{ts} and thus should be a numeric type.
#' @param start_date A date from which the data begins.
#' @param end_date A date where the data ends. If \code{df=NULL}, also specifies the date from which the hospitalization truth data sourced.
#' @param fips_code A 2-digit code specifying a United States state or territory of type \code{char}.
#' @param frequency Integer seasonal period. Defaults to a value of 1, indicating no seasonality.
#' @param transform.4root \code{logical} that specifies whether a variance stabilizing fourth root transformation should be performed on the data.
#'
#' @return A time series \code{ts} object made by coercing the original truth data into a time series format.
#' @export
#'
#' @examples
get_truth_ts <-
  function(df = NULL, ts_col = "value", start_date, end_date, fips_code, frequency = 1, transform.4root = FALSE) {
    library(tidyverse)
    library(lubridate)
    library(thief)
    library(covidHubUtils)
    
    ts_col <- ts_col
    
    if (fips_code %in% dplyr::pull(hub_locations, fips)) { 
      fips_code <- fips_code
    } else {
      stop("Please provide a US location fips code.")
    }
    # if (start_date == NULL) # first target_end_date, else
    start_date <- as.Date(start_date)
    # likewise for end_date, else
    end_date <- as.Date(end_date)

    if (is.null(df)) {
      df <- load_truth("HealthData",
                         "inc hosp",
                         as_of = end_date,
                         temporal_resolution="daily",
                         data_location = "covidData")
    } else {
      df <- df
      warning("Forecasts will be based on static truth data")
    }

    # obtain most recent date truth data was obtained from
    most_recent_date <- df %>%
      slice_max(target_end_date, n=1, with_ties=FALSE) %>%
      pull(target_end_date)
    if (as.numeric(end_date - most_recent_date) > 1) {
      warning(paste("Forecasts will be made as of", most_recent_date + 1, "due to insufficient truth data."))
    }
    
    hosp_truth <- df %>%
      dplyr::filter(target_end_date >= start_date,
                    target_end_date <= most_recent_date,
                    location == fips_code) %>%
      arrange(target_end_date)

      # Construct time series
      time_period <- as.numeric(most_recent_date - start_date) + 1
      periods <- floor(time_period / frequency)
      remainder <- time_period - (periods * frequency)

      if (transform.4root == TRUE) {
        hosp_values <- pull(hosp_truth, ts_col)^0.25
      } else {
        hosp_values <- pull(hosp_truth, ts_col)
      }
      ht_day_ts_ <- ts(hosp_values,
                       start = c(1, 1), end = c(periods+1, remainder),
                       frequency = frequency)
      
      return(ht_day_ts_)
  }
    
#' (Seasonal) ARIMA forecasting for COVID-19 incident hospitalizations for a single location
#'
#' @param df A data frame containing the desired truth data as one of the columns. Used to create the forecasts. Defaults to NULL in which hospitalization truth data is sourced as of the user-specified \code{end_date}.
#' @param ts_col The name of the column containing the truth data. This column is coerced into a time series object of class \code{ts} and thus should be a numeric type.
#' @param start_date A date from which the truth data begins.
#' @param end_date A date where the truth data ends and the forecasts begin. If \code{df=NULL}, also specifies the date from which the hospitalization truth data sourced.
#' @param fips_code A 2-digit code specifying a United States state or territory of type \code{char}.
#' @param frequency Integer seasonal period. Defaults to a value of 1, indicating no seasonality.
#' @param pi_levels A vector of prediction interval levels to calculate.
#' @param plot.ts \code{logical} that specifies whether a plot of the original time series should be generated.
#' @param plot.forecasts \code{logical} that specifies whether a plot of the forecasts should be generated.
#' @param transform.4root \code{logical} that specifies whether a variance stabilizing fourth root transformation should be performed on the data. (This data transformation is undone after all of the forecasts are re-formatted into a data frame.)
#'
#' @return A list containing two items: a data frame containing COVID-19 incident hospitalization forecasts with a US COVID-19 Forecast Hub format and a data frame containing the base forecast object with other relevant identifying information.
#' @export
#'
#' @examples

sarima_wrapper <-
  function(df = NULL, ts_col = "value", start_date, end_date, fips_code, frequency = 1, pi_levels, plot.forecasts = TRUE, transform.4root = FALSE) {
    library(tidyverse)
    library(lubridate)
    library(covidHubUtils)

    ts_col <- ts_col
    
    if (fips_code %in% dplyr::pull(hub_locations, fips)) { 
      fips_code <- fips_code
    } else {
      stop("Please provide a US location fips code.")
    }
    # if (start_date == NULL) # first target_end_date, else
    start_date <- as.Date(start_date)
    # likewise for end_date, else
    end_date <- as.Date(end_date)
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

    # obtain most recent date truth data was obtained from
    most_recent_date <- df %>%
      slice_max(target_end_date, n=1, with_ties=FALSE) %>%
      pull(target_end_date)
    if (as.numeric(end_date - most_recent_date) > 1) {
      warning(paste("Forecasts will be made as of", most_recent_date + 1, "due to insufficient truth data."))
    }
    h_ahead <- 42 + (as.numeric(end_date - most_recent_date) + 1)
    periods <- floor((as.numeric(most_recent_date - start_date) + 1) / frequency)
    
    time_series <- 
      suppressWarnings(get_truth_ts(df, ts_col, start_date, end_date, fips_code, frequency, transform.4root))
      
    #if (plot.ts == TRUE) {plot_thief_agg(thief_aggregation, start_date) }

    forecasts <- forecast(auto.arima(time_series), h=h_ahead, level = pi_levels)

    if (plot.forecasts == TRUE) {
      extended_truth <- 
        suppressWarnings(get_truth_ts(df, ts_col, start_date, end_date + days(h_ahead), fips_code, frequency))
      ts_dates <- get_ts_dates(start_date, most_recent_date, frequency)
      plot(forecasts, shadecols = c("light gray", "#EEC2C2", "#900000"),
          xaxt = "n", #axes = FALSE,
          ylim = c(0, max(forecasts$x, forecasts$upper)))
      lines(forecasts$mean, col="red", lwd=2) # plots red base forecasts line
      if(!is.null(extended_truth)) lines(extended_truth, col='black', lwd=1.5, lty = "dotted") # plots extended truth data against forecasts
      axis(1, at=1: ifelse(periods != length(time_series), periods + 1, periods), labels = ts_dates) # changes axis labels to provided dates
      axis(2)
    }

    hub_df <- transform_to_hub_df(forecasts, most_recent_date, fips_code, pi_levels, h_ahead, transform.4root)
    model_info <- tibble(forecast_date = most_recent_date, location = fips_code, fc_obj = list(forecasts))
      # tibble objects can't have forecasts as a column data type (would have to use tsibble instead)

    return(list(hub_df, model_info))
  }