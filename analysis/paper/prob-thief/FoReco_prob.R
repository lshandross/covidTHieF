library(forecast) # the data and the forecasting function
library(MASS)     # simulate from a multivariate normal distribution
library(FoReco)   # bootstrap and reconciliation phase
B <- 1000         # Sample size for the probabilistic forecasts sample

# Cross-sectional setup
tdeaths <- mdeaths + fdeaths
agg_mat <- t(c(1,1))
cons_cs <- cbind(1,-agg_mat)
lungDeaths <- cbind(tdeaths, mdeaths, fdeaths)

fit <- apply(lungDeaths, 2, function(x) ets(ts(x, frequency = frequency(lungDeaths))))
forecast_obj <- lapply(fit, forecast, h=12)      # forecast object
base <- sapply(forecast_obj, function(x) x$mean) # base mean (point forecasts)
res <- sapply(fit, residuals, type='response')   # in-sample residuals (one-step)

## Temporal framework

# In the temporal framework, we reconcile base forecasts across different time frequencies (e.g., monthly, quarterly, and annual data) for a single time series. For example, suppose we want to generate reconciled monthly, quarterly, and annual forecasts for the total number of deaths due to bronchitis, emphysema, and asthma in the UK. According to Girolimetto et al. (2023), we can use the same approach as in the cross-sectional framework, but we need to account for the different time frequencies.

# In the bootstrap approach, we can use the `boot_te()` function, which generates a bootstrap sample for time-series forecasts while keeping a temporal structure. The function requires the same inputs as the equivalent cross-sectional `boot_cs()` function, with an additional parameter __m__ that indicates the maximum order of temporal aggregation. The length of the block bootstrap is determined by both __m__ and __h__, where __h__ refers to the forecast horizons for the most temporally aggregated series.

# In the Gaussian approach, we assume that all the base forecasts follow a multivariate normal distribution, and we calculate the covariance matrix of the base forecasts using multi-step residuals organized in matrix form through the `residuals_matrix()` function.

# To reconcile each sample we use the optimal temporal reconclition function, `thfrec()`.

### te_base
library(tidyverse)
tdeaths <- mdeaths + fdeaths # male and female monthly deaths from lung disease

# Temporal setup
y <- tdeaths
m <- 12 # frequency
kset <- c(12, 3, 1) # factors subset of m = 12 
                    # (only monthly, quarterly and annual data are considered)
kset <- setNames(kset, paste0("k", kset)) # k12 = annual; k3 = quarterly; k1 = monthly
cons_te <- thf_tools(m = kset)$Zt # matrix

temp_y <- lapply(kset, agg_ts, x = y) # Aggregated time series list
  # must aggregate to top level without remainders, otherwise the residuals matrix can not be calculated
fit <- lapply(temp_y, function(x) ets(ts(x, frequency = frequency(x)))) # ets model fit
forecast_obj <- lapply(fit, function(tsfit)                   # make into a forecast object
  forecast(tsfit, h=frequency(tsfit$x)))                      # (frequency taken from inputs)
base_mean <- sapply(forecast_obj, function(x) x$mean)              # base mean for each level
res <- Reduce("c", sapply(fit, residuals, type='response'))   # in-sample residuals (one-step)

### Bootstrap approach

# ```{r tejb}
# Base forecasts' sample:
# we simulate from the base models by sampling errors 
# while keeping the temporal dimension fixed.
base_tejb <- boot_te(fit, B, m = kset)$sample # B = 1000; 1000 x 17 matrix
  # each row is one sample; 
  # each column is a set of point forecasts for the same aggregation level and target
  # a row gives values for the following forecasts for a particular sample i
  # annual1   quarter1   quarter2   quarter3   quarter4   month1   ...   month 12

# Reconciled forecasts' sample:
# we reconcile each member of the base forecasts' sample.
reco_tejb <- t(apply(base_tejb, 1, function(boot_base){
  thfrec(boot_base, m = kset, res = res, comb = "wlsv", keep = "recf")}))
  # iterate `thfrec` function over the rows to get reconciled version of `base_tejb` matrix
  # exact same as above except the column names are given by the "kmh#" pattern:
  # k12h1  k3h1  k3h2  k3h3  k3h4  k1h1  k1h2  k1h3  k1h4  ...  k1h9  k1h10  k1h11  k1h12
# ```

### Gaussian approach

