library(doParallel)
library(covidHubUtils)
library(covidData)
library(lubridate)
library(readr)
library(tidyverse)

# Set If Statement Arguments
system <- "windows" # c("linux", "windows")
num_cores <- 0 # NA if system == "windows"
action <- "generate_forecasts" # c("load_truth", "load_testing_forecasts", "generate_forecasts")
model_type <- "sarima" # c("thief", "sarima")
date_indices <- 1:47

# Get Command Line Arguments
args = commandArgs(trailingOnly = TRUE) # system, num_cores, action

# test if there is at least one argument: if not, return an error
if (length(args) < 2) {
  stop("At least 2 arguments must be supplied (input file).n", call.=FALSE)
} else if (length(args) == 2) { # generate_forecasts, sarima, fc_dates[1:47]
  system <- args[1]
  num_cores <- args[2]
} else if (length(args) == 3) { # sarima, fc_dates[1:47]
  system <- args[1]
  num_cores <- args[2]
  action <- args[3]
} else if (length(args == 4)) { # fc_dates[1:47]
  system <- args[1]
  num_cores <- args[2]
  action <- args[3]
  model_type <- args[4]
} else if (length(args == 4)) {
  system <- args[1]
  num_cores <- args[2]
  action <- args[3]
  model_type <- args[4]
  data_indices <- args[5]
}

# Date Vectors
mon_fc_dates <- c(as.Date("2020-12-07") + weeks(0:46))
sun_fc_dates <- c(as.Date("2020-12-06") + weeks(0:46))
sun_testing_dates <- c(as.Date("2021-10-31") + weeks(0:21))

# Models
main_thief <- sort(paste("THieF_", c(4, 8, 12), "wk-", c(rep("4root", 3), rep("noTransform", 3)), sep=""))[c(3:6, 1:2)]
all_thief <- sort(paste("THieF_", c(1:4, 8, 12), "wk-", c(rep("4root", 6), rep("noTransform", 6)), sep=""))[c(3:12, 1:2)]
sarima_models <- sort(paste("sarima_s", c(1, 7), c(rep("-4root", 2), rep("-noTransform", 2)), sep=""))
models <- c(all_thief, sarima_models)

thief_info <- sort(paste("modfc_", c(1:4, 8, 12), "wk_", c(rep("4root", 6), rep("noTransform", 6)), sep=""))[c(3:12, 1:2)]
sarima_info <- sort(paste("modfc_s", c(1, 7), c(rep("_4root", 2), rep("_noTransform", 2)), sep=""))
model_info <- c(thief_info, sarima_info)
for (i in 1:length(model_info)) assign(model_info[i], NULL)

# Static Truth
# full_hosp_truth <-
#   load_truth("HealthData", "inc hosp", temporal_resolution="daily", data_location = "remote_hub_repo")

# FUNCTIONS
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


# Generate THieF Forecasts
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
      aggregate_levels = list(21, 7, 1), frequency = 21, # change as needed
      pi_levels = c(10 * (1:9), 95, 98), transform.4root = TRUE) # change as needed
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
      as.Date("2020-07-27"), fc_dates, # change as needed
      fips_vec = states53, frequency = 1, # change as needed
      pi_levels = c(10 * (1:9), 95, 98), transform.4root = FALSE) # change as needed
  }

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


