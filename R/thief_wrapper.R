#' Temporal hierarchical forecasting for COVID-19 incident hospitalizations for a single location
#'
#' @param df A data frame containing the desired truth data as one of the columns. Used to create the forecasts. Defaults to NULL in which hospitalization truth data is sourced as of the user-specified \code{end_date}.
#' @param ts_col The name of the column containing the truth data. This column is coerced into a time series object of class \code{ts} and thus should be a numeric type.
#' @param start_date A date from which the truth data begins.
#' @param end_date A date where the truth data ends and the forecasts begin. If \code{df=NULL}, also specifies the date from which the hospitalization truth data sourced.
#' @param fips_code A 2-digit code specifying a United States state or territory of type \code{char}.
#' @param aggregate_levels A user-selected list of aggregates to use.
#' @param frequency Integer seasonal period.
#' @param pi_levels A vector of prediction interval levels to calculate.
#' @param plot.aggregates \code{logical} that specifies whether a plot of the aggregated original time series should be generated.
#' @param plot.forecasts \code{logical} that specifies whether a collection of plots of the forecasts should be generated.
#' @param transform.4root \code{logical} that specifies whether a variance stabilizing fourth root transformation should be performed on the data. (This data transformation is undone after all of the forecasts are reconciled and re-formatted into a data frame.)
#'
#' @return A list containing two items: a data frame containing COVID-19 incident hospitalization forecasts with a US COVID-19 Forecast Hub format and a data frame containing the base forecast object and the reconciled forecast object with other relevant identifying information.
#' @export
#'
#' @examples
thief_wrapper <-
  function(df = NULL, ts_col = "value", start_date, end_date, fips_code, aggregate_levels, frequency, pi_levels, plot.aggregates = TRUE, plot.forecasts = TRUE, transform.4root = FALSE) {
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

    # obtain most recent date truth data was obtained from
    most_recent_date <- df %>%
      slice_max(target_end_date, n=1, with_ties=FALSE) %>%
      pull(target_end_date)
    if (as.numeric(end_date - most_recent_date) > 1) {
      warning(paste("Forecasts will be made as of", most_recent_date + 1, "due to insufficient truth data."))
    }
    h_ahead <- 35 + (as.numeric(end_date - most_recent_date) + 1)
    
    thief_aggregation <- 
      suppressWarnings(aggregate_thief_df(df, ts_col, start_date, end_date, fips_code, aggregate_levels, NULL, frequency, transform.4root))

    if (plot.aggregates == TRUE) {plot_thief_agg(thief_aggregation, start_date) }

    base_fc <- compute_base_forecasts(thief_aggregation, pi_levels)
    reconciled_fc <- reconcilethief(base_fc, aggregatelist = aggregate_levels)

    if (plot.forecasts == TRUE) {
      extended_agg <- extended_truth_data(df, ts_col, start_date, end_date, fips_code, aggregate_levels, frequency)
      ts_dates <- get_ts_dates(start_date, most_recent_date, frequency = 56)
      plot_thief(base_fc, reconciled_fc, ts_dates, extended_agg, NULL)
    }

    hub_df <- transform_to_hub_df(reconciled_fc, most_recent_date, fips_code, pi_levels, h_ahead, transform.4root)
    model_info <- tibble(forecast_date = most_recent_date + 1, location = fips_code, level = aggregate_levels,
                         base_fc_obj = base_fc, rec_fc_obj = reconciled_fc)

    return(list(hub_df, model_info))
  }
