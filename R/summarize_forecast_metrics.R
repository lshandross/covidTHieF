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
# potentially add argument to filter for a certain number of weeks?
  if (us_only) {
    scores <- filter(scores, location=="US")
  } else {
    scores <- filter(scores, location!="US")
  }
  summarized_metrics <- scores %>%
    filter(!(location %in% c("22", "US") & forecast_date <= as.Date("2021-01-04"))) %>% # < 1/11/2021 to match code in score_forecasts
  group_by(model) %>%
  summarize(WIS = mean(wis), MAE = mean(abs_error), Cov50 = mean(coverage_50), Cov95 = mean(coverage_95))

  # add relative metrics
  summarized_metrics <- summarized_metrics %>%
    mutate(
      rWIS = WIS/pull(filter(summarized_metrics, model == baseline_name), 2),
      rMAE = MAE/pull(filter(summarized_metrics, model == baseline_name), 3) #,
      #Cov50 = Cov50/abs(pull(filter(summarized_metrics, model == baseline_name), 4)-0.5),
      #rCov95 = Cov95/abs(pull(filter(summarized_metrics, model == baseline_name), 5)-0.95)
    ) %>%
    rename(Model = model) %>%
    mutate(across(where(is.numeric), round, digits=3)) %>%
    arrange(WIS)

  if (us_only) {
    mutate(summarized_metrics, across(WIS:MAE, round, digits=1))
  } else {
    summarized_metrics
  }
}

#combined_scores <- rbind(scores, scores_baseline)
#summarize_overall_metrics(scores=combined_scores, baseline_name="COVIDhub-baseline", us_only=TRUE)


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
  if (us_only) {
    scores <- filter(scores, location=="US")
  } else {
    scores <- filter(scores, location!="US")
  }
  summarized_metrics <- scores %>%
    filter(!(location %in% c("22", "US") & forecast_date <= as.Date("2021-01-04"))) %>% # < 1/11/2021 to match code in score_forecasts
  group_by(model, horizon_wk) %>%
  summarize(WIS = mean(wis), MAE = mean(abs_error), Cov50 = mean(coverage_50), Cov95 = mean(coverage_95))

  # add relative metrics
  summarized_metrics <- summarized_metrics %>%
    mutate(
      rWIS = case_when(
        horizon_wk == 1 ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 3),
        horizon_wk == 2 ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 3),
        horizon_wk == 3 ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 3),
        horizon_wk == 4 ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 3),
      ),
      rMAE = case_when(
        horizon_wk == 1 ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 4),
        horizon_wk == 2 ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 4),
        horizon_wk == 3 ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 4),
        horizon_wk == 4 ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 4),
      # rCov50, rCov95
      )
    ) %>%
    rename(Model = model) %>%
    mutate(across(where(is.numeric), round, digits=3)) %>%
    arrange(horizon_wk, WIS)

  if (us_only) {
    mutate(summarized_metrics, across(WIS:MAE, round, digits=1))
  } else {
    summarized_metrics
  }
  }

