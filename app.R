# ==============================================================================
# AIRGUARD 360: Interactive Air Quality, Pollution Intelligence & Decision-Support System
# File: app.R
# Technology: 100% Native R (Shiny + bslib + ggplot2 + plotly + DT + RSQLite)
# Course: INT232 Data Science Toolbox : R Programming
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
  primary = "#1F77B4",
  secondary = "#10B981",
  success = "#059669",
  warning = "#F59E0B",
  danger = "#EF4444",
  base_font = font_google("Inter"),
  heading_font = font_google("Inter")
)

# Custom CSS for polished cards and aesthetic metrics
custom_css <- "
  .navbar { box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); font-weight: 600; }
  .kpi-card {
    background: #FFFFFF;
    border-radius: 10px;
    padding: 16px 20px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.05);
    border-left: 5px solid #1F77B4;
    margin-bottom: 15px;
    transition: transform 0.2s;
  }
  .kpi-card:hover { transform: translateY(-2px); box-shadow: 0 4px 10px rgba(0,0,0,0.1); }
  .kpi-title { font-size: 0.82rem; text-transform: uppercase; letter-spacing: 0.05em; color: #64748B; margin-bottom: 4px; font-weight: 700; }
  .kpi-value { font-size: 1.7rem; font-weight: 800; color: #0F172A; margin-bottom: 2px; }
  .kpi-subtext { font-size: 0.78rem; color: #94A3B8; }
  .advisory-box {
    border-radius: 8px;
    padding: 18px;
    color: #FFFFFF;
    font-weight: 500;
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
    padding: 3px 8px;
    border-radius: 12px;
    font-size: 0.75rem;
    font-weight: 600;
  }
"

# ------------------------------------------------------------------------------
# 3. User Interface Definition
# ------------------------------------------------------------------------------
ui <- navbarPage(
  title = div(
    tags$span(style = "color: #38BDF8; font-weight: 900; margin-right: 5px;", "AIRGUARD"),
    tags$span(style = "color: #FFFFFF; font-weight: 300;", "360")
  ),
  theme = airguard_theme,
  header = tags$head(tags$style(HTML(custom_css))),
  
  # ----------------------------------------------------------------------------
  # TAB 1: EXECUTIVE OVERVIEW
  # ----------------------------------------------------------------------------
  tabPanel(
    "Executive Overview",
    fluidRow(
      column(
        width = 3,
        card(
          card_header("Filter Controls", class = "bg-light text-dark font-weight-bold"),
          selectInput("sel_city", "Select City / Hub:", choices = available_cities, selected = default_city),
          selectInput("sel_pollutant", "Primary Target Parameter:", 
                      choices = available_polls, selected = "PM2.5"),
          dateRangeInput("sel_daterange", "Temporal Range:",
                         start = max_date - 365, end = max_date,
                         min = min_date, max = max_date),
          uiOutput("filter_status_ui"),
          hr(),
          p(class = "text-muted small",
            "AIRGUARD 360 connects directly to 108,000+ statutory CPCB monitoring records. Adjust filters to dynamically inspect multi-station aggregations.")
        )
      ),
      column(
        width = 9,
        fluidRow(
          column(3, uiOutput("kpi_mean_aqi")),
          column(3, uiOutput("kpi_mean_target")),
          column(3, uiOutput("kpi_severe_days")),
          column(3, uiOutput("kpi_exceed_rate"))
        ),
        fluidRow(
          column(
            width = 8,
            card(
              card_header("Continuous Air Quality Trajectory & Regulatory Baseline"),
              plotlyOutput("plot_trajectory", height = "390px")
            )
          ),
          column(
            width = 4,
            card(
              card_header("Severity Category Breakdown (CPCB)"),
              plotlyOutput("plot_category_donut", height = "390px")
            )
          )
        )
      )
    )
  ),
  
  # ----------------------------------------------------------------------------
  # TAB 2: GEOGRAPHIC & HOTSPOT INTELLIGENCE
  # ----------------------------------------------------------------------------
  tabPanel(
    "Geographic Intelligence",
    fluidRow(
      column(
        width = 12,
        card(
          card_header("National CAAQMS Monitoring Station Network & Geographic Coordinates"),
          plotlyOutput("plot_station_geo_map", height = "420px"),
          p(class = "text-muted small mt-1",
            "Continuous Ambient Air Quality Monitoring Stations across India with statutory geographical coordinates. Marker size & color scale represent observed station pollution intensity.")
        )
      )
    ),
    fluidRow(
      column(
        width = 5,
        card(
          card_header("National Air Quality Rankings & Hotspots"),
          div(
            class = "d-flex gap-2 mb-2",
            selectInput("hotspot_metric", "Rank By:", 
                        choices = c("Environmental Vulnerability Index (EVI)" = "EVI",
                                    "Mean AQI" = "AQI",
                                    "Mean PM2.5" = "PM2.5",
                                    "Mean PM10" = "PM10"),
                        selected = "EVI", width = "65%"),
            sliderInput("hotspot_topn", "Top Cities:", min = 5, max = 25, value = 10, step = 5, width = "35%")
          ),
          plotlyOutput("plot_hotspots_bar", height = "450px"),
          p(class = "text-muted small mt-2",
            "EVI is an objective weighted multi-criteria index: 40% Mean AQI, 40% % Severe Days, and 20% NAAQS Exceedance Rate.")
        )
      ),
      column(
        width = 7,
        card(
          card_header("National Monitoring Network Vulnerability Ranking"),
          DTOutput("table_hotspots")
        )
      )
    )
  ),
  
  # ----------------------------------------------------------------------------
  # TAB 3: MULTI-POLLUTANT DYNAMICS
  # ----------------------------------------------------------------------------
  tabPanel(
    "Pollutant Dynamics",
    fluidRow(
      column(
        width = 6,
        card(
          card_header("Multi-Pollutant Pearson Correlation Heatmap (Collinearity Matrix)"),
          plotlyOutput("plot_heatmap", height = "440px"),
          p(class = "text-muted small mt-1",
            "Values quantify stoichiometric co-occurrence. High correlation between PM2.5 and PM10 reflects shared vehicular and dust resuspension origins.")
        )
      ),
      column(
        width = 6,
        card(
          card_header("Multi-Pollutant Stoichiometry & Regression Analysis"),
          div(
            class = "d-flex gap-2 mb-2",
            selectInput("scatter_x", "X Parameter:", choices = available_polls, selected = "PM10", width = "50%"),
            selectInput("scatter_y", "Y Parameter:", choices = available_polls, selected = "PM2.5", width = "50%")
          ),
          plotlyOutput("plot_scatter", height = "390px"),
          p(class = "text-muted small mt-1",
            "Fitted ordinary least squares regression illustrates seasonal particulate clustering and chemical transport ratios.")
        )
      )
    )
  ),
  
  # ----------------------------------------------------------------------------
  # TAB 4: TEMPORAL & VOLATILITY ANALYSIS
  # ----------------------------------------------------------------------------
  tabPanel(
    "Volatility & Bollinger Bands",
    fluidRow(
      column(
        width = 12,
        card(
          card_header(
            div(
              class = "d-flex justify-content-between align-items-center",
              span("Bollinger Volatility Bands on Air Quality (INT232 Unit VI Syllabus Feature)", class = "font-weight-bold"),
              div(
                style = "width: 200px;",
                selectInput("bollinger_pollutant", NULL, 
                            choices = c("PM2.5" = "PM2.5", "PM10" = "PM10", "AQI" = "AQI"), 
                            selected = "PM2.5", width = "100%")
              )
            )
          ),
          plotlyOutput("plot_bollinger", height = "440px"),
          p(class = "text-muted small mt-2",
            "Bollinger Volatility Bands deploy a 20-day moving average with +/- 2 standard deviation envelopes. Red highlighted points flag severe environmental anomalies where pollutant surges breach statistical volatility boundaries.")
        )
      )
    )
  ),
  
  # ----------------------------------------------------------------------------
  # TAB 5: STATISTICAL & PREDICTIVE INTELLIGENCE
  # ----------------------------------------------------------------------------
  tabPanel(
    "Statistical & Predictive Models",
    fluidRow(
      column(
        width = 6,
        card(
          card_header("Hypothesis Testing Suite (CO6: Formal Statistical Tests)"),
          div(
            class = "p-2",
            h6(class = "font-weight-bold text-primary", hypo_tests$seasonal_ttest$test_name),
            p(sprintf("Welch t = %.3f | df = %.1f | p-value < 0.0001", 
                      hypo_tests$seasonal_ttest$statistic, hypo_tests$seasonal_ttest$df)),
            p(class = "text-success font-italic small", hypo_tests$seasonal_ttest$conclusion),
            hr(),
            h6(class = "font-weight-bold text-primary", hypo_tests$metro_anova$test_name),
            p(sprintf("Fisher F = %.2f | df = (%d, %d) | p-value < 0.0001",
                      hypo_tests$metro_anova$F_statistic, hypo_tests$metro_anova$df_between, hypo_tests$metro_anova$df_within)),
            p(class = "text-success font-italic small", hypo_tests$metro_anova$conclusion),
            hr(),
            h6(class = "font-weight-bold text-primary", hypo_tests$pm_correlation$test_name),
            p(sprintf("Pearson r = %.3f | t = %.1f | 95%% CI: [%.3f, %.3f]",
                      hypo_tests$pm_correlation$estimate_r, hypo_tests$pm_correlation$t_statistic,
                      hypo_tests$pm_correlation$conf_int_95[1], hypo_tests$pm_correlation$conf_int_95[2])),
            p(class = "text-success font-italic small", hypo_tests$pm_correlation$conclusion),
            hr(),
            h6(class = "font-weight-bold text-primary", hypo_tests$normality_test$test_name),
            p(sprintf("Kolmogorov-Smirnov D = %.4f | p-value < 0.0001",
                      hypo_tests$normality_test$D_statistic)),
            p(class = "text-success font-italic small", hypo_tests$normality_test$conclusion)
          )
        )
      ),
      column(
        width = 6,
        card(
          card_header(
            div(
              class = "d-flex justify-content-between align-items-center",
              span("Predictive Time-Series Forecast (CO5: ARIMA & Holt-Winters)"),
              div(
                class = "d-flex gap-2",
                selectInput("fc_pollutant", NULL, choices = available_polls, selected = "PM2.5", width = "120px"),
                selectInput("fc_horizon", NULL, choices = c("14 Days" = 14, "30 Days" = 30, "60 Days" = 60), selected = 30, width = "110px")
              )
            )
          ),
          plotlyOutput("plot_predictive_fc", height = "360px"),
          uiOutput("fc_metrics_ui")
        )
      )
    )
  ),
  
  # ----------------------------------------------------------------------------
  # TAB 6: ENVIRONMENTAL DECISION SUPPORT & TEXT MINING
  # ----------------------------------------------------------------------------
  tabPanel(
    "Decision Support & Text Mining",
    fluidRow(
      column(
        width = 6,
        card(
          card_header("Graded Response Action Plan (GRAP) Dynamic Advisory"),
          uiOutput("grap_advisory_ui")
        )
      ),
      column(
        width = 6,
        card(
          card_header("Text Mining of CPCB Health Advisories (Word Cloud - Unit V & VI)"),
          plotOutput("plot_wordcloud", height = "340px"),
          p(class = "text-muted small text-center mt-2",
            "Mined tokens from statutory CPCB environmental advisories highlighting key public health recommendations and emission control directives.")
        )
      )
    ),
    fluidRow(
      column(
        width = 12,
        card(
          card_header(
            div(
              class = "d-flex justify-content-between align-items-center",
              span("Embedded Relational Database Explorer (RSQLite - Unit III & Practical 7)"),
              div(
                style = "width: 320px;",
                selectInput("sel_sql_preset", NULL,
                            choices = c(
                              "Annual City Aggregations (GROUP BY & AVG)" = "annual",
                              "Severe Pollution Exceedance Audit (JOIN & HAVING)" = "severe",
                              "Criteria Standards Catalog (Dim_Pollutants)" = "standards"
                            ),
                            selected = "annual", width = "100%")
              )
            )
          ),
          div(
            class = "p-2",
            p("AIRGUARD 360 maintains an embedded SQLite database (", tags$code("data/airguard.sqlite"), 
              ") demonstrating direct SQL operations inside R using DBI and RSQLite."),
            DTOutput("table_sql_preview")
          )
        )
      )
    )
  )
)

# ------------------------------------------------------------------------------
# 4. Server Reactive Logic
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
    } else "#1F77B4"
    
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
      class = "kpi-card", style = "border-left-color: #EF4444;",
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
      class = "kpi-card", style = "border-left-color: #F59E0B;",
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
    plot_aqi_donut(df = filtered_city_data(), target_city = input$sel_city)
  })
  
  # ----------------------------------------------------------------------------
  # Geographic Intelligence
  # ----------------------------------------------------------------------------
  output$plot_station_geo_map <- renderPlotly({
    if (!is.null(station_geo_df) && nrow(station_geo_df) > 0) {
      plot_station_map(station_geo_df, interactive = TRUE)
    } else {
      plot_empty_message("Station geographical coordinates dataset unavailable.")
    }
  })
  
  output$plot_hotspots_bar <- renderPlotly({
    req(input$hotspot_metric, input$hotspot_topn)
    plot_city_rankings(
      df = df_city_daily, 
      target_var = input$hotspot_metric, 
      top_n = input$hotspot_topn, 
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
  # Pollutant Dynamics
  # ----------------------------------------------------------------------------
  output$plot_heatmap <- renderPlotly({
    plot_correlation_heatmap(cor_matrix, interactive = TRUE)
  })
  
  output$plot_scatter <- renderPlotly({
    req(input$scatter_x, input$scatter_y)
    plot_pollutant_scatter(
      df = df_city_daily,
      target_city = input$sel_city,
      var_x = input$scatter_x,
      var_y = input$scatter_y,
      start_date = input$sel_daterange[1],
      end_date = input$sel_daterange[2],
      interactive = TRUE
    )
  })
  
  # ----------------------------------------------------------------------------
  # Bollinger Bands Volatility
  # ----------------------------------------------------------------------------
  output$plot_bollinger <- renderPlotly({
    req(input$bollinger_pollutant)
    plot_bollinger_bands(
      df = df_city_daily,
      target_city = input$sel_city,
      target_var = input$bollinger_pollutant,
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
        tags$b("Validation Metrics: "),
        sprintf("Selected Architecture: %s | Out-of-Sample Test RMSE: %.2f | Test MAE: %.2f | Test MAPE: %.1f%%",
                m$Model_Selected,
                m[[paste0(ifelse(m$Model_Selected == "ARIMA", "ARIMA", "HW"), "_RMSE")]],
                m[[paste0(ifelse(m$Model_Selected == "ARIMA", "ARIMA", "HW"), "_MAE")]],
                m[[paste0(ifelse(m$Model_Selected == "ARIMA", "ARIMA", "HW"), "_MAPE")]]))
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
}

# ------------------------------------------------------------------------------
# 5. Application Launch
# ------------------------------------------------------------------------------
shinyApp(ui = ui, server = server)
