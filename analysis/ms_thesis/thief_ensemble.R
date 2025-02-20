library("thief")
library(forecast)
library(lubridate)
library(tidyverse)
library(zoltr)
library(covidHubUtils)
library(patchwork)
library(stringr)
library(hubEnsembles)

# Load in functions
func_list <- list.files(path = "R", pattern=".R", full.names=TRUE)
lapply(func_list, source)

# parallelize code
library(doParallel)
num_cores <- detectCores(logical=TRUE)
cl <- makeCluster(num_cores-1)
registerDoParallel(cl)
#source("inst/load_score_forecasts.R")

# Set variables, load in data
inc_hosp_targets <- paste(0:30, "day ahead inc hosp")
fips <- filter(hub_locations, geo_type == "state", population >= 500000) %>% pull(fips)
phase <- "testing"

# Date Vectors
mon_training_dates <- c(as.Date("2020-12-07") + weeks(0:46))
sun_training_dates <- c(as.Date("2020-12-06") + weeks(0:46))
mon_testing_dates <- c(as.Date("2021-11-01") + weeks(0:47))
sun_testing_dates <- c(as.Date("2021-10-31") + weeks(0:47))
mon_all_dates <- c(mon_training_dates, mon_testing_dates)

if (phase == "training") {
  mon_fc_dates <- mon_training_dates
  sun_fc_dates <- sun_training_dates

  # load("data/extended_fcv_thief_old.RData")
  # load("data/extended_fcv_thief_new.RData")
  # load("data/extended_fcv_sarima.RData")
  # load("data/extended_fcv_thief_old_small.RData")
  # load("data/extended_fcv_thief_new_small.RData")
  # load("data/extended_fcv_sarima_small.RData")
  load("data/extended_scv_thief_old.RData")
  load("data/extended_scv_thief_new.RData")
  load("data/extended_scv_sarima.RData")
  load("data/baseline_fc_scores_extended.RData")

  load("data/versioned_truth_training.RData")
  actual_fc_dates <- distinct(scores_version_sarima, forecast_date) %>% pull(1)
  full_hosp_truth <- load_truth("HealthData",
                           "inc hosp",
                           as_of=as.Date("2022-04-06"),
                           temporal_resolution="weekly",
                           data_location = "covidData")

  mon_dates_df <- tibble(forecast_date = actual_fc_dates, mon_fc_dates)
  scores <- rbind(scores_version_sarima, scores_version_thief_old, scores_version_thief_new) %>%
    left_join(mon_dates_df, by = "forecast_date") %>%
    mutate(horizon_wk=ceiling(as.numeric(target_end_date-c(mon_training_dates, mon_testing_dates))/7)) %>%
    select(-mon_fc_dates) %>%
    filter(horizon_wk %in% 1:4)
} else {
  mon_fc_dates <- mon_testing_dates
  sun_fc_dates <- sun_testing_dates

  # load("data/testing_fcv_thief_old.RData")
  # load("data/testing_fcv_thief_new.RData")
  # load("data/testing_fcv_sarima.RData")
  # load("data/testing_fcv_thief_old_small.RData")
  # load("data/testing_fcv_thief_new_small.RData")
  # load("data/testing_fcv_sarima_small.RData")
  load("data/testing_scv_thief_old.RData")
  load("data/testing_scv_thief_new.RData")
  load("data/baseline_fc_scores_testing.RData")
  
  load("data/extended_scv_thief_old.RData")
  load("data/extended_scv_thief_new.RData")
  load("data/baseline_fc_scores_extended.RData")

  actual_fc_dates <- rbind(scores_version_thief_old, scores_testing_thief_old) %>%
    distinct(forecast_date) %>% pull(1)
  load(file="data/versioned_truth_testing.RData")
  full_hosp_truth <- load_truth("HealthData",
                           "inc hosp",
                           as_of=as.Date("2022-12-06"),
                           temporal_resolution="weekly",
                           data_location = "covidData")

  mon_dates_df <- tibble(forecast_date = actual_fc_dates, mon_all_dates) # must include training and testing dates
  scores <- rbind(scores_version_thief_old, scores_version_thief_new) %>%
    rbind(scores_testing_thief_old, scores_testing_thief_new) %>%
    left_join(mon_dates_df, by = "forecast_date") %>%
    mutate(horizon_wk=ceiling(as.numeric(target_end_date-mon_all_dates)/7)) %>%
    select(-mon_all_dates) %>%
    filter(horizon_wk %in% 1:4)
    
  score_baseline <- rbind(scores_testing_baseline, scores_validation_baseline)
}

