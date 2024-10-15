#' Compute temporal hierarchical probabilistic forecasts
#'
#' @param temporal_hierarchy List of (hierarchical) time series.
#' @param n_samples Numeric of requested bootstrap samples. Defaults to 10000.
#' @param forecast_type Character string or vector specifying the types of
#'    forecasts to return. May be "base", "reconciled", or both.
#' @param aggregate_levels Numeric vector of aggregation levels, where each
#'   value is described relative to the smallest unit. For example, c(14, 7, 1)
#'   can represent a hierarchy with levels 2-weekly, weekly, and daily. Only
#'   required when `forecast_type` contains "reconciled"
#' @param ... Additional arguments passed onto `FoReco::terec`
#'
#' @return Either a matrix or a list of matrices (depending on the number of
#'   forecast types requested) containing probabilistic temporal hierarchical
#'   forecasts represented by samples. A single matrix has columns representing
#'   each element in the provided hierarchy, with one sample per row.
#' @export
#'
#' @examples
compute_prob_forecasts <-
  function(temporal_hierarchy, n_samples = 10000, 
           forecast_type = c("base", "reconciled"), aggregate_levels, ...) {

    fit <- lapply(
      temporal_hierarchy,
      function(x) forecast::auto.arima(ts(x, frequency = frequency(x)))
    )
    fit_arima <- list(); for (i in 1:5) fit_arima[[i]] <- fit[[6-i]]
    forecast_obj <- lapply( # make into a forecast object
      fit_arima,
      function(tsfit) forecast::forecast(tsfit, h = frequency(tsfit$x))
    )

    base_mean <- sapply(forecast_obj, function(x) x$mean)
    res <- Reduce("c", sapply(forecast_obj, residuals, type = "response"))
    # in-sample residuals (one-step)

    # Calculate probabilistic forecasts
    base_forecasts <- MASS::mvrnorm(
      n = n_samples, mu = unlist(base_mean), Sigma = FoReco::shrink_estim(mres)
    )

    if ("base" == forecast_type) {
      return (base_forecasts)
    } else if ("reconciled" %in% forecast_type) { # Gaussian reconciliation
      # Multi-step residuals (approx base forecast error to inform reco weights)
      hres_list <- lapply(
        fit_arima,
        function(mod) lapply(
          1:frequency(mod$x), # get frequency of ts at each agg level
          function(h) residuals(mod, type = "response", h = h)
          # note res = y_t - yhat_t, where t < h (aka obs time before pred hzns)
        )
        # list of residuals separated by aggregation level and time point
      )
      hres <- Reduce("c", lapply(hres_list, res2matrix::arrange_hres))
      # Reduce list to vector (length 102) of residuals ordered like og data
      # original data [102 total]: annual [6]; quarterly [24]; monthly [72]

      # Re-arrenge multi-step residuals in a matrix form
      mres <- FoReco::res2matrix(hres, agg_order = aggregate_levels)
      # m = 56, k* = 1 + 2 + 4 + 8 = 15, N = 336/56 = 6
      # N(k* + m) = 6(71) = 426

      reco_forecasts <- t(apply(
        base_forecasts, 1, FoReco::terec, agg_order = aggregate_levels,
        comb = "wlsv", res = unlist(res), nn = "sntz"
      ))

      if ("reconciled" == forecast_type) {
        return(reco_forecasts)
      } else {
        return(list(base = base_forecasts, reconciled = reco_forecasts))
      }
    }
  }
