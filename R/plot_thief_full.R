start_date <- as.Date("2020-07-27") # a monday
end_date <- as.Date("2021-06-06")

# create list of aggregation levels
aggregation_list <- list(28, 14, 7, 1)
aggregation_names <- c("1-daily", "1-weekly", "2-weekly", "4-weekly")

# library(c(tidyverse, thief, forecast, lubridate))
plot_thief_full <-
  function(truth, start_date = "2020-07-27", end_date, fips = "US", frequency, aggregation_list, aggregation_names) {
    start_date <- as.Date(start_date); end_date <- as.Date(end_date)
    start_date <- end_date - floor((end_date - start_date + 1) / frequency) * frequency + 1

    truth_vector <- truth %>%
      dplyr::filter(.data[["target_end_date"]] >= start_date,
                    .data[["target_end_date"]] <= end_date,
                    .data[["location"]] == fips) %>%
      dplyr::pull(value)

    # Construct aggregates
    truth_series <- stats::ts(
      truth_vector, 
      start = c(1,1), 
      end = c(floor((end_date - start_date + 1) / frequency), frequency), 
      frequency = frequency
    )

    truth_aggregated <- thief::tsaggregates(truth_series, m = frequency, aggregatelist = aggregation_list)
    for(i in seq_along(truth_aggregated)) names(truth_aggregated)[[i]] <- aggregation_names[i]

    # Compute base forecasts
    base_forecasts <- list()
    for(i in seq_along(truth_aggregated)) {
      base_forecasts[[i]] <- forecast::forecast(
        forecast::auto.arima(truth_aggregated[[i]]), 
        h = 2 * frequency(truth_aggregated[[i]]), 
        level = c(50, 95)
      )
    }

    # Reconcile forecasts
    reconciled_forecasts <- thief::reconcilethief(base_forecasts, aggregatelist = aggregation_list)


    # Truth data
    date_list <- list(); date <- NULL
    value <- NULL
    level_list <- list(); level <- NULL
    for (i in 1:length(aggregation_list)) {
      date_list[[i]] <- (1:length(truth_aggregated[[1 + length(aggregation_list) - i]])) * aggregation_list[[i]]
      date <- c(date, date_list[[i]])
      value <- c(value, truth_aggregated[[1 + length(aggregation_list) - i]])
      level_list[[i]] <- rep(
        aggregation_names[1 + length(aggregation_list) - i],
        length(truth_aggregated[[1 + length(aggregation_list) - i]])
      )
      level <- c(level, level_list[[i]])
    }

    truth_df <- 
      dplyr::tibble(date, value, level) %>%
      dplyr::add_row(value = 0, level = c("2-weekly", "1-weekly", "1-daily")) %>%
      dplyr::mutate(
        date = start_date + date - 1,
        level = factor(level, levels = unique(level), ordered = TRUE)
      )

    truth_plot <- ggplot2::ggplot(truth_df, ggplot2::aes(x = date, group = level)) +
      ggplot2::geom_line(ggplot2::aes(y = value)) +
      ggplot2::geom_point(ggplot2::aes(y = value)) +
      ggplot2::facet_grid(rows = dplyr::vars(level), scales = "free") +
      ggplot2::scale_x_date(name = "Date", date_labels = "20%y %b") +
      ggplot2::xlab("Date") + ggplot2::ylab("Incident Hospitalizations") +
      ggplot2::ggtitle("Aggregate Data")


    # Base forecasts
    date_list <- list(); date <- NULL
    q025 <- NULL; q25 <- NULL; q50 <- NULL; q75 <- NULL; q975 <- NULL
    level_list <- list(); level <- NULL
    for (i in 1:length(aggregation_list)) {
      date_list[[i]] <- (length(truth_aggregated[[1 + length(aggregation_list) - i]]) +
        (1:(2 * frequency / aggregation_list[[i]]))) * aggregation_list[[i]]
      date <- c(date, date_list[[i]])
      q025 <- c(q025, base_forecasts[[1 + length(aggregation_list) - i]][["lower"]][,2])
      q25 <- c(q25, base_forecasts[[1 + length(aggregation_list) - i]][["lower"]][,1])
      q50 <- c(q50, base_forecasts[[1 + length(aggregation_list) - i]][["mean"]])
      q75 <- c(q75, base_forecasts[[1 + length(aggregation_list) - i]][["upper"]][,1])
      q975 <- c(q975, base_forecasts[[1 + length(aggregation_list) - i]][["upper"]][,2])
      level_list[[i]] <- rep(aggregation_names[1 + length(aggregation_list) - i], 2 *  frequency / aggregation_list[[i]])
      level <- c(level, level_list[[i]])
    }

    base_df <- dplyr::tibble(date, q025, q25, q50, q75, q975, level) %>%
      dplyr::add_row(date = 336, q975 = max(truth_df$value[truth_df$level == "2-weekly"]), level = "2-weekly") %>%
      dplyr::add_row(date = 336, q975 = truth_df$value[truth_df$level == "1-weekly"], level = "1-weekly") %>%
      dplyr::add_row(date = 336, q975 = truth_df$value[truth_df$level == "1-daily"], level = "1-daily") %>%
      dplyr::mutate(
        date = start_date + date - 1,
        level = factor(level, levels = unique(level), ordered = TRUE),
        dplyr::across(dplyr::where(is.numeric), function(x) ifelse(x < 0, 0, x))
      )

    base_plot <- ggplot2::ggplot(base_df, ggplot2::aes(x = date, group = level)) +
      ggplot2::geom_ribbon(ggplot2::aes(ymin = q025, ymax = q975, fill = "95% PI"), alpha = .75) +
      ggplot2::geom_ribbon(ggplot2::aes(ymin = q25, ymax = q75, fill = "50% PI"), alpha = .75) +
      ggplot2::geom_line(ggplot2::aes(y = q50), col = 2) +
      ggplot2::geom_point(ggplot2::aes(y = q50), col = 2) +
      ggplot2::facet_grid(rows = dplyr::vars(level), scales = "free") +
      ggplot2::scale_fill_manual(name = "", values = c("50% PI" = "#900000", "95% PI" = "#EEC2C2")) +
      ggplot2::scale_x_date(name = "Date", date_breaks = paste(frequency / 7, "weeks"), date_labels = "%b %d") +
      ggplot2::xlab("Date") + ggplot2::ylab(" ") +
    #  ggplot2::theme(axis.title.x = "Date", axis.title.y = "") +
      ggplot2::ggtitle("Make Base Forecasts")

    # Reconciled forecasts
    date_list <- list(); date <- NULL
    q025 <- NULL; q25 <- NULL; q50 <- NULL; q75 <- NULL; q975 <- NULL
    level_list <- list(); level <- NULL
    for (i in 1:length(aggregation_list)) {
      date_list[[i]] <- (length(truth_aggregated[[1 + length(aggregation_list) - i]]) + (1:(2 * frequency / aggregation_list[[i]]))) * aggregation_list[[i]]
      date <- c(date, date_list[[i]])
      q025 <- c(q025, reconciled_forecasts[[1 + length(aggregation_list) - i]][["lower"]][,2])
      q25 <- c(q25, reconciled_forecasts[[1 + length(aggregation_list) - i]][["lower"]][,1])
      q50 <- c(q50, reconciled_forecasts[[1 + length(aggregation_list) - i]][["mean"]])
      q75 <- c(q75, reconciled_forecasts[[1 + length(aggregation_list) - i]][["upper"]][,1])
      q975 <- c(q975, reconciled_forecasts[[1 + length(aggregation_list) - i]][["upper"]][,2])
      level_list[[i]] <- rep(
        aggregation_names[1 + length(aggregation_list) - i],
        2 *  frequency / aggregation_list[[i]]
      )
      level <- c(level, level_list[[i]])
    }

    reconciled_df <- dplyr::tibble(date, q025, q25, q50, q75, q975, level) %>%
      # force same y-axis limits across all rows
      dplyr::add_row(date = 336, q975 = max(truth_df$value[truth_df$level == "2-weekly"]), level = "2-weekly") %>%
      dplyr::add_row(date = 336, q975 = truth_df$value[truth_df$level == "1-weekly"], level = "1-weekly") %>%
      dplyr::add_row(date = 336, q975 = truth_df$value[truth_df$level == "1-daily"], level = "1-daily") %>%
      dplyr::mutate(
        date = start_date + date - 1,
        level = factor(level, levels = unique(level), ordered = TRUE),
        dplyr::across(dplyr::where(is.numeric), function(x) ifelse(x < 0, 0, x))
      )

    reconciled_plot <- ggplot2::ggplot(reconciled_df, ggplot2::aes(x = date, group = level)) +
      ggplot2::geom_ribbon(ggplot2::aes(ymin = q025, ymax = q975, fill = "95% PI"), alpha = .75) +
      ggplot2::geom_ribbon(ggplot2::aes(ymin = q25, ymax = q75, fill = "50% PI"), alpha = .75) +
      ggplot2::geom_line(ggplot2::aes(y = q50), col = 4) +
      ggplot2::geom_point(ggplot2::aes(y = q50), col = 4) +
      ggplot2::facet_grid(rows = dplyr::vars(level), scales = "free") +
      ggplot2::scale_fill_manual(name = "", values = c("50% PI" = "#00458F", "95% PI" = "#C2DDEE")) +
      ggplot2::scale_x_date(name = "Date", date_breaks = paste(frequency / 7, "weeks"), date_labels = "%b %d") +
      ggplot2::xlab("Date") + ggplot2::ylab(" ") +
    #  ggplot2::theme(axis.title.x = "Date", axis.title.y = "") +
      ggplot2::ggtitle("Reconcile Forecasts")

    truth_plot + base_plot + reconciled_plot + 
#      patchwork::plot_annotation(title = "The THieF Methodology") + 
      patchwork::plot_layout(ncol = 3, width = c(2, 1, 1), guides = 'collect') &
      ggplot2::theme_minimal() &
      ggplot2::theme(legend.position = 'bottom')
}
