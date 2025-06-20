#' Summarize forecasts across the entire forecasts period
#'
#' @param scores A data frame of forecast scores to be summarized
#' @param baseline_name String specifying the name of the baseline model to calculate relative metrics against
#' @param us_only Boolean specifying whether to summarize metrics for the us national level only or just states
#'
#' @return A data frame of summarized forecast score metrics across all provided forecasts
#' @export
#'
#' @importFrom rlang .data
#' @importFrom magrittr %>%
summarize_overall_metrics <- function(scores, baseline_name, us_only=FALSE) {
  # potentially add argument to filter for a certain number of weeks?
  if (us_only) {
    scores <- dplyr::filter(scores, .data[["location"]] == "US")
  } else {
    scores <- dplyr::filter(scores, .data[["location"]] != "US")
  }
  summarized_metrics <- scores %>%
    dplyr::filter(!(.data[["location"]] %in% c("22", "US") & forecast_date <= as.Date("2021-01-04"))) %>% # < 1/11/2021 to match code in score_forecasts
    dplyr::group_by(.data[["model"]]) %>%
    dplyr::summarize(WIS = mean(wis), MAE = mean(abs_error), Cov50 = mean(coverage_50), Cov95 = mean(coverage_95))

  # add relative metrics
  summarized_metrics %>%
    dplyr::mutate(
      rWIS = WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name), 2),
      rMAE = MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name), 3) #,
      #Cov50 = Cov50 / abs(dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name), 4) - 0.5),
      #rCov95 = Cov95 / abs(dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name), 5)-0.95)
    ) %>%
    dplyr::rename(Model = model) %>%
    dplyr::mutate(dplyr::across(where(is.numeric), round, digits = 3)) %>%
    dplyr::arrange(WIS)
}

#combined_scores <- rbind(scores, scores_baseline)
#summarize_overall_metrics(scores=combined_scores, baseline_name="COVIDhub-baseline", us_only=TRUE)


#' Summarize forecasts by horizon week
#'
#' @param scores A data frame of forecast scores to be summarized
#' @param baseline_name String specifying the name of the baseline model to
#'   calculate relative metrics against
#' @param us_only Boolean specifying whether to summarize metrics for the
#'   US national level only or just states
#'
#' @return A data frame of summarized forecast score metrics stratified by horizon week
#' @export
#'
#' @examples
summarize_horizon_metrics <- function(scores, baseline_name, us_only =  FALSE) {
  if (us_only) {
    scores <- dplyr::filter(scores, .data[["location"]] == "US")
  } else {
    scores <- dplyr::filter(scores, .data[["location"]] != "US")
  }
  summarized_metrics <- scores %>%
    dplyr::filter(
      !(.data[["location"]] %in% c("22", "US") & .data[["forecast_date"]] <= as.Date("2021-01-04"))
    ) %>% # < 1/11/2021 to match code in score_forecasts
    dplyr::group_by(dplyr::across(dplyr::all_of(c("model", "horizon_wk")))) %>%
    dplyr::summarize(WIS = mean(wis), MAE = mean(abs_error),
                     Cov50 = mean(coverage_50), Cov95 = mean(coverage_95))

  # add relative metrics
  summarized_metrics %>%
    dplyr::mutate(
      rWIS = dplyr::case_when(
        horizon_wk == 1 ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 3),
        horizon_wk == 2 ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 3),
        horizon_wk == 3 ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 3),
        horizon_wk == 4 ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 3),
      ),
      rMAE = case_when(
        horizon_wk == 1 ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 4),
        horizon_wk == 2 ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 4),
        horizon_wk == 3 ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 4),
        horizon_wk == 4 ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 4),
      # rCov50, rCov95
      )
    ) %>%
    dplyr::rename(Model = model) %>%
    dplyr::mutate(dplyr::across(where(is.numeric), round, digits = 2)) %>%
    dplyr::arrange(horizon_wk, WIS)
}

#summarize_horizon_metrics(scores = combined_scores, baseline_name = "COVIDhub-baseline", us_only = TRUE)


