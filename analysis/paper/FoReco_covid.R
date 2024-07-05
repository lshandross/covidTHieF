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
end_date <- as.Date("2021-07-26")

hosp_truth <- full_hosp_truth |>
  dplyr::filter(target_end_date >= start_date,
                target_end_date <= end_date,
                location == "US") %>%
  mutate(day = wday(target_end_date), epi_week = epiweek(target_end_date)) %>%
  dplyr::select(value, epi_week, day)

# Construct aggregates (from daily data)
hosp_ts <- ts(hosp_truth$value, start = c(4,1), end = c(10, 29), frequency = 56)

# Aggregate target data new
hosp_agg <- lapply(agg_levels, agg_ts, x = hosp_ts, align = "end", rm_na = FALSE)   # Aggregated time series list (from FoReco)
agg.names <- c("8-weekly", "4-weekly", "2-weekly", "weekly", "daily")
for(i in seq_along(hosp_agg)) names(hosp_agg)[[i]] <- agg.names[i]
par(mfrow = c(3, 2))
for (i in 1:5) plot.ts(hosp_agg[[i]], plot.type="single", main=names(hosp_agg)[i])

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

reco_quantiles <- apply(reco.arima, 2, quantile, probs = c(0.01, 0.025, seq(0.05, 0.95, 0.05), 0.975, 0.99), na.rm = TRUE)
reco_subset <- apply(reco.arima, 2, quantile, probs = c(0.025, 0.25, 0.5, 0.75, 0.975), na.rm = TRUE)

# try with more samples
base.large <- MASS::mvrnorm(n = 10000, mu = unlist(base_mean.arima), Sigma = shrink_estim(mres.arima)$scov)
reco.large <- t(apply(base.arima, 1, thfrec, m = agg_levels, comb = "wlsv", res = res.arima, keep = "recf"))
quantiles_large <- apply(reco.large, 2, quantile, probs = c(0.025, 0.25, 0.5, 0.75, 0.975), na.rm = TRUE) #exact same as with fewer samples


reconciled_df <- reco_subset |>
  as.table() |>
  as.data.frame() |>
  dplyr::mutate(
    Var1 = paste0("q", stringr::str_remove_all(Var1, "%")),
    Var2 = as.character(Var2),
    Freq = ifelse(Freq < 0, 0, Freq)
  ) |>
  tidyr::pivot_wider(names_from="Var1", values_from="Freq") |>
  dplyr::mutate(
    k = as.numeric(stringr::str_extract(Var2, "\\d*(?=h)")),
    h = as.numeric(stringr::str_extract(Var2, "(?<=h)\\d*")),
    level = case_when(k == 56 ~ "8-weekly", k == 28 ~ "4-weekly",
                      k == 14 ~ "2-weekly", k == 7 ~ "weekly",
                      k == 1 ~ "daily", .default = NA),
    level=factor(level, levels=unique(level), ordered=TRUE),
#    test = time(hosp_agg[[level]])[length(hosp_agg[[level]])],
    test = case_when(k == 56 ~ time(hosp_agg[["8-weekly"]])[length(hosp_agg[["8-weekly"]])],
                     k == 28 ~ time(hosp_agg[["4-weekly"]])[length(hosp_agg[["4-weekly"]])],
                     k == 14 ~ time(hosp_agg[["2-weekly"]])[length(hosp_agg[["2-weekly"]])],
                     k == 7 ~ time(hosp_agg[["weekly"]])[length(hosp_agg[["weekly"]])],
                     k == 1 ~ time(hosp_agg[["daily"]])[length(hosp_agg[["daily"]])],
                     .default = NA),
    date = k*h
  )

  ggplot(reconciled_df, aes(x = date, group = level)) +
    geom_ribbon(aes(ymin = q2.5, ymax = q97.5, fill = "95% PI"), alpha = .75) + 
    geom_ribbon(aes(ymin = q25, ymax = q75, fill = "50% PI"), alpha = .75) +
    geom_line(aes(y = q50), col = 4) +
    geom_point(aes(y = q50), col = 4) +
    facet_grid(rows = vars(level), scales = "free") +
    scale_fill_manual(name = "", values = c("50% PI" = "#00458F", "95% PI" = "#C2DDEE")) +
    xlab("Date") + ylab(" ") +
  #  theme(axis.title.x="Date", axis.title.y="") +
    ggtitle("Reconcile Forecasts New")
      
hosp_agg |> View()
time(hosp_agg[["4-weekly"]])[length(hosp_agg[["4-weekly"]])]

# Aggregate target data old
old_hosp_agg <- tsaggregates(hosp_ts, m = 56, aggregatelist = as.list(agg_levels))
old.agg.names <- c("daily", "weekly", "2-weekly", "4-weekly", "8-weekly")
for(i in seq_along(old_hosp_agg)) names(old_hosp_agg)[[i]] <- old.agg.names[i]
plot(old_hosp_agg, main = "Covid-19 Inc Hosp")

