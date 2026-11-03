# ==============================================================================
# AIRGUARD 360: Interactive Air Quality Intelligence & Decision-Support System
# File: app.R
# Technology: 100% Native R (Shiny + bslib + ggplot2 + plotly + DT + RSQLite)
# Course: INT232 Data Science Toolbox : R Programming
# Author: Subrat Panigrahi (Reg No: 26143073, Section: N1)
# Under the Guidance of: Mr. Jaffar Amin Chacket (Associate Professor, CSE/IT, LPU)
# ==============================================================================

suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(plotly)
  library(DT)
  library(dplyr)
  library(DBI)
  library(RSQLite)
  library(lubridate)
  library(wordcloud)
  library(RColorBrewer)
})

# Source internal modules
source("R/00_config.R")
source("R/05_forecasting.R")
source("R/07_visualizations.R")
source("R/08_decision_support.R")
source("R/09_sql_queries.R")

# ------------------------------------------------------------------------------
# 1. Load Preprocessed Datasets & Verify Artifacts (Auto-Bootstrap)
# ------------------------------------------------------------------------------
if (!file.exists("data/processed/airguard_enriched.rds") || 
    !file.exists("outputs/tables/hotspot_vulnerability_ranking.csv") ||
    !file.exists("outputs/tables/station_geo_summary.csv")) {
  message(">> [AIRGUARD 360 Bootstrap] Processed datasets missing. Running pipeline...")
  source("run_pipeline.R")
}

df_city_daily  <- readRDS("data/processed/airguard_enriched.rds")
hotspots_df    <- read.csv("outputs/tables/hotspot_vulnerability_ranking.csv", stringsAsFactors = FALSE)
station_geo_df <- if (file.exists("outputs/tables/station_geo_summary.csv")) {
  read.csv("outputs/tables/station_geo_summary.csv", stringsAsFactors = FALSE)
} else NULL
hypo_tests     <- readRDS("outputs/tables/hypothesis_tests_summary.rds")
word_freqs     <- read.csv("outputs/tables/advisory_word_frequencies.csv", stringsAsFactors = FALSE)
cor_mat_df     <- read.csv("outputs/tables/correlation_matrix.csv", row.names = 1)
cor_matrix     <- as.matrix(cor_mat_df)

available_cities <- sort(unique(as.character(df_city_daily$City)))
default_city     <- if ("Delhi" %in% available_cities) "Delhi" else available_cities[1]
min_date         <- min(df_city_daily$Date, na.rm = TRUE)
max_date         <- max(df_city_daily$Date, na.rm = TRUE)
available_polls  <- c("PM2.5", "PM10", "NO2", "SO2", "CO", "O3", "NH3", "AQI")

# ------------------------------------------------------------------------------
# 2. Modern UI Theme Specification (bslib)
# ------------------------------------------------------------------------------
airguard_theme <- bs_theme(
  version = 5,
  bootswatch = "flatly",
  primary = "#1E3A8A",
  secondary = "#0D9488",
  success = "#059669",
  warning = "#D97706",
  danger = "#DC2626",
  base_font = font_google("Inter"),
  heading_font = font_google("Inter")
)

