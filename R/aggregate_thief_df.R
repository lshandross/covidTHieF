#' Non-overlapping temporal aggregation of COVID-19 truth data stored as a data frame
#'
#' @param df A data frame containing the desired truth data as one of the columns. Defaults to NULL in which hospitalization truth data is sourced as of the user-specified \code{end_date}.
#' @param ts_col The name of the column containing the truth data. This column is coerced into a time series object of class \code{ts} and thus should be a numeric type.
#' @param start_date A date from which the data begins.
#' @param end_date A date where the data ends. If \code{df=NULL}, also specifies the date from which the hospitalization truth data sourced.
#' @param fips_code A 2-digit code specifying a United States state or territory of type \code{char}.
#' @param aggregate_levels A user-selected list of aggregates to use.
#' @param agg.names A vector of names for the aggregation levels. Will be used for any plots generated later split by aggregation level.
#' @param frequency Integer seasonal period.
#' @param transform.4root \code{logical} that specifies whether a variance stabilizing fourth root transformation should be performed on the data.
#'
#' @return A list of time series. The first element is a \code{ts} object made by coercing the original truth data into a time series format, followed by series with increasing levels of aggregation.
#' @export
#'
#' @examples
aggregate_thief_df <- # aggregate levels list should be in order of smallest to largest level
  function(df = NULL, ts_col = "value", start_date, end_date, fips_code, aggregate_levels = list(56, 28, 14, 7, 1), agg.names = c("daily", "weekly", "2-weekly", "4-weekly", "8-weekly"), frequency = 56, transform.4root = FALSE) {
    library(tidyverse)
    library(lubridate)
    library(thief)

    ts_col <- ts_col
    # if fips_code == NULL, stop "you have not provided a fips code", else
    fips_code <- fips_code
    # if fips_code! %in% state_fips_codes, stop "Please provide the fips code of a US location"
    # if (start_date == NULL) # first target_end_date, else
    start_date <- as.Date(start_date)
    # likewise for end_date, else
    end_date <- as.Date(end_date)
    # if df is not a a data frame, stop "Please provide a a data frame"
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
    
    agg_list <- aggregate_levels
    freq <- frequency

    hosp_truth <- df %>%
      dplyr::filter(target_end_date >= start_date,
                    target_end_date <= most_recent_date,
                    location == fips_code) %>%
      arrange(target_end_date)

      # Construct time series
      time_period <- as.numeric(most_recent_date - start_date) + 1
      periods <- floor(time_period / freq)
      remainder <- time_period - (periods * freq)

      if (transform.4root == TRUE) {
        hosp_values <- pull(hosp_truth, ts_col)^0.25
      } else {
        hosp_values <- pull(hosp_truth, ts_col)
      }
      ht_day_ts_ <- ts(hosp_values,
                       start = c(1, 1), end = c(periods+1, remainder),
                       frequency = freq)

      # Construct temporal hierarchy
      day_agg_ <- tsaggregates(ht_day_ts_, m = freq, aggregatelist = agg_list)
      for(i in seq_along(day_agg_)) {
        names(day_agg_)[[i]] <- agg.names[i]
      }

      return(day_agg_)
  }