#summarize_horizon_metrics(scores=combined_scores, baseline_name="COVIDhub-baseline", us_only=TRUE)


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
  if (us_only) {
    scores <- filter(scores, location=="US")
  } else {
    scores <- filter(scores, location!="US")
  }
  summarized_metrics <- scores %>%
    filter(!(location %in% c("22", "US") & forecast_date <= as.Date("2021-01-04"))) %>% # < 1/11/2021 to match code in score_forecasts
    mutate(
      wave = case_when(
        forecast_date <= as.Date("2021-03-17") ~ "winter21",
        forecast_date %within% interval(as.Date("2021-03-18"),as.Date("2021-07-05")) ~ "alpha",
        forecast_date %within% interval(as.Date("2021-07-06"),as.Date("2021-10-31")) ~ "delta",
        forecast_date %within% interval(as.Date("2021-11-01"),as.Date("2022-04-04")) ~ "omicron",
        forecast_date >= as.Date("2022-04-05") ~ "ba4_ba5"
      )
    ) %>%
    group_by(model, horizon_wk, wave) %>%
    summarize(WIS = mean(wis), MAE = mean(abs_error), Cov50 = mean(coverage_50), Cov95 = mean(coverage_95))

  # add relative metrics
  summarized_metrics <- summarized_metrics %>%
    mutate(
      rWIS = case_when(
        horizon_wk == 1 & wave == "winter21" ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 4),
        horizon_wk == 2 & wave == "winter21" ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 4),
        horizon_wk == 3 & wave == "winter21" ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 4),
        horizon_wk == 4 & wave == "winter21" ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 4),
        horizon_wk == 1 & wave == "alpha" ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 4),
        horizon_wk == 2 & wave == "alpha" ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 4),
        horizon_wk == 3 & wave == "alpha" ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 4),
        horizon_wk == 4 & wave == "alpha" ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 4),
        horizon_wk == 1 & wave == "delta" ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 4),
        horizon_wk == 2 & wave == "delta" ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 4),
        horizon_wk == 3 & wave == "delta" ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 4),
        horizon_wk == 4 & wave == "delta" ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 4),
        horizon_wk == 1 & wave == "omicron" ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 4),
        horizon_wk == 2 & wave == "omicron" ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 4),
        horizon_wk == 3 & wave == "omicron" ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 4),
        horizon_wk == 4 & wave == "omicron" ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 4),
        horizon_wk == 1 & wave == "ba4_ba5" ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 4),
        horizon_wk == 2 & wave == "ba4_ba5" ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 4),
        horizon_wk == 3 & wave == "ba4_ba5" ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 4),
        horizon_wk == 4 & wave == "ba4_ba5" ~ WIS/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 4),
      ),
      rMAE = case_when(
        horizon_wk == 1 & wave == "winter21" ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 5),
        horizon_wk == 2 & wave == "winter21" ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 5),
        horizon_wk == 3 & wave == "winter21" ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 5),
        horizon_wk == 4 & wave == "winter21" ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 5),
        horizon_wk == 1 & wave == "alpha" ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 5),
        horizon_wk == 2 & wave == "alpha" ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 5),
        horizon_wk == 3 & wave == "alpha" ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 5),
        horizon_wk == 4 & wave == "alpha" ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 5),
        horizon_wk == 1 & wave == "delta" ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 5),
        horizon_wk == 2 & wave == "delta" ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 5),
        horizon_wk == 3 & wave == "delta" ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 5),
        horizon_wk == 4 & wave == "delta" ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 5),
        horizon_wk == 1 & wave == "omicron" ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 5),
        horizon_wk == 2 & wave == "omicron" ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 5),
        horizon_wk == 3 & wave == "omicron" ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 5),
        horizon_wk == 4 & wave == "omicron" ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 5),
        horizon_wk == 1 & wave == "ba4_ba5" ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 5),
        horizon_wk == 2 & wave == "ba4_ba5" ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 5),
        horizon_wk == 3 & wave == "ba4_ba5" ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 5),
        horizon_wk == 4 & wave == "ba4_ba5" ~ MAE/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 5),
      )
    ) %>%
    rename(Model = model) %>%
    mutate(across(where(is.numeric), round, digits=3)) %>%
    arrange(wave, horizon_wk, WIS)

    if (us_only) {
      mutate(summarized_metrics, across(WIS:MAE, round, digits=1))
    } else {
      summarized_metrics
    }
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
    scores <- filter(scores, location=="US")
  } else {
    scores <- filter(scores, location!="US")
  }
  summarized_metrics <- scores %>%
    filter(!(location %in% c("22", "US") & forecast_date <= as.Date("2021-01-04"))) %>% # < 1/11/2021 to match code in score_forecasts
    mutate(
      mon_fc_date = floor_date(forecast_date, unit = "weeks", week_start = getOption("lubricate.week.start", 1)) + weeks(1)
    ) %>%
    select(model, horizon, horizon_wk, mon_fc_date, target_end_date,
          true_value, abs_error, wis, coverage_50, coverage_95) %>%
    group_by(mon_fc_date, model, horizon_wk) %>%
    summarize(
      WIS = mean(wis), MAE=mean(abs_error),
      Cov50 = mean(coverage_50),
      Cov95 = mean(coverage_95)
    ) %>%
    rename(Model = model)
}

# summarize_forecast_date_metrics(combined_scores, us_only=TRUE)
