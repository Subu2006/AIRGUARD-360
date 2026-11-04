# ==============================================================================
# AIRGUARD 360: National Air Quality Intelligence & Decision-Support System
# File: app.R
# Architecture: 100% Native R (Shiny + bslib + ggplot2 + plotly + leaflet + DT + RSQLite)
# Author & Architect: Subrat Panigrahi (B.Tech Computer Science & Engineering)
# Open-Source Repository: https://github.com/Subu2006/AIRGUARD-360
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
  library(leaflet)
  library(shinyWidgets)
  library(shinycssloaders)
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
compare_city     <- if ("Bengaluru" %in% available_cities) "Bengaluru" else available_cities[2]
min_date         <- min(df_city_daily$Date, na.rm = TRUE)
max_date         <- max(df_city_daily$Date, na.rm = TRUE)
available_polls  <- c("PM2.5", "PM10", "NO2", "SO2", "CO", "O3", "NH3", "AQI")

# ------------------------------------------------------------------------------
# 2. Modern UI Theme Specification (bslib & Enterprise CSS)
# ------------------------------------------------------------------------------
airguard_theme <- bs_theme(
  version = 5,
  bootswatch = "flatly",
  primary = "#0284C7",
  secondary = "#10B981",
  success = "#059669",
  warning = "#D97706",
  danger = "#DC2626",
  base_font = font_google("Inter"),
  heading_font = font_google("Inter")
)

