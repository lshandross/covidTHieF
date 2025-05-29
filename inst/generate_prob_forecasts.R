library(FoReco)   # -> To perform reconciliation
library(forecast)  # -> To obtain base forecasts
library(thief)
library(dplyr)
library(lubridate)
library(ggplot2)

## Load and format truth data

# Example with Covid-19 inc hosp data. We adjust the top aggregation level to be 8 weeks, as we can't reasonably predict anything with a longer horizon well-enough.

full_hosp_truth <- covidHubUtils::load_truth("HealthData", "inc hosp",
                                             temporal_resolution = "weekly",
                                             data_location = "remote_hub_repo")

# Must have time series that is a multiple of the largest aggregation level
start_date <- as.Date("2020-08-24") # a monday
end_date <- as.Date("2021-02-07")
#end_date <- as.Date("2021-07-25")

hosp_truth <- full_hosp_truth |>
  dplyr::filter(target_end_date >= start_date,
                target_end_date <= end_date,
                location == "US") |>
  mutate(day = wday(target_end_date), epi_week = epiweek(target_end_date)) |>
  dplyr::select(value, epi_week, day)

te_agg <- c(56, 28, 14, 7, 1)
  # te_agg <- tetools(56)$set
te_agg.ascending <- c(1, 7, 14, 28, 56)
  # note the wrong order creates strange-looking forecasts
# y = hosp_truth$value
freq <- max(te_agg)

#Construct aggregates (from daily data) based on 8-week periods of epiweeks

set.seed(1234)

start_period <- 4
end_period <- start_period + as.numeric(end_date - start_date + 1) / freq - 1
hosp_ts <- ts(hosp_truth$value, start = c(start_period, 1), end = c(end_period, 56), frequency = 56)
hosp_agg <- aggts(hosp_ts, te_agg, align = "end", rm_na = TRUE)
agg_names <- c("8-weekly", "4-weekly", "2-weekly", "weekly", "daily")
agg_names.ascending <- c("daily", "weekly", "2-weekly", "4-weekly", "8-weekly")
hosp_agg <- setNames(hosp_agg, agg_names.ascending)
hosp_data <- list(); for (i in 1:5) hosp_data[[i]] <- hosp_agg[[6-i]]
  # To make aggregates list descending instead of ascending


# `FoReco` Method

## Calculate model fits and base point forecasts

fit <- lapply(hosp_agg, function(x) auto.arima(ts(x, frequency = frequency(x)))) # arima model fit
fit.arima <- list(); for (i in 1:5) fit.arima[[i]] <- fit[[6-i]] # order top down
forecast_obj.arima <- lapply(fit.arima, function(tsfit) # make into a forecast object
  forecast(tsfit, h=frequency(tsfit$x)))    # (frequency taken from inputs)
  # Could also use a for loop over `te_agg` instead

base_mean.arima <- sapply(forecast_obj.arima, function(x) x$mean)  # base mean for each level
res.arima <- Reduce("c", sapply(forecast_obj.arima, residuals, type='response'))
  # in-sample residuals (one-step)


## Gaussian reconciliation approach

B <- 10000
base_mean_vec.arima <- unlist(base_mean.arima, use.names = FALSE)
res_vec.arima <- unlist(res.arima, use.names = FALSE)

# Multi-step residuals (for approximating base forecast error, which informs weights during reconciliation)

hres_list.arima <- lapply(fit.arima, function(mod) # mod = model within the fit object
lapply(1:frequency(mod$x), function(h)     # get frequency of ts at each agg level
  residuals(mod, type='response', h = h))) # get residuals at each level
    # note residuals = y_t - yhat_t, where t < h (aka observed time before predicted horizons)
  # list of residuals separated by aggregation level and time point
hres.arima <- Reduce("c", lapply(hres_list.arima, arrange_hres))
  # Reduce list down into vector (length 102) of residuals following order of og data
  # original data [102 total]: annual [6]; quarterly [24]; monthly [72]

# Re-arrenge multi-step residuals in a matrix form
mres.arima <- res2matrix(hres.arima, agg_order = te_agg)
  # m = 56, k* = 1 + 2 + 4 + 8 = 15, N = 336/56 = 6
  # N(k* + m) = 6(71) = 426

#Calculate probabilistic forecasts

base.arima <- MASS::mvrnorm(n = B, mu = unlist(base_mean.arima), Sigma = shrink_estim(mres.arima))
base_subset <- apply(base.arima, 2, quantile, na.rm = TRUE,
                     probs = c(0.025, 0.25, 0.5, 0.75, 0.975))

