# library(dplyr)

#' Summarize forecasts across the entire forecasts period
#'
#' @param scores A data frame of forecast scores to be summarized
#' @param baseline_name String specifying the name of the baseline model to calculate relative metrics against
#' @param us_only Boolean specifying whether to summarize metrics for the us national level only or just states
#'
#' @return A data frame of summarized forecast score metrics across all provided forecasts
#' @export
#'
#' @examples
summarize_overall_metrics <- function(scores, baseline_name, us_only=FALSE) {
  summarized_metrics <- scores %>%
    filter(
      !(location %in% c("22", "US") & forecast_date <= as.Date("2021-01-04")),
      ifelse(us_only, location == "US", location != "US")
    ) %>%
  group_by(model) %>%
  summarize(wis = mean(wis), mae = mean(abs_error), cov_50 = mean(coverage_50), cov_95 = mean(coverage_95))

  # add relative metrics
  summarized_metrics <- summarized_metrics %>%
    mutate(
      rwis = wis/pull(filter(summarized_metrics, model == baseline_name), 2),
      rmae = mae/pull(filter(summarized_metrics, model == baseline_name), 3),
      #cov_50 = cov_50/abs(pull(filter(summarized_metrics, model == baseline_name), 4)-0.5),
      #rcov_95 = cov_95/abs(pull(filter(summarized_metrics, model == baseline_name), 5)-0.95),
    ) %>%
    mutate(across(cov_50:rmae, round, digits=3)) %>%
    arrange(wis)

  if (us_only) {
    mutate(summarized_metrics, across(wis:mae, round, digits=1))
  } else {
    summarized_metrics
  }
}

#' Summarize forecasts by horizon week
#'
#' @param scores A data frame of forecast scores to be summarized
#' @param baseline_name String specifying the name of the baseline model to calculate relative metrics against
#' @param us_only Boolean specifying whether to summarize metrics for the us national level only or just states
#'
#' @return A data frame of summarized forecast score metrics stratified by horizon week
#' @export
#'
#' @examples
summarize_horizon_metrics <- function(scores, baseline_name, us_only=FALSE) {
  summarized_metrics <- scores %>%
    filter(
      !(location %in% c("22", "US") & forecast_date <= as.Date("2021-01-04")),
      ifelse(us_only, location == "US", location != "US")
    ) %>%
  group_by(model, horizon_wk) %>%
  summarize(wis = mean(wis), mae = mean(abs_error), cov_50 = mean(coverage_50), cov_95 = mean(coverage_95))


  # add relative metrics
  summarized_metrics <- summarized_metrics %>%
    mutate(
      rwis = case_when(
        horizon_wk == 1 ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 3),
        horizon_wk == 2 ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 3),
        horizon_wk == 3 ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 3),
        horizon_wk == 4 ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 3),
      ),
      rmae = case_when(
        horizon_wk == 1 ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 4),
        horizon_wk == 2 ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 4),
        horizon_wk == 3 ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 4),
        horizon_wk == 4 ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 4) #,
      # rcov_50, rcov_95
      )
    ) %>%
    mutate(across(where(is.numeric), round, digits=3)) %>%
    arrange(horizon_wk, wis)

  if (us_only) {
    mutate(summarized_metrics, across(wis:mae, round, digits=1))
  } else {
    summarized_metrics
  }
  }


