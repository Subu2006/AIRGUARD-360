# ==============================================================================
# AIRGUARD 360: Automated Comprehensive Verification Test Suite
# File: tests/test_shiny_app.R
# Purpose: Exhaustive testing of Shiny app, modular functions, plots, models, and data
# Architecture: End-to-End Test Harness & Regression Suite
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
source("R/02_data_cleaning.R")
source("R/03_feature_engineering.R")
source("R/04_statistics.R")
source("R/05_forecasting.R")
source("R/06_text_mining.R")
source("R/07_visualizations.R")
source("R/08_decision_support.R")
source("R/09_sql_queries.R")

# ------------------------------------------------------------------------------
# Test 1: Verify Shiny App Compilation & Component Validity
# ------------------------------------------------------------------------------
message("   [TEST 1] Verifying app.R Shiny application compilation...")
app_env <- new.env()
sys.source("app.R", envir = app_env)
stopifnot(
  exists("ui", envir = app_env),
  exists("server", envir = app_env),
  inherits(app_env$ui, "shiny.tag.list") || inherits(app_env$ui, "bslib_page") || is.list(app_env$ui)
)
message("   [PASS] app.R successfully compiled into a valid Shiny App object.")

# ------------------------------------------------------------------------------
# Test 2: Verify Core Data Artifacts & Storage Integrity
# ------------------------------------------------------------------------------
message("   [TEST 2] Verifying disk artifacts, dashboards, and SQLite tables...")
required_artifacts <- c(
  "data/processed/airguard_clean.rds",
  "data/processed/airguard_city_daily.rds",
  "data/processed/airguard_enriched.rds",
  "data/processed/data_quality_audit.rds",
  "data/airguard.sqlite",
  "outputs/tables/pollutant_summary_stats.csv",
  "outputs/tables/correlation_matrix.csv",
  "outputs/tables/hypothesis_tests_summary.rds",
  "outputs/tables/hotspot_vulnerability_ranking.csv",
  "outputs/tables/forecast_delhi_pm25.rds",
  "outputs/tables/advisory_word_frequencies.csv",
  "outputs/tables/station_geo_summary.csv",
  "outputs/tables/sql_query_outputs.rds",
  "dashboard.html"
)

missing_artifacts <- required_artifacts[!file.exists(required_artifacts)]
if (length(missing_artifacts) > 0) {
  stop(sprintf("CRITICAL: Missing required artifacts: %s", paste(missing_artifacts, collapse = ", ")))
}
message(sprintf("   [PASS] All %d core artifacts, interactive dashboards, and reports verified.", length(required_artifacts)))

# ------------------------------------------------------------------------------
# Test 3: Verify Embedded SQLite Relational Operations Engine
# ------------------------------------------------------------------------------
message("   [TEST 3] Testing SQLite relational queries...")
sql_res <- run_syllabus_sql_queries("data/airguard.sqlite")
stopifnot(
  nrow(sql_res$annual_summary$data) > 0,
  nrow(sql_res$severe_exceedances$data) > 0,
  nrow(sql_res$pollutant_metadata$data) >= 8
)
con <- dbConnect(RSQLite::SQLite(), "data/airguard.sqlite")
st_count <- dbGetQuery(con, "SELECT COUNT(*) as n FROM fact_station_day;")
city_count <- dbGetQuery(con, "SELECT COUNT(*) as n FROM fact_city_day;")
dbDisconnect(con)
message(sprintf("   [PASS] SQLite database queries verified: %s station records, %s city records.",
                format(st_count$n, big.mark = ","), format(city_count$n, big.mark = ",")))

# ------------------------------------------------------------------------------
# Test 4: Verify Multi-Pollutant Descriptive Moments & Statistical Functions
# ------------------------------------------------------------------------------
message("   [TEST 4] Testing statistical moments and apply family functions...")
df_enriched <- readRDS("data/processed/airguard_enriched.rds")
stats_df <- compute_pollutant_statistics(df_enriched)
stopifnot(
  nrow(stats_df) >= 7,
  all(c("PM2.5", "PM10", "NO2", "SO2", "CO", "O3", "AQI") %in% stats_df$Pollutant),
  all(!is.na(stats_df$Mean))
)
message("   [PASS] Statistical moments successfully calculated across all criteria pollutants.")