all_thief <- sort(paste("THieF_", c(1:4, 6, 8, 12), "wk-", c(rep("4root", 7), rep("noTransform", 7)), sep=""))[c(3:14, 1:2)]
thief_new <- sort(paste("THieF_", c(1:3, 6), "wk-", c(rep("4root", 4), rep("noTransform", 4)), sep=""))
thief_old <- sort(paste("THieF_", c(4, 8, 12), "wk-", c(rep("4root", 3), rep("noTransform", 3)), sep=""))
sarima_models <- sort(paste("sarima_s", c(1, 7), c(rep("-4root", 2), rep("-noTransform", 2)), sep=""))
models <- all_thief

scores_baseline <- score_baseline %>%
  mutate(horizon=as.numeric(horizon),
    horizon_wk=ceiling(as.numeric(target_end_date-forecast_date)/7)) %>%
  filter(horizon_wk %in% 1:4)

scores_clean <- scores %>%
  filter(model %in% all_thief) %>%
  rbind(scores_baseline) %>%
  filter(ifelse(location == "22", forecast_date > as.Date("2021-01-04"), location != "US"))

# Calculate model rwis
rolling_end_date <- floor_date(as.Date("2021-11-01")-1, "week", 1)
wday(rolling_end_date)
rolling_period <- weeks(12)
rolling_start_date <- rolling_end_date - rolling_period

rolling_metrics_states <- scores_clean %>%
  filter(forecast_date >= rolling_start_date, forecast_date <= rolling_end_date) %>%
  group_by(model) %>%
  summarize(
    wis = mean(wis), mae=mean(abs_error),
    cov_50 = mean(coverage_50),
    cov_95 = mean(coverage_95)
  )
rolling_metrics_states <- rolling_metrics_states %>%
  mutate(
    rwis = wis/pull(filter(rolling_metrics_states, model == "COVIDhub-baseline"), 2),
    rmae = mae/pull(filter(rolling_metrics_states, model == "COVIDhub-baseline"), 3),
  ) %>%
  filter(model != "COVIDhub-baseline") %>%
  mutate(across(where(is.numeric), round, digits=3)) %>%
  arrange(wis)

# Compute weights
theta <- 6.5
model_weights <- rolling_metrics_states %>%
  filter(model %in% all_thief) %>%
  mutate(weight=exp(-theta * rwis) / sum(exp(-theta * rwis))) %>%
  select(model, weight)

# Create ensemble
date_index <- match(rolling_end_date, mon_fc_dates) + ifelse(phase == "testing", 47, 0)
forecast_data <- map_dfr(all_thief, load_formatted_forecasts, date_index)
intermediate <- forecast_data %>%
  left_join(model_weights, by = "model") %>%
  mutate(ensemble_contribution=weight*value)
ensemble_forecasts <- intermediate %>%
  group_by(forecast_date, location, horizon, temporal_resolution, target_variable, target_end_date, type, quantile) %>%
  summarize(value=sum(ensemble_contribution)) %>%
  mutate(model="THieF_ensemble-train6.5", .before=forecast_date) %>%
  left_join(hub_locations, by=c("location"="fips"))



