library("thief")
library(forecast)
library(lubridate)
library(tidyverse)
library(zoltr)
library(covidHubUtils)
library(parallel)

# Set If Statement Arguments
system <- "linux" # c("linux", "windows")
num_cores <- 32 # NA if system == "windows"
action <- "generate_forecasts" # c("load_truth", "load_testing_forecasts", "generate_forecasts")
model_spec <- list("thief", 2, FALSE) # list("THieF" or "sarima", thief_top_num or sarima_agg_num, transform.4root)
date_indices <- c(1, 17)

model_type <- ifelse(model_spec[[1]] == "thief", "THieF", model_spec[[1]])
specification <- ifelse(model_spec[[1]] == "sarima", paste("s", model_spec[[2]], sep=""), paste(model_spec[[2]], "wk", sep=""))
transform_type <- ifelse(model_spec[[3]], "4root", "noTransform")


sun_fc_dates <- c(as.Date("2020-12-06") + weeks(0:46))

# <Basic Functions No Errors>
# start_date = as.Date("2020-07-27"); end_date = as.Date("2021-01-02")
# pi_levels = c(10 * (1:9), 95, 98)
#
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
# sarima_test <- sarima_wrapper(df = sun_training_truth_list[[5]], ts_col = "value", start_date, end_date, fips_code = "04", frequency = 1, pi_levels, plot.forecasts = FALSE, transform.4root = FALSE)

load(file="data/versioned_truth_training.RData")

# Generate Forecasts
training_truth_df <- tibble(forecast_date=sun_fc_dates, truth_data=sun_training_truth_list)
actual_fc_dates <- map_dfr(sun_training_truth_list, slice_max, order_by = target_end_date, n = 1, with_ties = FALSE) %>%
  pull(target_end_date)
states53 <- filter(hub_locations, geo_type == "state", population >= 500000) %>% pull(fips)

top_level <- c(1:4, 6, 8, 12)
agg_6wk <- list(42, 21, 14, 7, 1); agg_8wk <- list(56, 28, 14, 7, 1)
aggregate_levels <- list(agg_8wk[4:5], agg_8wk[3:5], agg_6wk[3:5], agg_8wk[2:5], agg_6wk, agg_8wk, list(84, 56, 42, 28, 21, 14, 7, 1))
thief_aggregates <- tibble(top_level, aggregate_levels)

model <- paste(model_type, "_", specification, "-", transform_type, sep="")
model_agg <- thief_aggregates %>%
  filter(top_level == model_spec[[2]]) %>%
  pull(2) %>% pluck(1)
model_freq <- pluck(model_agg, 1)

# FUNCTIONS
# Generate THieF Forecasts
generate_thief_wk <-
  function(fc_dates) {
    library(tidyverse)
    library(lubridate)
    library(covidHubUtils)
    func_list <- list.files(path = "R", pattern=".R", full.names=TRUE)
    lapply(func_list, source)

    truth_df <- training_truth_df %>%
       filter(forecast_date == fc_dates) %>%
       pull(2) %>% pluck(1)

    covid_thief(truth_df, "value",
      as.Date("2020-07-27"), fc_dates, # change as needed
      fips_vec = states53, aggregate_levels = model_agg, frequency = model_freq,
      pi_levels = c(10 * (1:9), 95, 98), transform.4root = model_spec[[3]])
  }

# Generate Sarima Forecasts
generate_sarima_wk <-
  function(fc_dates) {
    library(tidyverse)
    library(lubridate)
    library(covidHubUtils)
    func_list <- list.files(path = "R", pattern=".R", full.names=TRUE)
    lapply(func_list, source)

    truth_df <- training_truth_df %>%
       filter(forecast_date == fc_dates) %>%
       pull(2) %>% pluck(1)

    covid_sarima(truth_df, "value",
      as.Date("2020-07-27"), fc_dates,
      fips_vec = states53, frequency = model_spec[[2]],
      pi_levels = c(10 * (1:9), 95, 98), transform.4root = model_spec[[3]])
  }

# Run function across previously specified number of cores
if (model_spec[[1]] == "sarima") {
  thief_fc_full <- mclapply(sun_fc_dates[date_indices[1]:date_indices[2]], mc.cores = num_cores, FUN = generate_sarima_wk)
} else {
  thief_fc_full <- mclapply(sun_fc_dates[date_indices[1]:date_indices[2]], mc.cores = num_cores, FUN = generate_thief_wk)
}

# message("Forecasts successfully generated")
#
# # write and save forecasts
# total_forecasts <- date_indices[2]-date_indices[1]+1
# model_df <- c()
# for (i in 1:total_forecasts) {
#   if (i == 1) {message("entered for loop")}
#   write.csv(thief_fc_full[[i]][[1]], file=paste("data/", model, "/", actual_fc_dates[i+date_indices[1]-1], "-", model, ".csv", sep=""))
# #  write.csv(thief_fc_full[[i]][[1]], file=paste("data/", actual_fc_dates[i+date_indices[1]-1], "-", model, ".csv", sep=""))
#   message(paste("Week", i,"forecast successfully written"))
#   if (i %in% c(1 + 6*(0:ceiling(total_forecasts/6)))) {model_df <- c()}
#   model_df <- rbind(model_df, thief_fc_full[[i]][[2]])
#   if (i %in% c(6*(1:floor(total_forecasts)/6), total_forecasts)) {
#     assign(paste("modfc", specification, transform_type, ceiling(i/6), sep="_"), model_df)
# #    save(list=paste("modfc", specification, transform_type, ceiling(i/6), sep="_"), file=paste("data/", model, "_", ceiling(i/6), ".RData", sep=""))
#     save(list=paste("modfc", specification, transform_type, ceiling(i/6), sep="_"), file=paste("data/", model, "/", model, "_", ceiling(i/6), ".RData", sep=""))
#   }
# }
# message("Forecasts successfully saved")
