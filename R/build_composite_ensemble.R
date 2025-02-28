#' Create a weighted quantile ensemble of composite models
#'
#' @param forecast_df A data frame of forecasts to build the ensemble.
#'   Defaults to NULL, in which the function looks for .csv files with the proper
#'   naming convention and organizational structure are searched for locally to
#'   create a data frame of forecasts. Note the implicit assumption that all
#'   forecasts have the same horizons
#' @param composite_models A character vector of model names. It is assumed that
#'   every element has forecasts in `forecast_df`, or will be used to search forward
#'   forecasts to construct `forecast_df`.
#' @param scores_df A data frame of scores to determine weights for the ensemble.
#'   Defaults to NULL, in which the function scores the forecasts within
#'   `forecast_df` using the provided `truth_data` to obtain weights
#' @param truth_data A data frame of truth data used to score `forecast_df` to
#'   obtain ensemble weights, only used if no scores are provided
#' @param use_median_as_point A boolean passed as an argument to score
#'   `forecast_df`, only used if no scores are provided
#' @param rolling_period A `Period` object specifying how long of a time period
#'   should be used to create ensemble weights based on past performance (scores)
#' @param theta A numeric used in creating ensemble weights.
#'   Defaults to 0, which creates an untrained mean ensemble. Larger values shrink
#'   the weights for poor-performing models to zero while increasing weights for
#'   well-performing models.
#' @param ensemble_name A string used to name the ensemble within the resulting data frame
#' @param forecast_date A `Date` object specifying the desired forecast at date.
#'   Will be coerced to the previous Monday
#' @param reference_dates A vector of `Date` objects used to aid in calculations.
#'   Should be a list of Mondays
#'
#' @return a data frame of forecasts for the ensemble in the hub format for the 
#' input forecast date
#' @export
#' @importFrom rlang .data
#' @importFrom magrittr %>%
#'
#' @examples
build_composite_ensemble <- function(forecast_df = NULL, composite_models, scores_df = NULL, truth_data, use_median_as_point = TRUE, rolling_period, theta = 0, ensemble_name = NULL, forecast_date, reference_dates) {
  func_list <- list.files(path = "R", pattern = ".R", full.names = TRUE)
  lapply(func_list, source)

  if (forecast_date > max(reference_dates)) {
    stop("Please provide a forecast date within the span of the reference dates")
  } else if (is.character(forecast_date)) {
    forecast_date <- as.Date(forecast_date)
  }
  rolling_end_date <- lubridate::floor_date(forecast_date - 1, "week", 1)
  rolling_start_date <- rolling_end_date - rolling_period

  date_index <- match(rolling_end_date + lubridate::weeks(1), reference_dates) +
    ifelse(forecast_date >= as.Date("2021-11-01"), 47, 0)
  
  if (is.null(forecast_df)) {
    forecast_df <- purrr::map_dfr(composite_models, load_formatted_forecasts, date_index)
  }

  if (date_index < lubridate::time_length(rolling_period, "week")) {
    warning("Insufficient forecasts provided for entire rolling period. Equal weights will be used instead.")
    theta <- 0
  }

  if (is.null(scores_df)) {
    scores_df <- covidHubUtils::score_forecasts(
      forecast_df, return_format = "wide", truth = truth_data,
      use_median_as_point = use_median_as_point
    )
  }

  # compute weights
  rolling_metrics_states <- scores_df %>%
    dplyr::group_by("model") %>%
    dplyr::filter(.data[["forecast_date"]] >= rolling_start_date, .data[["forecast_date"]] <= rolling_end_date) %>%
    dplyr::summarize(wis = mean(wis), mae = mean(abs_error))
  model_weights <- rolling_metrics_states %>%
    dplyr::mutate(
      rwis = wis / dplyr::pull(dplyr::filter(rolling_metrics_states, model == "COVIDhub-baseline"), 2),
      rmae = mae / dplyr::pull(dplyr::filter(rolling_metrics_states, model == "COVIDhub-baseline"), 3),
    ) %>%
    dplyr::filter(model != "COVIDhub-baseline", model %in% composite_models) %>%
    dplyr::mutate(weight = exp(-theta * rwis) / sum(exp(-theta * rwis))) %>%
    dplyr::select(model, weight)

  # Build ensemble
  ensemble_forecasts <- forecast_df %>%
    dplyr::left_join(model_weights, by = "model") %>%
    dplyr::mutate(ensemble_contribution = 
      dplyr::case_when(date_index == 1 ~ (1 / length(composite_models)) * value,
                       date_index != 1 ~ weight * value)
    ) %>%
    dplyr::group_by(forecast_date, location, horizon, temporal_resolution, target_variable, target_end_date, type, quantile) %>%
    dplyr::summarize(value = sum(ensemble_contribution)) %>%
    dplyr::mutate(model = ensemble_name, .before = forecast_date) %>%
    dplyr::left_join(covidHubUtils::hub_locations, by = c("location" = "fips"))

  return (ensemble_forecasts)
}

# Not run
# ensemble_test <- build_composite_ensemble(forecast_df = NULL, composite_models = all_thief, scores_df = scores_clean, truth_data = NULL, rolling_period = weeks(12), theta = 6.5, ensemble_name = "THieF_ensemble-train6.5", forecast_date = as.Date("2021-10-23"), reference_dates = mon_fc_dates)
