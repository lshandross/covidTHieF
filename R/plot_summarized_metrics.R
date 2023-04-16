#' Plot summarized metrics against horizon week
#'
#' @param summarized_metrics A data frame of summarized metrics. Must contain one row per model and horizon week combination plus a `horizon_wk` column
#' @param model_names An ordered vector of model names
#' @param model_colors An ordered vector of model colors. Must match with `model_names` order
#' @param y_var A string specifying which metric to plot as the y-variable
#' @param main A string specifying the plot title
#'
#' @return A scatter plot (with observations connected by lines) of the specified summary metric vs horizon week
#' @export
#'
#' @examples
plot_summarized_metrics <-
  function(summarized_metrics, model_names, model_colors, y_var="WIS", main) {
    data_to_plot <- summarized_metrics %>%
      mutate(
        specification = gsub(".*_(.+)-.*", "\\1", Model),
        transform =
          case_when(
            Model == "COVIDhub-baseline" ~ "noTransform",
            str_detect(Model, "ensemble") ~ "noTransform",
            !(str_detect(Model, "ensemble") && str_detect(Model, "baseline")) ~ sub(".*-", "", Model)
          ),
        type = ifelse(str_detect(Model, "ensemble"), "ensemble", sub("_.*", "", Model))
      )

    if (y_var == "WIS") {
      gg <- ggplot(data_to_plot, mapping=aes(x=horizon_wk, y=WIS, group=Model)) +
        coord_cartesian(
          ylim = c(min(data_to_plot$WIS)*0.9, median(filter(data_to_plot, horizon_wk==4)$WIS)*1.5)
        )
    } else if (y_var == "MAE") {
      gg <- ggplot(data_to_plot, mapping=aes(x=horizon_wk, y=MAE, group=Model)) +
        coord_cartesian(
          ylim = c(min(data_to_plot$WIS)*0.9, median(filter(data_to_plot, horizon_wk==4)$WIS)*1.5)
        )
    } else if (y_var == "Cov95") {
      gg <- ggplot(data_to_plot, mapping=aes(x=horizon_wk, y=cov95, group=Model)) +
        geom_hline(aes(yintercept=0.95))
    } else if (y_var == "Cov50") {
      gg <- ggplot(data_to_plot, mapping=aes(x=horizon_wk, y=Cov95, group=Model)) +
        geom_hline(aes(yintercept=0.50))
    }

    gg +
      geom_point(mapping=aes(col=Model), alpha = 0.8) +
      geom_line(mapping=aes(col=Model), alpha = 0.8) +
      scale_color_manual(breaks = model_names, values = model_colors) +
#      scale_linetype_manual(breaks=c("noTransform", "4root"), values=c("solid", "dashed")) +
      labs(title=main, x="horizon week", y=paste("average", y_var)) +
      guides(col=guide_legend(nrow=ceiling(length(model_names)/3), byrow=TRUE))
}

# wis_US <- plot_summarized_metrics(horizon_test_US, model_names, model_colors, y_var = "WIS", main="US")
# wis_states <- plot_summarized_metrics(horizon_test_states, model_names, model_colors, y_var="WIS", main="states")
# wis_US + wis_states +
#   plot_layout(ncol = 2, guides='collect') &
#   theme(legend.position='bottom')

# if wave-specific
# wis_winter21_US <- wave_test_US %>% filter(wave == "winter21") %>%
#   plot_summarized_metrics(model_names, model_colors, y_var = "WIS", main="US")


#' Plot summarized metrics against forecast date
#'
#' @param forecast_date_metrics A data frame of forecast_date metrics. Must contain one row per model and horizon week combination plus a `horizon_wk` column
#' @param model_names An ordered vector of model names
#' @param model_colors An ordered vector of model colors. Must match with `model_names` order
#' @param y_var A string specifying which metric to plot as the y-variable. Must be one of "WIS", "MAE", "Cov95", "Cov50"
#' @param horizon_week An integer specifying the horizon week of the desired metric to plot
#' @param main A string specifying the plot title
#'
#' @return A scatter plot (with observations connected by lines) of the specified summary metric vs forecast date
#' @export
#'
#' @examples
plot_forecast_date_metrics <-
  function(forecast_date_metrics, model_names, model_colors, y_var=c("WIS", "MAE", "Cov95", "Cov50"), horizon_week, main) {
    data_to_plot <- forecast_date_metrics %>%
      filter(horizon_wk == horizon_week) %>%
      mutate(
        specification = gsub(".*_(.+)-.*", "\\1", Model),
        transform =
          case_when(
            Model == "COVIDhub-baseline" ~ "noTransform",
            str_detect(Model, "ensemble") ~ "noTransform",
            !(str_detect(Model, "ensemble") && str_detect(Model, "baseline")) ~ sub(".*-", "", Model)
          ),
        type = ifelse(str_detect(Model, "ensemble"), "ensemble", sub("_.*", "", Model))
      )

    if (y_var == "WIS") {
      gg <- ggplot(data_to_plot, mapping=aes(x=mon_fc_date, y=WIS, group=Model)) +
        coord_cartesian(ylim = c(0, sum(quantile(data_to_plot$WIS, prob=c(0.25, 0.99)))))
    } else if (y_var == "MAE") {
      gg <- ggplot(data_to_plot, mapping=aes(x=mon_fc_date, y=MAE, group=Model)) +
        coord_cartesian(ylim = c(0, sum(quantile(data_to_plot$MAE, prob=c(0.25, 0.99)))))
    } else if (y_var == "Cov95") {
      gg <- ggplot(data_to_plot, mapping=aes(x=mon_fc_date, y=Cov95, group=Model)) +
        geom_hline(aes(yintercept=0.95))
    } else if (y_var == "Cov50") {
      gg <- ggplot(data_to_plot, mapping=aes(x=mon_fc_date, y=Cov50, group=Model)) +
        geom_hline(aes(yintercept=0.50))
    }

    gg +
      geom_point(mapping=aes(col=Model), alpha = 0.8) +
      geom_line(mapping=aes(col=Model), alpha = 0.8) +
      scale_x_date(name=NULL, date_breaks = "1 month", date_labels = "%b") +
      scale_color_manual(breaks = model_names, values = model_colors) +
#      scale_linetype_manual(breaks=c("noTransform", "4root"), values=c("solid", "dashed")) +
      labs(title=main, x="forecast date", y=paste("average", y_var)) +
      theme(
        axis.ticks.length.x = unit(0.1, "cm"),
        axis.text.x = element_text(vjust = 2, hjust = -0.2),
        legend.position = 'bottom'
      ) +
      guides(col=guide_legend(nrow=ceiling(length(model_names)/3), byrow=TRUE))
  }

# plot_forecast_date_metrics(forecast_date_test_US, model_names, model_colors, y_var="WIS", horizon_week=1, main="WIS (1-week)") 
