#' Plot aggregated time series data
#'
#' @param temporal_hierarchy A list of (hierarchical) time series.
#' @param start_date A date from which the data begins. Used to calculate date labels for the plot.
#'
#' @return A plot of the input time series stacked on top of each other, sharing an x-axis.
#' @export
#' @importFrom rlang .data
#' @importFrom magrittr %>%
#'
#' @examples
plot_thief_agg <- function(temporal_hierarchy, start_date) {
  start_date <- as.Date(start_date)

  # Make actual date labels for plot
  freq <- frequency(temporal_hierarchy[[1]])
  periods <- floor(length(temporal_hierarchy[[1]]) / freq)
  dates_actual_agg <- rep(start_date - lubridate::weeks(1), periods + 1)
  for (i in 1:length(dates_actual_agg)) {
    dates_actual_agg[i] <- start_date + (i - 1) * lubridate::weeks(freq / 7)
  }

  # Plot temporal hierarchy data
  plot(temporal_hierarchy, main = "Covid-19 Inc Hosp", xaxt = "n")
  graphics::axis(1, at = 1:(periods + 1), labels = dates_actual_agg, line = 1.1)
}