#Updated version
build_composite_ensemble <- function(forecast_df = NULL, composite_models, scores_df = NULL, truth_data, use_median_as_point = TRUE, rolling_period, theta = 0, ensemble_name = NULL, forecast_date, reference_dates, phase = "training") {
  library(tidyverse)
  library(lubridate)
  library(covidHubUtils)
  library(zoltr)
  # Load in functions
  func_list <- list.files(path = "R", pattern=".R", full.names=TRUE)
  lapply(func_list, source)

  if (is.character(forecast_date)) { forecast_date <- as.Date(forecast_date)}
  rolling_end_date <- floor_date(forecast_date-1, "week", 1)
  rolling_start_date <- rolling_end_date - rolling_period

  date_index <- match(rolling_end_date + weeks(1), reference_dates) + ifelse(phase == "testing", 47, 0)

  if (is.null(forecast_df)) {
    forecast_df <- map_dfr(composite_models, load_formatted_forecasts, date_index)
  }

  if (date_index < time_length(rolling_period, "week")) {
    warning("Insufficient forecasts provided for entire rolling period. Equal weights will be used instead.")
    theta <- 0
  }

  if (is.null(scores_df)) {
    scores_df <- score_forecasts(forecasts_df, return_format="wide", truth=truth_data, use_median_as_point=use_median_as_point)
  }

  # compute weights
  rolling_metrics_states <- scores_df %>%
    group_by(model) %>%
    filter(forecast_date >= rolling_start_date, forecast_date <= rolling_end_date) %>%
    summarize(wis = mean(wis), mae=mean(abs_error))
  model_weights <- rolling_metrics_states %>%
    mutate(
      rwis = wis/pull(filter(rolling_metrics_states, model == "COVIDhub-baseline"), 2),
      rmae = mae/pull(filter(rolling_metrics_states, model == "COVIDhub-baseline"), 3),
    ) %>%
    filter(model != "COVIDhub-baseline", model %in% composite_models) %>%
    mutate(weight= exp(-theta * rwis) / sum(exp(-theta * rwis))) %>%
    select(model, weight)

  # Build ensemble
  ensemble_forecasts <- forecast_df %>%
    left_join(model_weights, by = "model") %>%
    mutate(ensemble_contribution = ifelse(date_index == 1, 1/length(composite_models), weight)*value) %>%
    group_by(forecast_date, location, horizon, temporal_resolution, target_variable, target_end_date, type, quantile) %>%
    summarize(value=sum(ensemble_contribution)) %>%
    mutate(model = ensemble_name, .before = forecast_date) %>%
    left_join(hub_locations, by = c("location" = "fips"))

  (ensemble_forecasts)
}

# Testing
ensemble_test <- build_composite_ensemble(forecast_df = NULL, composite_models = all_thief, scores_df = scores_clean, truth_data = NULL, rolling_period = weeks(12), theta = 6.5, ensemble_name = "THieF_ensemble-train6.5", forecast_date = as.Date("2021-11-02"), reference_dates = mon_fc_dates)

fc_dates <- as.Date("2021-10-26")
theta <- 6.5 # c(0, 3, 6.5, 10, 15, 20, 25)
ensemble_name <- paste("THieF_ensemble-", ifelse(theta == 0, "mean", paste("train", theta, sep="")), sep="")

# Parallelize function for cluster
  generate_ensemble_wk <-
    function(fc_dates) {
      message(paste("Starting", fc_dates, "forecasts"))
      library(tidyverse)
      library(lubridate)
      library(covidHubUtils)
      func_list <- list.files(path = "R", pattern=".R", full.names=TRUE)
      lapply(func_list, source)

      results <-
        build_composite_ensemble(
          forecast_df = NULL, composite_models = all_thief,
          scores_df = scores_clean, truth_data = NULL,
          rolling_period = weeks(12), theta = theta, ensemble_name = ensemble_name,
          forecast_date = fc_dates, reference_dates = mon_fc_dates)
      message(paste("Finished", fc_dates, "forecasts"))
      return(results)
    }

parallel_test <- generate_ensemble_wk(fc_dates)
