library("thief")
library("MAPA")
library("hts")
library("fable")
library(forecast)
library(lubridate)
library(tidyverse)
library(zoltr)
library(covidHubUtils)

# Example with Covid-19 inc hosp data. We adjust the top aggregation level to be 8 weeks, as we can't reasonably predict anything with a longer horizon well-enough. 
require(FoReco)
B = 1000
m = 56
agg_levels <- c(56, 28, 14, 7, 1)

# get truth data
full_hosp_truth <- load_truth("HealthData", 
                         "inc hosp", 
                         temporal_resolution="weekly",
                         data_location = "remote_hub_repo")

start_date <- as.Date("2020-07-27") # a monday
end_date <- as.Date("2021-06-27")

hosp_truth <- full_hosp_truth |>
  dplyr::filter(target_end_date >= start_date,
                target_end_date <= end_date,
                location == "US") %>%
  mutate(day = wday(target_end_date), epi_week = epiweek(target_end_date)) %>%
  dplyr::select(value, epi_week, day)

# Construct aggregates (from daily data)
hosp_ts <- ts(hosp_truth$value, start = c(4,1), end = c(9, 56), frequency = 56) 
hosp_agg <- lapply(agg_levels, agg_ts, x = hosp_ts, align = "end", rm_na = FALSE)   # Aggregated time series list
agg.names <- c("8-weekly", "4-weekly", "2-weekly", "weekly", "daily")
for(i in seq_along(hosp_agg)) names(hosp_agg)[[i]] <- agg.names[i]
plot(hosp_agg, main="Covid-19 Inc Hosp")


# Make forecasts
fit.arima <- lapply(hosp_agg, function(x) auto.arima(ts(x, frequency = frequency(x)))) # arima model fit
forecast_obj.arima <- lapply(fit.arima, function(tsfit) # make into a forecast object
  forecast(tsfit, h=frequency(tsfit$x)))    # (frequency taken from inputs)
base_mean.arima <- sapply(forecast_obj.arima, function(x) x$mean)  # base mean for each level
res.arima <- Reduce("c", sapply(fit.arima, residuals, type='response'))   # in-sample residuals (one-step)

# Gaussian approach
# Multi-step residuals
hres_list.arima <- lapply(fit.arima, function(mod)       # mod = model within the fit object
  lapply(1:frequency(mod$x), function(h)     # get frequency of ts at each agg level
    residuals(mod, type='response', h = h))) # get residuals at each level
    # note residuals = y_t - yhat_t, where t < h (aka observed time before predicted horizons)
  # list of residuals separated by aggregation level and time point
hres.arima <- Reduce("c", lapply(hres_list.arima, arrange_hres))
  # Reduce list down into vector (length 102) of residuals following order of og data
  # original data [102 total]: annual [6]; quarterly [24]; monthly [72]

# Re-arrenge multi-step residuals in a matrix form
mres.arima <- residuals_matrix(hres.arima, m = agg_levels)

base.arima <- MASS::mvrnorm(n = B, mu = unlist(base_mean.arima), Sigma = shrink_estim(mres.arima)$scov)
reco.arima <- t(apply(base.arima, 1, thfrec, m = agg_levels, comb = "wlsv", res = res.arima, keep = "recf"))

reco_quantiles <- apply(base.arima, 2, quantile, probs = c(0.01, 0.025, seq(0.05, 0.95, 0.05), 0.975, 0.99), na.rm = TRUE)
reco_subset <- apply(base.arima, 2, quantile, probs = c(0.025, 0.25, 0.5, 0.75, 0.975), na.rm = TRUE)


# Compute base forecasts
old_hosp_agg <- tsaggregates(hosp_ts, m = 56, aggregatelist = as.list(agg_levels))
 base_fc_day <- list()
 for(i in seq_along(old_hosp_agg))
   base_fc_day[[i]] <- forecast(auto.arima(old_hosp_agg[[i]]), h=2*frequency(old_hosp_agg[[i]]), level = c(50, 95)) 
 
# Reconcile forecasts
reconciled_fc_day <- reconcilethief(base_fc_day, aggregatelist = as.list(agg_levels))

# Overall, the probabilistic forecasts seem to adhere closer to the recent truth data values and produce wider intervals.

# Plot forecasts before and after reconcilliation
par(mfrow=c(3,2))
for(i in seq_along(base_fc_day))
{
  plot(reconciled_fc_day[[i]], main=agg.names[i], 
       ylim = c(0, max(reconciled_fc_day[[i]]$x, reconciled_fc_day[[i]]$upper))) 
  lines(base_fc_day[[i]]$mean, col='red') # plots red mean line
}

#It would be a good idea to also plot the truth data here to compare how the base and reconciled forecasts did in terms of their predictions.