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
  summarize(wis = mean(wis), mae = mean(abs_error), cov_50 = mean(coverage_50), cov_95 = mean(coverage_95))

  # add relative metrics
  summarized_metrics <- summarized_metrics %>%
    mutate(
      rwis = wis/pull(filter(summarized_metrics, model == baseline_name), 2),
      rmae = mae/pull(filter(summarized_metrics, model == baseline_name), 3),
      #cov_50 = cov_50/abs(pull(filter(summarized_metrics, model == baseline_name), 4)-0.5),
      #rcov_95 = cov_95/abs(pull(filter(summarized_metrics, model == baseline_name), 5)-0.95),
    ) %>%
    mutate(across(where(is.numeric), round, digits=3)) %>%
    arrange(wis)

  if (us_only) {
    mutate(summarized_metrics, across(wis:mae, round, digits=1))
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
        forecast_date %in% c(as.Date("2021-03-18"):as.Date("2021-07-05")) ~ "alpha",
        forecast_date %in% c(as.Date("2021-07-06"):as.Date("2021-10-31")) ~ "delta",
        forecast_date %in% c(as.Date("2021-11-01"):as.Date("2022-04-04")) ~ "omicron",
        forecast_date >= as.Date("2022-04-05") ~ "ba4_ba5"
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
        horizon_wk == 1 & wave == "ba4_ba5" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 4),
        horizon_wk == 2 & wave == "ba4_ba5" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 4),
        horizon_wk == 3 & wave == "ba4_ba5" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 4),
        horizon_wk == 4 & wave == "ba4_ba5" ~ wis/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 4),
      ),
      rmae = case_when(
        horizon_wk == 1 & wave == "winter21" ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 5),
        horizon_wk == 2 & wave == "winter21" ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 5),
        horizon_wk == 3 & wave == "winter21" ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 5),
        horizon_wk == 4 & wave == "winter21" ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 5),
        horizon_wk == 1 & wave == "alpha" ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 5),
        horizon_wk == 2 & wave == "alpha" ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 5),
        horizon_wk == 3 & wave == "alpha" ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 5),
        horizon_wk == 4 & wave == "alpha" ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 5),
        horizon_wk == 1 & wave == "delta" ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 5),
        horizon_wk == 2 & wave == "delta" ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 5),
        horizon_wk == 3 & wave == "delta" ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 5),
        horizon_wk == 4 & wave == "delta" ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 5),
        horizon_wk == 1 & wave == "omicron" ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 5),
        horizon_wk == 2 & wave == "omicron" ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 5),
        horizon_wk == 3 & wave == "omicron" ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 5),
        horizon_wk == 4 & wave == "omicron" ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 5),
        horizon_wk == 1 & wave == "ba4_ba5" ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 1), 5),
        horizon_wk == 2 & wave == "ba4_ba5" ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 2), 5),
        horizon_wk == 3 & wave == "ba4_ba5" ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 3), 5),
        horizon_wk == 4 & wave == "ba4_ba5" ~ mae/pull(filter(summarized_metrics, model == baseline_name, horizon_wk == 4), 5),
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
      wis = mean(wis), mae=mean(abs_error),
      cov_50 = mean(coverage_50),
      cov_95 = mean(coverage_95)
    )
}

# summarize_forecast_date_metrics(combined_scores, us_only=TRUE)