reco.arima <- t(apply(base.arima, 1, terec, agg_order = te_agg, comb = "wlsv",
                      res = unlist(res.arima), nn = "sntz")) # order of aggregates doesn't matter

# extract quantiles
reco_quantiles <- apply(reco.arima, 2, quantile, na.rm = TRUE,
                        probs = c(0.01, 0.025, seq(0.05, 0.95, 0.05), 0.975, 0.99))
reco_subset <- apply(reco.arima, 2, quantile, na.rm = TRUE,
                     probs = c(0.025, 0.25, 0.5, 0.75, 0.975))



# transform to covid hub format
#reconciled_forecasts <-
reco_subset |>
  as.table() |>
  as.data.frame() |>
  tidyr::separate(Var2, into = c("a", "k", "h"), sep = "\\D+", convert = TRUE) |>
  dplyr::mutate(
    forecast_date = end_date,
    location = "fips",
    horizon = as.numeric(h)*k,
    temporal_resolution = "daily",
    target = "inc hosp",
    target_end_date = forecast_date + horizon,
    type = "quantile",
    quantile = as.numeric(stringr::str_remove(.data[["Var1"]], "%")) * 0.01,
    value = ifelse(Freq < 0, 0, Freq),
  ) |>
  dplyr::filter(k == 1, horizon <= 56) |> # keep only daily forecasts
  dplyr::select(c("forecast_date":"value")) |>
  dplyr::tibble()


    # transform to covid hub format
    #reconciled_forecasts <-
    base_subset |>
      as.table() |>
      as.data.frame() |>
      dplyr::mutate(
        Var1 = paste0("q", stringr::str_remove_all(.data[["Var1"]], "%")),
        Var2 = as.character(.data[["Var2"]])
      ) |>
      tidyr::pivot_wider(names_from = "Var1", values_from = "Freq") |>
      tidyr::separate(.data[["Var2"]], into = c("a", "k", "h"), sep = "\\D+",
                      convert = TRUE) |>
      dplyr::mutate(
        date = lubridate::days(.data[["k"]] * .data[["h"]]) + end_date,
        level = ifelse(.data[["k"]] != 1,
                       paste(.data[["k"]] / 7, "weekly", sep = "-"),
                       paste(.data[["k"]], "daily", sep = "-")),
        .before = "k"
      ) |>
      dplyr::select(-c("a", "k", "h")) |>
      dplyr::tibble()




base_mean.arima <- sapply(forecast_obj.arima, function(x) x$mean)  # base mean for each level
res.arima <- Reduce("c", sapply(forecast_obj.arima, residuals, type='response'))
  # in-sample residuals (one-step)


## Gaussian reconciliation approach

B <- 1000
base_mean_vec.arima <- unlist(base_mean.arima, use.names = FALSE)
res_vec.arima <- unlist(res.arima, use.names = FALSE)

# Multi-step residuals (for approximating base forecast error, which informs weights during reconciliation)

hres_list.fc <- lapply(forecast_obj.arima, function(mod) # mod = model within the fit object
lapply(1:frequency(mod$x), function(h)     # get frequency of ts at each agg level
  residuals(mod, type='response', h = h))) # get residuals at each level
    # note residuals = y_t - yhat_t, where t < h (aka observed time before predicted horizons)
  # list of residuals separated by aggregation level and time point
hres.fc <- Reduce("c", lapply(hres_list.fc, arrange_hres))
  # Reduce list down into vector (length 102) of residuals following order of og data
  # original data [102 total]: annual [6]; quarterly [24]; monthly [72]

# Re-arrenge multi-step residuals in a matrix form
mres.fc <- res2matrix(hres.fc, agg_order = te_agg)
  # m = 56, k* = 1 + 2 + 4 + 8 = 15, N = 336/56 = 6
  # N(k* + m) = 6(71) = 426

#Calculate probabilistic forecasts

base.fc <- MASS::mvrnorm(n = B, mu = unlist(base_mean.arima), Sigma = shrink_estim(mres.fc))

reco.fc <- t(apply(base.fc, 1, terec, agg_order = te_agg, comb = "wlsv",
                      res = unlist(res.arima), nn = "sntz")) # order of aggregates doesn't matter

# extract quantiles
reco_quantiles.fc <- apply(reco.fc, 2, quantile, na.rm = TRUE,
                        probs = c(0.01, 0.025, seq(0.05, 0.95, 0.05), 0.975, 0.99))
