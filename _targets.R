# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline # nolint

# Load packages required to define the pipeline:
library(targets)
library(tarchetypes) # Load other packages as needed. # nolint

# Set target options:
tar_option_set(
  packages = c("tibble", "dplyr", "thief", "forecast", "lubridate", "tidyverse", "zoltr", "covidHubUtils", "patchwork", "surveillance", "tidytext", "stringr"), # packages that your targets need to run
  format = "rds" # default storage format
  # Set other options as needed.
)

# tar_make_clustermq() configuration (okay to leave alone):
options(clustermq.scheduler = "multiprocess")

# tar_make_future() configuration (okay to leave alone):
# Install packages {{future}}, {{future.callr}}, and {{future.batchtools}} to allow use_targets() to configure tar_make_future() options.

# Run the R scripts in the R/ folder with your custom functions:
tar_source()
# source("other_functions.R") # Source other scripts as needed. # nolint

# Replace the target list below with your own:
list(
  tar_target(inc_hosp_targets, paste(0:30, "day ahead inc hosp")),
  tar_target(
    fips, 
    hub_locations %>% 
      filter(geo_type == "state", population >= 500000) %>%
      pull(fips)
  ),
  tar_target(validation_forecast_range, c(as.Date("2020-12-07"), as.Date("2021-10-31"))),
  tar_target(testing_forecast_range, c(as.Date("2021-11-01"), as.Date("2022-10-02"))),

  # model names
  tar_target(all_thief, sort(paste("THieF_", c(1:4, 6, 8, 12), "wk-", c(rep("4root", 7), rep("noTransform", 7)), sep=""))[c(3:14, 1:2)]),
  tar_target(thief_new, sort(paste("THieF_", c(1:3, 6), "wk-", c(rep("4root", 4), rep("noTransform", 4)), sep=""))),
  tar_target(thief_old, sort(paste("THieF_", c(4, 8, 12), "wk-", c(rep("4root", 3), rep("noTransform", 3)), sep=""))),
  tar_target(sarima_models, sort(paste("sarima_s", c(1, 7), c(rep("-4root", 2), rep("-noTransform", 2)), sep=""))),
  tar_target(thief_ensembles, paste("THieF_ensemble-", c("mean", paste(rep("train", 7), c(1, 3, 6.5, 10, 15, 20, 25), sep="")), sep="")),
  tar_target(validation_models, c(all_thief, sarima_models, thief_ensembles)),
  tar_target(testing_models, c("sarima_s7-noTransform", "sarima_s1-noTransform", "THieF_6wk-4root", "THieF_6wk-noTransform", "THieF_12wk-4root", "THieF_ensemble-train3", "THieF_ensemble-mean")),

  tar_target(validation_model_names, c("COVIDhub-baseline", validation_models)),
  tar_target(
    validation_model_colors, 
    c(
      "black", 
      rep(c("red", "orange", "yellow", "green", "blue", "purple", "magenta", "#b9865f", "#644e3d"), each=2), 
      "#dfdfdf", "#cacaca", "#a8a8a8", "#878787", "#6d6d6d", "#5f5f5f", "#4a4a4a", "#3d3d3d"
    )
  ),
  tar_target(testing_model_names, c("COVIDhub-baseline", "COVIDhub-4_week_ensemble", testing_models)),
  tar_target(
    testing_model_colors, 
    c("black", "darkgrey", "red", "orange", "yellow", "green", "blue", "magenta", "purple")
  ),
  
  # ADD FILEPATHS TO DATA
#  tar_target(all_data, list.files("data", full.names=TRUE), format="file"), # if using Arrow package
  tar_target(scores_baseline_validation_path, "data/validation_scv_baseline.rds", format="file"),
  tar_target(scores_thief_ensemble_validation_path, "data/validation_scv_thief_ensemble.rds", format="file"),
  tar_target(scores_thief_new_validation_path, "data/validation_scv_thief_new.rds", format="file"),
  tar_target(scores_thief_old_validation_path, "data/validation_scv_thief_old.rds", format="file"),
  tar_target(scores_sarima_validation_path, "data/validation_scv_sarima.rds", format="file"),

  tar_target(sunday_validation_truth_path, "data/validation_truth_sunday.rds", format="file"),
  tar_target(monday_validation_truth_path, "data/validation_truth_monday.rds", format="file"),

  tar_target(forecasts_baseline_testing_path, "data/testing_fcv_baseline.rds", format="file"),
  tar_target(forecasts_ensemble_testing_path, "data/testing_fcv_ensemble.rds", format="file"),
  tar_target(forecasts_models_small_testing_path, "data/testing_fcv_models_small.rds", format="file"),
  tar_target(scores_baseline_testing_path, "data/testing_scv_baseline.rds", format="file"),
  tar_target(scores_ensemble_testing_path, "data/testing_scv_ensemble.rds", format="file"),
  tar_target(scores_models_testing_path, "data/testing_scv_models.rds", format="file"),

  tar_target(sunday_testing_truth_path, "data/testing_truth_sunday.rds", format="file"),
  tar_target(monday_testing_truth_path, "data/testing_truth_monday.rds", format="file"),
  
  # READ IN DATA
#  tar_target(list_data, map_dfr(all_data, read_csv, col_types=cols())),
  tar_target(scores_baseline_validation, read_rds(scores_baseline_validation_path)),
  tar_target(scores_thief_ensemble_validation, read_rds(scores_thief_ensemble_validation_path)),
  tar_target(scores_thief_new_validation, read_rds(scores_thief_new_validation_path)),
  tar_target(scores_thief_old_validation, read_rds(scores_thief_old_validation_path)),
  tar_target(scores_sarima_validation, read_rds(scores_sarima_validation_path)),
  
  tar_target(sunday_validation_truth_list, read_rds(sunday_validation_truth_path)),
  tar_target(monday_validation_truth_list, read_rds(monday_validation_truth_path)),
  
  tar_target(forecasts_baseline_testing, read_rds(forecasts_baseline_testing_path)),
  tar_target(forecasts_ensemble_testing, read_rds(forecasts_ensemble_testing_path)),
  tar_target(forecasts_models_small_testing, read_rds(forecasts_models_small_testing_path)),
  tar_target(scores_baseline_testing, read_rds(scores_baseline_testing_path)),
  tar_target(scores_ensemble_testing, read_rds(scores_ensemble_testing_path)),
  tar_target(scores_models_testing, read_rds(scores_models_testing_path)),
  
  tar_target(sunday_testing_truth_list, read_rds(sunday_testing_truth_path)),
  tar_target(monday_testing_truth_list, read_rds(monday_testing_truth_path)),
  
  tar_target(
    actual_testing_dates, 
    distinct(scores_models_testing, forecast_date) %>% pull(1)
  ),
#  tar_target(
#    validation_dates_to_plot, 
#    c(as.Date("2020-12-07") + weeks(4*(0:11)), actual_validation_dates[1+4*(0:11)])
# ),
 tar_target(
   testing_dates_to_plot, 
   c(as.Date("2021-11-01") + weeks(4*(0:11)), actual_testing_dates[1+4*(0:11)])
 ),
  # mon_dates_df <- tibble(forecast_date = actual_fc_dates, mon_fc_dates)
  tar_target(
    testing_forecasts_to_plot, #fc_plot (bind small fc and baseline together)
    rbind(forecasts_models_small_testing, forecasts_baseline_testing, forecasts_ensemble_testing)
  ),
  
  tar_target(
    validation_scores, #scores(bind not baseline scores together, create horizon_wk)
    scores_baseline_validation %>%
    rbind(scores_thief_ensemble_validation, scores_thief_new_validation, scores_thief_old_validation, scores_sarima_validation) %>%
      mutate(
        mon_fc_date = 
          floor_date(
            forecast_date - days(1), 
            unit = "weeks", 
            week_start = getOption("lubricate.week.start", 1)
          ) + weeks(1),
        horizon_wk=ceiling(as.numeric(target_end_date-mon_fc_date)/7),
        forecast_date = mon_fc_date,
      ) %>%
      select(-mon_fc_date) %>%
      filter(horizon_wk %in% 1:4)
  ),
  tar_target(
    testing_scores, #scores(bind not baseline scores together, create horizon_wk)
    rbind(scores_models_testing, scores_baseline_testing, scores_ensemble_testing) %>%
      mutate(
        mon_fc_date = 
          floor_date(
            forecast_date - days(1), 
            unit = "weeks", 
            week_start = getOption("lubricate.week.start", 1)
          ) + weeks(1),
        horizon_wk=ceiling(as.numeric(target_end_date-mon_fc_date)/7),
        forecast_date = mon_fc_date,
      ) %>%
      select(-mon_fc_date) %>%
      filter(
        horizon_wk %in% 1:4,
        model != "THieF_12wk-noTransform"
      )
  ),
  tar_target(
    full_hosp_truth, 
    load_truth("HealthData", "inc hosp", as_of=as.Date("2022-10-01"), temporal_resolution="weekly", data_location = "covidData")
  ),
  
tar_target(
  evaluation_period_plot,
  full_hosp_truth %>%
    filter(
      location == "US", 
      target_end_date %in% c(as.Date("2020-07-27"):as.Date("2022-10-02"))
    ) %>%
  ggplot(aes(x = target_end_date, y = value)) + 
    geom_line() + 
    geom_vline(xintercept = as.Date("2020-07-27"), linetype="solid") +
    geom_vline(xintercept = as.Date("2020-10-22"), linetype="dashed") +
    geom_vline(xintercept = as.Date("2020-12-07"), linetype="solid") +
    geom_vline(xintercept = as.Date("2021-03-15"), linetype="dashed") +
    geom_vline(xintercept = as.Date("2021-07-05"), linetype="dashed") +
    geom_vline(xintercept = as.Date("2021-11-01"), linetype="solid") +
    geom_vline(xintercept = as.Date("2022-04-06"), linetype="dashed") +
    geom_vline(xintercept = as.Date("2022-10-02"), linetype="solid") +
    annotate(geom = "text", x = as.Date("2020-07-17"), y = 2500, 
             label = "Validation Start", size = 4, angle = 90) + 
    annotate(geom = "text", x = as.Date("2020-11-27"), y = 2500, # 2020-12-19
             label = "Forecasts Start", size = 4, angle = 90) +
    annotate(geom = "text", x = as.Date("2021-10-20"), y = 2500, 
             label = "Testing Start", size = 4, angle = 90) + 
    annotate(geom = "text", x = as.Date("2022-09-22"), y = 2500, 
             label = "Testing End", size = 4, angle = 90) + 
    annotate(geom = "text", x = as.Date("2021-01-03"), y = 25000, 
             label = "Winter 2020-21", size = 4, angle = 0) + 
    annotate(geom = "text", x = as.Date("2021-05-11"), y = 25000, 
             label = "Alpha", size = 4, angle = 0) + 
    annotate(geom = "text", x = as.Date("2021-09-03"), y = 25000, 
             label = "Delta", size = 4, angle = 0) + 
    annotate(geom = "text", x = as.Date("2022-01-19"), y = 25000, 
             label = "Omicron", size = 4, angle = 0) + 
    annotate(geom = "text", x = as.Date("2022-07-05"), y = 25000, 
             label = "BA.4/BA.5", size = 4, angle = 0) + 
    scale_x_date(name=NULL, date_breaks = "4 month", minor_breaks = "2 month",
                 date_labels = "%b '%y") + 
    ylim(c(0, NA)) +
    theme(axis.ticks.length.x = unit(0.25, "cm"),  
          axis.text.x = element_text(vjust = 1, hjust = 0.5),
          legend.position = "none") + 
    theme_bw() +
    labs(title = "COVID-19 US National Hospitalizations",
         x = "Date", y = "Incident Hospitalizations (Daily)")
),

  tar_target(thief_concept_plot, 
    plot_thief_full(
      truth=full_hosp_truth, 
      start_date = "2020-07-27", 
      end_date="2021-06-06", 
      fips = "US", 
      frequency=14, 
      aggregation_list = list(14, 7, 1), 
      aggregation_names = c("1-daily", "1-weekly", "2-weekly")
    )
  ),
  
  tar_target(ordered_testing_locations, 
    full_hosp_truth %>%
      filter(target_end_date %in% testing_forecast_range[1]:testing_forecast_range[2]) %>%
      group_by(location) %>%
      summarize(cum_value=sum(value)) %>%
      ungroup() %>%
      arrange(desc(cum_value)) %>%
#      filter(row_number() %in% c(1, 2, 53)) %>% # can change values
      pull(location)
  ),
  tar_target(plot_models_1, 
    plot_models_one_location(
      forecasts=testing_forecasts_to_plot, 
      models=testing_model_names[c(1:3,5)],
      truth=full_hosp_truth, 
      fips=ordered_testing_locations[1], 
      fc_dates=testing_dates_to_plot, 
      facet_nrow = 4, 
      date_limits = c(as.Date("2021-07-05"), testing_forecast_range[2]))
  ),

  tar_target(
    overall_validation_us,
    summarize_overall_metrics(validation_scores, baseline_name="COVIDhub-baseline", us_only=TRUE)
  ),
  tar_target(
    overall_validation_states,
    summarize_overall_metrics(validation_scores, baseline_name="COVIDhub-baseline", us_only=FALSE)
  ),
  tar_target(
    last17_validation_us,
    validation_scores %>%
      filter(forecast_date >= validation_forecast_range[2] - weeks(17)) %>%
      summarize_overall_metrics(baseline_name="COVIDhub-baseline", us_only=TRUE)
  ),
  tar_target(
    last17_validation_states,
    validation_scores %>%
      filter(forecast_date >= validation_forecast_range[2] - weeks(17)) %>%
      summarize_overall_metrics(baseline_name="COVIDhub-baseline", us_only=FALSE)
  ),
  
  tar_target(
    overall_metrics_us,
    summarize_overall_metrics(testing_scores, baseline_name="COVIDhub-baseline", us_only=TRUE)
  ),
  tar_target(
    overall_metrics_states,
    summarize_overall_metrics(testing_scores, baseline_name="COVIDhub-baseline", us_only=FALSE)
  ),
  
  tar_target(
    horizon_metrics_us,
    summarize_horizon_metrics(testing_scores, baseline_name="COVIDhub-baseline", us_only=TRUE)
  ),
  tar_target(
    horizon_metrics_states,
    summarize_horizon_metrics(testing_scores, baseline_name="COVIDhub-baseline", us_only=FALSE)
  ),
  tar_target(
    wis_plot_us, 
    plot_summarized_metrics(
      summarized_metrics=horizon_metrics_us, 
      testing_model_names, 
      testing_model_colors, 
      y_var="WIS", 
      main="US")
  ),
  tar_target(
    wis_plot_states, 
    plot_summarized_metrics(
      summarized_metrics=horizon_metrics_states, 
      testing_model_names, 
      testing_model_colors, 
      y_var="WIS", 
      main="States")
  ),
  tar_target(
    combined_wis_plot,
      wis_plot_us + wis_plot_states +
      plot_layout(ncol = 2, guides='collect') &
      theme(legend.position='bottom')
  ),
  
  tar_target(
    wave_metrics_us,
    testing_scores %>%
      summarize_wave_metrics(baseline_name="COVIDhub-baseline", us_only=TRUE)
  ),
  tar_target(
    wave_metrics_states,
    testing_scores %>%
      summarize_wave_metrics(baseline_name="COVIDhub-baseline", us_only=FALSE)
  ),
  tar_target(
    wis_plot_omicron_us, 
    filter(wave_metrics_us, wave=="omicron") %>%
      plot_summarized_metrics(
        testing_model_names, 
        testing_model_colors, 
        y_var="WIS", 
        main="Omicron (US)"
      )
  ),
  tar_target(
    wis_plot_omicron_states, 
    filter(wave_metrics_states, wave=="omicron") %>%
      plot_summarized_metrics(
        testing_model_names, 
        testing_model_colors, 
        y_var="WIS", 
        main="Omicron (States)"
      )
  ),
  tar_target(
    wis_plot_ba4ba5_us, 
    filter(wave_metrics_us, wave=="ba4_ba5") %>%
      plot_summarized_metrics(
        testing_model_names, 
        testing_model_colors, 
        y_var="WIS", 
        main="BA.4/BA.5 (US)"
      )
  ),
  tar_target(
    wis_plot_ba4ba5_states, 
    filter(wave_metrics_states, wave=="ba4_ba5") %>%
      plot_summarized_metrics(
        testing_model_names, 
        testing_model_colors, 
        y_var="WIS", 
        main="BA.4/BA.5 (States)"
      )
  ),
  tar_target(
    combined_wis_wave_plot,
    wis_plot_omicron_us + wis_plot_omicron_states + wis_plot_ba4ba5_us + wis_plot_ba4ba5_states +
      plot_layout(ncol = 2, guides='collect') &
      theme(legend.position='bottom')
  ),
  
  tar_target(
    forecast_date_metrics_us,
    summarize_forecast_date_metrics(testing_scores, us_only=TRUE)
  ),
  tar_target(
    wis_plot_date_1week_us, 
    plot_forecast_date_metrics(
      forecast_date_metrics=forecast_date_metrics_us, 
      testing_model_names, 
      testing_model_colors, 
      y_var="WIS", 
      horizon_week=1,
      main="WIS (1 week)"
    )
  ),
  tar_target(
    wis_plot_date_4week_us, 
    plot_forecast_date_metrics(
      forecast_date_metrics=forecast_date_metrics_us, 
      testing_model_names, 
      testing_model_colors, 
      y_var="WIS", 
      horizon_week=4,
      main="WIS (4 week)"
    )
  ),
  tar_target(
    cov95_plot_date_1week_us, 
    plot_forecast_date_metrics(
      forecast_date_metrics=forecast_date_metrics_us, 
      testing_model_names, 
      testing_model_colors, 
      y_var="Cov95", 
      horizon_week=1,
      main="95% coverage (1 week)"
    )
  ),
  tar_target(
    cov95_plot_date_4week_us, 
    plot_forecast_date_metrics(
      forecast_date_metrics=forecast_date_metrics_us, 
      testing_model_names, 
      testing_model_colors, 
      y_var="Cov95", 
      horizon_week=4,
      main="95% coverage (4 week)"
    )
  ),
  tar_target(
    combined_wis_cov95_plot_us,
    wis_plot_date_1week_us + wis_plot_date_4week_us +
      cov95_plot_date_1week_us + cov95_plot_date_4week_us +
      plot_layout(ncol = 2, guides='collect') &
      theme(legend.position='bottom')
  ),
  
  tar_target(
    forecast_date_metrics_states,
    summarize_forecast_date_metrics(testing_scores, us_only=FALSE)
  ),
  tar_target(
    wis_plot_date_1week_states, 
    plot_forecast_date_metrics(
      forecast_date_metrics=forecast_date_metrics_states, 
      testing_model_names, 
      testing_model_colors, 
      y_var="WIS", 
      horizon_week=1,
      main="WIS (1 week)"
    )
  ),
  tar_target(
    wis_plot_date_4week_states, 
    plot_forecast_date_metrics(
      forecast_date_metrics=forecast_date_metrics_states, 
      testing_model_names, 
      testing_model_colors, 
      y_var="WIS", 
      horizon_week=4,
      main="WIS (4 week)"
    )
  ),
  tar_target(
    cov95_plot_date_1week_states, 
    plot_forecast_date_metrics(
      forecast_date_metrics=forecast_date_metrics_states, 
      testing_model_names, 
      testing_model_colors, 
      y_var="Cov95", 
      horizon_week=1,
      main="95% coverage (1 week)"
    )
  ),
  tar_target(
    cov95_plot_date_4week_states, 
    plot_forecast_date_metrics(
      forecast_date_metrics=forecast_date_metrics_states, 
      testing_model_names, 
      testing_model_colors, 
      y_var="Cov95", 
      horizon_week=4,
      main="95% coverage (4 week)"
    )
  ),
  tar_target(
    combined_wis_cov95_plot_states,
    wis_plot_date_1week_states + wis_plot_date_4week_states +
      cov95_plot_date_1week_states + cov95_plot_date_4week_states +
      plot_layout(ncol = 2, guides='collect') &
      theme(legend.position='bottom')
  ),
 
  tar_target(ordered_testing_models, pull(overall_metrics_states, Model)),
  tar_target(
    wis_location_plot,
    plot_wis_loc(
      testing_scores, 
      full_hosp_truth, 
      ordered_testing_models, 
      baseline_name = "COVIDhub-baseline"
    )
  )

)

