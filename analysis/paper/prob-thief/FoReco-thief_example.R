# ============================================================================ #
# FoReco-thief Example (from package)

if (FALSE) {
library(thief)
require(FoReco)
dataset <- window(AEdemand[, 12], start = c(2011, 1), end = c(2014, 52))
data <- tsaggregates(dataset)
# Base forecasts
base <- list()
for (i in 1:5) {
  base[[i]] <- forecast(auto.arima(data[[i]]))
}
base[[6]] <- forecast(auto.arima(data[[6]]), h = 2)
# Base forecasts vector
base_vec <- NULL
for (i in 6:1) {
  base_vec <- c(base_vec, base[[i]]$mean)
}
# Residual vector
res <- NULL
for (i in 6:1) {
  res <- c(res, base[[i]]$residuals)
}

# OLS
# two commands in thief...
obj_thief <- thief(dataset, m = 52, h = 2 * 52, comb = "ols", usemodel = "arima")
obj_thief <- tsaggregates(obj_thief$mean)
y_thief <- NULL
for (i in 6:1) {
  y_thief <- c(y_thief, obj_thief[[i]])
}
obj_thief_ols <- reconcilethief(base, comb="ols")
y_thief_ols <- NULL
for (i in 6:1) {
  y_thief_ols <- c(y_thief_ols, obj_thief_ols[[i]]$mean)
}
# ...with the same results:
sum(abs(y_thief_ols - y_thief) > 1e-10)

y_FoReco_ols <- thfrec(base_vec, 52, comb = "ols")$recf
sum(abs(y_FoReco_ols - y_thief_ols) > 1e-10)

# STRUC
obj_thief_struc <- reconcilethief(base, comb="struc")
y_thief_struc <- NULL
for (i in 6:1) {
  y_thief_struc <- c(y_thief_struc, obj_thief_struc[[i]]$mean)
}
y_FoReco_struc <- thfrec(base_vec, 52, comb = "struc")$recf
sum(abs(y_FoReco_struc - y_thief_struc) > 1e-10) # approaches yield the same results

# BU
obj_thief_bu <- reconcilethief(base, comb="bu")
y_thief_bu <- NULL
for (i in 6:1) {
  y_thief_bu <- c(y_thief_bu, obj_thief_bu[[i]]$mean)
}
y_FoReco_bu <- thfrec(base_vec, 52, comb = "bu")$recf
sum(abs(y_FoReco_bu - y_thief_bu) > 1e-10)

# SHR
obj_thief_shr <- reconcilethief(base, comb="shr")
y_thief_shr <- NULL
for (i in 6:1) {
  y_thief_shr <- c(y_thief_shr, obj_thief_shr[[i]]$mean)
}
y_FoReco_shr <- thfrec(base_vec, 52, comb = "shr", res = res)$recf
sum(abs(y_FoReco_shr - y_thief_shr) > 1e-10)
}

# ============================================================================ #
# 

library(thief)
require(FoReco)
dataset <- window(AEdemand[, 12], start = c(2011, 1), end = c(2014, 52))
data <- tsaggregates(dataset)

# Base forecasts
base <- list()
for (i in 1:5) {
  base[[i]] <- forecast(auto.arima(data[[i]]))
}
base[[6]] <- forecast(auto.arima(data[[6]]), h = 2)
# Base forecasts vector
base_vec <- NULL
for (i in 6:1) {
  base_vec <- c(base_vec, base[[i]]$mean)
}
# Residual vector
res <- NULL
for (i in 6:1) {
  res <- c(res, base[[i]]$residuals)
}

# STRUC
obj_thief_struc <- reconcilethief(base, comb="struc") # as an object, og output
  # list of forecast objects; each is a data frame of point and interval forecasts
y_thief_struc <- NULL
for (i in 6:1) {
  y_thief_struc <- c(y_thief_struc, obj_thief_struc[[i]]$mean) # as a vector
}

y_FoReco_struc <- thfrec(base_vec, 52, comb = "struc")$recf # as a vector
  # list of numeric (+ logical) vectors/values;
obj_FoReco_struc <- thfrec(basef = base_vec, m=52, comb = "struc") # as a object

# 196 total point forecasts
# 2 annual, 4 semi annual, 8 quarterly, 26 4-weekly, 52 2-weekly, 104 weekly
# It seems like the `thfrec` function could be used to get samples by using a matrix with sapply
View(obj_FoReco_struc)

# plot (taken from original thief code)
par(mfrow=c(3,2))
for(i in seq_along(base)) {
  plot(obj_thief_struc[[i]],
       ylim = c(0, max(obj_thief_struc[[i]]$x, obj_thief_struc[[i]]$upper))) 
  lines(base[[i]]$mean, col='red') # plots red mean line
}



data(FoReco_data)
# top ts base forecasts ([lowest_freq' ...  highest_freq']')
topbase <- FoReco_data$base[1, ]
 # top ts residuals ([lowest_freq' ...  highest_freq']')
topres <- FoReco_data$res[1, ]
obj <- thfrec(topbase, m = 12, comb = "acov", res = topres)




# ============================================================================ #
# Reconstruct Vignette Example

library(thief)
require(FoReco)
B = 1000
m = 52
agg_levels <- c(52, 26, 13, 4, 2, 1)
dataset <- window(AEdemand[, 12], start = c(2011, 1), end = c(2014, 52)) # Single time series
data <- tsaggregates(dataset) # same as temp_y

fit.arima <- lapply(data, function(x) auto.arima(ts(x, frequency = frequency(x)))) # arima model fit
forecast_obj.arima <- lapply(fit.arima, function(tsfit) # make into a forecast object
  forecast(tsfit, h=frequency(tsfit$x)))    # (frequency taken from inputs)
base_mean.arima <- sapply(forecast_obj.arima, function(x) x$mean)  # base mean for each level
res.arima <- Reduce("c", sapply(fit.arima, residuals, type='response'))   # in-sample residuals (one-step)

# Bootstrap approach
bootstrap_base <- boot_te(fit.arima, B, m = agg_levels)$sample # B = 1000; 1000 x 17 matrix
  # each row is one sample; 
  # each column is a set of point forecasts for the same aggregation level and target
  # a row gives values for the following forecasts for a particular sample i
  # annual1   quarter1   quarter2   quarter3   quarter4   month1   ...   month 12

# Reconciled forecasts' sample:
bootstrap_rec <- t(apply(bootstrap_base, 1, function(boot_base){
  thfrec(boot_base, m = agg_levels, res = res.arima, comb = "wlsv", keep = "recf")}))


# Gaussian approach
# Multi-step residuals
hres_list <- lapply(fit.arima, function(mod)       # mod = model within the fit object
  lapply(1:frequency(mod$x), function(h)     # get frequency of ts at each agg level
    residuals(mod, type='response', h = h))) # get residuals at each level
    # note residuals = y_t - yhat_t, where t < h (aka observed time before predicted horizons)
  # list of residuals separated by aggregation level and time point
hres <- Reduce("c", lapply(hres_list, arrange_hres))
  # Reduce list down into vector (length 102) of residuals following order of og data
  # original data [102 total]: annual [6]; quarterly [24]; monthly [72]

# Re-arrenge multi-step residuals in a matrix form
mres <- residuals_matrix(hres, m = agg_levels)

apply(bootstrap_rec, 2, quantile, probs = c(0.005, 0.01, seq(0.05, 0.95, 0.05), 0.99, 0.995), na.rm = TRUE) |> View()
