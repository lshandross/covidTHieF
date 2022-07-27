library("thief")
library(forecast)
library(lubridate)
library(tidyverse)
library(zoltr)
library(covidHubUtils)

func_list <- list.files(path = "R", pattern=".R", full.names=TRUE)
lapply(func_list, source)

load(file="data/versioned_truth_training.RData")

start_date = as.Date("2020-07-27"); end_date = as.Date("2021-01-02")
pi_levels = c(10 * (1:9), 95, 98)

sarima_models <- sort(paste("sarima_s", c(1, 7), c(rep("-4root", 2), rep("-noTransform", 2)), sep=""))
sun_fc_dates <- c(as.Date("2020-12-06") + weeks(0:46))

# <Basic Functions No Errors>
# test <-
#   aggregate_thief_df(
#     sun_training_truth_list[[5]], ts_col = "value",
#     start_date, end_date, fips_code = "04",
#     aggregate_levels = list(56, 28, 14, 7, 1), frequency = 56, transform.4root = FALSE)
# #plot_thief_agg(test, start_date)
# temp <- compute_base_forecasts(test, pi_levels)
# temp_reconciled <- reconcilethief(temp, aggregatelist = list(56, 28, 14, 7, 1)) # produces a warning
# #plot_thief(base_forecasts= temp, reconciled_forecasts= temp_reconciled, ts_dates = dates_test, agg.names = agg.names)
# temp_rec_df <- transform_to_hub_df(temp_reconciled, end_date, "04", pi_levels, transform.4root = FALSE)

# hub_test <- thief_wrapper(sun_training_truth_list[[5]], ts_col = "value",
#   start_date, end_date, fips_code = "04",
#   aggregate_levels = list(56, 28, 14, 7, 1), frequency = 56,
#   pi_levels = pi_levels,
#   plot.aggregates = FALSE, plot.forecasts = FALSE)

sarima_test <- sarima_wrapper(df = sun_training_truth_list[[5]], ts_col = "value", start_date, end_date, fips_code = "04", frequency = 1, pi_levels, plot.forecasts = FALSE, transform.4root = FALSE)

write.csv(sarima_test[[1]], file=paste("data/", sun_fc_dates[5], "-", sarima_models[2], ".csv", sep=""))