#' Summarize forecasts by both pandemic wave and horizon week
#'
#' @param scores A data frame of forecast scores to be summarized
#' @param baseline_name String specifying the name of the baseline model to
#'   calculate relative metrics against
#' @param us_only Boolean specifying whether to summarize metrics for the
#'   US national level only or just states
#'
#' @return A data frame of summarized forecast score metrics stratified by
#' pandemic wave and horizon week
#' @export
#'
#' @examples
summarize_wave_metrics <- function(scores, baseline_name, us_only=FALSE) {
  if (us_only) {
    scores <- dplyr::filter(scores, .data[["location"]] == "US")
  } else {
    scores <- dplyr::filter(scores, .data[["location"]] != "US")
  }
  summarized_metrics <- scores %>%
    dplyr::filter(
      !(.data[["location"]] %in% c("22", "US") & .data[["forecast_date"]] <= as.Date("2021-01-04"))
    ) %>% # < 1/11/2021 to match code in score_forecasts
    dplyr::mutate(
      wave = dplyr::case_when(
        forecast_date <= as.Date("2021-03-17") ~ "winter21",
        forecast_date %within% interval(as.Date("2021-03-18"), as.Date("2021-07-05")) ~ "alpha",
        forecast_date %within% interval(as.Date("2021-07-06"), as.Date("2021-10-31")) ~ "delta",
        forecast_date %within% interval(as.Date("2021-11-01"), as.Date("2022-04-04")) ~ "omicron",
        forecast_date >= as.Date("2022-04-05") ~ "ba4_ba5"
      )
    ) %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(c("model", "horizon_wk", "wave")))) %>%
    dplyr::summarize(WIS = mean(wis), MAE = mean(abs_error), Cov50 = mean(coverage_50), Cov95 = mean(coverage_95))

  # add relative metrics
  summarized_metrics %>%
    dplyr::mutate(
      rWIS = dplyr::case_when(
        horizon_wk == 1 & wave == "winter21" ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 4),
        horizon_wk == 2 & wave == "winter21" ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 4),
        horizon_wk == 3 & wave == "winter21" ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 4),
        horizon_wk == 4 & wave == "winter21" ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 4),
        horizon_wk == 1 & wave == "alpha" ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 4),
        horizon_wk == 2 & wave == "alpha" ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 4),
        horizon_wk == 3 & wave == "alpha" ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 4),
        horizon_wk == 4 & wave == "alpha" ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 4),
        horizon_wk == 1 & wave == "delta" ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 4),
        horizon_wk == 2 & wave == "delta" ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 4),
        horizon_wk == 3 & wave == "delta" ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 4),
        horizon_wk == 4 & wave == "delta" ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 4),
        horizon_wk == 1 & wave == "omicron" ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 4),
        horizon_wk == 2 & wave == "omicron" ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 4),
        horizon_wk == 3 & wave == "omicron" ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 4),
        horizon_wk == 4 & wave == "omicron" ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 4),
        horizon_wk == 1 & wave == "ba4_ba5" ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 4),
        horizon_wk == 2 & wave == "ba4_ba5" ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 4),
        horizon_wk == 3 & wave == "ba4_ba5" ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 4),
        horizon_wk == 4 & wave == "ba4_ba5" ~ WIS / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 4),
      ),
      rMAE = dplyr::case_when(
        horizon_wk == 1 & wave == "winter21" ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 5),
        horizon_wk == 2 & wave == "winter21" ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 5),
        horizon_wk == 3 & wave == "winter21" ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 5),
        horizon_wk == 4 & wave == "winter21" ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 5),
        horizon_wk == 1 & wave == "alpha" ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 5),
        horizon_wk == 2 & wave == "alpha" ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 5),
        horizon_wk == 3 & wave == "alpha" ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 5),
        horizon_wk == 4 & wave == "alpha" ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 5),
        horizon_wk == 1 & wave == "delta" ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 5),
        horizon_wk == 2 & wave == "delta" ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 5),
        horizon_wk == 3 & wave == "delta" ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 5),
        horizon_wk == 4 & wave == "delta" ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 5),
        horizon_wk == 1 & wave == "omicron" ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 5),
        horizon_wk == 2 & wave == "omicron" ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 5),
        horizon_wk == 3 & wave == "omicron" ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 5),
        horizon_wk == 4 & wave == "omicron" ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 5),
        horizon_wk == 1 & wave == "ba4_ba5" ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 5),
        horizon_wk == 2 & wave == "ba4_ba5" ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 5),
        horizon_wk == 3 & wave == "ba4_ba5" ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 5),
        horizon_wk == 4 & wave == "ba4_ba5" ~ MAE / dplyr::pull(dplyr::filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 5),
      )
    ) %>%
    dplyr::rename(Model = model) %>%
    dplyr::mutate(dplyr::across(where(is.numeric), round, digits = 3)) %>%
    dplyr::arrange(wave, horizon_wk, WIS)
  }

#summarize_wave_metrics(scores=combined_scores, baseline_name="COVIDhub-baseline", us_only=TRUE)


#' Summarize forecasts by forecast date and horizon week
#'
#' @param scores A data frame of forecast scores to be summarized
#' @param us_only Boolean specifying whether to summarize metrics for the us national level only or just states
#'
#' @return A data frame of summarized forecast score metrics stratified by forecast date and horizon week
#' @export
#'
#' @examples
summarize_forecast_date_metrics <- function(scores, us_only) {
  if (us_only) {
    scores <- dplyr::filter(scores, .data[["location"]] == "US")
  } else {
    scores <- dplyr::filter(scores, .data[["location"]] != "US")
  }
  scores %>%
    dplyr::filter(!(.data[["location"]] %in% c("22", "US") & forecast_date <= as.Date("2021-01-04"))) %>% # < 1/11/2021 to match code in score_forecasts
    dplyr::mutate(
      mon_fc_date = lubridate::floor_date(
        forecast_date, unit = "weeks",
        week_start = getOption("lubridate.week.start", 1)) + lubridate::weeks(1)
    ) %>%
    dplyr::select(model, horizon, horizon_wk, mon_fc_date, target_end_date,
          true_value, abs_error, wis, coverage_50, coverage_95) %>%
    dplyr::group_by(mon_fc_date, model, horizon_wk) %>%
    dplyr::summarize(
      WIS = mean(wis), MAE = mean(abs_error),
      Cov50 = mean(coverage_50),
      Cov95 = mean(coverage_95)
    ) %>%
    dplyr::rename(Model = model)
}

# summarize_forecast_date_metrics(combined_scores, us_only = TRUE)