if (system == "linux") {
  library(parallel)
  # dataList <- list(dat1, dat2, dat3, dat4, dat5)
  # mclapply(dataList, mc.cores = num_cores, function(dat) {   some_code_doing_something_with_dat })

  if (action == "load_truth") {
    # # Export our function on the cluster
    # clusterExport(cl, list('load_weekly_truth', 'sun_fc_dates'))

    # Run function across previously specified number of cores
    system.time({
      sun_training_truth_list <- mclapply(sun_fc_dates[date_indices], mc.cores = num_cores, FUN = load_weekly_truth)
    })

    save(mon_training_truth_list, sun_training_truth_list, file="data/versioned_truth_training.RData")

  } else if (action == "load_testing_forecasts") {
    # Pull forecasts from other models
    system.time({
      forecast_testing_list <- mclapply(sun_testing_dates[date_indices], mc.cores = num_cores, FUN = pull_forecasts)
    })

    save(forecast_testing_list, file=paste("data/", forecast_testing_list, ".RData", sep=""))
  } else {
    load(file="data/versioned_truth_training.RData")

    # Generate Forecasts
    training_truth_df <- tibble(forecast_date=sun_fc_dates, truth_data=sun_training_truth_list)
    actual_fc_dates <- map_dfr(sun_training_truth_list, slice_max, order_by = target_end_date, n = 1, with_ties = FALSE) %>%
      pull(target_end_date)
    states53 <- filter(hub_locations, geo_type == "state", population >= 500000) %>% pull(fips)

    # # Export our function on the cluster
    # clusterExport(cl, list('generate_thief_wk', 'generate_sarima_wk', 'states53', 'sun_fc_dates', 'training_truth_df'))

    # Run function across previously specified number of cores
    system.time({
      if (model_type == "sarima") {
        thief_fc_full <- mclapply(sun_fc_dates[date_indices], mc.cores = num_cores, FUN = generate_sarima_wk)
      } else {
        thief_fc_full <- mclapply(sun_fc_dates[date_indices], mc.cores = num_cores, FUN = generate_thief_wk)
      }
    })

    # write and save forecasts
      # models: THieF: 1, 2, 3, 4, 8, 12; Sarima: 1, 7
    for (i in 1:(length(date_indices)+1)) {
      #write_csv(thief_fc_full[[i]][[1]], file=paste("data/", sarima_models[2], "/", actual_fc_dates[i+0], "-", sarima_models[2], ".csv", sep=""))
      write_csv(thief_fc_full[[i]][[1]], file=paste("data/", actual_fc_dates[i+0], "-", sarima_models[2], ".csv", sep=""))
      #assign(model_info[1], rbind(modfc_s1_noTransform, thief_fc_full[[i]][[2]]))
    }

    #save(modfc_s1_noTransform, file=paste("data/", sarima_models[2], "/", sarima_models[2], ".RData", sep=""))
  }

} else {
  num_cores <- detectCores(logical=TRUE) # returns number of available cores

  # allocate number of available cores to R
  cl <- makeCluster(num_cores-1)
  registerDoParallel(cl)

  if (action == "load_truth") {
    # Export our function on the cluster
    clusterExport(cl, list('load_weekly_truth', 'sun_fc_dates'))

    # Run function across previously specified number of cores
    system.time({
      sun_training_truth_list <- c(parLapply(cl, sun_fc_dates, fun = load_weekly_truth))
    })

    save(mon_training_truth_list, sun_training_truth_list, file="data/versioned_truth_training.RData")

  } else if (action == "load_testing_forecasts") {
    # Pull forecasts from other models
    system.time({
      forecast_testing_list <- c(parLapply(cl, sun_testing_dates, fun = pull_forecasts))
    })

    save(forecast_testing_list, file=paste("data/", forecast_testing_list, ".RData", sep=""))

  } else {
    load(file="data/versioned_truth_training.RData")

    # Generate Forecasts
    training_truth_df <- tibble(forecast_date=sun_fc_dates, truth_data=sun_training_truth_list)
    actual_fc_dates <- map_dfr(sun_training_truth_list, slice_max, order_by = target_end_date, n = 1, with_ties = FALSE) %>%
      pull(target_end_date)
    states53 <- filter(hub_locations, geo_type == "state", population >= 500000) %>% pull(fips)

    # Export our function on the cluster
    clusterExport(cl, list('generate_thief_wk', 'generate_sarima_wk', 'states53', 'sun_fc_dates', 'training_truth_df'))

    # Run function across previously specified number of cores
    system.time({
      # models: THieF: 1, 2, 3, 4, 8, 12; Sarima: 1, 7
      if (model_type == "sarima") {
        thief_fc_full <- c(parLapply(cl, sun_fc_dates[36:47], fun = generate_sarima_wk))
      } else {
        thief_fc_full <- c(parLapply(cl, sun_fc_dates[1:length(sun_fc_dates)], fun = generate_thief_wk))
      }
    })

    # Write and Save forecasts
#    load(file=paste("data/", models[13], "/", models[13], ".RData", sep=""))
    for (i in 1:12) {
      write_csv(thief_fc_full[[i]][[1]], file=paste("data/", models[14], "/", actual_fc_dates[i+35], "-", models[14], ".csv", sep=""))
      assign(model_info[14], rbind(modfc_s1_noTransform, thief_fc_full[[i]][[2]]))
    }

    #modfc_3wk_4root <-rbind(modfc_3wk_noTransform, modfc_3wk_4root)
    save(modfc_s1_noTransform, file=paste("data/", models[14], "/", models[14], ".RData", sep=""))
  }
}


# for (i in 1:20) {
#   csv.temp <- read_csv(file=paste("data/", actual_fc_dates[i+0], "-", models[13], ".csv", sep=""))
#   write_csv(csv.temp, file=paste("data/", models[14], "/", actual_fc_dates[i], "-", models[14], ".csv", sep=""))
# }

