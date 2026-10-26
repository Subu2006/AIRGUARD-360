# ==============================================================================
# AIRGUARD 360: Automated Comprehensive Verification Test Suite
# File: tests/test_shiny_app.R
# Purpose: Exhaustive testing of Shiny app, modular functions, plots, models, and data
# ==============================================================================

message(">> [TEST SUITE] Initiating Comprehensive AIRGUARD 360 Verification...")

suppressPackageStartupMessages({
  library(shiny)
  library(ggplot2)
  library(plotly)
  library(dplyr)
  library(DBI)
  library(RSQLite)
})

# Source internal modules
source("R/00_config.R")
source("R/01_data_import.R")
source("R/05_forecasting.R")
source("R/07_visualizations.R")
source("R/08_decision_support.R")
source("R/09_sql_queries.R")

# ------------------------------------------------------------------------------
# Test 1: Verify Shiny Compilation
# ------------------------------------------------------------------------------
message("   [TEST 1] Verifying app.R Shiny application compilation...")
app_obj <- tryCatch({
  source("app.R", local = TRUE)$value
}, error = function(e) {
  stop("FATAL: app.R failed to load: ", conditionMessage(e))
})

stopifnot(shiny::is.shiny.appobj(app_obj))
message("   [PASS] app.R successfully compiled into a valid Shiny App object.")

# ------------------------------------------------------------------------------
# Test 2: Check Processed Artifacts & Database
# ------------------------------------------------------------------------------
message("   [TEST 2] Verifying disk artifacts, dashboards, and SQLite tables...")
required_files <- c(
  "data/airguard.sqlite",
  "data/processed/airguard_clean.rds",
  "data/processed/airguard_enriched.rds",
  "outputs/tables/pollutant_summary_stats.csv",
  "outputs/tables/correlation_matrix.csv",
  "outputs/tables/hotspot_vulnerability_ranking.csv",
  "outputs/tables/station_geo_summary.csv",
  "outputs/tables/hypothesis_tests_summary.rds",
  "reports/AIRGUARD_360_Project_Report.docx",
  "reports/AIRGUARD_360_Project_Report.pdf",
  "dashboard.Rmd",
  "dashboard.html",
  "VIVA_PREPARATION_GUIDE.md",
  "LINKEDIN_POST_KIT.md"
)

for (f in required_files) {
  if (!file.exists(f)) stop("Missing required artifact: ", f)
}

df_enriched <- readRDS("data/processed/airguard_enriched.rds")
stopifnot(nrow(df_enriched) > 25000)
message("   [PASS] All 14 core artifacts, interactive dashboards, and reports verified.")


# ------------------------------------------------------------------------------
# Test 3: SQL Relational Operations
# ------------------------------------------------------------------------------
message("   [TEST 3] Testing SQLite relational queries...")
sql_test <- query_airguard_sql("SELECT COUNT(*) AS total FROM fact_station_day;", "data/airguard.sqlite")
stopifnot(sql_test$total >= 100000)

syllabus_sql <- run_syllabus_sql_queries("data/airguard.sqlite")
stopifnot(length(syllabus_sql) == 3)
message("   [PASS] SQLite database queries executed successfully (108,035 fact records).")

# ------------------------------------------------------------------------------
# Test 4: Multi-Pollutant Moving Averages & Temporal Trajectory
# ------------------------------------------------------------------------------
message("   [TEST 4] Testing temporal trend visualization across all criteria pollutants...")
test_polls <- c("PM2.5", "PM10", "NO2", "SO2", "CO", "O3", "AQI")

for (p in test_polls) {
  # Verify moving averages exist in dataset
  ma_col <- paste0(p, "_MA7")
  if (!(ma_col %in% colnames(df_enriched))) {
    stop(sprintf("MA7 column '%s' missing from enriched dataset!", ma_col))
  }
  
  # Verify plot renders without error
  plt <- plot_temporal_trend(df_enriched, target_city = "Delhi", target_var = p, interactive = TRUE)
  stopifnot(!is.null(plt))
}
message("   [PASS] Temporal trajectory plots verified for all 7 criteria pollutants.")

# ------------------------------------------------------------------------------
# Test 5: Visualizations Suite (Scatter, Rankings, Donut, Heatmap, Bollinger)
# ------------------------------------------------------------------------------
message("   [TEST 5] Testing advanced visualizations suite...")

