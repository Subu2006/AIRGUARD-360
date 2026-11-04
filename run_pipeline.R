# ==============================================================================
# AIRGUARD 360: Environmental Intelligence & Decision-Support System
# File: run_pipeline.R
# Purpose: Master Execution Pipeline (Data Ingestion, Cleaning, Modeling & Outputs)
# Author: Subrat Panigrahi (Reg No: 26143073, Section: N1)
# ==============================================================================

message("==================================================================")
message("          AIRGUARD 360 : MASTER PIPELINE EXECUTION                ")
message("==================================================================")

# Source all modular scripts in strict architectural sequence
source("R/config.R")
source("R/data_engine.R")
source("R/analytics_engine.R")
source("R/visualization_engine.R")







# Ensure required directory structure exists
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs/tables", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs/figures", showWarnings = FALSE, recursive = TRUE)
dir.create("reports", showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------------------------
# STEP 1: Ingestion & Relational Database Creation
# ------------------------------------------------------------------------------
raw_bundle <- initialize_data_pipeline(raw_dir = "data/raw", db_path = "data/airguard.sqlite")

# ------------------------------------------------------------------------------
# STEP 2: Rigorous Cleaning & Grain Separation
# ------------------------------------------------------------------------------
clean_bundle <- clean_airguard_data(raw_bundle, output_dir = "data/processed")

# ------------------------------------------------------------------------------
# STEP 3: Advanced Feature Engineering
# ------------------------------------------------------------------------------
df_city_daily <- clean_bundle$city_daily
df_enriched   <- engineer_airguard_features(df_city_daily)
saveRDS(df_enriched, "data/processed/airguard_enriched.rds")

# ------------------------------------------------------------------------------
# STEP 4: Descriptive Statistics & Hypothesis Testing Engine
# ------------------------------------------------------------------------------
poll_stats <- compute_pollutant_statistics(df_enriched)
write.csv(poll_stats, "outputs/tables/pollutant_summary_stats.csv", row.names = FALSE)

cor_bundle <- compute_correlation_matrices(df_enriched)
write.csv(cor_bundle$correlation_matrix, "outputs/tables/correlation_matrix.csv")

hypo_tests <- run_hypothesis_tests(df_enriched)
saveRDS(hypo_tests, "outputs/tables/hypothesis_tests_summary.rds")

# ------------------------------------------------------------------------------
# STEP 5: Time-Series Modeling & Baseline Benchmarking Engine
# ------------------------------------------------------------------------------
forecast_res <- forecast_city_pollution(df_enriched, target_city = "Delhi", target_var = "PM2.5", horizon = 30)
saveRDS(forecast_res, "outputs/tables/forecast_delhi_pm25.rds")

# ------------------------------------------------------------------------------
# STEP 6: Text Mining & Term Frequency Extraction Engine
# ------------------------------------------------------------------------------
word_freqs <- mine_environmental_text()
write.csv(word_freqs, "outputs/tables/advisory_word_frequencies.csv", row.names = FALSE)

# ------------------------------------------------------------------------------
# STEP 7: Environmental Vulnerability Index (EVI) Hotspots (Decision Support)
# ------------------------------------------------------------------------------
evi_df <- compute_hotspot_priority_index(df_enriched)
write.csv(evi_df, "outputs/tables/hotspot_vulnerability_ranking.csv", row.names = FALSE)

# Station Geospatial Summary Table for Map
station_clean <- clean_bundle$station_clean
station_geo_summary <- station_clean %>%
  filter(!is.na(Latitude), !is.na(Longitude)) %>%
  group_by(StationId, StationName, City, State, Latitude, Longitude, Status) %>%
  summarise(
    Total_Observations = n(),
    Valid_AQI_Days     = sum(!is.na(AQI)),
    Mean_AQI           = round(mean(AQI, na.rm = TRUE), 1),
    Peak_AQI           = if (all(is.na(AQI))) NA_real_ else round(max(AQI, na.rm = TRUE), 1),
    Mean_PM25          = if (all(is.na(PM2.5))) NA_real_ else round(mean(PM2.5, na.rm = TRUE), 1),
    Mean_PM10          = if (all(is.na(PM10))) NA_real_ else round(mean(PM10, na.rm = TRUE), 1),
    .groups = "drop"
  )
write.csv(station_geo_summary, "outputs/tables/station_geo_summary.csv", row.names = FALSE)

# ------------------------------------------------------------------------------
# STEP 8: Relational SQL Queries Execution
# ------------------------------------------------------------------------------
sql_outputs <- run_syllabus_sql_queries("data/airguard.sqlite")
saveRDS(sql_outputs, "outputs/tables/sql_query_outputs.rds")

# ------------------------------------------------------------------------------
# STEP 9: Generate High-Resolution Publication Figures
# ------------------------------------------------------------------------------
source("generate_figures.R")

# ------------------------------------------------------------------------------
# STEP 10: Compile Standalone HTML Dashboard (if flexdashboard installed)
# ------------------------------------------------------------------------------
if (file.exists("dashboard.Rmd") && requireNamespace("rmarkdown", quietly = TRUE)) {
  message(">> [DASHBOARD] Compiling Interactive R Markdown Dashboard (dashboard.html)...")
  tryCatch({
    rmarkdown::render("dashboard.Rmd", output_file = "dashboard.html", quiet = TRUE)
    message(">> [SUCCESS] Interactive R Markdown Dashboard compiled: dashboard.html")
  }, error = function(e) {
    message(">> [WARNING] Dashboard compilation encountered an issue: ", e$message)
  })
}

message("==================================================================")
message(">> [SUCCESS] AIRGUARD 360 Full Analytical Pipeline Completed!")
message(sprintf(">> Total City-Daily Records Processed: %d", nrow(df_enriched)))
message(sprintf(">> Target Metros Evaluated: %d", n_distinct(df_enriched$City)))
message("==================================================================")
