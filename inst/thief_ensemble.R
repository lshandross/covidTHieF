library("thief")
library(forecast)
library(lubridate)
library(tidyverse)
library(zoltr)
library(covidHubUtils)
library(patchwork)
library(surveillance)
library(tidytext)
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
mon_fc_dates <- c(as.Date("2020-12-07") + weeks(0:46))

all_thief <- sort(paste("THieF_", c(1:4, 6, 8, 12), "wk-", c(rep("4root", 7), rep("noTransform", 7)), sep=""))[c(3:14, 1:2)]
thief_new <- sort(paste("THieF_", c(1:3, 6), "wk-", c(rep("4root", 4), rep("noTransform", 4)), sep=""))
thief_old <- sort(paste("THieF_", c(4, 8, 12), "wk-", c(rep("4root", 3), rep("noTransform", 3)), sep=""))
sarima_models <- sort(paste("sarima_s", c(1, 7), c(rep("-4root", 2), rep("-noTransform", 2)), sep=""))
models <- c(all_thief, sarima_models)
#models <- sarima_models

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

actual_fc_dates <- distinct(scores_version_sarima, forecast_date) %>% pull(1)
mon_dates_df <- tibble(forecast_date = actual_fc_dates, mon_fc_dates)
scores <- 
  rbind(scores_version_sarima, scores_version_thief_old, scores_version_thief_new) %>%
  left_join(mon_dates_df, by = "forecast_date") %>%
  mutate(horizon_wk=ceiling(as.numeric(target_end_date-mon_fc_dates)/7)) %>%
  select(-mon_fc_dates) %>%
  filter(horizon_wk %in% 1:4)

load("data/versioned_truth_training.RData")
full_hosp_truth <- load_truth("HealthData",
                         "inc hosp",
                         as_of=as.Date("2022-04-06"),
                         temporal_resolution="weekly",
                         data_location = "covidData")

scores_baseline <- score_baseline %>%
  mutate(horizon=as.numeric(horizon),
    horizon_wk=ceiling(as.numeric(target_end_date-forecast_date)/7)) %>%
  filter(horizon_wk %in% 1:4)

# Calculate model rwis
rolling_end_date <- floor_date(as.Date("2021-10-26")-1, "week", 1)
wday(rolling_end_date)
rolling_period <- weeks(12)
rolling_start_date <- rolling_end_date - rolling_period

rolling_metrics_states <- scores %>%
  rbind(scores_baseline) %>%
  filter(ifelse(location == "22", forecast_date > as.Date("2021-01-04"), location != "US")) %>%
  group_by(model) %>%
  filter(forecast_date >= rolling_start_date, forecast_date <= rolling_end_date) %>%
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
  filter(models %in% all_thief) %>%
  mutate(weight=exp(-theta * rwis) / sum(exp(-theta * rwis))) %>%
  select(model, weight)

# Create ensemble
date_index <- match(rolling_end_date, mon_fc_dates)
forecast_data <- map_dfr(all_thief, load_formatted_forecasts, date_index)
intermediate <- forecast_data %>%
  left_join(model_weights, by = "model") %>%
  mutate(ensemble_contribution=weight*value)
ensemble_forecasts <- intermediate %>%
  group_by(forecast_date, location, horizon, temporal_resolution, target_variable, target_end_date, type, quantile) %>%
  summarize(value=sum(ensemble_contribution)) %>%
  mutate(model="THieF_ensemble-train6.5", .before=forecast_date) %>%
  left_join(hub_locations, by=c("location"="fips"))





