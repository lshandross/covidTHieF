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
#' @param target_name A character string giving the name to use for the target.
#' @param n_samples Numeric giving the number of samples for each unique
#'   forecast unit to return. Defaults to NULL, in which case no
#'   sample forecasts are returned.
#' @param quantile_levels Numeric vector of quantile levels (probabilities) to
#'   calculate from the input `fc_matrix` sample forecasts. NULL means that no
#'   quantile forecasts are returned. Defaults to quantiles representing
#'   50% and 95% prediction intervals and a median.
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
transform_matrix_to_hub_df <-
  function(fc_matrix, forecast_date, fips_code, target_name, n_samples = NULL,
           quantile_levels = c(0.025, 0.25, 0.5, 0.75, 0.975), h_ahead = 56,
           temp_res = 1, keep_bottommost_only = TRUE) {
    if (!is.null(n_samples)) {
      if (n_samples > nrow(fc_matrix)) {
        stop("Requested number of samples cannot exceed the number that have been provided")
      }
      fc_samples <- fc_matrix[1:n_samples,]
      rownames(fc_samples) <- 1:n_samples
    } else {
      fc_samples <- NULL
    }

    # extract quantiles - rows become quantile levels
    if (!is.null(quantile_levels)) {
      fc_quantiles <- apply(fc_matrix, 2, stats::quantile, na.rm = TRUE,
                            probs = quantile_levels)
      rownames(fc_quantiles) <- rownames(fc_quantiles) |>
        stringr::str_remove("%") |>
        as.numeric() * 0.01
    } else {
      fc_quantiles <- NULL
    }

    fc_combined <- rbind(fc_samples, fc_quantiles)
    hub_df <- fc_combined |>
      as.table() |>
      as.data.frame(stringsAsFactors = FALSE) |>
      tidyr::separate(
        .data[["Var2"]], into = c("a", "k", "h"),
        sep = "\\D+", convert = TRUE
      ) |>
      dplyr::mutate(
        forecast_date = forecast_date,
        level = .data[["k"]],
        location = fips_code,
        horizon = as.numeric(.data[["h"]]) * .data[["k"]],
        temporal_resolution = dplyr::case_when(
          temp_res == 1 ~ "daily",
          temp_res == 7 ~ "weekly",
          temp_res == 30 ~ "monthly",
          temp_res == 365 ~ "yearly",
          .default = as.character(temp_res)
        ),
        target = target_name,
        target_end_date = forecast_date + .data[["horizon"]] * temp_res,
        type = ifelse(as.numeric(.data[["Var1"]] < 1), "quantile", "sample"),
        quantile = as.numeric(.data[["Var1"]]),
        value = ifelse(.data[["Freq"]] < 0, 0, .data[["Freq"]]),
      )

    if (keep_bottommost_only) {
      hub_df <- hub_df |>
        dplyr::filter(.data[["k"]] == min(hub_df$k)) |>
        dplyr::select(-"level")
    }

    hub_df |>
      dplyr::filter(.data[["horizon"]] <= h_ahead) |>
      dplyr::select(c("forecast_date":"value")) |>
      dplyr::arrange(.data[["horizon"]]) |>
      dplyr::tibble()
  }
