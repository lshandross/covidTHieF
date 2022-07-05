#' Generate extended (aggregated) truth data
#'
#' @param df A data frame containing the desired truth data as one of the columns. Defaults to NULL in which hospitalization truth data is sourced as of the user-specified \code{end_date}.
#' @param ts_col The name of the column containing the truth data. This column is coerced into a time series object of class \code{ts} and thus should be a numeric type.
#' @param start_date A date from which the data begins.
#' @param end_date A date where the original data ends. An additional \code{frequency} days are added to the \code{end_date}.
#' @param fips_code A 2-digit code specifying a United States state or territory of type \code{char}.
#' @param aggregate_levels A user-selected list of aggregates to use.
#' @param frequency Integer seasonal period. Specifies the additional number of days worth of truth data to include.
#'
#' @return A list of time series of extended truth data. The first element is a \code{ts} object made by coercing the original truth data into a time series format, followed by series with increasing levels of aggregation.
#' @export
#'
#' @examples
# Additional data and date vectors for plotting (as of what date?) - FIX ME
extended_truth_data <-
  function(df, ts_col = "value", start_date, end_date, fips_code, aggregate_levels = list(56, 28, 14, 7, 1), frequency = 56) {
    # an extra 1*(top agg level) of truth data to plot against forecasts
    extra_days <- max(frequency, 28)*2
    aggregate_thief_df(df, ts_col, start_date, end_date + days(extra_days), fips_code, aggregate_levels, frequency)
  }

#'
#' @param start_date A date from which the data begins. Used to calculate the actual dates of the time series.
#' @param most_recent_date A date where the truth data ends. Used to calculate the actual dates of the time series.
#' @param frequency Integer seasonal period. Specifies how many actual dates to calculate.
#'
#' @return A vector of dates of length \code{frequency}.
#' @export
#'
#' @examples
get_ts_dates <-
  function(start_date, most_recent_date, frequency = 56) {
    library(tidyverse)
    library(lubridate)

    freq <- frequency
    time_period <- as.numeric(most_recent_date - start_date)
    periods <- floor(time_period / freq)
    dates_actual_forecast <- rep(start_date - weeks(1), periods + 1)
    for (i in 1:length(dates_actual_forecast)) {
      dates_actual_forecast[i] <- start_date + (i-1)*weeks(freq/7)
    }
    return(dates_actual_forecast)
}

#' Plot base and reconciled temporal hierarchical forecasts.
#'
#' @param base_forecasts A \code{forecast} object containing the original (unreconciled) base forecasts.
#' @param reconciled_forecasts A \code{forecast} object containing reconciled forecasts. If prediction intervals are specified, two will be shown.
#' @param ts_dates A vector of dates to be used as x-axis labels.
#' @param extended_truth A list of time series to be plotted against the forecasts for comparison. Defaults to NULL in which no extended truth line is shown.
#' @param agg.names A vector of titles for the plots of each aggregation level. Defaults to NULL in which the detected ARIMA model is used to name the plots.
#'
#' @return A collection of plots made at every aggregation level displaying base point forecasts, reconciled point forecasts, reconciled prediction intervals at two different levels, and the truth data used to make the forecasts. The user may provide extended truth data to plot against the forecasts for an accuracy comparison.
#' @export
#'
#' @examples
plot_thief <-
  function(base_forecasts, reconciled_forecasts, ts_dates, extended_truth = NULL, agg.names = NULL) {
    library(tidyverse)
    library(lubridate)
    library(forecast)
    library(thief)

    periods <- floor(length(base_forecasts[[1]]$x) / frequency(base_forecasts[[1]]$x)) # maybe change to reconciled_forecasts so function is usable without base_forecasts?
    par(mfrow=c(ceiling(length(base_forecasts)/2), 2), mai=c(0.35,0.5,0.35,0.35))
    for(i in seq_along(base_forecasts))
    { # This code is not optimized for plotting when there are many levels
      plot(reconciled_forecasts[[i]], main=agg.names[i], shadecols = c("light gray", "#C2DDEE", "#00458F") ,
          xaxt = "n", #axes = FALSE,
          ylim = c(0, max(reconciled_forecasts[[i]]$x, reconciled_forecasts[[i]]$upper)))
      lines(reconciled_forecasts[[i]]$mean, col=4, lwd=2) # plots blue reconciled forecasts line
      lines(base_forecasts[[i]]$mean, col='red') # plots red mean line
      if(!is.null(extended_truth)) lines(extended_truth[[i]], col='black', lwd=1.5, lty = "dotted") # plots extended truth data against forecasts
      axis(1, at=1:(periods + 1), labels = ts_dates) # changes axis labels to provided dates
      axis(2)
    }
    points(base_forecasts[[length(base_forecasts)]]$mean, col= 'red')
  }