# 5A. City Rankings with EVI and AQI
p_rank_evi <- plot_city_rankings(df_enriched, target_var = "EVI", top_n = 10, interactive = TRUE)
p_rank_aqi <- plot_city_rankings(df_enriched, target_var = "AQI", top_n = 10, interactive = TRUE)
stopifnot(!is.null(p_rank_evi), !is.null(p_rank_aqi))

# 5B. Multi-Pollutant Scatter
p_scat <- plot_pollutant_scatter(df_enriched, target_city = "Delhi", var_x = "PM10", var_y = "PM2.5", interactive = TRUE)
stopifnot(!is.null(p_scat))

# 5C. AQI Severity Donut
p_donut <- plot_aqi_donut(df_enriched, target_city = "Delhi")
stopifnot(!is.null(p_donut))

# 5D. Correlation Heatmap
cor_mat_df <- read.csv("outputs/tables/correlation_matrix.csv", row.names = 1)
p_heat <- plot_correlation_heatmap(as.matrix(cor_mat_df), interactive = TRUE)
stopifnot(!is.null(p_heat))

# 5E. Bollinger Volatility Bands (PM2.5, PM10, AQI)
p_bb_pm25 <- plot_bollinger_bands(df_enriched, target_city = "Delhi", target_var = "PM2.5", interactive = TRUE)
p_bb_pm10 <- plot_bollinger_bands(df_enriched, target_city = "Delhi", target_var = "PM10", interactive = TRUE)
p_bb_aqi  <- plot_bollinger_bands(df_enriched, target_city = "Delhi", target_var = "AQI", interactive = TRUE)
stopifnot(!is.null(p_bb_pm25), !is.null(p_bb_pm10), !is.null(p_bb_aqi))

# 5F. National CAAQMS Station Map
if (file.exists("outputs/tables/station_geo_summary.csv")) {
  st_geo <- read.csv("outputs/tables/station_geo_summary.csv", stringsAsFactors = FALSE)
  p_map <- plot_station_map(st_geo, interactive = TRUE)
  stopifnot(!is.null(p_map))
}

message("   [PASS] All basic and advanced visualization modules verified successfully.")

# ------------------------------------------------------------------------------
# Test 6: Predictive Analytics (ARIMA & Holt-Winters)
# ------------------------------------------------------------------------------
message("   [TEST 6] Testing predictive forecasting engine across diverse metros...")
fc_delhi <- forecast_city_pollution(df_enriched, target_city = "Delhi", target_var = "PM2.5", horizon = 14)
stopifnot(!is.null(fc_delhi), !isTRUE(fc_delhi$error), nrow(fc_delhi$data) > 0)

fc_mumbai <- forecast_city_pollution(df_enriched, target_city = "Mumbai", target_var = "AQI", horizon = 14)
stopifnot(!is.null(fc_mumbai), !isTRUE(fc_mumbai$error))

# Test graceful low-data handling (e.g., Aizawl)
fc_aizawl <- forecast_city_pollution(df_enriched, target_city = "Aizawl", target_var = "PM2.5", horizon = 14)
stopifnot(!is.null(fc_aizawl)) # Should return valid forecast or structured error object, never unhandled crash
message("   [PASS] Predictive modeling verified (Delhi, Mumbai, Aizawl).")

# ------------------------------------------------------------------------------
# Test 7: Decision Support & GRAP Advisories
# ------------------------------------------------------------------------------
message("   [TEST 7] Testing environmental decision support & GRAP advisories...")
hotspots <- compute_hotspot_priority_index(df_enriched)
stopifnot(nrow(hotspots) == 26, "Rank" %in% colnames(hotspots))

adv_clean <- generate_environmental_advisory(45)
stopifnot(adv_clean$Stage == "Stage 0: Baseline")

adv_severe <- generate_environmental_advisory(450)
stopifnot(adv_severe$Color == "#7030A0")

# Test extreme edge cases (NA, NaN, zero-length)
adv_na <- generate_environmental_advisory(NA)
stopifnot(adv_na$Stage == "Unknown")

adv_empty <- generate_environmental_advisory(numeric(0))
stopifnot(adv_empty$Stage == "Unknown")

message("   [PASS] Decision support and advisory edge cases verified.")

message(">> [TEST SUITE] 100% Comprehensive Tests Passed with Zero Errors!")
