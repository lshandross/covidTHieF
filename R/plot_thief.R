# Additional data and date vectors for plotting - FIX ME
extended_truth_data <-
  function(df, ts_col = "value", start_date, end_date, fips_code, aggregate_levels = list(56, 28, 14, 7, 1), frequency = 56) {
    # an extra 1*(top agg level) of truth data to plot against forecasts
    aggregate_thief_df(df, ts_col, start_date, end_date + days(frequency), fips_code, aggregate_levels, frequency) 
  }

get_ts_dates <-
  function(start_date, end_date, frequency = 56) {
    library(tidyverse)
    library(lubridate)
    
    freq <- frequency
    time_period <- as.numeric(end_date - start_date) + 1
    periods <- floor(time_period / freq)
    dates_actual_forecast <- rep(start_date - weeks(1), periods + 1)
    for (i in 1:length(dates_actual_forecast)) {
      dates_actual_forecast[i] <- start_date + (i-1)*weeks(freq/7)
    }
    return(dates_actual_forecast)
}
  
plot_thief <- 
  function(base_forecasts, reconciled_forecasts, ts_dates, extended_truth = NULL) {
    library(tidyverse)
    library(lubridate)
    library(forecast)
    library(thief)
    
    periods <- floor(length(base_forecasts[[1]]$x) / frequency(base_forecasts[[1]]$x))
    par(mfrow=c(ceiling(length(base_forecasts)/2), 2), mai=c(0.35,0.5,0.35,0.35))
    for(i in seq_along(base_forecasts))
    { # This code is not optimized for plotting when there are many levels
      plot(reconciled_forecasts[[i]], main=agg.names[i], shadecols = c("light gray", "#C2DDEE", "#00458F") , 
          xaxt = "n", #axes = FALSE,
          ylim = c(0, max(reconciled_forecasts[[i]]$x, reconciled_forecasts[[i]]$upper))) 
      lines(reconciled_forecasts[[i]]$mean, col=4, lwd=2) # plots blue reconciled forecasts line
      lines(base_forecasts[[i]]$mean, col='red') # plots red mean line
      if(!is.null(extended_truth)) lines(extended_truth[[i]], col='black', lwd=1.5, lty = "dotted") # plots extended truth data against forecasts
      axis(1, at=1:(periods + 4), labels = ts_dates) # changes axis labels to provided dates
      axis(2)
    }
    points(base_forecasts[[length(base_forecasts)]]$mean, col= 'red')
  }