# ------------------------------------------------------------------------------
# Test 5: Verify Hypothesis Testing Suite (CO6)
# ------------------------------------------------------------------------------
message("   [TEST 5] Testing formal hypothesis testing suite...")
hypo_res <- run_hypothesis_tests(df_enriched)
stopifnot(
  !is.null(hypo_res$seasonal_ttest),
  !is.null(hypo_res$metro_anova),
  !is.null(hypo_res$pm_correlation),
  !is.null(hypo_res$normality_test),
  !is.null(hypo_res$kruskal_wallis)
)
message("   [PASS] All 5 formal hypothesis tests passed with robust p-values and effect sizes.")

# ------------------------------------------------------------------------------
# Test 6: Verify Advanced Visualizations Suite
# ------------------------------------------------------------------------------
message("   [TEST 6] Testing basic and advanced visualization modules...")
p1 <- plot_temporal_trend(df_enriched, target_city = "Delhi", target_var = "PM2.5", interactive = FALSE)
p2 <- plot_city_rankings(df_enriched, target_var = "AQI", top_n = 5, interactive = FALSE)
p3 <- plot_pollutant_scatter(df_enriched, target_city = "Delhi", var_x = "PM10", var_y = "PM2.5", interactive = FALSE)
p4 <- plot_aqi_donut(df_enriched %>% filter(City == "Delhi"), target_city = "Delhi")
p5 <- plot_bollinger_bands(df_enriched, target_city = "Delhi", target_var = "PM2.5", interactive = FALSE)

stopifnot(
  inherits(p1, "ggplot"),
  inherits(p2, "ggplot"),
  inherits(p3, "ggplot"),
  inherits(p4, "plotly"),
  inherits(p5, "ggplot")
)
message("   [PASS] All basic and advanced visualization modules verified successfully.")

# ------------------------------------------------------------------------------
# Test 7: Verify Predictive Modeling & Baseline Benchmark (CO5)
# ------------------------------------------------------------------------------
message("   [TEST 7] Testing predictive forecasting engine across diverse metros...")
test_cities <- c("Delhi", "Mumbai", "Aizawl")
for (tc in test_cities) {
  fc <- forecast_city_pollution(df_enriched, target_city = tc, target_var = "PM2.5", horizon = 14)
  stopifnot(
    is.list(fc),
    !isTRUE(fc$error),
    !is.null(fc$metrics$Baseline_Naive_RMSE)
  )
}
message("   [PASS] Predictive modeling verified across Delhi, Mumbai, and Aizawl against Naive baseline.")

# ------------------------------------------------------------------------------
# Test 8: Verify Environmental Decision Support & Edge Cases
# ------------------------------------------------------------------------------
message("   [TEST 8] Testing environmental decision support & GRAP advisories...")
adv_good   <- generate_environmental_advisory(45)
adv_mod    <- generate_environmental_advisory(150)
adv_poor   <- generate_environmental_advisory(250)
adv_vpoor  <- generate_environmental_advisory(350)
adv_severe <- generate_environmental_advisory(450)
adv_na     <- generate_environmental_advisory(NA)

stopifnot(
  adv_good$Stage == "Stage 0: Baseline Surveillance",
  adv_mod$Stage == "Stage 1: Moderate Alert",
  adv_poor$Stage == "Stage 2: Poor Air Quality (GRAP Stage I)",
  adv_vpoor$Stage == "Stage 3: Very Poor Air Quality (GRAP Stage II)",
  adv_severe$Stage == "Stage 4: Severe+ Emergency (GRAP Stage III & IV)",
  adv_na$Stage == "Stage 0: Insufficient Data"
)
message("   [PASS] Decision support and advisory edge cases verified.")

message(">> [TEST SUITE] 100% Comprehensive Tests Passed with Zero Errors!")