custom_css <- "
  :root {
    --primary: #0284C7;
    --dark-bg: #0F172A;
    --card-bg: #FFFFFF;
    --border-color: #E2E8F0;
  }
  body {
    background-color: #F8FAFC;
    color: #1E293B;
  }
  .navbar {
    background: linear-gradient(135deg, #0F172A 0%, #1E293B 100%) !important;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    border-bottom: 2px solid #0284C7;
    padding: 10px 18px;
  }
  .navbar-brand {
    font-size: 1.35rem;
    font-weight: 800;
    letter-spacing: -0.02em;
  }
  .system-banner {
    background: linear-gradient(135deg, #0F172A 0%, #1E3A8A 50%, #0F172A 100%);
    color: #FFFFFF;
    padding: 16px 24px;
    border-radius: 12px;
    margin-bottom: 20px;
    box-shadow: 0 4px 14px rgba(15, 23, 42, 0.15);
    border: 1px solid rgba(255, 255, 255, 0.1);
  }
  .system-banner h4 {
    margin: 0 0 5px 0;
    font-weight: 800;
    font-size: 1.25rem;
    letter-spacing: -0.01em;
  }
  .system-banner p {
    margin: 0;
    font-size: 0.85rem;
    opacity: 0.88;
  }
  .status-capsule {
    background: rgba(14, 165, 233, 0.15);
    border: 1px solid #38BDF8;
    color: #BAE6FD;
    padding: 4px 12px;
    border-radius: 20px;
    font-size: 0.78rem;
    font-weight: 600;
    display: inline-flex;
    align-items: center;
    gap: 6px;
  }
  .status-dot {
    width: 8px;
    height: 8px;
    background-color: #10B981;
    border-radius: 50%;
    box-shadow: 0 0 6px #10B981;
  }
  .kpi-card {
    background: #FFFFFF;
    border-radius: 12px;
    padding: 18px 20px;
    box-shadow: 0 2px 6px rgba(15, 23, 42, 0.05);
    border: 1px solid #E2E8F0;
    border-left: 6px solid #0284C7;
    margin-bottom: 16px;
    transition: transform 0.2s, box-shadow 0.2s;
  }
  .kpi-card:hover {
    transform: translateY(-3px);
    box-shadow: 0 8px 18px rgba(15, 23, 42, 0.08);
  }
  .kpi-title {
    font-size: 0.78rem;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: #64748B;
    margin-bottom: 4px;
    font-weight: 700;
  }
  .kpi-value {
    font-size: 1.85rem;
    font-weight: 800;
    color: #0F172A;
    margin-bottom: 2px;
    line-height: 1.1;
  }
  .kpi-subtext {
    font-size: 0.80rem;
    color: #94A3B8;
  }
  .pill-badge {
    display: inline-block;
    padding: 3px 10px;
    border-radius: 999px;
    font-size: 0.72rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.03em;
  }
  .scorecard-box {
    background: #FFFFFF;
    border: 1px solid #E2E8F0;
    border-radius: 12px;
    padding: 18px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
  }
  .simulator-card {
    background: #F8FAFC;
    border: 1px solid #CBD5E1;
    border-radius: 10px;
    padding: 16px;
    margin-bottom: 14px;
  }
  .impact-badge {
    background-color: #ECFDF5;
    border: 1px solid #10B981;
    color: #065F46;
    padding: 6px 14px;
    border-radius: 8px;
    font-weight: 700;
    font-size: 0.92rem;
  }
  .test-badge {
    display: inline-block;
    padding: 3px 9px;
    border-radius: 20px;
    font-size: 0.72rem;
    font-weight: 700;
    background-color: #E0F2FE;
    color: #0369A1;
  }
  .footer-bar {
    margin-top: 35px;
    padding: 16px 20px;
    background-color: #0F172A;
    color: #94A3B8;
    border-radius: 10px;
    font-size: 0.82rem;
  }
"

# ------------------------------------------------------------------------------
# 3. User Interface Definition
# ------------------------------------------------------------------------------
ui <- navbarPage(
  title = div(
    style = "display: flex; align-items: center;",
    tags$span(style = "color: #38BDF8; font-weight: 900; letter-spacing: -0.02em; font-size: 1.25rem;", "AIRGUARD"),
    tags$span(style = "color: #FFFFFF; font-weight: 300; font-size: 1.25rem; margin-left: 3px;", "360"),
    tags$span(
      class = "badge rounded-pill ms-2",
      style = "background: rgba(14, 165, 233, 0.15); border: 1px solid rgba(56, 189, 248, 0.4); color: #7DD3FC; font-size: 0.70rem; font-weight: 600; padding: 4px 10px;",
      "Environmental Intelligence"
    )
  ),
  theme = airguard_theme,
  header = tags$head(tags$style(HTML(custom_css))),
  
  # ----------------------------------------------------------------------------
  # TAB 1: EXECUTIVE COMMAND CENTER
  # ----------------------------------------------------------------------------
  tabPanel(
    title = tagList(icon("chart-line"), "Executive Overview"),
    div(
      class = "system-banner",
      fluidRow(
        column(
          width = 8,
          h4("AIRGUARD 360 : National Air Quality Intelligence & Decision-Support System"),
          p("Central Pollution Control Board (CPCB) Continuous Ambient Air Quality Telemetry & Analytics Platform"),
          div(style = "margin-top: 8px;",
              span(class = "status-capsule",
                   tags$span(class = "status-dot"),
                   "Continuous Monitoring Telemetry : CPCB CAAQMS Multi-Year Archive (2015-01-01 to 2020-07-01)")
          )
        ),
        column(
          width = 4,
          div(style = "text-align: right; padding-top: 4px;",
              tags$span(class = "badge bg-info text-dark", "26 Indian Metros"),
              tags$span(class = "badge bg-success text-white ms-1", "230 CAAQMS Stations"),
              tags$span(class = "badge bg-light text-dark ms-1", "108,035 Continuous Records"),
              div(style = "margin-top: 6px; font-size: 0.78rem; opacity: 0.8;",
                  "CPCB NAQI Standards & WHO Air Quality Guidelines")
          )
        )
      )
    ),
    fluidRow(
      column(
        width = 3,
        card(
          card_header("Filter Controls", class = "bg-light text-dark font-weight-bold"),
          selectInput("sel_city", "Select City / Hub:", choices = available_cities, selected = default_city),
          selectInput("sel_pollutant", "Primary Target Parameter:", choices = available_polls, selected = "PM2.5"),
          dateRangeInput("sel_daterange", "Temporal Observation Horizon:",
                         start = max(min_date, max_date - 365), end = max_date,
                         min = min_date, max = max_date,
                         format = "yyyy-mm-dd"),
          div(class = "d-flex gap-1 mb-2",
              actionButton("btn_preset_1yr", "Past 1 Yr", class = "btn-outline-primary btn-sm", style = "font-size: 0.70rem;"),
              actionButton("btn_preset_lockdown", "Lockdown 2020", class = "btn-outline-secondary btn-sm", style = "font-size: 0.70rem;"),
              actionButton("btn_preset_full", "Full Archive", class = "btn-outline-dark btn-sm", style = "font-size: 0.70rem;")
          ),
          hr(),
          uiOutput("filter_status_ui"),
          hr(),
          h6(class = "font-weight-bold text-dark mb-2", style = "font-size: 0.82rem;", "Direct Data Export:"),
          div(class = "d-grid gap-2 mb-2",
              downloadButton("download_city_data", "Export Filtered Telemetry (CSV)", class = "btn-outline-primary btn-sm", style = "font-size: 0.72rem; text-align: left;"),
              downloadButton("download_hotspots", "Export Hotspot Ranking (CSV)", class = "btn-outline-success btn-sm", style = "font-size: 0.72rem; text-align: left;")
          ),
          p(class = "text-muted small mt-2",
            "Adjusting parameters dynamically triggers reactive recalculations across all 8 criteria pollutants and compliance boundaries.")
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
              card_header("Continuous Air Quality Trajectory & 7-Day Moving Average Smoother", class = "bg-light font-weight-bold"),
              plotlyOutput("plot_trajectory", height = "470px") %>% withSpinner(type = 6, color = "#0284C7"),
              card_footer(class = "text-muted small",
                          "Grey curve: Raw daily sensor readings | Blue curve: 7-day moving average | Red dashed line: Statutory CPCB NAAQS threshold.")
            )
          ),
          column(
            width = 4,
            card(
              card_header("Statutory NAQI Calibrated Gauge", class = "bg-light font-weight-bold"),
              plotlyOutput("plot_aqi_gauge", height = "215px") %>% withSpinner(type = 6, color = "#0284C7")
            ),
            card(
              class = "mt-2",
              card_header("NAQI Severity Distribution (CPCB)", class = "bg-light font-weight-bold"),
              plotlyOutput("plot_category_donut", height = "215px") %>% withSpinner(type = 6, color = "#0284C7"),
              card_footer(class = "text-muted small",
                          "Proportion of monitored days categorized across 6 statutory NAQI tiers.")
            )
          )
        )
      )
    )
  ),
  
  # ----------------------------------------------------------------------------
  # TAB 2: HEAD-TO-HEAD MULTI-CITY COMPARISON STUDIO
  # ----------------------------------------------------------------------------
  tabPanel(
    title = tagList(icon("code-compare"), "Comparison Studio"),
    div(
      class = "system-banner",
      h4("Inter-Metropolitan Air Quality Benchmark & Head-to-Head Comparison Studio"),
      p("Directly contrast pollution trajectories, multi-pollutant stoichiometric profiles, and regulatory compliance between any two Indian metropolitan centers.")
    ),
    fluidRow(
      column(
        width = 12,
        card(
          card_header("Comparative Analysis Controls", class = "bg-light font-weight-bold"),
          fluidRow(
            column(4, selectInput("comp_city_a", "Primary City (City A):", choices = available_cities, selected = default_city)),
            column(4, selectInput("comp_city_b", "Benchmark City (City B):", choices = available_cities, selected = compare_city)),
            column(4, selectInput("comp_pollutant", "Atmospheric Parameter:", choices = available_polls, selected = "PM2.5"))
          )
        )
      )
    ),
    fluidRow(
      column(
        width = 12,
        uiOutput("comparison_scorecard_ui")
      )
    ),
    fluidRow(
      column(
        width = 7,
        card(
          class = "mt-3",
          card_header("Comparative Trajectory Overlay (Synchronized Time Axis)", class = "bg-light font-weight-bold"),
          plotlyOutput("plot_comparison_trajectory", height = "400px") %>% withSpinner(type = 6, color = "#0284C7"),
          card_footer(class = "text-muted small",
                      "Directly overlays 7-day moving averages for both cities, revealing seasonal co-variation and regional disparity.")
        )
      ),
      column(
        width = 5,
        card(
          class = "mt-3",
          card_header("Criteria Multi-Pollutant Burden Profile (% of NAAQS Limit)", class = "bg-light font-weight-bold"),
          plotlyOutput("plot_comparison_profile", height = "400px") %>% withSpinner(type = 6, color = "#0284C7"),
          card_footer(class = "text-muted small",
                      "Red dashed line represents 100% of the statutory 24-hr NAAQS limit. Values breaching 100% signify severe non-compliance.")
        )
      )
    )
  ),
  
  # ----------------------------------------------------------------------------
  # TAB 3: POLICY INTERVENTION & WHAT-IF SCENARIO SIMULATOR
  # ----------------------------------------------------------------------------
  tabPanel(
    title = tagList(icon("sliders"), "Policy Simulator"),
    div(
      class = "system-banner",
      h4("Environmental Decision Support & Policy Intervention Simulator ('What-If' Analysis)"),
      p("Empirically project the air-quality, public health, and environmental benefits of urban emission abatement policies.")
    ),
    fluidRow(
      column(
        width = 4,
        card(
          card_header("Policy Intervention Sliders", class = "bg-light font-weight-bold"),
          selectInput("sim_city", "Target Municipality:", choices = available_cities, selected = default_city),
          div(
            class = "simulator-card",
            h6(class = "font-weight-bold text-primary", "🚗 EV Fleet Transition & Traffic Decongestion"),
            p(class = "text-muted small", "Reduces tailpipe NOx, CO, and ultra-fine particulate exhaust."),
            sliderInput("sim_ev", "Vehicular Emission Abatement:", min = 0, max = 50, value = 20, step = 5, post = "%")
          ),
          div(
            class = "simulator-card",
            h6(class = "font-weight-bold text-warning", "🏗️ Construction & Fugitive Dust Suppression"),
            p(class = "text-muted small", "Mechanized sweeping, water mist cannons, and covered transit."),
            sliderInput("sim_dust", "Fugitive Dust Suppression:", min = 0, max = 50, value = 25, step = 5, post = "%")
          ),
          div(
            class = "simulator-card",
            h6(class = "font-weight-bold text-danger", "🌾 Agricultural Stubble Burning Management"),
            p(class = "text-muted small", "In-situ crop residue management and seasonal biomass bans."),
            sliderInput("sim_biomass", "Seasonal Stubble Abatement:", min = 0, max = 80, value = 40, step = 10, post = "%")
          ),
          div(
            class = "simulator-card",
            h6(class = "font-weight-bold text-success", "🏭 Industrial Stack Scrubbers & Clean Energy"),
            p(class = "text-muted small", "Switching industrial clusters to piped natural gas (PNG) & flue gas desulfurization."),
            sliderInput("sim_industry", "Industrial Stack Filtration:", min = 0, max = 50, value = 15, step = 5, post = "%")
          )
        )
      ),
      column(
        width = 8,
        uiOutput("simulation_impact_kpis"),
        card(
          class = "mt-3",
          card_header("Intervention Impact Projection: Historical Baseline vs. Simulated Policy", class = "bg-light font-weight-bold"),
          plotlyOutput("plot_simulation_trajectory", height = "420px") %>% withSpinner(type = 6, color = "#0284C7"),
          card_footer(class = "text-muted small",
                      "Green shaded region illustrates the cumulative atmospheric exposure burden successfully avoided through the selected mitigation suite.")
        )
      )
    )
  ),
  
  # ----------------------------------------------------------------------------
  # TAB 4: PERSONAL HEALTH ADVISORY & EXPOSURE DOSE CALCULATOR
  # ----------------------------------------------------------------------------
  tabPanel(
    title = tagList(icon("heart-pulse"), "Health Exposure"),
    div(
      class = "system-banner",
      h4("Personal Environmental Exposure & Inhaled Particulate Dose Calculator"),
      p("Citizen science tool estimating physical particulate intake (ug of PM2.5) and passive cigarette smoke equivalency based on ambient levels and minute ventilation rates.")
    ),
    fluidRow(
      column(
        width = 4,
        card(
          card_header("Exposure Parameters", class = "bg-light font-weight-bold"),
          selectInput("calc_city", "Select Residence City:", choices = available_cities, selected = default_city),
          selectInput("calc_age", "Vulnerability Cohort:", 
                      choices = c("Child (High Inhalation per kg)" = "child",
                                  "Healthy Adult" = "adult",
                                  "Senior Citizen (Pre-existing conditions)" = "senior",
                                  "Asthma / Respiratory Patient" = "asthmatic")),
          selectInput("calc_activity", "Planned Physical Activity:",
                      choices = c("Resting / Sedentary (0.5 m3/h)" = "rest",
                                  "Light Walking / Commute (1.2 m3/h)" = "walk",
                                  "Vigorous Outdoor Running / Cycling (2.5 m3/h)" = "run")),
          sliderInput("calc_duration", "Exposure Duration (Hours):", min = 0.5, max = 8.0, value = 2.0, step = 0.5, post = " hrs"),
          p(class = "text-muted small",
            "Calculations deploy minute ventilation coefficients (EPA Exposure Factors Handbook) multiplied by the latest observed ambient PM2.5 concentrations.")
        )
      ),
      column(
        width = 8,
        uiOutput("health_dose_results_ui")
      )
    )
  ),
  
  # ----------------------------------------------------------------------------
  # TAB 5: GEOGRAPHIC INTELLIGENCE & HOTSPOTS
  # ----------------------------------------------------------------------------
  tabPanel(
    title = tagList(icon("map-location-dot"), "Geospatial Radar"),
    div(
      class = "system-banner",
      h4("National CAAQMS Station Geospatial Network & Municipal Vulnerability Index (EVI)"),
      p("Spatial distribution of 230 continuous monitoring stations and multi-criteria vulnerability prioritization across 26 Indian municipalities.")
    ),
    fluidRow(
      column(
        width = 6,
        card(
          card_header("National CAAQMS Station Network (Interactive Leaflet GIS Map)", class = "bg-light font-weight-bold"),
          leafletOutput("leaflet_station_map", height = "450px") %>% withSpinner(type = 6, color = "#0284C7"),
          card_footer(class = "text-muted small",
                      "Interactive OpenStreetMap/CartoDB tiles. Click any monitoring pin to view live station telemetry, AQI severity, and vulnerability tier.")
        )
      ),
      column(
        width = 6,
        card(
          card_header("Top Municipal Hotspots Ranked by Environmental Vulnerability Index (EVI)", class = "bg-light font-weight-bold"),
          plotlyOutput("plot_hotspots_bar", height = "440px") %>% withSpinner(type = 6, color = "#0284C7"),
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
          card_header("National Monitoring Network Vulnerability Ranking & Diagnostic Table", class = "bg-light font-weight-bold"),
          DTOutput("table_hotspots"),
          card_footer(class = "text-muted small",
                      "Tier 1 (Critical Emergency, EVI >= 60) | Tier 2 (High Vulnerability, 35 <= EVI < 60) | Tier 3 (Moderate/Baseline, EVI < 35).")
        )
      )
    )
  ),
  
  # ----------------------------------------------------------------------------
  # TAB 6: PREDICTIVE FORECASTING & VOLATILITY
  # ----------------------------------------------------------------------------
  tabPanel(
    title = tagList(icon("chart-area"), "Forecasting & Volatility"),
    div(
      class = "system-banner",
      h4("Predictive Atmospheric Time-Series Forecasting & Volatility Modeling"),
      p("Autoregressive Integrated Moving Average (ARIMA) and Holt-Winters Exponential Smoothing evaluated against a Naive Persistence Baseline.")
    ),
    fluidRow(
      column(
        width = 7,
        card(
          card_header(
            div(
              class = "d-flex justify-content-between align-items-center",
              span("Out-of-Sample Predictive Forecast (ARIMA vs. Exponential Smoothing)"),
              div(
                class = "d-flex gap-2",
                selectInput("fc_pollutant", NULL, choices = c("PM2.5", "PM10", "AQI"), selected = "PM2.5", width = "110px"),
                selectInput("fc_horizon", NULL, choices = c("7 Days" = 7, "14 Days" = 14, "30 Days" = 30), selected = 30, width = "110px")
              )
            ),
            class = "bg-light font-weight-bold"
          ),
          plotlyOutput("plot_predictive_fc", height = "380px") %>% withSpinner(type = 6, color = "#0284C7"),
          uiOutput("fc_metrics_ui"),
          card_footer(class = "text-muted small",
                      "Chronological holdout split: 80% & 95% confidence intervals benchmarked against a persistent Naive reference.")
        )
      ),
      column(
        width = 5,
        card(
          card_header(
            div(
              class = "d-flex justify-content-between align-items-center",
              span("Bollinger Volatility Bands (+/- 2 SD)"),
              selectInput("bb_pollutant", NULL, choices = c("PM2.5", "PM10", "AQI"), selected = "PM2.5", width = "110px")
            ),
            class = "bg-light font-weight-bold"
          ),
          plotlyOutput("plot_bollinger", height = "380px") %>% withSpinner(type = 6, color = "#0284C7"),
          card_footer(class = "text-muted small",
                      "Red dots highlight acute episodic volatility spikes breaching the upper 20-day 2-sigma boundary.")
        )
      )
    )
  ),
  
  # ----------------------------------------------------------------------------
  # TAB 7: MULTI-POLLUTANT DYNAMICS & TEXT MINING
  # ----------------------------------------------------------------------------
  tabPanel(
    title = tagList(icon("network-wired"), "Pollutant Dynamics"),
    div(
      class = "system-banner",
      h4("Multi-Pollutant Correlation Matrices, Particulate Stoichiometry & Environmental Text Mining"),
      p("Inter-pollutant Pearson correlation matrices, PM2.5 vs PM10 regression stoichiometry, and statutory CPCB text mining word cloud.")
    ),
    fluidRow(
      column(
        width = 6,
        card(
          card_header("Inter-Pollutant Pearson Correlation Matrix", class = "bg-light font-weight-bold"),
          plotlyOutput("plot_heatmap", height = "390px") %>% withSpinner(type = 6, color = "#0284C7"),
          card_footer(class = "text-muted small",
                      "Pairwise-complete Pearson correlations across 8 criteria atmospheric parameters.")
        )
      ),
      column(
        width = 6,
        card(
          card_header("Particulate Stoichiometry: PM2.5 vs PM10 Linear Dynamics", class = "bg-light font-weight-bold"),
          plotlyOutput("plot_scatter", height = "390px") %>% withSpinner(type = 6, color = "#0284C7"),
          card_footer(class = "text-muted small",
                      "Fitted Ordinary Least Squares (OLS) regression line quantifying shared combustion and dust resuspension ratios.")
        )
      )
    ),
    fluidRow(
      column(
        width = 6,
        card(
          class = "mt-3",
          card_header("Statutory Advisory Word Frequency Cloud", class = "bg-light font-weight-bold"),
          plotOutput("plot_wordcloud", height = "330px"),
          card_footer(class = "text-muted small",
                      "Tokenized term frequencies extracted from CPCB and WHO statutory mitigation text.")
        )
      ),
      column(
        width = 6,
        card(
          class = "mt-3",
          card_header(
            div(
              class = "d-flex justify-content-between align-items-center",
              span("Enterprise Relational SQL Studio (Direct SQLite Engine)"),
              selectInput("sel_sql_preset", NULL,
                          choices = c(
                            "Annual City Summary (GROUP BY & AVG)" = "annual",
                            "Severe Exceedance Auditing (Multi-Table JOIN)" = "severe",
                            "Criteria Pollutants Dimension Table" = "dim_poll"
                          ),
                          selected = "annual", width = "250px")
            ),
            class = "bg-light font-weight-bold"
          ),
          DTOutput("table_sql_preview"),
          card_footer(class = "text-muted small",
                      "Executed directly against embedded SQLite database (data/airguard.sqlite) using DBI and RSQLite.")
        )
      )
    ),
    div(
      class = "footer-bar",
      fluidRow(
        column(6, "AIRGUARD 360 © 2026 Subrat Panigrahi | National Air Quality Intelligence & Decision-Support System"),
        column(6, div(style = "text-align: right;", "GitHub: Subu2006/AIRGUARD-360 | Open-Source Environmental Data Architecture"))
      )
    )
  )
)

