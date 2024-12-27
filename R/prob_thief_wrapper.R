#' Probabilistic temporal hierarchical forecasting for a single location
#'
#' @param truth_data A data frame containing truth data used to create forecasts
#'   Must contain a "target_end_date" column of dates, a "location" column of
#'   fips codes, and a column of truth data values. Defaults to NULL, in
#'   which case hospitalization truth data is sourced as of the user-specified
#'   \code{end_date}.
#' @param ts_col The name of the column containing the truth data. This column
#'   is coerced into a time series object of class \code{ts} and thus should be
#'   a numeric type.
#' @param start_date A date from which the truth data begins.
#' @param end_date A date where the truth data ends and the forecasts begin.
#'   If \code{df = NULL}, also specifies the date from which the hospitalization
#'   truth data sourced.
#' @param fips_code A 2-digit code specifying a United States state or territory
#'   of type \code{char}.
#' @param target_name A character string giving the name to use for the target.
#' @param aggregate_levels A user-selected list of aggregates to use.
#' @param frequency Integer seasonal period.
#' @param nsim Numeric of bootstrap samples used to generate probabilistic
#'   forecasts. Defaults to 10000.
#' @param n_samples Numeric giving the number of samples for each unique
#'   forecast unit to return. Defaults to NULL, in which case no
#'   sample forecasts are returned.
#' @param quantile_levels Numeric vector of quantile levels (probabilities) to
#'   calculate for the returned forecasts.
#' @param transform.4root \code{logical} that specifies whether a variance
#'   stabilizing fourth root transformation should be performed on the data.
#'   (This data transformation is undone after all of the forecasts are
#'   reconciled and re-formatted into a data frame.)
#'
#' @return A list containing two items: a data frame containing COVID-19
#'   incident hospitalization truth data with a US COVID-19 Forecast Hub format
#'   and a data frame containing the base forecast matrix and the reconciled
#'   forecast matrix with other relevant identifying information.
#' @export
#'
#' @importFrom rlang .data
prob_thief_wrapper <-
  function(truth_data = NULL, ts_col = "value", start_date, end_date, fips_code,
           target_name = "inc hosp", aggregate_levels, frequency, nsim = 1e5,
           n_samples = NULL, quantile_levels = NULL, transform.4root = FALSE) {
    if (is.null(aggregate_levels)) {
      stop("You haven't provided any aggregate levels")
    }
    if (is.null(quantile_levels) && is.null(n_samples)) {
      stop("You haven't requested any forecasts")
    }

    if (is.null(truth_data)) {
      truth_data <- covidHubUtils::load_truth("HealthData",
                                              "inc hosp",
                                              as_of = end_date,
                                              temporal_resolution = "daily",
                                              locations = fips_code,
                                              data_location = "covidData")
    } else {
      warning("Forecasts will be based on static truth data")
    }

    # obtain most recent date truth data was obtained from
    most_recent_date <- max(unique(truth_data$target_end_date))
    num_missing_obs <- as.numeric(end_date - most_recent_date)
    if (num_missing_obs >= 1) {
      truth_data <- truth_data |>
        dplyr::add_row(target_end_date = most_recent_date + 1:num_missing_obs) |>
        tidyr::fill(!!!rlang::syms(names(truth_data)))
      warning(paste(num_missing_obs, "missing truth data observations will be imputed using last available value."))
    }

    thief_aggregation <- truth_data |>
      aggregate_thief_df(ts_col, start_date, end_date, fips_code,
                         aggregate_levels, NULL, frequency, transform.4root) |>
      suppressWarnings()

    # if plot aggregates

    forecasts_list <- thief_aggregation |>
      compute_prob_forecasts(nsim, forecast_type = c("base", "reconciled"),
                             aggregate_levels, comb = "wlsv", nn = "sntz",
                             return_forecast_obj = TRUE)

    # if plot forecasts

    h_ahead <- min(35, max(aggregate_levels))
    hub_df <- forecasts_list[["reconciled"]] |>
      transform_matrix_to_hub_df(forecast_date = end_date, fips_code, target_name,
                                 n_samples, quantile_levels, h_ahead)
    if (transform.4root == TRUE) {
      hub_df <- dplyr::mutate(hub_df, value = .data[["value"]]^4)
    }

    model_info <- data.frame(
      forecast_date = end_date,
      location = fips_code,
      level = I(list(aggregate_levels)),
      base_matrix = I(list(forecasts_list[["base"]])),
      rec_matrix = I(list(forecasts_list[["reconciled"]]))
    )

    return(list(hub_df, model_info))
  }
