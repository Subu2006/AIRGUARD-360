# ==============================================================================
# AIRGUARD 360: Environmental Intelligence & Decision-Support System
# File: run_pipeline.R
# Purpose: Master Execution Pipeline (Data Ingestion, Cleaning, Modeling & Outputs)
# ==============================================================================

message("==================================================================")
message("          AIRGUARD 360 : MASTER PIPELINE EXECUTION                ")
message("==================================================================")

# Source all modular scripts
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

# Ensure output directories exist
dir.create("outputs/tables", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs/figures", showWarnings = FALSE, recursive = TRUE)
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------------------------
# 1. Ingest Raw Data & Initialize SQLite
# ------------------------------------------------------------------------------
raw_data <- initialize_data_pipeline(raw_dir = "data/raw", db_path = "data/airguard.sqlite")

# ------------------------------------------------------------------------------
# 2. Clean & Preprocess Data
# ------------------------------------------------------------------------------
cleaned_data <- clean_airguard_data(raw_data, output_dir = "data/processed")

# ------------------------------------------------------------------------------
# 3. Engineer Features (Temporal, Volatility, Bollinger Bands)
# ------------------------------------------------------------------------------
df_city_enriched <- engineer_airguard_features(cleaned_data$city_daily)
saveRDS(df_city_enriched, "data/processed/airguard_enriched.rds")

# ------------------------------------------------------------------------------
# 4. Statistical Analysis & Hypothesis Testing
# ------------------------------------------------------------------------------
stats_summary <- compute_pollutant_statistics(df_city_enriched)
write.csv(stats_summary, "outputs/tables/pollutant_summary_stats.csv", row.names = FALSE)

cor_results <- compute_correlation_matrices(df_city_enriched)
write.csv(as.data.frame(cor_results$correlation_matrix), "outputs/tables/correlation_matrix.csv")

hypo_tests <- run_hypothesis_tests(df_city_enriched)
saveRDS(hypo_tests, "outputs/tables/hypothesis_tests_summary.rds")

# ------------------------------------------------------------------------------
# 5. Time-Series Predictive Analytics (Forecast on Delhi PM2.5)
# ------------------------------------------------------------------------------
fc_delhi <- forecast_city_pollution(df_city_enriched, target_city = "Delhi", target_var = "PM2.5", horizon = 30)
saveRDS(fc_delhi, "outputs/tables/forecast_delhi_pm25.rds")

# ------------------------------------------------------------------------------
# 6. Text Mining & Advisory Corpus Analysis
# ------------------------------------------------------------------------------
word_freqs <- mine_environmental_text()
write.csv(word_freqs, "outputs/tables/advisory_word_frequencies.csv", row.names = FALSE)

# ------------------------------------------------------------------------------
# 7. Hotspot Prioritization (Environmental Vulnerability Index)
# ------------------------------------------------------------------------------
hotspots_df <- compute_hotspot_priority_index(df_city_enriched)
write.csv(hotspots_df, "outputs/tables/hotspot_vulnerability_ranking.csv", row.names = FALSE)

# ------------------------------------------------------------------------------
# 8. SQL Queries Execution Test
# ------------------------------------------------------------------------------
sql_outputs <- run_syllabus_sql_queries("data/airguard.sqlite")
saveRDS(sql_outputs, "outputs/tables/sql_query_outputs.rds")

message("\n==================================================================")
message(">> [SUCCESS] AIRGUARD 360 Full Analytical Pipeline Completed!")
message(sprintf(">> Total City-Daily Records Processed: %d", nrow(df_city_enriched)))
message(sprintf(">> Target Metros Evaluated: %d", n_distinct(df_city_enriched$City)))
message("==================================================================")
