#' Load available forecasts from local directory (optimized for parallelization)
#'
#' @param model_vector the name of a single model
#' @param date_indices a vector of numerics corresponding to associated forecasts dates
#'
#' @return a data frame containing the forecasts from a single model during the
#' corresponding dates to the specified date indices
#' @export
#' @importFrom rlang .data
#' @importFrom magrittr %>%
#'
#' @examples
load_formatted_forecasts <- function(model_vector, date_indices) {
  files <- c()
  df <- c()
  forecasts <- c()
  files <- list.files(path = paste("data/", model_vector, "/", sep = ""), pattern = ".csv", full.names = TRUE)
  for (j in date_indices) {
    df <- readr::read_csv(files[j]) %>%
      dplyr::mutate(model = model_vector)
    forecasts <- rbind(forecasts, df)
  }

  forecasts %>%
    tidyr::separate(target, into = c("horizon", "temp"), sep = " ") %>%
    dplyr::mutate(
      horizon = as.numeric(.data[["horizon"]]),
      temporal_resolution = "day",
      target_variable = "inc hosp"
    ) %>%
    dplyr::select("model", "forecast_date", "location", "horizon", "target_variable", "target_end_date", "type", "quantile", "value") %>%
    dplyr::left_join(covidHubUtils::hub_locations, by = c("location" = "fips"))
}
