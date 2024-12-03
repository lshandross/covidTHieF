#' Transform temporal hierarchical COVID-19 probabilistic forecasts in a matrix
#' to US COVID-19 Forecast Hub-formatted data frame of quantile forecasts
#'
#' @param fc_matrix Object of class \code{matrix} containing forecasts to be
#'   transformed into a data frame. The assumed matrix format contains columns
#'   of samples for each element in the hierarchy, with one sample per row.
#'   The columns are named with format "k-agg h-element", e.g. "k-28 h-1"
#'   represents the 28-day level's first element.
#' @param forecast_date Date from which horizons begin counting from (h = 0),
#'   tends to be the last observed value in the truth data.
#' @param fips_code A 2-digit code specifying a United States state or territory
#'   of type \code{char}. Used to set the \code{location} in the new data frame.
#' @param quantile_levels Numeric vector of quantile levels (probabilities) to
#'   calculate from the input `fc_matrix` sample forecasts. Defaults to
#'   quartiles.
#' @param h_ahead Numeric specifying the time units ahead of the longest horizon
#'   being forecast should be. Defaults to 56 with the assumption the unit is
#'   in days (for a total of 8 weeks ahead).
#' @param keep_bottommost_only Logical specifying whether to discard all
#'   forecasts except for those from the bottommost level of the hierarchy.
#'   Defaults to TRUE.
#'
#' @return A data frame of forecasts containing columns: \code{forecast_date},
#' \code{location}, \code{target}, \code{target_end_date}, \code{type},
#' \code{quantile}, \code{value}. Quantile values are summarized from the input
#' sample forecasts.
#' @export
#'
#' @importFrom rlang .data
transform_matrix_to_hub_df <- function(fc_matrix, forecast_date, fips_code,
                                       quantile_levels = c(0.25, 0.5, 0.75),
                                       h_ahead = 56,
                                       keep_bottommost_only = TRUE) {

  # extract quantiles - rows become quantile levels
  fc_quantiles <- apply(fc_matrix, 2, stats::quantile, na.rm = TRUE,
                        probs = quantile_levels)

  hub_df <- fc_quantiles |>
    as.table() |>
    as.data.frame() |>
    tidyr::separate(
      .data[["Var2"]], into = c("a", "k", "h"),
      sep = "\\D+", convert = TRUE
    ) |>
    dplyr::mutate(
      forecast_date = forecast_date,
      location = fips_code,
      horizon = as.numeric(.data[["h"]]) * .data[["k"]],
      temporal_resolution = "daily",
      target = "inc hosp",
      target_end_date = forecast_date + .data[["horizon"]],
      type = "quantile",
      quantile = as.numeric(stringr::str_remove(.data[["Var1"]], "%")) * 0.01,
      value = ifelse(.data[["Freq"]] < 0, 0, .data[["Freq"]]),
    )

  if (keep_bottommost_only) {
    hub_df <- dplyr::filter(hub_df, .data[["k"]] == min(hub_df$k))
  }

  hub_df |>
    dplyr::filter(.data[["horizon"]] <= h_ahead) |>
    dplyr::select(c("forecast_date":"value")) |>
    dplyr::tibble()
}
