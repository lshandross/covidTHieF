plot_thief_agg <- function(temporal_hierarchy, start_date) {
  library(lubridate)
  library(tidyverse)
  library(thief)
  
  start_date <- as.Date(start_date)

  # Make actual date labels for plot
  freq <-frequency(temporal_hierarchy[[1]])
  periods <- floor(length(temporal_hierarchy[[1]]) / freq)
  dates_actual_agg <- rep(start_date - weeks(1), periods + 1)
  for (i in 1:length(dates_actual_agg)) {
    dates_actual_agg[i] <- start_date + (i-1)*weeks(freq/7)
  }

  # Plot temporal hierarchy data
  plot(temporal_hierarchy, main="Covid-19 Inc Hosp", xaxt = "n")
  axis(1, at=1:(periods + 1), labels = dates_actual_agg, line = 1.1)
}
