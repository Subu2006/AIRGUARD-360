# ==============================================================================
# AIRGUARD 360: Environmental Intelligence & Decision-Support System
# File: R/02_data_cleaning.R
# Purpose: Rigorous Data Cleaning, Missing Data Auditing, and Normalization
# INT232 Syllabus Mapping: Unit II (Data Frames, Factors), Unit IV (dplyr, tidyr, pipe, handling missing data)
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(lubridate)
})

#' Clean and Preprocess Raw Environmental Data
#' 
#' @param raw_data List returned by initialize_data_pipeline() or loaded from disk
#' @param output_dir Path to save clean processed RDS files
#' @return A list containing cleaned station-level and city-level data frames
clean_airguard_data <- function(raw_data, output_dir = "data/processed") {
  message(">> [AIRGUARD 360] Executing Data Cleaning and Preprocessing...")
  
  df_st_day  <- raw_data$station_day
  df_stations<- raw_data$stations
  
  # ----------------------------------------------------------------------------
  # Step 1: Schema Standardisation & Type Coercion
  # ----------------------------------------------------------------------------
  pollutant_cols <- c("PM2.5", "PM10", "NO", "NO2", "NOx", "NH3", "CO", 
                      "SO2", "O3", "Benzene", "Toluene", "Xylene", "AQI")
  
  # Ensure all numeric columns are strictly numeric
  for (col in pollutant_cols) {
    df_st_day[[col]] <- suppressWarnings(as.numeric(df_st_day[[col]]))
    # Physical Sanity Check: Ambient concentrations cannot be negative.
    # Replace sensor calibration negative anomalies with NA
    df_st_day[[col]][!is.na(df_st_day[[col]]) & df_st_day[[col]] < 0] <- NA
  }
  
  # Parse dates safely
  df_st_day$Date <- as.Date(df_st_day$Date)
  
  # ----------------------------------------------------------------------------
  # Step 2: Relational Join with Spatial Dimension (Unit II & Unit IV)
  # ----------------------------------------------------------------------------
  message("   Joining fact table with station geographic dimension...")
  df_joined <- df_st_day %>%
    left_join(
      df_stations %>% select(StationId, StationName, City, State, Status, 
                             any_of(c("Latitude", "Longitude", "CoordinateStatus", "CoordinateSource"))),
      by = "StationId"
    )
  
  # ----------------------------------------------------------------------------
  # Step 3: AQI Bucket Imputation and Factor Encoding (Unit II: Factors)
  # ----------------------------------------------------------------------------
  # CPCB Official AQI Categories
  bucket_levels <- c("Good", "Satisfactory", "Moderate", "Poor", "Very Poor", "Severe")
  
  # If AQI exists but AQI_Bucket is NA, impute bucket based on statutory breakpoints
  df_joined <- df_joined %>%
    mutate(
      AQI_Bucket_Clean = case_when(
        !is.na(AQI_Bucket) & AQI_Bucket %in% bucket_levels ~ AQI_Bucket,
        !is.na(AQI) & AQI <= 50  ~ "Good",
        !is.na(AQI) & AQI <= 100 ~ "Satisfactory",
        !is.na(AQI) & AQI <= 200 ~ "Moderate",
        !is.na(AQI) & AQI <= 300 ~ "Poor",
        !is.na(AQI) & AQI <= 400 ~ "Very Poor",
        !is.na(AQI) & AQI > 400  ~ "Severe",
        TRUE ~ NA_character_
      ),
      AQI_Bucket = factor(AQI_Bucket_Clean, levels = bucket_levels, ordered = TRUE),
      City = as.character(City),
      State = as.character(State)
    ) %>%
    select(-AQI_Bucket_Clean)
  
  # ----------------------------------------------------------------------------
  # Step 4: Missing Data Quality Audit (INT232 Practical 9: Data Wrangling)
  # ----------------------------------------------------------------------------
  total_records <- nrow(df_joined)
  missing_summary <- sapply(df_joined, function(x) sum(is.na(x)))
  missing_pct <- round((missing_summary / total_records) * 100, 2)
  
  missing_audit_df <- data.frame(
    Variable = names(missing_summary),
    Missing_Count = missing_summary,
    Missing_Percentage = missing_pct,
    stringsAsFactors = FALSE
  )
  
  message("   Data Cleaning Audit Completed:")
  message(sprintf("   - Total Valid Rows: %d", total_records))
  message(sprintf("   - Mean AQI Missingness: %.1f%%", missing_pct["AQI"]))
  message(sprintf("   - Mean PM2.5 Missingness: %.1f%%", missing_pct["PM2.5"]))
  
  # ----------------------------------------------------------------------------
  # Step 5: City-Level Daily Data Processing (Reconciliation & Enriched Roll-up)
  # ----------------------------------------------------------------------------
  if (!is.null(raw_data$city_day)) {
    message("   Standardising and cleaning raw city_day.csv records...")
    df_raw_city <- raw_data$city_day
    
    # Coerce numeric types & clean
    for (col in pollutant_cols) {
      if (col %in% colnames(df_raw_city)) {
        df_raw_city[[col]] <- suppressWarnings(as.numeric(df_raw_city[[col]]))
        df_raw_city[[col]][!is.na(df_raw_city[[col]]) & df_raw_city[[col]] < 0] <- NA
      }
    }
    df_raw_city$Date <- as.Date(df_raw_city$Date)
    
    # Map State from stations metadata
    city_state_map <- df_stations %>%
      filter(!is.na(City) & City != "") %>%
      select(City, State) %>%
      distinct(City, .keep_all = TRUE)
    
    df_city_daily <- df_raw_city %>%
      left_join(city_state_map, by = "City") %>%
      mutate(
        AQI_Bucket_Clean = case_when(
          !is.na(AQI_Bucket) & AQI_Bucket %in% bucket_levels ~ AQI_Bucket,
          !is.na(AQI) & AQI <= 50  ~ "Good",
          !is.na(AQI) & AQI <= 100 ~ "Satisfactory",
          !is.na(AQI) & AQI <= 200 ~ "Moderate",
          !is.na(AQI) & AQI <= 300 ~ "Poor",
          !is.na(AQI) & AQI <= 400 ~ "Very Poor",
          !is.na(AQI) & AQI > 400  ~ "Severe",
          TRUE ~ NA_character_
        ),
        AQI_Bucket = factor(AQI_Bucket_Clean, levels = bucket_levels, ordered = TRUE),
        AQI_Severity_Rank = as.integer(AQI_Bucket),
        AQI_Outlier_Flag = ifelse(!is.na(AQI) & AQI > 500, 1L, 0L),
        City = as.character(City),
        State = as.character(State)
      ) %>%
      select(-AQI_Bucket_Clean)
  } else {
    message("   Computing City-level daily aggregates across monitoring stations...")
    df_city_daily <- df_joined %>%
      filter(!is.na(City) & City != "") %>%
      group_by(City, State, Date) %>%
      summarise(
        Active_Stations = n_distinct(StationId[!is.na(AQI) | !is.na(PM2.5)]),
        PM2.5   = if (all(is.na(PM2.5)))   NA_real_ else round(mean(PM2.5, na.rm = TRUE), 1),
        PM10    = if (all(is.na(PM10)))    NA_real_ else round(mean(PM10, na.rm = TRUE), 1),
        NO      = if (all(is.na(NO)))      NA_real_ else round(mean(NO, na.rm = TRUE), 1),
        NO2     = if (all(is.na(NO2)))     NA_real_ else round(mean(NO2, na.rm = TRUE), 1),
        NOx     = if (all(is.na(NOx)))     NA_real_ else round(mean(NOx, na.rm = TRUE), 1),
        NH3     = if (all(is.na(NH3)))     NA_real_ else round(mean(NH3, na.rm = TRUE), 1),
        CO      = if (all(is.na(CO)))      NA_real_ else round(mean(CO, na.rm = TRUE), 2),
        SO2     = if (all(is.na(SO2)))     NA_real_ else round(mean(SO2, na.rm = TRUE), 1),
        O3      = if (all(is.na(O3)))      NA_real_ else round(mean(O3, na.rm = TRUE), 1),
        Benzene = if (all(is.na(Benzene))) NA_real_ else round(mean(Benzene, na.rm = TRUE), 2),
        Toluene = if (all(is.na(Toluene))) NA_real_ else round(mean(Toluene, na.rm = TRUE), 2),
        Xylene  = if (all(is.na(Xylene)))  NA_real_ else round(mean(Xylene, na.rm = TRUE), 2),
        AQI     = if (all(is.na(AQI)))     NA_real_ else round(mean(AQI, na.rm = TRUE), 1),
        .groups = "drop"
      ) %>%
      mutate(
        AQI_Bucket = case_when(
          !is.na(AQI) & AQI <= 50  ~ "Good",
          !is.na(AQI) & AQI <= 100 ~ "Satisfactory",
          !is.na(AQI) & AQI <= 200 ~ "Moderate",
          !is.na(AQI) & AQI <= 300 ~ "Poor",
          !is.na(AQI) & AQI <= 400 ~ "Very Poor",
          !is.na(AQI) & AQI > 400  ~ "Severe",
          TRUE ~ NA_character_
        ),
        AQI_Bucket = factor(AQI_Bucket, levels = bucket_levels, ordered = TRUE),
        AQI_Severity_Rank = as.integer(AQI_Bucket),
        AQI_Outlier_Flag = ifelse(!is.na(AQI) & AQI > 500, 1L, 0L),
        City = as.character(City),
        State = as.character(State)
      )
  }
  
  # Also add severity rank and outlier flag to station data
  df_joined <- df_joined %>%
    mutate(
      AQI_Severity_Rank = as.integer(AQI_Bucket),
      AQI_Outlier_Flag = ifelse(!is.na(AQI) & AQI > 500, 1L, 0L)
    )
  
  # ----------------------------------------------------------------------------
  # Step 6: Save Processed RDS Artifacts
  # ----------------------------------------------------------------------------
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  saveRDS(df_joined, file.path(output_dir, "airguard_clean.rds"))
  saveRDS(df_city_daily, file.path(output_dir, "airguard_city_daily.rds"))
  saveRDS(missing_audit_df, file.path(output_dir, "data_quality_audit.rds"))
  
  message(sprintf(">> [AIRGUARD 360] Cleaned datasets saved to %s", output_dir))
  
  return(list(
    station_clean = df_joined,
    city_daily    = df_city_daily,
    audit         = missing_audit_df
  ))
}
