library(doParallel)
library(parallel)
library(covidHubUtils)
library(lubridate)
library(readr)

# returns number of available cores
num_cores <- detectCores(logical=TRUE)

# allocate number of available cores to R
cl <- makeCluster(num_cores-1)
registerDoParallel(cl)

# Create df to run through function
# full_hosp_truth <-
#   load_truth("HealthData", "inc hosp", temporal_resolution="daily", data_location = "remote_hub_repo")

mon_fc_dates <- c(as.Date("2020-12-07") + weeks(0:29))

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
    filter(target_end_date <= as.Date("2020-07-25"),
           geo_type == "state", population >= 500000)
  return(df)
}

# Export our function on the cluster
clusterExport(cl, list('load_weekly_truth', 'mon_fc_dates'))
# Run function across previously specified number of cores
system.time({
  training_truth_list <- c(parLapply(cl, mon_fc_dates, fun = load_weekly_truth))
})

save(training_truth_list, file="data/versioned_truth_training.RData")


# Create a function to process our data
generate_thief_wk <-
  function(fc_dates) {
    library(tidyverse)
    library(lubridate)
    library(covidHubUtils)
#    setwd("C:/Users/lshan/Documents/UMass Amherst/04 Senior/covidTHieF")
    func_list <- list.files(path = "R", pattern=".R", full.names=TRUE)
    lapply(func_list, source)

        covid_thief(NULL, "value",
          as.Date("2020-07-27"), fc_dates, # change as needed
          fips_vec = filter(hub_locations, geo_type == "state", population >= 500000) %>% pull(fips),
          aggregate_levels = list(84, 42, 28, 21, 14, 7, 1), frequency = 84, # change as needed
          pi_levels = c(10 * (1:9), 95, 98), transform.4root = TRUE) # change as needed
  }

# Export our function on the cluster
clusterExport(cl, list('generate_thief_wk', 'mon_fc_dates'))
# Run function across previously specified number of cores
system.time({
  thief_fc_full <- c(parLapply(cl, mon_fc_dates[16:20], fun = generate_thief_wk))
})

#modfc_12wk_noTrans <- c()
#modfc_12wk_4root <- c()
for (i in 1:5) {
#  write_csv(thief_fc_full[[i]][[1]], file=paste("data/THieF_12wk-4root/", mon_fc_dates[i+28], "-THieF_12wk-4root.csv", sep=""))
#  write_csv(thief_fc_full[[i]][[1]], file=paste("data/THieF_12wk-noTrans/", mon_fc_dates[i+28], "-THieF_12wk-noTrans.csv", sep=""))
  modfc_12wk_4root <- rbind(modfc_12wk_4root, thief_fc_full[[i]][[2]])
#  modfc_12wk_noTrans <- rbind(modfc_12wk_noTrans, thief_fc_full[[i]][[2]])
}

save(modfc_12wk_4root, file="data/THieF_12wk-4root/THieF_12wk-4root.RData")

forecast_list <- list.files(path = "data/Base_arima_4root/", pattern=".csv", full.names=TRUE)
for (i in 25:31) {
  df <- read_csv(forecast_list[i])
  write_csv(df, file=paste("data/Multiple3_arima_4root/", mon_fc_dates[i], "-covidTHieF-Multiple3_arima_4root.csv", sep=""))
}
getwd()
forecast_list <- list.files(path = "data", pattern=".csv", full.names=TRUE)
lapply(forecast_list, read_csv)
read_csv(paste("data/", mon_fc_dates[28], "-covidTHieF-Topmost8_arima_noTrans.csv", sep=""))