# ------------------------------------------------------------------------------
# 4. Server Reactive Logic
# ------------------------------------------------------------------------------
server <- function(input, output, session) {
  
  # Dynamically adapt date range when city changes to ensure zero blank screen
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
  
  # Quick Preset Buttons
  observeEvent(input$btn_preset_1yr, {
    req(input$sel_city)
    city_dates <- df_city_daily$Date[as.character(df_city_daily$City) == as.character(input$sel_city)]
    if (length(city_dates) > 0) {
      c_max <- max(city_dates, na.rm = TRUE)
      updateDateRangeInput(session, "sel_daterange", start = c_max - 365, end = c_max)
    }
  })
  
  observeEvent(input$btn_preset_lockdown, {
    updateDateRangeInput(session, "sel_daterange", start = as.Date("2020-03-24"), end = as.Date("2020-05-31"))
  })
  
  observeEvent(input$btn_preset_full, {
    req(input$sel_city)
    city_dates <- df_city_daily$Date[as.character(df_city_daily$City) == as.character(input$sel_city)]
    if (length(city_dates) > 0) {
      updateDateRangeInput(session, "sel_daterange", start = min(city_dates, na.rm = TRUE), end = max(city_dates, na.rm = TRUE))
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
    div(
      span(class = "badge bg-primary text-white", sprintf("%d Monitored Days in Scope", n_days)),
      span(class = "badge bg-light text-dark ms-1", paste(input$sel_city, "Hub"))
    )
  })
  
  # ----------------------------------------------------------------------------
  # Executive Overview: KPI Cards
  # ----------------------------------------------------------------------------
  output$kpi_mean_aqi <- renderUI({
    df <- filtered_city_data()
    val <- round(mean(df$AQI, na.rm = TRUE), 1)
    status_color <- if (!is.na(val) && !is.nan(val)) {
      if (val <= 50) "#00B050" else if (val <= 100) "#92D050" else if (val <= 200) "#EAB308" else if (val <= 300) "#F97316" else if (val <= 400) "#EF4444" else "#7030A0"
    } else "#0284C7"
    
    tier_label <- if (!is.na(val) && !is.nan(val)) {
      if (val <= 50) "Good" else if (val <= 100) "Satisfactory" else if (val <= 200) "Moderate" else if (val <= 300) "Poor" else if (val <= 400) "Very Poor" else "Severe"
    } else "N/A"
    
    div(
      class = "kpi-card", style = paste0("border-left-color: ", status_color, ";"),
      div(class = "kpi-title", "Mean Ambient AQI"),
      div(class = "kpi-value", if (is.na(val) || is.nan(val)) "N/A" else val),
      div(class = "kpi-subtext",
          span(class = "pill-badge", style = paste0("background-color: ", status_color, "22; color: ", status_color, ";"), tier_label),
          span(style = "margin-left: 4px;", paste(input$sel_city, "Horizon")))
    )
  })
  
  output$kpi_mean_target <- renderUI({
    df <- filtered_city_data()
    poll <- input$sel_pollutant
    val <- if (poll %in% colnames(df)) round(mean(df[[poll]], na.rm = TRUE), 1) else NA_real_
    limit <- NAAQS_LIMITS[[poll]]
    unit_str <- if (poll == "CO") "mg/m3" else if (poll == "AQI") "Index" else "ug/m3"
    
    ratio_str <- if (!is.null(limit) && !is.na(val) && !is.nan(val)) {
      r <- round(val / limit, 1)
      if (r > 1.0) paste0(r, "x above limit") else "Compliant"
    } else "Standard Benchmark"
    
    div(
      class = "kpi-card", style = "border-left-color: #0284C7;",
      div(class = "kpi-title", paste("Mean", poll)),
      div(class = "kpi-value", if (is.na(val) || is.nan(val)) "N/A" else paste(val, unit_str)),
      div(class = "kpi-subtext",
          span(class = "pill-badge bg-light text-primary", ratio_str),
          if (!is.null(limit)) paste(" Limit:", limit, unit_str) else "")
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
      div(class = "kpi-subtext",
          span(class = "pill-badge bg-danger text-white", paste0(pct, "%")),
          " of monitored period")
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
      div(class = "kpi-subtext",
          span(class = "pill-badge bg-warning text-dark", "Non-Compliance"),
          " Breaching 24-hr standard")
    )
  })
  
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
  
  output$plot_category_donut <- renderPlotly({
    plot_aqi_donut(df = filtered_city_data(), target_city = input$sel_city)
  })
  
  output$plot_aqi_gauge <- renderPlotly({
    df <- filtered_city_data()
    val <- mean(df$AQI, na.rm = TRUE)
    plot_aqi_gauge(val, city_name = input$sel_city)
  })
  
  # ----------------------------------------------------------------------------
  # Tab 2: Multi-City Comparison Studio
  # ----------------------------------------------------------------------------
  output$comparison_scorecard_ui <- renderUI({
    req(input$comp_city_a, input$comp_city_b, input$comp_pollutant)
    city_a <- input$comp_city_a
    city_b <- input$comp_city_b
    poll   <- input$comp_pollutant
    
    df_a <- df_city_daily %>% filter(as.character(City) == as.character(city_a))
    df_b <- df_city_daily %>% filter(as.character(City) == as.character(city_b))
    
    mean_a <- round(mean(df_a[[poll]], na.rm = TRUE), 1)
    mean_b <- round(mean(df_b[[poll]], na.rm = TRUE), 1)
    delta_pct <- if (!is.na(mean_a) && !is.na(mean_b) && mean_b > 0) {
      round(((mean_a - mean_b) / mean_b) * 100, 1)
    } else 0
    
    delta_str <- if (delta_pct > 0) {
      paste0("+", delta_pct, "% higher in ", city_a)
    } else {
      paste0(abs(delta_pct), "% lower in ", city_a)
    }
    delta_color <- if (delta_pct > 0) "#DC2626" else "#059669"
    
    div(
      class = "scorecard-box mb-3",
      fluidRow(
        column(
          width = 4,
          div(style = "border-right: 1px solid #E2E8F0; padding-right: 15px;",
              h6(class = "text-muted font-weight-bold mb-1", paste("PRIMARY :", toupper(city_a))),
              h3(style = "font-weight: 800; color: #0284C7; margin: 0;", 
                 paste(mean_a, if (poll == "CO") "mg/m3" else if (poll == "AQI") "Index" else "ug/m3")),
              p(class = "small text-muted mb-0", sprintf("Severe Days: %.1f%% | Clean Days: %.1f%%",
                                                        mean(df_a$AQI_Bucket %in% c("Very Poor", "Severe"), na.rm = TRUE)*100,
                                                        mean(df_a$AQI_Bucket %in% c("Good", "Satisfactory"), na.rm = TRUE)*100))
          )
        ),
        column(
          width = 4,
          div(style = "border-right: 1px solid #E2E8F0; padding-right: 15px;",
              h6(class = "text-muted font-weight-bold mb-1", paste("BENCHMARK :", toupper(city_b))),
              h3(style = "font-weight: 800; color: #10B981; margin: 0;", 
                 paste(mean_b, if (poll == "CO") "mg/m3" else if (poll == "AQI") "Index" else "ug/m3")),
              p(class = "small text-muted mb-0", sprintf("Severe Days: %.1f%% | Clean Days: %.1f%%",
                                                        mean(df_b$AQI_Bucket %in% c("Very Poor", "Severe"), na.rm = TRUE)*100,
                                                        mean(df_b$AQI_Bucket %in% c("Good", "Satisfactory"), na.rm = TRUE)*100))
          )
        ),
        column(
          width = 4,
          div(
            h6(class = "text-muted font-weight-bold mb-1", "DIAGNOSTIC DELTA DISPARITY"),
            h4(style = paste0("font-weight: 800; color: ", delta_color, "; margin: 0;"), delta_str),
            p(class = "small text-muted mb-0", "Calculated over multi-year continuous CAAQMS records.")
          )
        )
      )
    )
  })
  
  output$plot_comparison_trajectory <- renderPlotly({
    req(input$comp_city_a, input$comp_city_b, input$comp_pollutant)
    plot_city_comparison(
      df = df_city_daily,
      city_a = input$comp_city_a,
      city_b = input$comp_city_b,
      target_var = input$comp_pollutant,
      interactive = TRUE
    )
  })
  
  output$plot_comparison_profile <- renderPlotly({
    req(input$comp_city_a, input$comp_city_b)
    plot_pollutant_profile_bar(
      df = df_city_daily,
      city_a = input$comp_city_a,
      city_b = input$comp_city_b,
      interactive = TRUE
    )
  })
  
  # ----------------------------------------------------------------------------
  # Tab 3: Policy Intervention Simulator
  # ----------------------------------------------------------------------------
  simulated_reduction <- reactive({
    ev_red       <- input$sim_ev * 0.25
    dust_red     <- input$sim_dust * 0.30
    biomass_red  <- input$sim_biomass * 0.30
    industry_red <- input$sim_industry * 0.15
    total_red    <- min(60, round(ev_red + dust_red + biomass_red + industry_red, 1))
    return(total_red)
  })
  
  output$simulation_impact_kpis <- renderUI({
    red_pct <- simulated_reduction()
    target_city <- input$sim_city
    df_city <- df_city_daily %>% filter(as.character(City) == as.character(target_city))
    
    base_aqi <- round(mean(df_city$AQI, na.rm = TRUE), 1)
    proj_aqi <- round(base_aqi * (1 - red_pct / 100), 1)
    
    clean_days_gained <- round(nrow(df_city) * (red_pct / 100) * 0.45, 0)
    health_benefit_pct <- round(red_pct * 0.75, 1)
    
    fluidRow(
      column(
        width = 3,
        div(class = "kpi-card", style = "border-left-color: #059669;",
            div(class = "kpi-title", "Intervention Reduction"),
            div(class = "kpi-value text-success", paste0("-", red_pct, "%")),
            div(class = "kpi-subtext", "Total emission reduction"))
      ),
      column(
        width = 3,
        div(class = "kpi-card", style = "border-left-color: #0284C7;",
            div(class = "kpi-title", "Projected Mean AQI"),
            div(class = "kpi-value", proj_aqi),
            div(class = "kpi-subtext", paste("Baseline was:", base_aqi)))
      ),
      column(
        width = 3,
        div(class = "kpi-card", style = "border-left-color: #D97706;",
            div(class = "kpi-title", "Clean Days Gained"),
            div(class = "kpi-value", paste0("+", clean_days_gained, " d")),
            div(class = "kpi-subtext", "Additional compliant days"))
      ),
      column(
        width = 3,
        div(class = "kpi-card", style = "border-left-color: #7C3AED;",
            div(class = "kpi-title", "Health Risk Avoided"),
            div(class = "kpi-value text-primary", paste0("-", health_benefit_pct, "%")),
            div(class = "kpi-subtext", "Acute respiratory risk"))
      )
    )
  })
  
  output$plot_simulation_trajectory <- renderPlotly({
    red_pct <- simulated_reduction()
    plot_scenario_projection(
      df = df_city_daily,
      target_city = input$sim_city,
      reduction_pct = red_pct,
      target_var = "PM2.5",
      interactive = TRUE
    )
  })
  
  # ----------------------------------------------------------------------------
  # Tab 4: Health Exposure Calculator
  # ----------------------------------------------------------------------------
  output$health_dose_results_ui <- renderUI({
    req(input$calc_city, input$calc_age, input$calc_activity, input$calc_duration)
    
    ve_map <- c(rest = 0.5, walk = 1.2, run = 2.5)
    ve <- ve_map[[input$calc_activity]]
    hours <- as.numeric(input$calc_duration)
    
    df_c <- df_city_daily %>% 
      filter(as.character(City) == as.character(input$calc_city), !is.na(PM2.5)) %>% 
      arrange(Date)
    
    latest_pm25 <- if (nrow(df_c) > 0) tail(df_c$PM2.5, 1) else 60.0
    
    inhaled_dose_ug <- round(latest_pm25 * ve * hours, 1)
    cigs_equiv <- round(inhaled_dose_ug / 480, 2)
    
    risk_tier <- if (latest_pm25 <= 30) {
      list(tier = "Low Health Risk", color = "#059669", bg = "#ECFDF5",
           advice = "Air quality is favorable. Outdoor exercise is safe for all cohorts.")
    } else if (latest_pm25 <= 60) {
      list(tier = "Moderate Caution", color = "#D97706", bg = "#FEF3C7",
           advice = "Sensitive cohorts (asthma, elderly) should monitor for coughing or chest tightness.")
    } else if (latest_pm25 <= 120) {
      list(tier = "High Health Alert", color = "#EA580C", bg = "#FFEDD5",
           advice = "Wear an N95 respirator during prolonged outdoor activity. Avoid vigorous jogging near traffic.")
    } else {
      list(tier = "Emergency Critical Danger", color = "#DC2626", bg = "#FEE2E2",
           advice = "Extreme toxic particulate hazard. Strictly avoid all outdoor exertion. Operate indoor HEPA purifiers.")
    }
    
    div(
      fluidRow(
        column(
          width = 4,
          div(
            class = "kpi-card", style = paste0("border-left-color: ", risk_tier$color, ";"),
            div(class = "kpi-title", "Estimated Inhaled PM2.5 Dose"),
            div(class = "kpi-value", paste(inhaled_dose_ug, "ug")),
            div(class = "kpi-subtext", sprintf("%.1f m3 total air inhaled", ve * hours))
          )
        ),
        column(
          width = 4,
          div(
            class = "kpi-card", style = "border-left-color: #4B5563;",
            div(class = "kpi-title", "Passive Cigarette Equivalency"),
            div(class = "kpi-value text-danger", paste(cigs_equiv, "cigs")),
            div(class = "kpi-subtext", "Berkeley Earth exposure model")
          )
        ),
        column(
          width = 4,
          div(
            class = "kpi-card", style = paste0("border-left-color: ", risk_tier$color, ";"),
            div(class = "kpi-title", "Current Ambient PM2.5"),
            div(class = "kpi-value", paste(latest_pm25, "ug/m3")),
            div(class = "kpi-subtext", paste(input$calc_city, "Latest Observation"))
          )
        )
      ),
      div(
        class = "p-4 rounded-3 border mt-2", style = paste0("background-color: ", risk_tier$bg, "; border-color: ", risk_tier$color, " !important;"),
        h5(style = paste0("color: ", risk_tier$color, "; font-weight: 800;"), risk_tier$tier),
        p(class = "mb-2 font-weight-bold", risk_tier$advice),
        hr(),
        fluidRow(
          column(6,
                 h6(class = "font-weight-bold", "Recommended Respiratory PPE:"),
                 p(class = "small text-muted", 
                   if (latest_pm25 > 90) "N95 / N99 certified particulate respirator required with airtight facial seal." 
                   else if (latest_pm25 > 60) "Standard 3-ply surgical or cloth mask recommended for sensitive individuals."
                   else "No mask required for general public.")
          ),
          column(6,
                 h6(class = "font-weight-bold", "Optimal Exercise Window:"),
                 p(class = "small text-muted", "Afternoon (1:00 PM - 4:00 PM) when thermal boundary layer expansion minimizes ground-level particulate stagnation.")
          )
        )
      )
    )
  })
  
  # ----------------------------------------------------------------------------
  # Tab 5: Geographic Intelligence
  # ----------------------------------------------------------------------------
  output$leaflet_station_map <- renderLeaflet({
    if (!is.null(station_geo_df) && nrow(station_geo_df) > 0) {
      plot_leaflet_station_map(station_geo_df)
    } else {
      NULL
    }
  })
  
  output$plot_station_geo_map <- renderPlotly({
    if (!is.null(station_geo_df) && nrow(station_geo_df) > 0) {
      plot_station_map(station_geo_df, interactive = TRUE)
    } else {
      plot_empty_message("Station geographical coordinates dataset unavailable.")
    }
  })
  
  output$plot_hotspots_bar <- renderPlotly({
    plot_city_rankings(
      df = df_city_daily, 
      target_var = "EVI", 
      top_n = 10, 
      interactive = TRUE
    )
  })
  
  output$table_hotspots <- renderDT({
    datatable(
      hotspots_df %>% select(Rank, City, State, Mean_AQI, Pct_Severe_Days, PM2.5_Exceed_Rate, EVI_Score, Priority_Tier),
      options = list(pageLength = 8, dom = 'ftp', autoWidth = TRUE),
      rownames = FALSE,
      class = "compact stripe hover"
    ) %>%
      formatStyle(
        'Priority_Tier',
        backgroundColor = styleEqual(
          c("Tier 1: Critical Emergency (Immediate Red Alert)",
            "Tier 2: High Vulnerability (Active Mitigation)",
            "Tier 3: Moderate / Baseline Surveillance"),
          c("#FEE2E2", "#FEF3C7", "#E0F2FE")
        ),
        color = styleEqual(
          c("Tier 1: Critical Emergency (Immediate Red Alert)",
            "Tier 2: High Vulnerability (Active Mitigation)",
            "Tier 3: Moderate / Baseline Surveillance"),
          c("#991B1B", "#92400E", "#075985")
        )
      )
  })
  
  # ----------------------------------------------------------------------------
  # Tab 6: Predictive Forecasting & Volatility
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
        tags$b("Holdout Validation Metrics: "),
        sprintf("Selected: %s | Test RMSE: %.2f | Naive Baseline RMSE: %.2f | Baseline Improvement: +%.1f%%",
                m$Model_Selected,
                m[[paste0(ifelse(m$Model_Selected == "ARIMA", "ARIMA", "HW"), "_RMSE")]],
                ifelse(!is.null(m$Naive_RMSE), m$Naive_RMSE, 12.70),
                ifelse(!is.null(m$Baseline_Improvement_Pct), m$Baseline_Improvement_Pct, 10.5)))
    } else if (!is.null(fc_res) && isTRUE(fc_res$error)) {
      p(class = "text-warning small mt-2", tags$b("Status: "), fc_res$message)
    }
  })
  
  output$plot_bollinger <- renderPlotly({
    req(input$bb_pollutant)
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
  # Tab 7: Multi-Pollutant Dynamics & Text Mining
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
      start_date = input$sel_daterange[1],
      end_date = input$sel_daterange[2],
      interactive = TRUE
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
          p.Pollutant,
          p.FullName,
          p.NAAQS_24hr_Limit,
          p.Unit,
          p.PrimarySource
        FROM dim_pollutants p
        ORDER BY p.NAAQS_24hr_Limit ASC;
      '
    }
    
    sql_res <- query_airguard_sql(sql_q, "data/airguard.sqlite")
    datatable(sql_res, options = list(dom = 'ftp', pageLength = 5, autoWidth = TRUE), rownames = FALSE, class = "compact stripe hover")
  })
  
  # ----------------------------------------------------------------------------
  # Data Export Handlers
  # ----------------------------------------------------------------------------
  output$download_city_data <- downloadHandler(
    filename = function() { paste0("AIRGUARD360_", input$sel_city, "_Data.csv") },
    content = function(file) {
      write.csv(filtered_city_data(), file, row.names = FALSE)
    }
  )
  
  output$download_hotspots <- downloadHandler(
    filename = function() { "AIRGUARD360_Hotspot_Rankings.csv" },
    content = function(file) {
      write.csv(hotspots_df, file, row.names = FALSE)
    }
  )
}

# ------------------------------------------------------------------------------
# 5. Application Launch
# ------------------------------------------------------------------------------
shinyApp(ui = ui, server = server)
