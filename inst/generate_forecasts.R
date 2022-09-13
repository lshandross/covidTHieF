library(parallel)
library(covidHubUtils)
library(covidData)
library(lubridate)
library(readr)
library(tidyverse)
library(thief)

# Set If Statement Arguments
system <- "windows" # c("linux", "windows")
num_cores <- 0 # NA if system == "windows"
action <- "generate_forecasts" # c("load_truth", "load_testing_forecasts", "generate_forecasts")
model_spec <- list("sarima", 1, TRUE) # list("THieF" or "sarima", thief_top_num or sarima_agg_num, transform.4root)
date_indices <- c(1, 47)

# Get Command Line Arguments
args <- commandArgs(trailingOnly = TRUE) # system, num_cores, action, model_specs(type, specification, transform), date_indices

# test if there is at least one argument: if not, return an error
if (length(args) < 2) {
  stop("At least 2 arguments must be supplied (input file).n", call.=FALSE)
} else if (length(args) == 2) { # generate_forecasts, sarima_s1-4root, fc_dates[1:47]
  system <- args[1]
  num_cores <- as.numeric(args[2])
} else if (length(args) == 3) { # sarima_s1-4root, fc_dates[1:47]
  system <- args[1]
  num_cores <- as.numeric(args[2])
  action <- args[3]
} else if (length(args) %in% 4:5) {
  stop("More arguments must be supplied (input file).n", call.=FALSE)
} else if (length(args) %in% 6:7) { # fc_dates[1:47]
  system <- args[1]
  num_cores <- as.numeric(args[2])
  action <- args[3]
  model_spec <- list(args[4], as.numeric(args[5]), as.logical(args[6]))
} else if (length(args == 8)) {
  system <- args[1]
  num_cores <- as.numeric(args[2])
  action <- args[3]
  model_spec <- list(args[4], as.numeric(args[5]), as.logical(args[6]))
  date_indices <- c(as.numeric(args[7]), as.numeric(args[8]))
}

model_type <- ifelse(model_spec[[1]] == "thief", "THieF", model_spec[[1]])
specification <- ifelse(model_spec[[1]] == "sarima", paste("s", model_spec[[2]], sep=""), paste(model_spec[[2]], "wk", sep=""))
transform_type <- ifelse(model_spec[[3]], "4root", "noTransform")

# Date Vectors
mon_fc_dates <- c(as.Date("2020-12-07") + weeks(0:46))
sun_fc_dates <- c(as.Date("2020-12-06") + weeks(0:46))
sun_testing_dates <- c(as.Date("2021-10-31") + weeks(0:21))

# Static Truth
# full_hosp_truth <-
#   load_truth("HealthData", "inc hosp", temporal_resolution="daily", data_location = "remote_hub_repo")

states53 <- filter(hub_locations, geo_type == "state", population >= 500000) %>% pull(fips)

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


