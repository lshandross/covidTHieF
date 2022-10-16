#' Load available forecasts from local directory (optimized for parallelization)
#'
#' @param model_vector the name of a single model
#' @param date_indices a vector of numerics corresponding to associated forecasts dates
#'
#' @return a data frame containing the forecasts from a single model during the corresponding dates to the specified date indices
#' @export
#'
#' @examples
load_formatted_forecasts <- function(model_vector, date_indices) {
  library(tidyverse)
  library(covidHubUtils)
  files <- c()
  df <- c()
  forecasts <- c()
  files <- list.files(path=paste("data/", model_vector, "/", sep=""), pattern=".csv", full.names=TRUE)
  for (j in date_indices) {
    df <- read_csv(files[j]) %>% mutate(model = model_vector)
    forecasts <- rbind(forecasts, df)
  }

  forecasts %>%
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
}
