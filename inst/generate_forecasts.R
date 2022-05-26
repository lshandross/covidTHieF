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
full_hosp_truth <-
  load_truth("HealthData", "inc hosp", temporal_resolution="daily", data_location = "remote_hub_repo")

mon_fc_dates <- c(as.Date("2020-12-07") + weeks(0:30))

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
          aggregate_levels = list(56, 28, 14, 7, 1), frequency = 56, # change as needed
          pi_levels = c(10 * (1:9), 95, 98), transform.4root = FALSE) # change as needed
  }

# Export our function on the cluster
clusterExport(cl, list('generate_thief_wk', 'mon_fc_dates'))
# Run function across previously specified number of cores
system.time({
  thief_fc_full <- c(parLapply(cl, mon_fc_dates[21:25], fun = generate_thief_wk))
})

#modfc_12wk_noTrans <- c()
#modfc_8wk_4root <- c()
for (i in 1:5) {
#  write_csv(thief_fc_full[[i]][[1]], file=paste("data/THieF_12wk-4root/", mon_fc_dates[i+0], "-THieF_12wk-4root.csv", sep=""))
  write_csv(thief_fc_full[[i]][[1]], file=paste("data/THieF_8wk-noTrans/", mon_fc_dates[i+20], "-THieF_8wk-noTrans.csv", sep=""))
  modfc_8wk_noTrans <- rbind(modfc_8wk_noTrans, thief_fc_full[[i]][[2]])
}

save(modfc_8wk_noTrans, file="data/THieF_8wk-noTrans/THieF_8wk-noTrans.RData")

forecast_list <- list.files(path = "data/Base_arima_4root/", pattern=".csv", full.names=TRUE)
for (i in 25:31) {
  df <- read_csv(forecast_list[i])
  write_csv(df, file=paste("data/Multiple3_arima_4root/", mon_fc_dates[i], "-covidTHieF-Multiple3_arima_4root.csv", sep=""))
}
getwd()
forecast_list <- list.files(path = "data", pattern=".csv", full.names=TRUE)
lapply(forecast_list, read_csv)
read_csv(paste("data/", mon_fc_dates[28], "-covidTHieF-Topmost8_arima_noTrans.csv", sep=""))
