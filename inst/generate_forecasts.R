library(doParallel)
library(parallel)
library(covidHubUtils)

# returns number of available cores
num_cores <- detectCores(logical=TRUE)

# allocate number of available cores to R
cl <- makeCluster(num_cores-1)
registerDoParallel(cl)

# Create df to run through function
full_hosp_truth <- load_truth("HealthData",
                              "inc hosp",
                              temporal_resolution="weekly",
                              data_location = "remote_hub_repo")

# Create a function to process our data
test_func <-
  function(fc_periods) {
    source("scrapwork/covidTHieF_functions.R") # needs to be changed - maybe build the package?
    library(tidyverse)

    covid_thief(full_hosp_truth, "value", 
      as.Date("2020-07-27") + fc_periods, as.Date("2021-07-26") + fc_periods, # change as needed
      fips_vec = c("01", "02"), 
      aggregate_levels = c(56, 8, 4, 2, 1), frequency = 56, # change as needed
      pi_levels = c(10 * (1:9), 95, 98), 
      model_name="Topmost8_arima_notrans") %>% # change as needed
      mutate(forecast_date = forecast_date + fc_periods, target_end_date = target_end_date + fc_periods)
  }

# Export our function on the cluster
clusterExport(cl, list('test_func', 'full_hosp_truth'))
# Run function across previously specified number of cores
system.time({
  myresult <- c(parLapply(cl, c(0: 6), fun = test_func))
})

full_df <- myresult[[1]]; temp_df <- myresult[[1]]
for (i in 2:length(myresult)) {
  temp_df <- myresult[[i]]
  full_df <- rbind(full_df, temp_df)
}

# Format: "YYYY-MM-DD-team-model.csv", change as needed
write_csv(mutate(full_df), "../data/YYYY-MM-DD-team-model.csv")