# ```{r tegauss}
# Multi-step residuals
hres_list <- lapply(fit, function(mod)       # mod = model within the fit object
  lapply(1:frequency(mod$x), function(h)     # get frequency of ts at each agg level
    residuals(mod, type='response', h = h))) # get residuals at each level
    # note residuals = y_t - yhat_t, where t < h (aka observed time before predicted horizons)
  # list of residuals separated by aggregation level and time point
hres <- Reduce("c", lapply(hres_list, arrange_hres))
  # Reduce list down into vector (length 102) of residuals following order of og data
  # original data [102 total]: annual [6]; quarterly [24]; monthly [72]

# Re-arrenge multi-step residuals in a matrix form
mres <- residuals_matrix(hres, m = kset)

# plot residuals
par(mfrow=c(3,1))
for(i in seq_along(base)) {
  plot(obj_thief_struc[[i]],
       ylim = c(0, max(obj_thief_struc[[i]]$x, obj_thief_struc[[i]]$upper))) 
}

# Base forecasts' sample:
# we simulate (B = 1000 samples) from a multivariate normal distribution.
base_teg <- MASS::mvrnorm(n = B, mu = unlist(base_mean), Sigma = shrink_estim(mres)$scov)
  # each row is one sample;
  # each column is set of point forecasts for same agg level and target for all 1000 samples
  # a row gives values for the following forecasts for a particular sample i
  # k12  k31  k32  k33  k34  k11  k12  k13  k14  ...  k19  k110  k111  k112

# Reconciled forecasts' sample:
# we reconcile each member of the base forecasts' sample.
reco_teg <- t(apply(base_teg, 1, thfrec, m = kset, comb = "wlsv", res = res, keep = "recf"))
  # iterate `thfrec` function over the rows to get reconciled version of `base_tejb` matrix
  # likewise as above, but slightly different column names
  # k12h1  k3h1  k3h2  k3h3  k3h4  k1h1  k1h2  k1h3  k1h4  ...  k1h9  k1h10  k1h11  k1h12
# ```

# ```{r teplot, echo=FALSE}
# plotting all samples for monthly h=1 base and reconciled forecasts using all approaches
rbind(tibble(value = base_tejb[,6], 
             type = "base forecasts",
             facet = "Bootstrap approach"),
      tibble(value = reco_tejb[,6],
             type = "reconciled forecasts",
             facet = "Bootstrap approach"),
      tibble(value = base_teg[,6],
             type = "base forecasts",
             facet = "Gaussian approach"),
      tibble(value = reco_teg[,6],
             type = "reconciled forecasts",
             facet = "Gaussian approach")) |>
  ggplot(aes(x = value, fill = type, col = type)) +
  geom_density(adjust = 3, alpha = 0.25)+
  labs(x = NULL, y = "density of Total (monthly, one-step ahead)")+
  facet_grid(.~facet)+
  theme_minimal()+
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        title = element_text(size = 10),
        text = element_text(size = 11))
# ```

# calculate quantiles using tables above?
quantile(reco_tejb[, 6], probs = c(0.005, 0.01, seq(0.05, 0.95, 0.05), 0.99, 0.995), na.rm = FALSE) 
quantile(reco_teg[, 6], probs = c(0.005, 0.01, seq(0.05, 0.95, 0.05), 0.99, 0.995), na.rm = FALSE) 

# original list of reconciled forecasts was list of data frames of interval forecasts, split by aggregation level
# Now matrix of reconciled forecasts for all aggregation levels of 1000 iterations
  # Will need to obtain quantile forecasts using samples, but we'll need to do this for the lowest level forecasts and can discard the higher level ones
  # does it make sense to force to original thief format, then hub format? Or go directly to hub format? Probably the latter would be better/cleaner even though I could reuse the old function

B = 10000
base_tejb <- boot_te(fit, B, m = kset)$sample # B = 1000; 1000 x 17 matrix
reco_tejb <- t(apply(base_tejb, 1, function(boot_base){
  thfrec(boot_base, m = kset, res = res, comb = "wlsv", keep = "recf")}))

apply(reco_tejb, 2, quantile, probs = c(0.005, 0.01, seq(0.05, 0.95, 0.05), 0.99, 0.995), na.rm = FALSE) |> View()

apply(reco_teg, 2, quantile, probs = c(0.005, 0.01, seq(0.05, 0.95, 0.05), 0.99, 0.995), na.rm = FALSE) |> View()