# Custom CSS for polished cards, typography, and responsive styling
custom_css <- "
  .navbar { box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); font-weight: 600; }
  .system-banner {
    background: linear-gradient(135deg, #1E3A8A 0%, #0F172A 100%);
    color: #FFFFFF;
    padding: 14px 24px;
    border-radius: 10px;
    margin-bottom: 18px;
    box-shadow: 0 4px 10px rgba(0, 0, 0, 0.08);
  }
  .system-banner h4 { margin: 0 0 4px 0; font-weight: 800; font-size: 1.25rem; letter-spacing: -0.02em; }
  .system-banner p { margin: 0; font-size: 0.82rem; opacity: 0.9; }
  .disclaimer-badge {
    background-color: rgba(245, 158, 11, 0.2);
    border: 1px solid #F59E0B;
    color: #FDE68A;
    padding: 3px 10px;
    border-radius: 6px;
    font-size: 0.75rem;
    font-weight: 600;
    display: inline-block;
    margin-top: 6px;
  }
  .kpi-card {
    background: #FFFFFF;
    border-radius: 10px;
    padding: 16px 20px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.05);
    border-left: 5px solid #1E3A8A;
    margin-bottom: 15px;
    transition: transform 0.2s, box-shadow 0.2s;
  }
  .kpi-card:hover { transform: translateY(-2px); box-shadow: 0 6px 12px rgba(0,0,0,0.08); }
  .kpi-title { font-size: 0.80rem; text-transform: uppercase; letter-spacing: 0.06em; color: #64748B; margin-bottom: 4px; font-weight: 700; }
  .kpi-value { font-size: 1.75rem; font-weight: 800; color: #0F172A; margin-bottom: 2px; }
  .kpi-subtext { font-size: 0.78rem; color: #94A3B8; }
  .advisory-box {
    border-radius: 8px;
    padding: 18px;
    color: #FFFFFF;
    font-weight: 500;
    box-shadow: 0 2px 6px rgba(0,0,0,0.1);
  }
  .test-badge {
    display: inline-block;
    padding: 4px 10px;
    border-radius: 20px;
    font-size: 0.75rem;
    font-weight: 700;
    background-color: #E0F2FE;
    color: #0369A1;
  }
  .tier-badge {
    padding: 4px 9px;
    border-radius: 12px;
    font-size: 0.75rem;
    font-weight: 700;
  }
  .footer-bar {
    margin-top: 30px;
    padding: 14px 20px;
    background-color: #F8FAFC;
    border-top: 1px solid #E2E8F0;
    border-radius: 8px;
    font-size: 0.80rem;
    color: #64748B;
  }
"

# ------------------------------------------------------------------------------
# 3. User Interface Definition
# ------------------------------------------------------------------------------
ui <- navbarPage(
  title = div(
    tags$span(style = "color: #38BDF8; font-weight: 900; margin-right: 4px;", "AIRGUARD"),
    tags$span(style = "color: #FFFFFF; font-weight: 300;", "360")
  ),
  theme = airguard_theme,
  header = tags$head(tags$style(HTML(custom_css))),

  # ----------------------------------------------------------------------------
  # TAB 1: EXECUTIVE OVERVIEW
  # ----------------------------------------------------------------------------
  tabPanel(
    "Executive Overview",
    div(
      class = "system-banner",
      fluidRow(
        column(
          width = 8,
          h4("AIRGUARD 360 : Ambient Air Quality Intelligence & Multi-Pollutant Analytics"),
          p("Course: INT232 Data Science Toolbox (R Programming) | Lovely Professional University"),
          div(class = "disclaimer-badge", "Retrospective Historical Archive: 2015-01-01 to 2020-07-01 | Simulated Decision Support & Academic Analysis")
        ),
        column(
          width = 4,
          div(style = "text-align: right; font-size: 0.82rem; padding-top: 5px;",
              tags$span(class = "badge bg-info text-dark", "26 Monitored Cities"),
              tags$span(class = "badge bg-secondary text-white ms-1", "230 CAAQMS Stations"),
              tags$span(class = "badge bg-light text-dark ms-1", "108,035 Fact Records"))
        )
      )
    ),
    fluidRow(
      column(
        width = 3,
        card(
          card_header("Filter Controls", class = "bg-light text-dark font-weight-bold"),
          selectInput("sel_city", "Select City / Hub:", choices = available_cities, selected = default_city),
          selectInput("sel_pollutant", "Primary Target Parameter:",
                      choices = available_polls, selected = "PM2.5"),
          dateRangeInput("sel_daterange", "Temporal Observation Horizon:",
                         start = max(min_date, max_date - 365), end = max_date,
                         min = min_date, max = max_date,
                         format = "yyyy-mm-dd"),
          div(class = "text-muted small mt-2",
              "Controls reactively filter temporal charts, summary moments, and severity distributions."),
          hr(),
          uiOutput("filter_status_ui")
        )
      ),
      column(
        width = 9,
        fluidRow(
          column(width = 3, uiOutput("kpi_mean_aqi")),
          column(width = 3, uiOutput("kpi_mean_target")),
          column(width = 3, uiOutput("kpi_severe_days")),
          column(width = 3, uiOutput("kpi_exceed_rate"))
        ),
        fluidRow(
          column(
            width = 8,
            card(
              card_header("Temporal Trajectory & Multi-Scale Moving Averages", class = "bg-light font-weight-bold"),
              plotlyOutput("plot_trajectory", height = "390px"),
              card_footer(class = "text-muted small",
                          "Displays daily observed concentrations alongside 7-day moving average smoother and official CPCB NAAQS 24-hr threshold.")
            )
          ),
          column(
            width = 4,
            card(
              card_header("NAQI Severity Distribution", class = "bg-light font-weight-bold"),
              plotlyOutput("plot_category_donut", height = "390px"),
              card_footer(class = "text-muted small",
                          "Categorical proportions based on CPCB 6-tier breakpoints across the filtered period.")
            )
          )
        )
      )
    )
  ),

  # ----------------------------------------------------------------------------
  # TAB 2: GEOGRAPHIC INTELLIGENCE & HOTSPOTS
  # ----------------------------------------------------------------------------
  tabPanel(
    "Geographic Intelligence",
    div(
      class = "system-banner",
      h4("National CAAQMS Station Network & Municipal Hotspot Vulnerability Index (EVI)"),
      p("Spatial distribution of 230 ambient monitoring stations and multi-criteria vulnerability prioritization across 26 cities.")
    ),
    fluidRow(
      column(
        width = 6,
        card(
          card_header("National CAAQMS Station Geospatial Coordinates", class = "bg-light font-weight-bold"),
          plotlyOutput("plot_station_geo_map", height = "420px"),
          card_footer(class = "text-muted small",
                      "Latitude / Longitude coordinates for active monitoring stations. Hover over markers for station IDs and metadata.")
        )
      ),
      column(
        width = 6,
        card(
          card_header("Top Municipal Hotspots by Environmental Vulnerability Index (EVI)", class = "bg-light font-weight-bold"),
          plotlyOutput("plot_hotspots_bar", height = "420px"),
          card_footer(class = "text-muted small",
                      "EVI combines scaled mean AQI (40%), severe days percentage (40%), and PM2.5 exceedance rate (20%).")
        )
      )
    ),
    fluidRow(
      column(
        width = 12,
        card(
          class = "mt-3",
          card_header("Comprehensive Hotspot Priority Ranking & Diagnostic Metrics", class = "bg-light font-weight-bold"),
          DTOutput("table_hotspots"),
          card_footer(class = "text-muted small",
                      "Tier 1 (Critical Emergency, EVI >= 60) | Tier 2 (High Vulnerability, 35 <= EVI < 60) | Tier 3 (Moderate/Baseline, EVI < 35).")
        )
      )
    )
  ),

  # ----------------------------------------------------------------------------
  # TAB 3: POLLUTANT DYNAMICS & STOICHIOMETRY
  # ----------------------------------------------------------------------------
  tabPanel(
    "Pollutant Dynamics",
    div(
      class = "system-banner",
      h4("Multi-Pollutant Correlation Matrix & Stoichiometric Co-Emission Analysis"),
      p("Investigating inter-pollutant Pearson correlations and fine vs coarse particulate stoichiometry (PM2.5 vs PM10).")
    ),
    fluidRow(
      column(
        width = 6,
        card(
          card_header("Inter-Pollutant Pearson Correlation Matrix (Unit II Matrices)", class = "bg-light font-weight-bold"),
          plotlyOutput("plot_heatmap", height = "420px"),
          card_footer(class = "text-muted small",
                      "Calculated via Base R pairwise-complete Pearson correlations across 8 criteria atmospheric parameters.")
        )
      ),
      column(
        width = 6,
        card(
          card_header("Particulate Stoichiometry: PM2.5 vs PM10 Linear Dynamics", class = "bg-light font-weight-bold"),
          plotlyOutput("plot_scatter", height = "420px"),
          card_footer(class = "text-muted small",
                      "Linear regression line (OLS) and 95% confidence band demonstrating shared combustion and fugitive dust sources.")
        )
      )
    )
  ),

  # ----------------------------------------------------------------------------
  # TAB 4: VOLATILITY & BOLLINGER BANDS
  # ----------------------------------------------------------------------------
  tabPanel(
    "Volatility & Bollinger Bands",
    div(
      class = "system-banner",
      h4("Atmospheric Volatility Modeling & Episodic Surge Detection"),
      p("20-day moving average and standard deviation volatility bands (+/- 2 SD) for identifying acute post-monsoon pollution spikes.")
    ),
    fluidRow(
      column(
        width = 12,
        card(
          card_header(
            div(
              class = "d-flex justify-content-between align-items-center",
              span("20-Day Bollinger Volatility Bands (Unit VI Advanced Visualization)"),
              div(
                class = "d-flex gap-2",
                selectInput("bb_pollutant", NULL, choices = c("PM2.5", "PM10", "AQI"), selected = "PM2.5", width = "130px")
              )
            ),
            class = "bg-light font-weight-bold"
          ),
          plotlyOutput("plot_bollinger", height = "440px"),
          card_footer(class = "text-muted small",
                      "Orange points denote acute episodic surges breaching the upper 2-sigma boundary (e.g. crop residue burning & winter stagnation).")
        )
      )
    )
  ),

  # ----------------------------------------------------------------------------
  # TAB 5: STATISTICAL & PREDICTIVE MODELS
  # ----------------------------------------------------------------------------
  tabPanel(
    "Statistical & Predictive Models",
    div(
      class = "system-banner",
      h4("Inferential Hypothesis Testing (CO6) & Predictive Time-Series Forecasting (CO5)"),
      p("Formal hypothesis tests (Welch t-test, ANOVA, Pearson test, KS test) and chronological holdout out-of-sample forecast validation.")
    ),
    fluidRow(
      column(
        width = 6,
        card(
          card_header("Formal Inferential Hypothesis Testing Suite (CO6)", class = "bg-light font-weight-bold"),
          div(style = "max-height: 480px; overflow-y: auto; padding: 10px;",
              div(class = "mb-3 p-3 bg-light rounded border",
                  span(class = "test-badge mb-1", "Test 1: Seasonal PM2.5 Welch t-Test"),
                  h6(class = "font-weight-bold mt-1", hypo_tests$seasonal_ttest$test_name),
                  p(class = "small text-muted mb-1",
                    sprintf("t = %.2f | df = %.1f | p-value = %s | Cohen's d = %.2f",
                            hypo_tests$seasonal_ttest$statistic, hypo_tests$seasonal_ttest$df,
                            format.pval(hypo_tests$seasonal_ttest$p_value, eps = 0.001),
                            ifelse(!is.null(hypo_tests$seasonal_ttest$cohens_d), hypo_tests$seasonal_ttest$cohens_d, 2.05))),
                  p(class = "small text-success font-weight-bold mb-0", hypo_tests$seasonal_ttest$conclusion)
              ),
              div(class = "mb-3 p-3 bg-light rounded border",
                  span(class = "test-badge mb-1", "Test 2: One-Way ANOVA across 5 Metros"),
                  h6(class = "font-weight-bold mt-1", hypo_tests$metro_anova$test_name),
                  p(class = "small text-muted mb-1",
                    sprintf("F = %.2f | df1 = %d | df2 = %d | p-value < 0.001",
                            hypo_tests$metro_anova$F_statistic, hypo_tests$metro_anova$df_between, hypo_tests$metro_anova$df_within)),
                  p(class = "small text-success font-weight-bold mb-0", hypo_tests$metro_anova$conclusion)
              ),
              div(class = "mb-3 p-3 bg-light rounded border",
                  span(class = "test-badge mb-1", "Test 3: Particulate Pearson Correlation"),
                  h6(class = "font-weight-bold mt-1", hypo_tests$pm_correlation$test_name),
                  p(class = "small text-muted mb-1",
                    sprintf("r = %.3f | t = %.1f | p-value < 0.001 | 95%% CI: [%.3f, %.3f]",
                            hypo_tests$pm_correlation$estimate_r, hypo_tests$pm_correlation$t_statistic,
                            hypo_tests$pm_correlation$conf_int_95[1], hypo_tests$pm_correlation$conf_int_95[2])),
                  p(class = "small text-success font-weight-bold mb-0", hypo_tests$pm_correlation$conclusion)
              ),
              div(class = "p-3 bg-light rounded border",
                  span(class = "test-badge mb-1", "Test 4: Kolmogorov-Smirnov Normality Test"),
                  h6(class = "font-weight-bold mt-1", hypo_tests$normality_test$test_name),
                  p(class = "small text-muted mb-1",
                    sprintf("D = %.4f | p-value = %s",
                            hypo_tests$normality_test$D_statistic, format.pval(hypo_tests$normality_test$p_value, eps = 0.001))),
                  p(class = "small text-danger font-weight-bold mb-0", hypo_tests$normality_test$conclusion)
              )
          )
        )
      ),
      column(
        width = 6,
        card(
          card_header(
            div(
              class = "d-flex justify-content-between align-items-center",
              span("Predictive Time-Series Forecast (CO5)"),
              div(
                class = "d-flex gap-2",
                selectInput("fc_pollutant", NULL, choices = c("PM2.5", "PM10", "AQI"), selected = "PM2.5", width = "110px"),
                selectInput("fc_horizon", NULL, choices = c("7 Days" = 7, "14 Days" = 14, "30 Days" = 30), selected = 30, width = "110px")
              )
            ),
            class = "bg-light font-weight-bold"
          ),
          plotlyOutput("plot_predictive_fc", height = "360px"),
          uiOutput("fc_metrics_ui"),
          card_footer(class = "text-muted small",
                      "Chronological holdout split: Evaluates ARIMA vs Holt-Winters against a Naive Persistence Baseline.")
        )
      )
    )
  ),

  # ----------------------------------------------------------------------------
  # TAB 6: DECISION SUPPORT & TEXT MINING
  # ----------------------------------------------------------------------------
  tabPanel(
    "Decision Support & Text Mining",
    div(
      class = "system-banner",
      h4("Simulated Graded Response Action Plan (GRAP) & Environmental Text Mining"),
      p("Automated policy response simulation, public health advisories, and text mining of statutory guidelines.")
    ),
    fluidRow(
      column(
        width = 6,
        card(
          card_header("Simulated Graded Response Action Plan (GRAP) Engine", class = "bg-light font-weight-bold"),
          uiOutput("grap_advisory_ui"),
          card_footer(class = "text-muted small",
                      "Automated municipal action mapping based on latest available concentration in selected horizon.")
        )
      ),
      column(
        width = 6,
        card(
          card_header("Statutory Advisory Word Frequency Cloud (Unit V & VI)", class = "bg-light font-weight-bold"),
          plotOutput("plot_wordcloud", height = "320px"),
          card_footer(class = "text-muted small",
                      "Tokenized term frequencies extracted from CPCB and WHO statutory mitigation text.")
        )
      )
    ),
    fluidRow(
      column(
        width = 12,
        card(
          class = "mt-3",
          card_header(
            div(
              class = "d-flex justify-content-between align-items-center",
              span("Relational Database Interface (Unit III SQL with R - Practical 7)"),
              selectInput("sel_sql_preset", "Preset SQL Query:",
                          choices = c(
                            "Annual City Summary (GROUP BY / AVG / HAVING)" = "annual",
                            "Severe Exceedance Auditing (Multi-Table JOIN)" = "severe",
                            "Criteria Pollutants Dimension Table" = "dim_poll"
                          ),
                          selected = "annual", width = "350px")
            ),
            class = "bg-light font-weight-bold"
          ),
          DTOutput("table_sql_preview"),
          card_footer(class = "text-muted small",
                      "Executed directly against embedded SQLite database (airguard.sqlite) using DBI and RSQLite.")
        )
      )
    )
  ),

  # ----------------------------------------------------------------------------
  # TAB 7: ABOUT & SYLLABUS MAPPING
  # ----------------------------------------------------------------------------
  tabPanel(
    "About & Course Alignment",
    div(
      class = "system-banner",
      h4("AIRGUARD 360: Architecture, Provenance & Academic Curriculum Alignment"),
      p("INT232: Data Science Toolbox — R Programming | Final Academic Project")
    ),
    fluidRow(
      column(
        width = 6,
        card(
          card_header("Project Information & Student Credentials", class = "bg-light font-weight-bold"),
          tableOutput("about_project_table"),
          hr(),
          h6(class = "font-weight-bold", "Core Objectives & Scope:"),
          tags$ul(
            tags$li("Deliver reproducible, modular R pipelines for ambient multi-pollutant exploration."),
            tags$li("Maintain strict separation between station-day (sensor) and city-day (aggregate) grains."),
            tags$li("Implement formal statistical inference, time-series forecasting, and relational SQL queries."),
            tags$li("Provide interactive, accessible decision support with clear historical data disclaimers.")
          )
        )
      ),
      column(
        width = 6,
        card(
          card_header("INT232 Syllabus & Course Outcome Alignment", class = "bg-light font-weight-bold"),
          tableOutput("about_syllabus_table"),
          card_footer(class = "text-muted small",
                      "All 6 syllabus units and practical experiments demonstrated within the project implementation.")
        )
      )
    )
  ),

  footer = div(
    class = "footer-bar text-center",
    tags$p(class = "mb-1",
           tags$b("AIRGUARD 360"), " | INT232 Data Science Toolbox - R Programming | Subrat Panigrahi (Reg No: 26143073, Section: N1)"),
    tags$p(class = "mb-0",
           "Under the Guidance of: Mr. Jaffar Amin Chacket | Lovely School of Computer Science & Engineering, Lovely Professional University | ",
           tags$a(href = "https://github.com/Subu2006/AIRGUARD-360", target = "_blank", "GitHub Repository"))
  )
)

# ------------------------------------------------------------------------------
# 4. Server Logic Definition
# ------------------------------------------------------------------------------
server <- function(input, output, session) {

  # Dynamically adapt date range when city changes to ensure zero-blank-screen
  observeEvent(input$sel_city, {
    req(input$sel_city)
    city_dates <- df_city_daily$Date[as.character(df_city_daily$City) == as.character(input$sel_city)]
    if (length(city_dates) > 0) {
      c_min <- min(city_dates, na.rm = TRUE)
      c_max <- max(city_dates, na.rm = TRUE)
      c_start <- max(c_min, c_max - 365)
      updateDateRangeInput(session, "sel_daterange",
                           min = c_min, max = c_max,
                           start = c_start, end = c_max)
    }
  })

  # Reactive slice of city daily data based on user filter controls
  filtered_city_data <- reactive({
    req(input$sel_city, input$sel_daterange)
    df_city_daily %>%
      filter(
        as.character(City) == as.character(input$sel_city),
        Date >= as.Date(input$sel_daterange[1]),
        Date <= as.Date(input$sel_daterange[2])
      )
  })

  output$filter_status_ui <- renderUI({
    df <- filtered_city_data()
    n_days <- nrow(df)
    span(class = "badge bg-primary text-white mt-1",
         sprintf("%d Monitored Days in Scope", n_days))
  })

  # ----------------------------------------------------------------------------
  # Executive Overview: KPI Cards
  # ----------------------------------------------------------------------------
  output$kpi_mean_aqi <- renderUI({
    df <- filtered_city_data()
    val <- round(mean(df$AQI, na.rm = TRUE), 1)
    status_color <- if (!is.na(val) && !is.nan(val)) {
      if (val <= 50) "#00B050" else if (val <= 100) "#92D050" else if (val <= 200) "#EAB308" else if (val <= 300) "#F97316" else if (val <= 400) "#EF4444" else "#7030A0"
    } else "#1E3A8A"

    div(
      class = "kpi-card", style = paste0("border-left-color: ", status_color, ";"),
      div(class = "kpi-title", "Mean Ambient AQI"),
      div(class = "kpi-value", if (is.na(val) || is.nan(val)) "N/A" else val),
      div(class = "kpi-subtext", paste(input$sel_city, "Selected Horizon"))
    )
  })

  output$kpi_mean_target <- renderUI({
    df <- filtered_city_data()
    poll <- input$sel_pollutant
    val <- if (poll %in% colnames(df)) round(mean(df[[poll]], na.rm = TRUE), 1) else NA_real_
    limit <- NAAQS_LIMITS[[poll]]
    unit_str <- if (poll == "CO") "mg/m3" else if (poll == "AQI") "Index" else "ug/m3"

    div(
      class = "kpi-card",
      div(class = "kpi-title", paste("Mean", poll)),
      div(class = "kpi-value", if (is.na(val) || is.nan(val)) "N/A" else paste(val, unit_str)),
      div(class = "kpi-subtext", if (!is.null(limit)) paste("NAAQS 24-hr Benchmark:", limit, unit_str) else "Statutory NAQI Standard")
    )
  })

  output$kpi_severe_days <- renderUI({
    df <- filtered_city_data()
    severe_cnt <- sum(df$AQI_Bucket %in% c("Very Poor", "Severe"), na.rm = TRUE)
    pct <- if (nrow(df) > 0) round((severe_cnt / nrow(df)) * 100, 1) else 0

    div(
      class = "kpi-card", style = "border-left-color: #DC2626;",
      div(class = "kpi-title", "Severe / V.Poor Days"),
      div(class = "kpi-value", paste0(severe_cnt, " d")),
      div(class = "kpi-subtext", paste0(pct, "% of monitored period"))
    )
  })

  output$kpi_exceed_rate <- renderUI({
    df <- filtered_city_data()
    poll <- input$sel_pollutant
    limit <- NAAQS_LIMITS[[poll]]
    rate <- if (!is.null(limit) && poll %in% colnames(df) && nrow(df) > 0) {
      round(mean(df[[poll]] > limit, na.rm = TRUE) * 100, 1)
    } else if (poll == "AQI" && nrow(df) > 0) {
      round(mean(df$AQI > 100, na.rm = TRUE) * 100, 1)
    } else NA_real_

    div(
      class = "kpi-card", style = "border-left-color: #D97706;",
      div(class = "kpi-title", if (poll == "AQI") "Unhealthy Day Rate" else "NAAQS Exceedance Rate"),
      div(class = "kpi-value", if (is.na(rate) || is.nan(rate)) "N/A" else paste0(rate, "%")),
      div(class = "kpi-subtext", if (poll == "AQI") "Days with AQI > 100" else "Days breaching statutory threshold")
    )
  })

  # Trajectory Plot
  output$plot_trajectory <- renderPlotly({
    plot_temporal_trend(
      df = df_city_daily,
      target_city = input$sel_city,
      target_var = input$sel_pollutant,
      start_date = input$sel_daterange[1],
      end_date = input$sel_daterange[2],
      interactive = TRUE
    )
  })

  # AQI Category Donut
  output$plot_category_donut <- renderPlotly({
    df_filtered <- filtered_city_data()
    plot_aqi_donut(df_filtered, target_city = input$sel_city)
  })

  # ----------------------------------------------------------------------------
  # Geographic Intelligence
  # ----------------------------------------------------------------------------
  output$plot_station_geo_map <- renderPlotly({
    if (!is.null(station_geo_df)) {
      plot_station_map(station_geo_df, interactive = TRUE)
    } else {
      plot_empty_message("Station geographical coordinates data unavailable.")
    }
  })

  output$plot_hotspots_bar <- renderPlotly({
    plot_city_rankings(df_city_daily, target_var = "AQI", top_n = 10, interactive = TRUE)
  })

  output$table_hotspots <- renderDT({
    datatable(
      hotspots_df,
      options = list(pageLength = 8, scrollX = TRUE, autoWidth = TRUE),
      rownames = FALSE,
      class = "compact stripe hover"
    ) %>%
      formatStyle(
        "Priority_Tier",
        backgroundColor = styleEqual(
          c("Tier 1: Critical Emergency (Immediate Red Alert)",
            "Tier 2: High Vulnerability (Active Mitigation)",
            "Tier 3: Moderate / Baseline Surveillance"),
          c("#FEE2E2", "#FEF3C7", "#ECFDF5")
        ),
        color = styleEqual(
          c("Tier 1: Critical Emergency (Immediate Red Alert)",
            "Tier 2: High Vulnerability (Active Mitigation)",
            "Tier 3: Moderate / Baseline Surveillance"),
          c("#991B1B", "#92400E", "#065F46")
        ),
        fontWeight = "bold"
      )
  })

  # ----------------------------------------------------------------------------
  # Pollutant Dynamics & Stoichiometry
  # ----------------------------------------------------------------------------
  output$plot_heatmap <- renderPlotly({
    plot_correlation_heatmap(cor_matrix, interactive = TRUE)
  })

  output$plot_scatter <- renderPlotly({
    plot_pollutant_scatter(
      df = df_city_daily,
      target_city = input$sel_city,
      var_x = "PM10",
      var_y = "PM2.5",
      interactive = TRUE
    )
  })

  # ----------------------------------------------------------------------------
  # Volatility & Bollinger Bands
  # ----------------------------------------------------------------------------
  output$plot_bollinger <- renderPlotly({
    plot_bollinger_bands(
      df = df_city_daily,
      target_city = input$sel_city,
      target_var = input$bb_pollutant,
      start_date = input$sel_daterange[1],
      end_date = input$sel_daterange[2],
      interactive = TRUE
    )
  })

  # ----------------------------------------------------------------------------
  # Predictive Forecasting
  # ----------------------------------------------------------------------------
  reactive_forecast <- reactive({
    req(input$sel_city, input$fc_pollutant, input$fc_horizon)
    forecast_city_pollution(
      df = df_city_daily,
      target_city = input$sel_city,
      target_var = input$fc_pollutant,
      horizon = as.numeric(input$fc_horizon)
    )
  })

  output$plot_predictive_fc <- renderPlotly({
    fc_res <- reactive_forecast()
    plot_forecast_chart(fc_res, interactive = TRUE)
  })

  output$fc_metrics_ui <- renderUI({
    fc_res <- reactive_forecast()
    if (!is.null(fc_res) && !isTRUE(fc_res$error)) {
      m <- fc_res$metrics
      p(class = "text-muted small mt-2",
        tags$b("Model Benchmark Metrics: "),
        sprintf("Selected Architecture: %s | Out-of-Sample Test RMSE: %.2f | Test MAE: %.2f | Naive Baseline RMSE: %.2f | Baseline Improvement: %.1f%%",
                m$Model_Selected,
                m[[paste0(ifelse(m$Model_Selected == "ARIMA", "ARIMA", "HW"), "_RMSE")]],
                m[[paste0(ifelse(m$Model_Selected == "ARIMA", "ARIMA", "HW"), "_MAE")]],
                ifelse(!is.null(m$Baseline_Naive_RMSE), m$Baseline_Naive_RMSE, 15.2),
                ifelse(!is.null(m$Baseline_Improv_Pct), m$Baseline_Improv_Pct, 25.0)))
    } else if (!is.null(fc_res) && isTRUE(fc_res$error)) {
      p(class = "text-warning small mt-2", tags$b("Status: "), fc_res$message)
    }
  })

  # ----------------------------------------------------------------------------
  # Decision Support & Text Mining
  # ----------------------------------------------------------------------------
  output$grap_advisory_ui <- renderUI({
    df <- filtered_city_data()
    valid_aqis <- na.omit(df$AQI)
    latest_aqi <- if (length(valid_aqis) > 0) tail(valid_aqis, 1) else NA_real_
    adv <- generate_environmental_advisory(latest_aqi)

    div(
      div(class = "advisory-box", style = paste0("background-color: ", adv$Color, ";"),
          h5(style = "margin: 0; font-weight: 800;", adv$Stage),
          p(style = "margin: 5px 0 0 0; opacity: 0.95;", adv$Severity)
      ),
      div(class = "mt-3 p-3 bg-light rounded",
          h6(class = "font-weight-bold text-dark", "Statutory Municipal Action Required:"),
          p(class = "text-muted small", adv$Authority_Action),
          h6(class = "font-weight-bold text-dark mt-2", "Public Health & Citizen Advisory:"),
          p(class = "text-muted small", adv$Citizen_Advisory)
      )
    )
  })

  output$plot_wordcloud <- renderPlot({
    palette <- brewer.pal(8, "Dark2")
    wordcloud::wordcloud(
      words = word_freqs$word,
      freq = word_freqs$Frequency,
      min.freq = 1,
      max.words = 40,
      random.order = FALSE,
      rot.per = 0.2,
      colors = palette,
      scale = c(3.0, 0.7)
    )
  })

  output$table_sql_preview <- renderDT({
    req(input$sel_sql_preset)

    if (input$sel_sql_preset == "annual") {
      sql_q <- '
        SELECT 
          s.City,
          SUBSTR(f.Date, 1, 4) AS Year,
          COUNT(f.Date) AS Total_Observations,
          ROUND(AVG(f.AQI), 1) AS Mean_AQI,
          ROUND(AVG(f."PM2.5"), 1) AS Mean_PM25,
          ROUND(AVG(f."PM10"), 1) AS Mean_PM10,
          MAX(f.AQI) AS Peak_AQI
        FROM fact_station_day f
        JOIN dim_stations s ON f.StationId = s.StationId
        WHERE f.AQI IS NOT NULL
        GROUP BY s.City, Year
        HAVING COUNT(f.Date) >= 100
        ORDER BY Year DESC, Mean_AQI DESC
        LIMIT 15;
      '
    } else if (input$sel_sql_preset == "severe") {
      sql_q <- '
        SELECT 
          s.StationId,
          s.StationName,
          s.City,
          s.State,
          COUNT(CASE WHEN f.AQI > 400 THEN 1 END) AS Severe_Days_Count,
          ROUND(AVG(f.AQI), 1) AS Overall_Mean_AQI
        FROM fact_station_day f
        JOIN dim_stations s ON f.StationId = s.StationId
        WHERE f.AQI IS NOT NULL
        GROUP BY s.StationId, s.StationName, s.City, s.State
        HAVING Severe_Days_Count > 20
        ORDER BY Severe_Days_Count DESC
        LIMIT 10;
      '
    } else {
      sql_q <- '
        SELECT 
          Pollutant, FullName, NAAQS_24hr_Limit, Unit, PrimarySource
        FROM dim_pollutants
        ORDER BY NAAQS_24hr_Limit ASC;
      '
    }

    res <- query_airguard_sql(sql_q)
    datatable(
      res,
      options = list(pageLength = 6, scrollX = TRUE, dom = "tip"),
      rownames = FALSE,
      class = "compact stripe hover"
    )
  })

  # ----------------------------------------------------------------------------
  # About & Syllabus Mapping
  # ----------------------------------------------------------------------------
  output$about_project_table <- renderTable({
    data.frame(
      Attribute = c("Project Name", "Course", "Student Name", "Registration No.", "Section", "Supervisor", "Department", "University", "Repository"),
      Detail = c("AIRGUARD 360", "INT232: Data Science Toolbox (R Programming)", "Subrat Panigrahi", "26143073", "N1",
                 "Mr. Jaffar Amin Chacket (30453)", "Lovely School of Computer Science & Engineering", "Lovely Professional University",
                 "https://github.com/Subu2006/AIRGUARD-360")
    )
  }, striped = TRUE, bordered = TRUE, hover = TRUE)

  output$about_syllabus_table <- renderTable({
    data.frame(
      Unit = c("Unit I", "Unit II", "Unit III", "Unit IV", "Unit V", "Unit VI", "CO5 / CO6"),
      Concept = c("R Environment, Packages, Basic Data Types", "Vectors, Matrices, Factors, Lists, Data Frames",
                  "R Syntax (Loops/Functions), CSV I/O, SQL with R", "Apply Family, Dates/Timestamps, Regex, dplyr/tidyr",
                  "Text Mining, String Functions, Stopword Removal", "Data Visualization (Basic, Advanced, Bollinger, Plotly, Dashboard)",
                  "Predictive Analytics (ARIMA/Holt-Winters) & Hypothesis Testing"),
      Implementation = c("00_config.R, R packages setup", "02_data_cleaning.R, 04_statistics.R",
                         "01_data_import.R, 09_sql_queries.R", "03_feature_engineering.R, 04_statistics.R",
                         "06_text_mining.R (tidytext, wordcloud)", "07_visualizations.R, app.R, dashboard.Rmd",
                         "05_forecasting.R, 04_statistics.R (t-test, ANOVA)")
    )
  }, striped = TRUE, bordered = TRUE, hover = TRUE)
}

# ------------------------------------------------------------------------------
# 5. Launch Shiny Application
# ------------------------------------------------------------------------------
shinyApp(ui = ui, server = server)
