library(doParallel)
library(parallel)
library(covidHubUtils)

# returns number of available cores
num_cores <- detectCores(logical=TRUE)

# allocate number of available cores to R
cl <- makeCluster(num_cores-1)
registerDoParallel(cl)

# Create df to run through function
full_hosp_truth <-
  load_truth("HealthData", "inc hosp", temporal_resolution="weekly", data_location = "remote_hub_repo")

# Create a function to process our data
generate_thief_fc <-
  function(fc_periods) {
    library(tidyverse)
    library(lubridate)
#    setwd("C:/Users/lshan/Documents/UMass Amherst/04 Senior/covidTHieF")
    func_list <- list.files(path = "R", pattern=".R", full.names=TRUE)
    lapply(func_list, source)

    covid_thief(full_hosp_truth, "value",
      as.Date("2020-07-27") + fc_periods, as.Date("2021-07-26") + fc_periods, # change as needed
      fips_vec = c("01", "02"),
      aggregate_levels = c(56, 8, 4, 2, 1), frequency = 56, # change as needed
      pi_levels = c(10 * (1:9), 95, 98),
      model_name="Topmost8_arima_noTrans") # change as needed
  }

# Export our function on the cluster
clusterExport(cl, list('generate_thief_fc', 'full_hosp_truth'))
# Run function across previously specified number of cores
system.time({
  thief_fc <- c(parLapply(cl, c(0: 6), fun = generate_thief_fc))
})

full_df <- thief_fc[[1]]; temp_df <- thief_fc[[1]]
for (i in 2:length(thief_fc)) {
  temp_df <- thief_fc[[i]]
  full_df <- rbind(full_df, temp_df)
}

# Format: "YYYY-MM-DD-team-model.csv", change as needed
write_csv(mutate(full_df), "../data/YYYY-MM-DD-team-model.csv")
