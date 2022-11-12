# Load libraries
library("thief")
library(forecast)
library(lubridate)
library(tidyverse)
library(zoltr)
library(covidHubUtils)
library(stringr)

# parallelize code
library(doParallel)
num_cores <- detectCores(logical=TRUE)
cl <- makeCluster(num_cores-1)
registerDoParallel(cl)

# Instantiate variables
inc_hosp_targets <- paste(0:30, "day ahead inc hosp")
fips <- filter(hub_locations, geo_type == "state", population >= 500000) %>% pull(fips)
mon_fc_dates <- c(as.Date("2020-12-07") + weeks(0:46))

all_thief <- sort(paste("THieF_", c(1:4, 6, 8, 12), "wk-", c(rep("4root", 7), rep("noTransform", 7)), sep=""))[c(3:14, 1:2)]
thief_new <- sort(paste("THieF_", c(1:3, 6), "wk-", c(rep("4root", 4), rep("noTransform", 4)), sep=""))
thief_old <- sort(paste("THieF_", c(4, 8, 12), "wk-", c(rep("4root", 3), rep("noTransform", 3)), sep=""))
sarima_models <- sort(paste("sarima_s", c(1, 7), c(rep("-4root", 2), rep("-noTransform", 2)), sep=""))
thief_ensembles <- paste("THieF_ensemble-", c("mean", paste(rep("train", 6), c(1, 3, 6.5, 10, 15, 20, 25), sep="")), sep="")
#models <- c(all_thief, sarima_models)
models <- thief_ensembles

# LOAD FORECASTS
# forecasts_baseline <- load_forecasts(models = "COVIDhub-baseline",
#                                         dates = mon_fc_dates,
#                                         date_window_size = 6, 
#                                         locations = fips,
#                                         types = c("point","quantile"),
#                                         targets = inc_hosp_targets,
#                                         source = "zoltar",
#                                         verbose = FALSE,
#                                         as_of=NULL,
#                                         hub = c("US"))
# 

# Load local formatted forecasts
date_indices <- 1:47
load_formatted_forecasts <- function(model_vector) {
  library(tidyverse)
  library(covidHubUtils)
  files <- rep("path", length(date_indices))
  df <- c()
  forecasts <- c()
  files <- list.files(path=paste("data/", model_vector, "/", sep=""), pattern=".csv", full.names=TRUE)
  for (j in date_indices) {
    df <- read_csv(files[j]) %>% mutate(model = model_vector)
    forecasts <- rbind(forecasts, df)
  }

  forecasts <- forecasts %>%
    separate(target,
      into=c("horizon", "temp"),
      sep=" "
    ) %>%
    mutate(
      horizon=as.numeric(horizon),
      temporal_resolution="day",
      target_variable="inc hosp"
    ) %>%
    select(model, forecast_date, location, horizon, temporal_resolution, target_variable, target_end_date:value) %>%
    left_join(hub_locations, by=c("location"="fips"))
    
  return (forecasts)
}

# Export our function on the cluster
clusterExport(cl, list('load_formatted_forecasts', 'models', 'all_thief', 'date_indices'))

# Run function across previously specified number of cores
system.time({
  fc_versioned_list <- c(parLapply(cl, models, fun = load_formatted_forecasts))
})

fc_version_thief_ensemble <- map_dfr(models, load_formatted_forecasts)

# Split into data frames
fc_version_thief_new <- c(); fc_version_thief_old <- c(); fc_version_sarima <- c()
for (i in 1:length(fc_versioned_list)) {
  if (i %in% c(1:6, 9, 10)) {
    fc_version_thief_new <- rbind(fc_version_thief_new, fc_versioned_list[[i]])
  } else if (i %in% c(7, 8, 11:14)) {
    fc_version_thief_old <- rbind(fc_version_thief_old, fc_versioned_list[[i]])
  } else {
    fc_version_sarima <- rbind(fc_version_sarima, fc_versioned_list[[i]])
  }
}

# save(full_hosp_truth, sun_training_truth_list, sun_testing_truth_list, file = "all_truth_data.RData")
# save(fc_version_sarima, file="data/extended_fcv_sarima.RData")
# save(fc_version_thief_old, file="data/extended_fcv_thief_old.RData")
# save(fc_version_thief_new, file="data/extended_fcv_thief_new.RData")


# SCORE FORECASTS
full_hosp_truth <- load_truth("HealthData", 
                         "inc hosp", 
                         as_of=as.Date("2022-04-06"),
                         temporal_resolution="weekly",
                         data_location = "covidData")

#scores_ver <- score_forecasts(forecasts=forecasts_ver, return_format="wide", truth=full_hosp_truth, use_median_as_point=TRUE)
#score_baseline <- score_forecasts(forecasts=forecasts_baseline, return_format="wide", truth=full_hosp_truth, use_median_as_point=FALSE)
  # note that the default column order may differ between these dfs due to existence of separate point forecasts
  # you will need to re-order the columns to correctly rbind them: score_baseline <- select(score_baseline, 1:7, 20, 9:19, 21:49, 8)

# if forecasts are too big for a single call
df_to_score <- fc_version_thief_ensemble
parallel_scoring <- function (model_vector) { 
    library(tidyverse)
    library(covidHubUtils)
    score_forecasts(
      forecasts=filter(df_to_score, model==model_vector),
      return_format="wide",
      truth=full_hosp_truth,
      use_median_as_point=TRUE
    )
}

# Export our function on the cluster
clusterExport(cl, list('parallel_scoring', 'full_hosp_truth', 'models', 'df_to_score'))

# Run function across previously specified number of cores
system.time({
  scores_list_temp <- c(parLapply(cl, models, fun = parallel_scoring))
})

scores_version_thief_ensemble <- c()
for (i in 1:length(models)) {
  scores_version_thief_ensemble <- rbind(scores_version_thief_ensemble, scores_list_temp[[i]])
}

save(scores_version_thief_ensemble, file="data/extended_scv_thief_ensemble.RData")

# save(forecasts_ver, scores_ver, mon_dates_df, file="data/versioned_fc_df.RData")
# save(forecasts_baseline, scores_base, file="data/baseline_fc_scores.RData")
