#' Plot the forecasts of multiple models for a single location
#'
#' @param forecasts A data frame of forecasts to plot
#' @param truth A data frame of truth data
#' @param fips A string of the fips code for the desired location to plot
#' @param fc_dates A vector of the forecast dates to plot. Defaults to NULL where
#'   all provided forecasts will be plotted
#' @param prediction_intervals A vector of (1-alpha)*100% prediction intervals to
#'   plot in addition to point forecasts. Defaults to 50% and 95%.
#' @param facet_nrow An integer specifying how many rows the grid of forecast plots
#'   should have. Defaults to 6
#' @param date_limits A vector containing two dates between which to restrict the
#'   x-axis (in case of extra long truth data)
#'
#' @return A plot of provided forecasts and truth data, faceted by model, for a single location
#' @export
#' @importFrom rlang .data
#' @importFrom magrittr %>%
#'
#' @examples
plot_models_one_location <-
  function(forecasts, truth, models = NULL, fips = "US", fc_dates = NULL, prediction_intervals = c(0.5, 0.95), facet_nrow = 6, date_limits = NULL) {
    fdat <- dplyr::filter(
      forecasts,
      .data[["forecast_date"]] %in% fc_dates,
      .data[["location"]] == fips, 
      !(.data[["location"]] %in% c("22", "US") & .data[["forecast_date"]] <= as.Date("2021-01-04")),
      .data[["horizon"]] <= 28
    )

    if (is.null(models)) {
      p <- covidHubUtils::plot_forecasts(
        fdat,
#       models = c(),
#       truth_data = dplyr::filter(truth, target_end_date <= as.Date("2021-05-03")),
        target_variable = "inc hosp",
        intervals = prediction_intervals,
        truth_source = "HealthData",
        use_median_as_point = TRUE,
        facet = model ~ .,
        facet_nrow = facet_nrow,
#       facet_scales = "free_y",
        fill_by_model = TRUE,
        plot = FALSE
      )
    } else {
      p <- covidHubUtils::plot_forecasts(
        fdat,
        models = models,
#       truth_data = dplyr::filter(truth, target_end_date <= as.Date("2021-05-03")),
        target_variable = "inc hosp",
        intervals = prediction_intervals,
        truth_source = "HealthData",
        use_median_as_point = TRUE,
        facet = model ~ .,
        facet_nrow = facet_nrow,
#       facet_scales = "free_y",
        fill_by_model = TRUE,
        plot = FALSE
      ) +
        ggplot2::theme_bw()
    }

  pt <- p +
    ggplot2::scale_x_date(name = NULL, limits = date_limits, date_breaks = "4 months", date_labels = "%b '%y") +
    ggplot2::coord_cartesian(ylim = c(0, max(dplyr::filter(truth, .data[["location"]] == fips)$value) * 1.15)) +
    ggplot2::theme(axis.ticks.length.x = grid::unit(0.5, "cm"),
                   axis.text.x = ggplot2::element_text(vjust = 7, hjust = -0.2),
                   legend.position = "none")

    print(pt)
}



# locs <- full_hosp_truth %>%
#   dplyr::filter(target_end_date <= train_end_date) %>%
#   dplyr::group_by(location) %>%
#   dplyr::summarize(cum_value=sum(value)) %>%
#   dplyr::ungroup() %>%
#   dplyr::arrange(desc(cum_value)) %>%
#   dplyr::filter(row_number() %in% c(1, 2, 53)) %>%
#   dplyr::pull(location)
#
# for (i in 1:3) {
#   plot_models_one_location(fc_plot, full_hosp_truth, fips = locs[i], fc_dates, facet_nrow = 6, date_limits = c(as.Date("2020-10-01"), train_end_date))
# }
