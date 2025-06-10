#' Transform temporal hierarchical COVID-19 forecasts to US COVID-19 Forecast
#' Hub-formatted data frame
#'
#' @param forecasts An object of class \code{forecast} to be transformed into a
#'   data frame
#' @param most_recent_date A date from which the truth data ends and the day
#'   before the forecasts begin. Used to set the \code{forecast_date} in the
#'   new data frame.
#' @param fips_code A 2-digit code specifying a United States state or territory
#'   of type \code{char}. Used to set the \code{location} in the new data frame.
#' @param pi_levels A vector of prediction interval levels to calculate. Used
#'   to obtain the corresponding \code{quantile} value in the new data frame.
#' @param h_ahead A number specifying how many time units ahead the longest
#'   horizon being forecast should be. Defaults to 56 with the assumption the
#'   unit is in days (for a total of 8 weeks ahead).
#' @param transform.4root \code{logical} that specifies whether a variance
#'   stabilizing fourth root transformation was performed on the data when
#'   creating the provided forecasts. If \code{TRUE}, the forecast values are
#'   raised to the fourth power to undo the initial transformation.
#'
#' @return A data frame containing the following columns: \code{forecast_date},
#'   \code{location}, \code{target}, \code{target_end_date}, \code{type},
#'   \code{quantile}, \code{value}
#' @export
#'
#' @importFrom rlang .data
transform_to_hub_df <- function(forecasts, most_recent_date, fips_code, pi_levels, h_ahead = 56, transform.4root = FALSE) {
  if (fips_code %in% dplyr::pull(covidHubUtils::hub_locations, .data[["fips"]])) {
    fips_code <- fips_code
  } else {
    stop("Please provide a US location fips code.")
  }

  if (!forecast::is.forecast(forecasts)) {
    num_fc <- c()
    for (i in seq_along(forecasts)) {
      num_fc[i] <- length(forecasts[[i]][["mean"]])
    }
    index <- match(max(num_fc), num_fc)
  }

  # Lower Forecasts
  if (!forecast::is.forecast(forecasts)) {
    low_fc <- as.data.frame(forecasts[[index]][["lower"]], stringsAsFactors = FALSE)
  } else {
    low_fc <- as.data.frame(forecasts[["lower"]], stringsAsFactors = FALSE)
  }

  old_col_names <- colnames(low_fc)
  new_col_names <- rep("string", length(old_col_names))
  for (i in seq_along(old_col_names)) {
    new_col_names[i] <- as.character(((100 - pi_levels[i]) / 2) / 100)
  }
  colnames(low_fc) <- c(new_col_names)

  # High Forecasts
  if (!forecast::is.forecast(forecasts)) {
    high_fc <- as.data.frame(forecasts[[index]][["upper"]], stringsAsFactors = FALSE)
  } else {
    high_fc <- as.data.frame(forecasts[["upper"]], stringsAsFactors = FALSE)
  }

  old_col_names <- colnames(high_fc)
  new_col_names <- rep("string", length(old_col_names))
  for (i in seq_along(old_col_names)) {
    new_col_names[i] <- as.character((100 - ((100 - pi_levels[i]) / 2)) / 100)
  }
  colnames(high_fc) <- c(new_col_names)


  # Point Forecasts
  if (!forecast::is.forecast(forecasts)) {
    point_fc <- dplyr::tibble("0.5" = forecasts[[index]][["mean"]])
  } else {
    point_fc <- dplyr::tibble("0.5" = forecasts[["mean"]])
  }

  # Join forecasts together
  hub_df <- cbind(low_fc, point_fc, high_fc) |>
    dplyr::mutate(
      forecast_date = most_recent_date,
      horizon = as.numeric(rownames(low_fc)),
      target = paste(.data[["horizon"]], " day ahead inc hosp"),
      target_end_date = .data[["forecast_date"]] + lubridate::days(.data[["horizon"]])
    ) |>
    tidyr::pivot_longer(
      1:(2 * length(pi_levels) + 1), names_to = "quantile", values_to = "value"
    ) |>
    dplyr::filter(.data[["horizon"]] <= h_ahead) |>
    dplyr::arrange(.data[["target_end_date"]], .data[["quantile"]]) |>
    dplyr::mutate(location = fips_code,
                  type = "quantile",
                  quantile = as.numeric(.data[["quantile"]]),
                  value = ifelse(.data[["value"]] < 0, 0, .data[["value"]])) |>
    dplyr::select("forecast_date", "location", "target", "target_end_date", "type", "quantile", "value")

  if (transform.4root == TRUE) hub_df <- dplyr::mutate(hub_df, value = .data[["value"]]^4)

  return(hub_df)
}