# Compute base forecasts old
base_fc_day <- list()
for(i in seq_along(old_hosp_agg))
  base_fc_day[[i]] <- forecast(auto.arima(old_hosp_agg[[i]]), h=frequency(old_hosp_agg[[i]]), level = c(50, 95))

# Reconcile forecasts
reconciled_fc_day <- reconcilethief(base_fc_day, aggregatelist = as.list(agg_levels))

# Overall, the probabilistic forecasts seem to adhere closer to the recent truth data values and produce wider intervals.

# Extend truth line
extended_truth <- full_hosp_truth |>
  dplyr::filter(target_end_date >= end_date,
                 target_end_date <= end_date + weeks(8),
                 location == "US") |>
  dplyr::mutate(day = wday(target_end_date), epi_week = epiweek(target_end_date)) |>
  dplyr::select("value", "epi_week", "day")

long_truth <- rbind(hosp_truth, extended_truth)
long_ts <- ts(long_truth$value, start=c(4, 1), end=c(11, 29), frequency=56)

long_aggs <- tsaggregates(long_ts, m=56, aggregatelist = as.list(agg_levels))
for (i in seq_along(long_aggs)) names(long_aggs)[[i]] <- old.agg.names[i]

# Plot forecasts before and after reconcilliation
par(mfrow=c(3,2), mai=c(0.35, 0.5, 0.35, 0.35))
for(i in seq_along(base_fc_day)) {
  plot(reconciled_fc_day[[i]], main=old.agg.names[i], shadecols = c("#C2DDEE", "#00458F"),
       ylim = c(0, max(reconciled_fc_day[[i]]$x, reconciled_fc_day[[i]]$upper)))
  lines(base_fc_day[[i]]$mean, col='red') # plots red mean line
  lines(reconciled_fc_day[[i]]$mean, col='blue', lwd=2) # plots blue rec mean line
  lines(long_aggs[[i]], col='black', lwd=1.5, lty="dotted") # plots extended truth
}
points(base_fc_day[[5]]$mean, col='red')



    # Reconciled forecasts
    aggregation_list <- as.list(agg_levels); date_list <- list(); frequency <- 56
    q025 <- NULL; q25 <- NULL; q50 <- NULL; q75 <- NULL; q975 <- NULL
    level_list <- list(); level <- NULL
    for (i in 1:length(aggregation_list)) {
      date_list[[i]] <- (length(old_hosp_agg[[1+length(aggregation_list) - i]]) + (1:(frequency/aggregation_list[[i]])))*aggregation_list[[i]]
      date <- c(date, date_list[[i]])
      q025 <- c(q025, reconciled_fc_day[[1+length(aggregation_list) - i]][["lower"]][,2])
      q25 <- c(q25, reconciled_fc_day[[1+length(aggregation_list) - i]][["lower"]][,1])
      q50 <- c(q50, reconciled_fc_day[[1+length(aggregation_list) - i]][["mean"]])
      q75 <- c(q75, reconciled_fc_day[[1+length(aggregation_list) - i]][["upper"]][,1])
      q975 <- c(q975, reconciled_fc_day[[1+length(aggregation_list) - i]][["upper"]][,2])
      level_list[[i]] <- rep(old.agg.names[1+length(aggregation_list) - i],  frequency/aggregation_list[[i]])
      level <- c(level, level_list[[i]])
    }

    reconcile_df_old <- 
      tibble::tibble(q025, q25, q50, q75, q975, level) |>
      cbind(date = c(56, 28, 56, seq(14, 56, 14), seq(7, 56, 7), 1:56)) |>
      dplyr::mutate(
#        date=start_date + date-1,
        level=factor(level, levels=unique(level), ordered=TRUE),
        across(where(is.numeric), function(x) ifelse(x < 0, 0, x))
      )
      
    ggplot(reconcile_df_old, aes(x = date, group = level)) +
      geom_ribbon(aes(ymin = q025, ymax = q975, fill = "95% PI"), alpha = .75) + 
      geom_ribbon(aes(ymin = q25, ymax = q75, fill = "50% PI"), alpha = .75) +
      geom_line(aes(y = q50), col = 4) +
      geom_point(aes(y = q50), col = 4) +
      facet_grid(rows = vars(level), scales = "free") +
      scale_fill_manual(name = "", values = c("50% PI" = "#00458F", "95% PI" = "#C2DDEE")) +
      xlab("Date") + ylab(" ") +
    #  theme(axis.title.x="Date", axis.title.y="") +
      ggtitle("Reconcile Forecasts Old")
