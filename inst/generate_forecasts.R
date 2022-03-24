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
generate_thief_fc <-
  function(fc_periods) {
    library(tidyverse)
    library(lubridate)
    library(covidHubUtils)
#    setwd("C:/Users/lshan/Documents/UMass Amherst/04 Senior/covidTHieF")
    func_list <- list.files(path = "R", pattern=".R", full.names=TRUE)
    lapply(func_list, source)

    covid_thief(full_hosp_truth, "value",
      as.Date("2020-07-27") + fc_periods, mon_fc_dates[28] + fc_periods, # change as needed
      fips_vec = filter(hub_locations, geo_type == "state", population >= 500000) %>% pull(fips),
      aggregate_levels = c(56, 8, 4, 2, 1), frequency = 56, # change as needed
      pi_levels = c(10 * (1:9), 95, 98),
      model_name="Topmost8_arima_noTrans") # change as needed
  }

# Export our function on the cluster
clusterExport(cl, list('generate_thief_fc', 'full_hosp_truth', 'mon_fc_dates'))
# Run function across previously specified number of cores
system.time({
  thief_fc <- c(parLapply(cl, c(0: 6), fun = generate_thief_fc))
  
  full_df <- thief_fc[[1]]; temp_df <- thief_fc[[1]]
  for (i in 2:length(thief_fc)) {
    temp_df <- thief_fc[[i]]
    full_df <- rbind(full_df, temp_df)
  }
})


# Format: "YYYY-MM-DD-team-model.csv", change as needed
write_csv(full_df, file=paste("data/", mon_fc_dates[28], "-covidTHieF-Topmost8_arima_noTrans.csv", sep=""))


# Create a function to process our data
generate_thief_wk <-
  function(fc_dates) {
    library(tidyverse)
    library(lubridate)
    library(covidHubUtils)
#    setwd("C:/Users/lshan/Documents/UMass Amherst/04 Senior/covidTHieF")
    func_list <- list.files(path = "R", pattern=".R", full.names=TRUE)
    lapply(func_list, source)
    
        covid_thief(full_hosp_truth, "value",
          as.Date("2020-07-27"), fc_dates, # change as needed
          fips_vec = filter(hub_locations, geo_type == "state", population >= 500000) %>% pull(fips),
          aggregate_levels = c(84, 42, 28, 21, 14, 7, 1), frequency = 84, # change as needed
          pi_levels = c(10 * (1:9), 95, 98),
          model_name="Multiple3_arima_noTrans") # change as needed
  }
  

# Export our function on the cluster
clusterExport(cl, list('generate_thief_wk', 'full_hosp_truth', 'mon_fc_dates'))
# Run function across previously specified number of cores
system.time({
  thief_fc_full <- c(parLapply(cl, mon_fc_dates, fun = generate_thief_wk))
})
 
for (i in 1:length(mon_fc_dates)) {
  write_csv(thief_fc_full[[i]], file=paste("data/", mon_fc_dates[i], "-covidTHieF-Multiple3_arima_noTrans.csv", sep=""))
}

getwd()
forecast_list <- list.files(path = "data", pattern=".csv", full.names=TRUE)
lapply(forecast_list, read_csv)
read_csv(paste("data/", mon_fc_dates[28], "-covidTHieF-Topmost8_arima_noTrans.csv", sep=""))