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
phase <- "testing" # c("training", "testing")
model_spec <- list("sarima", 1, FALSE) # list("THieF" or "sarima", thief_top_num or sarima_agg_num, transform.4root)
# ensemble: list("ensemble",6.5, NA) -> "THieF_ensemble-train6.5"
date_indices <- c(1, 48)

model_type <- ifelse(model_spec[[1]] == "thief", "THieF", model_spec[[1]])
specification <- 
    case_when(
        pluck(model_spec, 1) == "sarima" ~ paste("s", pluck(model_spec, 2), sep=""), 
        pluck(model_spec, 1) == "thief" ~ paste(pluck(model_spec, 2), "wk", sep=""), 
        pluck(model_spec, 1) == "ensemble" ~ as.character(pluck(model_spec, 2))
    )
transform_type <- 
    case_when(pluck(model_spec, 3) ~ "4root", 
              !pluck(model_spec, 3) ~ "noTransform",
              is.na(pluck(model_spec, 3)) ~ "THieF")

# Date Vectors
mon_training_dates <- c(as.Date("2020-12-07") + weeks(0:46))
sun_training_dates <- c(as.Date("2020-12-06") + weeks(0:46))
mon_testing_dates <- c(as.Date("2021-11-01") + weeks(0:47))
sun_testing_dates <- c(as.Date("2021-10-31") + weeks(0:47))
mon_all_dates <- c(mon_training_dates, mon_testing_dates)

if (phase == "training") {
    mon_fc_dates <- mon_training_dates
    sun_fc_dates <- sun_training_dates
} else {
    mon_fc_dates <- mon_testing_dates
    sun_fc_dates <- sun_testing_dates
}

states53 <- filter(hub_locations, geo_type == "state", population >= 500000) %>% pull(fips)

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

if (phase == "training") {
    load(file="data/versioned_truth_training.RData")
    truth_df <- tibble(forecast_date=sun_training_dates, truth_data=sun_training_truth_list)
    actual_fc_dates <- map_dfr(sun_training_truth_list, slice_max, order_by = target_end_date, n = 1, with_ties = FALSE) %>%
        pull(target_end_date)
} else {
    load(file="data/versioned_truth_testing.RData")
    truth_df <- tibble(forecast_date=sun_testing_dates, truth_data=sun_testing_truth_list)
    actual_fc_dates <- map_dfr(sun_testing_truth_list, slice_max, order_by = target_end_date, n = 1, with_ties = FALSE) %>%
        pull(target_end_date)
}

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
        
        truth <- truth_df %>%
            filter(forecast_date == fc_dates) %>%
            pull(2) %>% pluck(1)
        
        covid_thief(truth, "value",
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
        
        truth <- truth_df %>%
            filter(forecast_date == fc_dates) %>%
            pull(2) %>% pluck(1)
        
        covid_sarima(truth, "value",
                     as.Date("2020-07-27"), fc_dates, # change as needed
                     fips_vec = states53, frequency = 1, # change as needed
                     pi_levels = c(10 * (1:9), 95, 98), transform.4root = FALSE) # change as needed
    }

# Generate Ensemble Forecasts
generate_ensemble_wk <-
    function(fc_dates) {
        library(tidyverse)
        library(lubridate)
        library(covidHubUtils)
        func_list <- list.files(path = "R", pattern=".R", full.names=TRUE)
        lapply(func_list, source)
        
        results <- 
            build_composite_ensemble(
                forecast_df = NULL, composite_models = all_thief, 
                scores_df = scores_clean, truth_data = NULL, use_median_as_point = TRUE,
                rolling_period = weeks(12), theta = 0, # change as needed
                ensemble_name = ensemble_name, # change as needed
                forecast_date = fc_dates, reference_dates = mon_fc_dates)
        message(paste("Finished", fc_dates, "forecasts"))
        return(results)
    }

# Export our function on the cluster
clusterExport(cl, list('generate_thief_wk', 'generate_sarima_wk', 'states53', 'sun_fc_dates', 'truth_df', 'model_spec'))


# Run function across previously specified number of cores
system.time({
    # models: THieF: 1, 2, 3, 4, 8, 12; Sarima: 1, 7
    if (model_type == "sarima") {
#        fc_list <- map(sun_fc_dates[31:36], generate_sarima_wk)
                fc_list <- c(parLapply(cl, sun_fc_dates[31:36], fun = generate_sarima_wk))
    } else {
        #        fc_list <- c(parLapply(cl, sun_fc_dates[1:30], fun = generate_thief_wk))
    }
})

modfc_s1_noTransform = NULL
# Write and Save forecasts

#    load(file=paste("data/", models[13], "/", models[13], ".RData", sep=""))
for (i in 1:6) {
    write_csv(fc_list[[i]][[1]], file=paste("data/", models[14], "/", actual_fc_dates[i+30], "-", models[14], ".csv", sep=""))
    assign(model_info[14], rbind(modfc_s1_noTransform, fc_list[[i]][[2]]))
}

#modfc_3wk_4root <-rbind(modfc_3wk_noTransform, modfc_3wk_4root)
save(modfc_s1_noTransform, file=paste("data/", models[14], "/", models[14], "6.RData", sep=""))


for (i in 43:48) {
    print(paste("data/", models[14], "/", actual_fc_dates[i], "-", models[14], ".csv", sep=""))
    read_csv(file=paste("data/", models[14], "/", actual_fc_dates[i], "-", models[14], ".csv", sep=""), show_col_types = FALSE) %>%
        slice(1) %>%
        print()
}