# Pull forecasts from other models
#hub_models <- # eligible models
pull_forecasts <- function(fc_dates) {
  library(tidyverse)
  library(covidHubUtils)
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
  if (action == "load_truth") {
    # Run function across previously specified number of cores
    mon_training_truth_list <- mclapply(mon_fc_dates, mc.cores = num_cores, FUN = load_weekly_truth)
    sun_training_truth_list <- mclapply(sun_fc_dates, mc.cores = num_cores, FUN = load_weekly_truth)

    save(mon_training_truth_list, sun_training_truth_list, file="data/versioned_truth_training.RData")

  } else if (action == "load_testing_forecasts") {
    # Pull forecasts from other models
    forecast_testing_list <- mclapply(sun_testing_dates[date_indices], mc.cores = num_cores, FUN = pull_forecasts)

    save(forecast_testing_list, file=paste("data/", forecast_testing_list, ".RData", sep=""))
  } else { #action == "generate_forecasts"
    load(file="data/versioned_truth_training.RData")

    # Generate Forecasts
    training_truth_df <- tibble(forecast_date=sun_fc_dates, truth_data=sun_training_truth_list)
    actual_fc_dates <- map_dfr(sun_training_truth_list, slice_max, order_by = target_end_date, n = 1, with_ties = FALSE) %>%
      pull(target_end_date)
    
    top_level <- c(1:4, 6, 8, 12)
    agg_6wk <- list(42, 21, 14, 7, 1); agg_8wk <- list(56, 28, 14, 7, 1)
    aggregate_levels <- list(agg_8wk[4:5], agg_8wk[3:5], list(21, 7, 1), agg_8wk[2:5], agg_6wk, agg_8wk, list(84, 42, 28, 21, 14, 7, 1))
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
      message(paste("Starting", fc_dates, "forecasts"))
      library(tidyverse)
      library(lubridate)
      library(covidHubUtils)
      func_list <- list.files(path = "R", pattern=".R", full.names=TRUE)
      lapply(func_list, source)

      truth_df <- training_truth_df %>%
         filter(forecast_date == fc_dates) %>%
         pull(2) %>% pluck(1)
      results <- covid_thief(truth_df, "value",
        as.Date("2020-07-27"), fc_dates, # change as needed
        fips_vec = states53, aggregate_levels = model_agg, frequency = model_freq,
        pi_levels = c(10 * (1:9), 95, 98), transform.4root = model_spec[[3]])
      message(paste("Finished", fc_dates, "forecasts"))
      return(results)
    }

  # Generate Sarima Forecasts
  generate_sarima_wk <-
    function(fc_dates) {
      message(paste("Starting", fc_dates, "forecasts"))
      library(tidyverse)
      library(lubridate)
      library(covidHubUtils)
      func_list <- list.files(path = "R", pattern=".R", full.names=TRUE)
      lapply(func_list, source)

      truth_df <- training_truth_df %>%
         filter(forecast_date == fc_dates) %>%
         pull(2) %>% pluck(1)
      results <- covid_sarima(truth_df, "value",
        as.Date("2020-07-27"), fc_dates,
        fips_vec = states53, frequency = model_spec[[2]],
        pi_levels = c(10 * (1:9), 95, 98), transform.4root = model_spec[[3]])
      message(paste("Finished", fc_dates, "forecasts"))
      return(results)
    }

    # Run function across previously specified number of cores
    if (model_spec[[1]] == "sarima") {
      thief_fc_full <- mclapply(sun_fc_dates[date_indices[1]:date_indices[2]], mc.cores = num_cores, FUN = generate_sarima_wk)
    } else { # model_spec[[1]] == "thief"
      thief_fc_full <- mclapply(sun_fc_dates[date_indices[1]:date_indices[2]], mc.cores = num_cores, FUN = generate_thief_wk)
    }
    
    message("Forecasts successfully generated")

    # write and save forecasts
    if (date_indices[1] %in% c(1 + 6*(0:ceiling(47/6)))) {
      model_df <- c()
    } else {
#      load(paste("data/", model, "_", ceiling((date_indices[1]-1)/6), ".RData", sep=""))
      load(paste("data/", model, "/", model, "_", ceiling((date_indices[1]-1)/6), ".RData", sep=""))
    }
    for (i in date_indices[1]:date_indices[2]) {
      if (i == date_indices[1]) {message("entered for loop")}
#      write.csv(thief_fc_full[[i-date_indices[1]+1]][[1]], file=paste("data/", actual_fc_dates[i], "-", model, ".csv", sep=""))
      write.csv(thief_fc_full[[i-date_indices[1]+1]][[1]], file=paste("data/", model, "/", actual_fc_dates[i], "-", model, ".csv", sep=""))
      message(paste(model, "week", i,"csv file written"))
      if (i %in% c(1 + 6*(0:ceiling(47/6)))) {model_df <- c()}
      model_df <- rbind(model_df, thief_fc_full[[i-date_indices[1]+1]][[2]])
      if (i %in% c(6*(1:floor(47/6)), 47)) {
        assign(paste("modfc", specification, transform_type, ceiling(i/6), sep="_"), model_df)
#        save(list=paste("modfc", specification, transform_type, ceiling(i/6), sep="_"), file=paste("data/", model, "_", ceiling(i/6), ".RData", sep=""))
        save(list=paste("modfc", specification, transform_type, ceiling(i/6), sep="_"), file=paste("data/", model, "/", model, "_", ceiling(i/6), ".RData", sep=""))
      message(paste(model, "RData object", ceiling(i/6), "saved"))
      } 
    }
  }

} else {
  library(doParallel)
  num_cores <- detectCores(logical=TRUE) # returns number of available cores

  # allocate number of available cores to R
  cl <- makeCluster(num_cores-1)
  registerDoParallel(cl)

  # Models
  main_thief <- sort(paste("THieF_", c(4, 8, 12), "wk-", c(rep("4root", 3), rep("noTransform", 3)), sep=""))[c(3:6, 1:2)]
  all_thief <- sort(paste("THieF_", c(1:4, 8, 12), "wk-", c(rep("4root", 6), rep("noTransform", 6)), sep=""))[c(3:12, 1:2)]
  sarima_models <- sort(paste("sarima_s", c(1, 7), c(rep("-4root", 2), rep("-noTransform", 2)), sep=""))
  models <- c(all_thief, sarima_models)

  thief_info <- sort(paste("modfc_", c(1:4, 8, 12), "wk_", c(rep("4root", 6), rep("noTransform", 6)), sep=""))[c(3:12, 1:2)]
  sarima_info <- sort(paste("modfc_s", c(1, 7), c(rep("_4root", 2), rep("_noTransform", 2)), sep=""))
  model_info <- c(thief_info, sarima_info)
  for (i in 1:length(model_info)) assign(model_info[i], NULL)


  if (action == "load_truth") {
    # Export our function on the cluster
    clusterExport(cl, list('load_weekly_truth', 'sun_fc_dates'))

    # Run function across previously specified number of cores
    system.time({
      sun_training_truth_list <- c(parLapply(cl, sun_fc_dates, fun = load_weekly_truth))
    })

    save(mon_training_truth_list, sun_training_truth_list, file="data/versioned_truth_training.RData")

  } else if (action == "load_testing_forecasts") {
    # Export our function on the cluster
    clusterExport(cl, list('pull_forecasts', 'sun_testing_dates', 'states53'))
    
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

    # FUNCTIONS
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
          aggregate_levels = list(84, 42, 28, 21, 14, 7, 1), frequency = 84, # change as needed
          pi_levels = c(10 * (1:9), 95, 98), transform.4root = FALSE) # change as needed
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

    # Export our function on the cluster
    clusterExport(cl, list('generate_thief_wk', 'generate_sarima_wk', 'states53', 'sun_fc_dates', 'training_truth_df'))

    # Run function across previously specified number of cores
    system.time({
      # models: THieF: 1, 2, 3, 4, 8, 12; Sarima: 1, 7
      if (model_type == "sarima") {
        thief_fc_full <- c(parLapply(cl, sun_fc_dates[36:47], fun = generate_sarima_wk))
      } else {
        thief_fc_full <- c(parLapply(cl, sun_fc_dates[1:30], fun = generate_thief_wk))
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

