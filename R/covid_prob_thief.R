#' Temporal hierarchical forecasting for COVID-19 incident hospitalizations for
#' multiple locations
#'
#' @param truth_data A data frame containing truth data used to create forecasts
#'   Must contain a "target_end_date" column of dates, a "location" column of
#'   fips codes, and a column of truth data values. Defaults to NULL, in
#'   which case hospitalization truth data is sourced as of the user-specified
#'   \code{end_date}.
#' @param ts_col The name of the column containing the truth data. This column
#'   is coerced into a time series object of class \code{ts} and thus should
#'   be a numeric type.
#' @param start_date A date from which the truth data begins.
#' @param end_date A date where the truth data ends and the forecasts begin.
#'   If \code{df = NULL}, also specifies the date from which the hospitalization
#'   truth data sourced.
#' @param fips_vec A vector of one or more 2-digit codes specifying a
#'   United States state or territory, of class \code{char}.
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
#' @return A list containing two data frames: the first containing COVID-19
#'   incident hospitalization forecasts for the specified date and locations
#'   in a US COVID-19 Forecast Hub format and the second containing metadata
#'   about the forecaster making the predictions for each location, with
#'   columns "forecast_data", "location", aggregate_levels, "base_matrix",
#'   "rec_matrix" (the matrices contain the original sample forecasts)
#' @export
#'
#' @importFrom rlang .data
covid_prob_thief <-
  function(truth_data = NULL, ts_col = "value", start_date, end_date, fips_vec,
           target_name, aggregate_levels, frequency, nsim = 1e5,
           n_samples = NULL, quantile_levels, transform.4root = FALSE) {
    all_locs_list <- purrr::map(
      .x = fips_vec,
      .f = function(fips_code) {
        prob_thief_wrapper(truth_data, ts_col, start_date, end_date,
                           fips_code, target_name, aggregate_levels, frequency,
                           nsim, n_samples, quantile_levels, transform.4root)
      }
    )
    all_locs_fc <- purrr::imap(.x = fips_vec, ~ all_locs_list[[.y]][[1]]) |>
      purrr::list_rbind()
    all_locs_mod <- purrr::imap(.x = fips_vec, ~ all_locs_list[[.y]][[2]]) |>
      purrr::list_rbind()

    return(list(all_locs_fc, all_locs_mod))
  }
