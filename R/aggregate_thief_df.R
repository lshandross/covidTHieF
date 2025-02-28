#' Non-overlapping temporal aggregation of COVID-19 truth data stored as a list
#'
#' @param df A data frame containing the desired truth data as one of the
#'   columns. Used to create the forecasts. Defaults to NULL in which
#'   hospitalization truth data is sourced as of the user-specified
#'   \code{end_date}. Must have "target_end_date" and "location" as columns.
#' @param ts_col The name of the column containing the truth data. This column
#'   is coerced into a time series object of class \code{ts} and thus should
#'   be a numeric type.
#' @param start_date A date from which the truth data begins.
#' @param end_date A date where the truth data ends and the forecasts begin.
#'   If \code{df = NULL}, also specifies the date from which the hospitalization
#'   truth data sourced.
#' @param fips_code A 2-digit code specifying a United States state or territory
#'   of type \code{char}.
#' @param aggregate_levels A user-selected list of aggregates to use.
#' @param agg.names A vector of names for the aggregation levels. Will be used
#'   for any plots generated later split by aggregation level. Defaults to NULL.
#' @param frequency Integer seasonal period.
#' @param transform.4root \code{logical} that specifies whether a variance
#'   stabilizing fourth root transformation should be performed on the data.
#'
#' @return A list of time series. The first element is a \code{ts} object
#'   made by coercing the original truth data into a time series format,
#'   followed by series with increasing levels of aggregation.
#' @export
#'
#' @importFrom rlang .data
#' @importFrom lubridate %within%
aggregate_thief_df <- # aggregate levels list should be in order of smallest to largest level
  function(df = NULL, ts_col = "value", start_date, end_date, fips_code, aggregate_levels = list(56, 28, 14, 7, 1), agg.names = NULL, frequency = 56, transform.4root = FALSE) {

    ts_col <- ts_col

    fips_vector <- dplyr::pull(covidHubUtils::hub_locations, .data[["fips"]])
    if (fips_code %in% fips_vector) {
      fips_code <- fips_code
    } else {
      stop("Please provide a US location fips code.")
    }

    # if (start_date == NULL) # first target_end_date, else
    start_date <- as.Date(start_date)
    # likewise for end_date, else
    end_date <- as.Date(end_date)

    # if (!is.null(df) | !is.data.frame(df)) {
    #   df <- NULL
    #   warning(paste("You have not provided a data frame.
    #                 Forecasts will be made using versioned truth data as of",
    #                 end_date-1, "or the most recent date is available for."))
    # } else
    if (is.null(df)) {
      df <- covidHubUtils::load_truth("HealthData",
                                      "inc hosp",
                                      as_of = end_date,
                                      temporal_resolution = "daily",
                                      data_location = "covidData")
    } else {
      df <- df
      warning("Forecasts will be based on static truth data")
    }

    # obtain most recent date truth data was obtained from
    most_recent_date <- max(unique(df$target_end_date))
    if (as.numeric(end_date - most_recent_date) > 1) {
      warning(paste("Forecasts will be made as of",
                    most_recent_date + 1,
                    "due to insufficient truth data."))
    }

    agg_list <- aggregate_levels
    agg.names <- c("daily", "weekly", "2-weekly", "4-weekly", "8-weekly")
    freq <- frequency

    hosp_truth <- df |>
      dplyr::filter(
        .data[["target_end_date"]] >= start_date,
        .data[["target_end_date"]] <= most_recent_date,
        .data[["location"]] == fips_code
      ) |>
      dplyr::arrange(.data[["target_end_date"]])

    # Construct time series
    time_period <- as.numeric(most_recent_date - start_date) + 1
    periods <- floor(time_period / freq)
    remainder <- time_period - (periods * freq)

    if (transform.4root == TRUE) {
      hosp_values <- dplyr::pull(hosp_truth, ts_col)^0.25
    } else {
      hosp_values <- dplyr::pull(hosp_truth, ts_col)
    }
    ht_day_ts_ <- stats::ts(hosp_values,
                            start = c(1, 1), end = c(periods + 1, remainder),
                            frequency = freq)

    # Construct temporal hierarchy
    day_agg_ <- thief::tsaggregates(ht_day_ts_, m = freq, align = "end", aggregatelist = agg_list)
    for(i in seq_along(day_agg_)) {
      names(day_agg_)[[i]] <- agg.names[i]
    }

    return(day_agg_)
  }
