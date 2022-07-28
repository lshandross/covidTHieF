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

all_thief <- sort(paste("THieF_", c(1:4, 8, 12), "wk-", c(rep("4root", 6), rep("noTransform", 6)), sep=""))[c(3:12, 1:2)]
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
# sarima_test <- sarima_wrapper(df = sun_training_truth_list[[5]], ts_col = "value", start_date, end_date, fips_code = "04", frequency = 1, pi_levels, plot.forecasts = FALSE, transform.4root = FALSE)


training_truth_df <- tibble(forecast_date=sun_fc_dates, truth_data=sun_training_truth_list)
actual_fc_dates <- map_dfr(sun_training_truth_list, slice_max, order_by = target_end_date, n = 1, with_ties = FALSE) %>%
  pull(target_end_date)
states53 <- filter(hub_locations, geo_type == "state", population >= 500000) %>% pull(fips)

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
      fips_vec = states53,
      aggregate_levels = list(21, 7, 1), frequency = 21, # change as needed
      pi_levels = c(10 * (1:9), 95, 98), transform.4root = TRUE) # change as needed
  }

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
        as.Date("2020-07-27"), fc_dates, # change as needed
        fips_vec = states53, frequency = 1, # change as needed
        pi_levels = c(10 * (1:9), 95, 98), transform.4root = FALSE) # change as needed
    }

# test <- covid_sarima(sun_training_truth_list[[5]], "value",
#   as.Date("2020-07-27"), end_date, # change as needed
#   fips_vec = states53, frequency = 1, # change as needed
#   pi_levels = c(10 * (1:9), 95, 98), transform.4root = FALSE) # change as needed

# thief_test <- covid_thief(sun_training_truth_list[[5]], "value",
#   as.Date("2020-07-27"), end_date, # change as needed
#   fips_vec = states53,
#   aggregate_levels = list(21, 7, 1), frequency = 21, # change as needed
#   pi_levels = c(10 * (1:9), 95, 98), transform.4root = FALSE) # change as needed

#thief_fc_full <- mclapply(sun_fc_dates[date_indices], mc.cores = num_cores, FUN = generate_thief_wk)
thief_fc_full <- mclapply(sun_fc_dates[5:6], mc.cores = 7, FUN = generate_sarima_wk)

write.csv(thief_fc_full[[1]][[1]], file=paste("data/", sun_fc_dates[5], "-", sarima_models[2], ".csv", sep=""))
write.csv(thief_fc_full[[2]][[1]], file=paste("data/", sun_fc_dates[6], "-", sarima_models[2], ".csv", sep=""))