#' Summarize forecasts by both pandemic wave and horizon week
#'
#' @param scores A data frame of forecast scores to be summarized
#' @param baseline_name String specifying the name of the baseline model to calculate relative metrics against
#' @param us_only Boolean specifying whether to summarize metrics for the us national level only or just states
#'
#' @return A data frame of summarized forecast score metrics stratified by pandemic wave and horizon week
#' @export
#'
#' @examples
summarize_wave_metrics <- function(scores, baseline_name, us_only=FALSE) {
  summarized_metrics <- scores %>%
    filter(
      !(location %in% c("22", "US") & forecast_date <= as.Date("2021-01-04")),
      ifelse(us_only, location == "US", location != "US")
    ) %>%
  mutate(
    wave = case_when(
      forecast_date <= as.Date("2021-03-17") ~ "winter21",
      forecast_date %in% c(as.Date("2021-03-17"):as.Date("2021-07-05")) ~ "alpha",
      forecast_date %in% c(as.Date("2021-07-05"):as.Date("2021-10-31")) ~ "delta",
      forecast_date >= as.Date("2021-11-01") ~ "omicron"
    )
  ) %>%
  group_by(model, horizon_wk, wave) %>%
  summarize(wis = mean(wis), mae = mean(abs_error), cov_50 = mean(coverage_50), cov_95 = mean(coverage_95))

  # add relative metrics
  summarized_metrics <- summarized_metrics %>%
    mutate(
      rwis = case_when(
        horizon_wk == 1 & wave == "winter21" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 4),
        horizon_wk == 2 & wave == "winter21" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 4),
        horizon_wk == 3 & wave == "winter21" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 4),
        horizon_wk == 4 & wave == "winter21" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 4),
        horizon_wk == 1 & wave == "alpha" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 4),
        horizon_wk == 2 & wave == "alpha" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 4),
        horizon_wk == 3 & wave == "alpha" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 4),
        horizon_wk == 4 & wave == "alpha" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 4),
        horizon_wk == 1 & wave == "delta" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 4),
        horizon_wk == 2 & wave == "delta" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 4),
        horizon_wk == 3 & wave == "delta" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 4),
        horizon_wk == 4 & wave == "delta" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 4),
        horizon_wk == 1 & wave == "omicron" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 4),
        horizon_wk == 2 & wave == "omicron" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 4),
        horizon_wk == 3 & wave == "omicron" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 4),
        horizon_wk == 4 & wave == "omicron" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 4),
      ),
      rmae = case_when(
        horizon_wk == 1 & wave == "winter21" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 5),
        horizon_wk == 2 & wave == "winter21" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 5),
        horizon_wk == 3 & wave == "winter21" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 5),
        horizon_wk == 4 & wave == "winter21" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 5),
        horizon_wk == 1 & wave == "alpha" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 5),
        horizon_wk == 2 & wave == "alpha" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 5),
        horizon_wk == 3 & wave == "alpha" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 5),
        horizon_wk == 4 & wave == "alpha" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 5),
        horizon_wk == 1 & wave == "delta" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 5),
        horizon_wk == 2 & wave == "delta" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 5),
        horizon_wk == 3 & wave == "delta" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 5),
        horizon_wk == 4 & wave == "delta" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 5),
        horizon_wk == 1 & wave == "omicron" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 5),
        horizon_wk == 2 & wave == "omicron" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 5),
        horizon_wk == 3 & wave == "omicron" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 5),
        horizon_wk == 4 & wave == "omicron" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 5),
      )
    ) %>%
    mutate(across(where(is.numeric), round, digits=3)) %>%
    arrange(wave, horizon_wk, wis)

    if (us_only) {
      mutate(summarized_metrics, across(wis:mae, round, digits=1))
    } else {
      summarized_metrics
    }
  }


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
  summarized_forecast_date_metrics <- scores %>%
    left_join(mon_dates_df, by = "forecast_date") %>%
    filter(
      !(location %in% c("22", "US") & forecast_date <= as.Date("2021-01-04")),
      ifelse(us_only, location == "US", location != "US")
    ) %>%
    select(model, horizon, horizon_wk, forecast_date = mon_fc_dates, target_end_date,
          true_value, abs_error, wis, coverage_50, coverage_95) %>%
    group_by(forecast_date, model, horizon_wk) %>%
    summarize(
      wis = mean(wis), mae=mean(abs_error),
      cov_50 = mean(coverage_50),
      cov_95 = mean(coverage_95)
    )
}
