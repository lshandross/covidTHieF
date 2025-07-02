###################################################################################################
#' All functions in script adapted from Cramer, et al
#' Source: \url{https://github.com/reichlab/covid19-forecast-evals/blob/main/code/figure-wis_by_location.R}

# Helper functions

# helper function
next_monday <- function(date){
  nm <- rep(NA, length(date))
  for(i in seq_along(date)){
    nm[i] <- date[i] + (0:6)[weekdays(date[i] + (0:6)) == "Monday"]
  }
  return(as.Date(nm, origin = "1970-01-01"))
}

# function for pairwise comparison of models
pairwise_comparison <-
  function(heat_scores, mx, my, subset = rep(TRUE, nrow(heat_scores)), permutation_test = FALSE){

  # apply subset:
  heat_scores <- heat_scores[subset, ]

  # subsets of available heat_scores for both models:
  subx <- subset(heat_scores, model == mx)
  suby <- subset(heat_scores, model == my)

  # merge together and restrict to overlap:
  sub <- merge(subx, suby, by = c("forecast_date", "location", "horizon"), all.x = FALSE, all.y = FALSE)

  # compute ratio:
  ratio <- sum(sub$wis.x) / sum(sub$wis.y)

  # perform permutation tests:
  if(permutation_test){
    pval <- surveillance::permutationTest(sub$wis.x, sub$wis.y, nPermutation = 999)$pVal.permut

    # aggregate by forecast date:
    sub_fcd <- stats::aggregate(cbind(wis.x, wis.y) ~ forecast_date, data = sub, FUN = mean)
    pval_fcd <- surveillance::permutationTest(sub_fcd$wis.x, sub_fcd$wis.y, nPermutation = 999)$pVal.permut
  } else {
    pval <- NULL
    pval_fcd <- NULL
  }

  return(list(ratio = ratio, pval = pval, pval_fcd = pval_fcd, mx = mx, my = my))
}


###################################################################################################
# Calculate and plot pairwise WIS

#' Calculate and plot pairwise WIS by location
#'
#' @param scores A data frame of forecast scores to plot
#' @param truth A data frame of truth data
#' @param model_levels Ordered vector of model names used as axis levels
#' @param baseline_name Name of baseline model (must be included in model_levels)
#'
#' @return A tile plot of pairwise relative WIS broken down by location and model using the scores provided
#' @export
#'
#' @examples
plot_wis_loc <- function(scores, truth, model_levels, baseline_name) { # potentially add choice of wis, mae, coverage?
  #reorder states, reorder models
  inc_scores <- dplyr::filter(
    scores,
    !(.data[["location"]] %in% c("22", "US") & .data[["forecast_date"]] <= as.Date("2021-01-04"))
  )

  # bring all forecast_dates to Monday:
  inc_scores$forecast_date <- next_monday(inc_scores$forecast_date)

  # select relevant columns:
  heat_scores <- inc_scores %>%
    dplyr::left_join(covidHubUtils::hub_locations[1:2], by = c("location" = "fips")) %>%
    dplyr::select("model", "forecast_date", "location", "location_name", "horizon", "abs_error", "wis") %>%
    droplevels()

  # the included models and locations:
  models <- unique(heat_scores$model)
  locations <- unique(heat_scores$location)
  location_names <- unique(heat_scores$location_name)

  # compute pairwise and relative WIS for each location separately:
  for(i in seq_along(locations)){

    # select location:
    loc <- locations[i]
    loc_name <- location_names[i]

    # matrix to store:
    results_ratio_temp <- matrix(ncol = length(models),
                                 nrow = length(models),
                                 dimnames = list(models, models))

    # run pairwise comparison for chosen location:
    for(mx in seq_along(models)){
      for(my in 1:mx){
        pwc <- pairwise_comparison(
          heat_scores = dplyr::filter(heat_scores, .data[["horizon"]] %in% 1:4), mx = models[mx], my = models[my],
          permutation_test = FALSE, # disable permutation test to speed up things
          subset = dplyr::filter(heat_scores, .data[["horizon"]] %in% 1:4)$location == loc
            # this will subset to the respective location inside the function
        )
        results_ratio_temp[mx, my] <- pwc$ratio
        results_ratio_temp[my, mx] <- 1/pwc$ratio
      }
    }

    # compute the geometric means etc
    ind_baseline <- which(rownames(results_ratio_temp) == baseline_name)
    geom_mean_ratios_temp <- exp(rowMeans(log(results_ratio_temp[, -ind_baseline]), na.rm = TRUE))
    ratios_baseline_temp <- results_ratio_temp[, baseline_name]
    ratios_baseline2_temp <- geom_mean_ratios_temp/geom_mean_ratios_temp[baseline_name]

    # summarize results:
    to_add <- data.frame(model = names(ratios_baseline2_temp),
                         location = loc,
                         location_name = loc_name,
                         relative_wis = ratios_baseline2_temp,
                         log_relative_wis = log(ratios_baseline2_temp))

    # append to already stored:
    if (i == 1) { # initialize at first location
      average_by_loc <- to_add
    } else {
      average_by_loc <- rbind(average_by_loc, to_add)
    }
  }

  ## plot of true data by state, tiled
  truth_dat <- truth %>%
    dplyr::filter(.data[["geo_type"]] == "state", .data[["population"]] >= 500000) %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(c("location", "location_name")))) %>%
    dplyr::summarize(cum_value = sum(value)) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(location_name = stats::reorder(.data[["location_name"]], .data[["cum_value"]])) %>%
    dplyr::pull(.data[["location_name"]])

  average_by_loc_to_plot <- average_by_loc %>%
    dplyr::mutate(
      location_name = forcats::fct_relevel(.data[["location_name"]], levels(truth_dat)),
      relative_wis_text = sprintf("%.2f", round(relative_wis, 2)),
      log_relative_wis = log2(relative_wis),
      model = forcats::fct_relevel(.data[["model"]], model_levels)
    ) %>%
    dplyr::filter(!is.na(relative_wis))

  # plot:
  fig_wis_loc <- average_by_loc_to_plot %>%
    ggplot2::ggplot(ggplot2::aes(
      x = model, y = location_name,
      fill = scales::oob_squish(log_relative_wis, range = c(-2, 1.5))
    )) +
    ggplot2::geom_tile() +
    ggplot2::geom_text(ggplot2::aes(label = relative_wis_text), size = 2.5) + # I adapted the rounding
    ggplot2::scale_fill_gradient2(
      low = "steelblue",
      high = "red",
      midpoint = 0,
      na.value = "grey50",
      name = "Relative WIS",
      breaks = c(-2,-1,0,1),
      labels =c("0.25", 0.5, 1, "2+")
    ) +
    ggplot2::xlab(NULL) + ggplot2::ylab(NULL) +
    guides(x = guide_axis(angle = 45)) +
    ggplot2::theme(
      axis.title.x = ggplot2::element_text(size = 12),
      axis.text.y = ggplot2::element_text(size = 12),
      title = ggplot2::element_text(size = 12)
    ) +
    ggplot2::theme_bw()

  print(fig_wis_loc)
}


# model_levels <- dplyr::pull(overall_metrics_states, model)
# plot_wis_loc(combined_scores, full_hosp_truth, model_levels, baseline_name = "COVIDhub-baseline")
