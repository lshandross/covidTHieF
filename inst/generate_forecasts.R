library(doParallel)
library(parallel)
library(covidHubUtils)
library(lubridate)
library(readr)
library(tidyverse)

# returns number of available cores
num_cores <- detectCores(logical=TRUE)

# allocate number of available cores to R
cl <- makeCluster(num_cores-1)
registerDoParallel(cl)

# Create df to run through function
# full_hosp_truth <-
#   load_truth("HealthData", "inc hosp", temporal_resolution="daily", data_location = "remote_hub_repo")

# Date Vectors
mon_fc_dates <- c(as.Date("2020-12-07") + weeks(0:29))
sun_fc_dates <- c(as.Date("2020-12-06") + weeks(0:29))
sun_testing_dates <- c(as.Date("2020-12-06") + weeks(0:29))

# Save time by pre-loading as of truth data for all dates of interest in a list
load_weekly_truth <- function(fc_dates) {
  library(tidyverse)
  library(lubridate)
  library(covidHubUtils)
  df <- load_truth("HealthData",
                   "inc hosp",
                   as_of = fc_dates,
                   temporal_resolution="daily",
                   data_location = "covidData")
  df <- df %>%
    filter(target_end_date >= as.Date("2020-07-27"),
           geo_type == "state", population >= 500000) %>%
    arrange(desc(target_end_date), location)

  return(df)
}

# Export our function on the cluster
clusterExport(cl, list('load_weekly_truth', 'mon_fc_dates'))
# Run function across previously specified number of cores
system.time({
  sun_training_truth_list <- c(parLapply(cl, sun_fc_dates, fun = load_weekly_truth))
})

#save(mon_training_truth_list, sun_training_truth_list, file="data/versioned_truth_training.RData")
load(file="data/versioned_truth_training.RData")

training_truth_df <- tibble(forecast_date=sun_fc_dates, truth_data=sun_training_truth_list)

states53 <- filter(hub_locations, geo_type == "state", population >= 500000) %>% pull(fips)

# Generate forecasts
generate_thief_wk <-
  function(fc_dates) {
    library(tidyverse)
    library(lubridate)
    library(covidHubUtils)
#    setwd("C:/Users/lshan/Documents/UMass Amherst/04 Senior/covidTHieF")
    func_list <- list.files(path = "R", pattern=".R", full.names=TRUE)
    lapply(func_list, source)

    truth_df <- training_truth_df %>%
      filter(forecast_date == fc_dates) %>%
      pull(2) %>% pluck(1)

    covid_thief(truth_df, "value",
      as.Date("2020-07-27"), fc_dates, # change as needed
      fips_vec = states53,
      aggregate_levels = list(56, 28, 14, 7, 1), frequency = 56, # change as needed
      pi_levels = c(10 * (1:9), 95, 98), transform.4root = TRUE) # change as needed
  }

# Export our function on the cluster
clusterExport(cl, list('generate_thief_wk', 'states53', 'sun_fc_dates', 'training_truth_df'))
#clusterExport(cl, list('generate_thief_wk', 'mon_fc_dates'))

# Run function across previously specified number of cores
system.time({
  thief_fc_full <- c(parLapply(cl, sun_fc_dates[6:9], fun = generate_thief_wk))
})

#models <- c("THieF_4wk-4root", "THieF_4wk-noTrans", "THieF_8wk-4root", "THieF_8wk-noTrans", "THieF_12wk-4root", "THieF_12wk-noTrans")

#modfc_4wk_noTrans <- c()
#modfc_8wk_4root <- c()
for (i in 1:4) {
  write_csv(thief_fc_full[[i]][[1]], file=paste("data/", models[3], "/", mon_fc_dates[i+5], "-", models[3], ".csv", sep=""))
  modfc_8wk_4root <- rbind(modfc_8wk_4root, thief_fc_full[[i]][[2]])
#  modfc_4wk_noTrans <- rbind(modfc_4wk_noTrans, thief_fc_full[[i]][[2]])
}

save(modfc_8wk_4root, file=paste("data/", models[3], "/", models[3], ".RData", sep=""))


# Pull forecasts from other models
#hub_models <- # eligible models
pull_forecasts <- function(fc_dates) {
  load_forecasts(#models = hub_models,
                dates = fc_dates,
                date_window_size = 6,
                locations = states53,
                types = c("point","quantile"),
                targets = paste(0:30, "day ahead inc hosp"),
                source = "zoltar",
                verbose = FALSE,
                as_of=NULL,
                hub = c("US"))
}

system.time({
  forecast_testing_list <- c(parLapply(cl, sun_testing_dates, fun = pull_forecasts))
})

save(forecast_testing_list, file=paste("data/", forecast_testing_list, ".RData", sep=""))