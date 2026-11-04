# ==============================================================================
# AIRGUARD 360: National Air Quality Intelligence & Decision-Support System
# File: R/data_engine.R
# Architecture: Data Ingestion, Relational SQLite Database, Cleaning & Feature Engineering
# Author: Subrat Panigrahi (B.Tech Computer Science & Engineering)
# Open-Source Repository: https://github.com/Subu2006/AIRGUARD-360
# ==============================================================================

suppressPackageStartupMessages({
  library(DBI)
  library(RSQLite)
  library(dplyr)
  library(tidyr)
  library(lubridate)
})

# ==============================================================================
# SECTION 1: DATA INGESTION & RELATIONAL SQLITE DATABASE INITIALIZATION
# ==============================================================================

#' Ingest Raw Environmental Data and Initialize Embedded SQLite Storage
#' 
#' @param raw_dir Character path to directory containing raw CSV files
#' @param db_path Character path to SQLite database file
#' @return A list containing raw data frames and database status
initialize_data_pipeline <- function(raw_dir = "data/raw", db_path = "data/airguard.sqlite") {
  message(">> [DATA ENGINE] Starting Data Ingestion Pipeline...")
  
  # 1. Path Verification
  station_day_file <- file.path(raw_dir, "station_day.csv")
  city_day_file    <- file.path(raw_dir, "city_day.csv")
  stations_file    <- file.path(raw_dir, "stations.csv")
  coords_file      <- file.path(raw_dir, "StationCoordinates.csv")
  dim_aqi_file     <- file.path(raw_dir, "Dim_AQICategory.csv")
  dim_poll_file    <- file.path(raw_dir, "Dim_Pollutant.csv")
  
  stopifnot(
    file.exists(station_day_file),
    file.exists(stations_file),
    file.exists(dim_aqi_file),
    file.exists(dim_poll_file)
  )
  
  # 2. Ingest CSVs using Base R read.csv
  message("   Loading fact table: station_day.csv...")
  df_station_day <- read.csv(station_day_file, stringsAsFactors = FALSE, na.strings = c("", "NA", "NULL"))
  
  df_city_day <- if (file.exists(city_day_file)) {
    message("   Loading city-level fact table: city_day.csv...")
    read.csv(city_day_file, stringsAsFactors = FALSE, na.strings = c("", "NA", "NULL"))
  } else NULL
  
  message("   Loading dimension and spatial tables...")
  df_stations <- read.csv(stations_file, stringsAsFactors = FALSE, na.strings = c("", "NA"))
  df_coords   <- if (file.exists(coords_file)) {
    read.csv(coords_file, stringsAsFactors = FALSE, na.strings = c("", "NA"))
  } else NULL
  df_dim_aqi  <- read.csv(dim_aqi_file, stringsAsFactors = FALSE)
  df_dim_poll <- read.csv(dim_poll_file, stringsAsFactors = FALSE)
  
  # Enrich stations with coordinates if available
  if (!is.null(df_coords)) {
    df_stations <- df_stations %>%
      left_join(
        df_coords %>% select(StationId, Latitude, Longitude, CoordinateStatus, CoordinateSource),
        by = "StationId"
      )
  }
  
  message(sprintf("   Ingested %d station records across %d monitoring stations.", 
                  nrow(df_station_day), nrow(df_stations)))
  
  # 3. Create / Connect to Embedded SQLite Database (RSQLite Engine)
  message(sprintf("   Initializing SQLite Database at: %s", db_path))
  con <- dbConnect(RSQLite::SQLite(), db_path)
  
  # Write tables to SQLite with overwrite protection
  dbWriteTable(con, "fact_station_day", df_station_day, overwrite = TRUE)
  if (!is.null(df_city_day)) {
    dbWriteTable(con, "fact_city_day", df_city_day, overwrite = TRUE)
    dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_city_day_city ON fact_city_day(City);")
    dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_city_day_date ON fact_city_day(Date);")
  }
  dbWriteTable(con, "dim_stations",    df_stations,    overwrite = TRUE)
  dbWriteTable(con, "dim_aqi_category",df_dim_aqi,     overwrite = TRUE)
  dbWriteTable(con, "dim_pollutants",  df_dim_poll,    overwrite = TRUE)
  
  # Create SQLite indexes for fast querying
  dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_st_day_id ON fact_station_day(StationId);")
  dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_st_day_date ON fact_station_day(Date);")
  dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_stations_city ON dim_stations(City);")
  
  tables <- dbListTables(con)
  message(sprintf("   SQLite database successfully initialized with %d tables: %s", 
                  length(tables), paste(tables, collapse = ", ")))
  
  dbDisconnect(con)
  
  return(list(
    station_day = df_station_day,
    city_day    = df_city_day,
    stations    = df_stations,
    dim_aqi     = df_dim_aqi,
    dim_poll    = df_dim_poll,
    db_path     = db_path
  ))
}

#' Helper function to execute SQL query on AIRGUARD database
#' 
#' @param query SQL query string
#' @param db_path Path to SQLite file
#' @return data.frame with query results
query_airguard_sql <- function(query, db_path = "data/airguard.sqlite") {
  con <- dbConnect(RSQLite::SQLite(), db_path)
  on.exit(dbDisconnect(con))
  res <- dbGetQuery(con, query)
  return(res)
}

# ==============================================================================
# SECTION 2: RIGOROUS DATA CLEANING & GRAIN SEGREGATION
# ==============================================================================

#' Clean and Preprocess Raw Environmental Data
#' 
#' @param raw_data List returned by initialize_data_pipeline() or loaded from disk
#' @param output_dir Path to save clean processed RDS files
#' @return A list containing cleaned station-level and city-level data frames
clean_airguard_data <- function(raw_data, output_dir = "data/processed") {
  message(">> [DATA ENGINE] Executing Data Cleaning and Preprocessing...")
  
  df_st_day   <- raw_data$station_day
  df_stations <- raw_data$stations
  
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
  # Step 2: Relational Join with Spatial Dimension
  # ----------------------------------------------------------------------------
  message("   Joining fact table with station geographic dimension...")
  df_joined <- df_st_day %>%
    left_join(
      df_stations %>% select(StationId, StationName, City, State, Status, 
                             any_of(c("Latitude", "Longitude", "CoordinateStatus", "CoordinateSource"))),
      by = "StationId"
    )
  
  # ----------------------------------------------------------------------------
  # Step 3: AQI Bucket Imputation and Factor Encoding
  # ----------------------------------------------------------------------------
  bucket_levels <- c("Good", "Satisfactory", "Moderate", "Poor", "Very Poor", "Severe")
  
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
  # Step 4: Missing Data Quality Audit & Completeness Profiling
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
    
    for (col in pollutant_cols) {
      if (col %in% colnames(df_raw_city)) {
        df_raw_city[[col]] <- suppressWarnings(as.numeric(df_raw_city[[col]]))
        df_raw_city[[col]][!is.na(df_raw_city[[col]]) & df_raw_city[[col]] < 0] <- NA
      }
    }
    df_raw_city$Date <- as.Date(df_raw_city$Date)
    
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
  
  message(sprintf(">> [DATA ENGINE] Cleaned datasets saved to %s", output_dir))
  
  return(list(
    station_clean = df_joined,
    city_daily    = df_city_daily,
    audit         = missing_audit_df
  ))
}

# ==============================================================================
# SECTION 3: ADVANCED FEATURE ENGINEERING & ATMOSPHERIC VOLATILITY
# ==============================================================================

#' Base R Rolling Mean (Right-Aligned)
roll_mean_base <- function(x, k) {
  n <- length(x)
  if (n < k) return(rep(NA_real_, n))
  res <- rep(NA_real_, n)
  valid_x <- ifelse(is.na(x), 0, x)
  is_valid <- ifelse(is.na(x), 0, 1)
  
  c_val <- c(0, cumsum(valid_x))
  c_cnt <- c(0, cumsum(is_valid))
  
  for (i in k:n) {
    cnt <- c_cnt[i + 1] - c_cnt[i - k + 1]
    if (cnt >= (k * 0.6)) { # require at least 60% valid observations in window
      res[i] <- (c_val[i + 1] - c_val[i - k + 1]) / cnt
    }
  }
  return(res)
}

#' Base R Rolling Standard Deviation (Right-Aligned)
roll_sd_base <- function(x, k) {
  n <- length(x)
  if (n < k) return(rep(NA_real_, n))
  res <- rep(NA_real_, n)
  for (i in k:n) {
    window <- x[(i - k + 1):i]
    window_clean <- window[!is.na(window)]
    if (length(window_clean) >= (k * 0.6)) {
      res[i] <- sd(window_clean)
    }
  }
  return(res)
}

#' Engineer Advanced Temporal, Volatility, and Exceedance Features
#' 
#' @param df_city_daily Aggregated city daily data frame
#' @return Enriched data frame with derived analytical features
engineer_airguard_features <- function(df_city_daily) {
  message(">> [DATA ENGINE] Engineering Analytical & Volatility Features...")
  
  df_enriched <- df_city_daily %>%
    arrange(City, Date) %>%
    mutate(
      # 1. Calendar and Temporal Decompositions
      Year        = lubridate::year(Date),
      Month       = lubridate::month(Date, label = TRUE, abbr = TRUE),
      Month_Num   = lubridate::month(Date),
      Day         = lubridate::day(Date),
      DayOfWeek   = lubridate::wday(Date, label = TRUE, abbr = TRUE),
      IsWeekend   = factor(ifelse(DayOfWeek %in% c("Sat", "Sun"), "Weekend", "Weekday"),
                           levels = c("Weekday", "Weekend")),
      
      # 2. Climatological Seasons in India (Official IMD Classification)
      Season = factor(case_when(
        Month_Num %in% c(12, 1, 2)   ~ "Winter",
        Month_Num %in% c(3, 4, 5)    ~ "Summer",
        Month_Num %in% c(6, 7, 8, 9) ~ "Monsoon",
        Month_Num %in% c(10, 11)     ~ "Post-Monsoon"
      ), levels = c("Winter", "Summer", "Monsoon", "Post-Monsoon"), ordered = TRUE),
      
      # 3. Regulatory Exceedance Flags (NAAQS Standard)
      PM2.5_Exceeded = ifelse(!is.na(PM2.5) & PM2.5 > 60, 1L, 0L),
      PM10_Exceeded  = ifelse(!is.na(PM10)  & PM10 > 100, 1L, 0L),
      NO2_Exceeded   = ifelse(!is.na(NO2)   & NO2 > 80, 1L, 0L),
      SO2_Exceeded   = ifelse(!is.na(SO2)   & SO2 > 80, 1L, 0L),
      CO_Exceeded    = ifelse(!is.na(CO)    & CO > 2.0, 1L, 0L),
      O3_Exceeded    = ifelse(!is.na(O3)    & O3 > 100, 1L, 0L),
      AQI_Exceeded   = ifelse(!is.na(AQI)   & AQI > 100, 1L, 0L)
    ) %>%
    # 4. Rolling Statistics and Bollinger Bands (Atmospheric Volatility)
    group_by(City) %>%
    mutate(
      AQI_MA7    = round(roll_mean_base(AQI, 7), 1),
      AQI_MA30   = round(roll_mean_base(AQI, 30), 1),
      PM2.5_MA7  = round(roll_mean_base(PM2.5, 7), 1),
      PM2.5_MA30 = round(roll_mean_base(PM2.5, 30), 1),
      PM10_MA7   = round(roll_mean_base(PM10, 7), 1),
      PM10_MA30  = round(roll_mean_base(PM10, 30), 1),
      NO2_MA7    = round(roll_mean_base(NO2, 7), 1),
      NO2_MA30   = round(roll_mean_base(NO2, 30), 1),
      SO2_MA7    = round(roll_mean_base(SO2, 7), 1),
      SO2_MA30   = round(roll_mean_base(SO2, 30), 1),
      CO_MA7     = round(roll_mean_base(CO, 7), 2),
      CO_MA30    = round(roll_mean_base(CO, 30), 2),
      O3_MA7     = round(roll_mean_base(O3, 7), 1),
      O3_MA30    = round(roll_mean_base(O3, 30), 1),
      NH3_MA7    = round(roll_mean_base(NH3, 7), 1),
      NH3_MA30   = round(roll_mean_base(NH3, 30), 1),
      
      # 20-Day Bollinger Volatility Bands on PM2.5
      PM2.5_BB_Mid   = roll_mean_base(PM2.5, 20),
      PM2.5_BB_SD    = roll_sd_base(PM2.5, 20),
      PM2.5_BB_Upper = round(PM2.5_BB_Mid + (2 * PM2.5_BB_SD), 1),
      PM2.5_BB_Lower = round(pmax(0, PM2.5_BB_Mid - (2 * PM2.5_BB_SD)), 1),
      PM2.5_Bollinger_Spike = ifelse(!is.na(PM2.5) & !is.na(PM2.5_BB_Upper) & PM2.5 > PM2.5_BB_Upper, 1L, 0L),
      
      # 20-Day Bollinger Volatility Bands on PM10
      PM10_BB_Mid   = roll_mean_base(PM10, 20),
      PM10_BB_SD    = roll_sd_base(PM10, 20),
      PM10_BB_Upper = round(PM10_BB_Mid + (2 * PM10_BB_SD), 1),
      PM10_BB_Lower = round(pmax(0, PM10_BB_Mid - (2 * PM10_BB_SD)), 1),
      PM10_Bollinger_Spike = ifelse(!is.na(PM10) & !is.na(PM10_BB_Upper) & PM10 > PM10_BB_Upper, 1L, 0L),

      # 20-Day Bollinger Volatility Bands on AQI
      AQI_BB_Mid   = roll_mean_base(AQI, 20),
      AQI_BB_SD    = roll_sd_base(AQI, 20),
      AQI_BB_Upper = round(AQI_BB_Mid + (2 * AQI_BB_SD), 1),
      AQI_BB_Lower = round(pmax(0, AQI_BB_Mid - (2 * AQI_BB_SD)), 1),
      AQI_Bollinger_Spike = ifelse(!is.na(AQI) & !is.na(AQI_BB_Upper) & AQI > AQI_BB_Upper, 1L, 0L)
    ) %>%
    ungroup()
  
  message(sprintf("   Engineered %d features across %d city-daily records.",
                  ncol(df_enriched) - ncol(df_city_daily), nrow(df_enriched)))
  
  return(df_enriched)
}

# ==============================================================================
# SECTION 4: RELATIONAL SQL QUERY LIBRARY (DBI / RSQLITE)
# ==============================================================================

#' Execute Relational SQL Queries on Air Quality Database
#' 
#' @param db_path Path to SQLite file
#' @return A list containing query strings and resulting data frames
run_relational_sql_queries <- function(db_path = "data/airguard.sqlite") {
  message(">> [DATA ENGINE] Executing Relational SQL Queries via DBI/RSQLite...")
  
  con <- dbConnect(RSQLite::SQLite(), db_path)
  on.exit(dbDisconnect(con))
  
  # ----------------------------------------------------------------------------
  # Query 1: Annual City Aggregation with GROUP BY, AVG, and ORDER BY
  # ----------------------------------------------------------------------------
  q1 <- '
    SELECT 
      s.City,
      SUBSTR(f.Date, 1, 4) AS Year,
      COUNT(f.Date) AS Total_Observations,
      ROUND(AVG(f.AQI), 1) AS Mean_AQI,
      ROUND(AVG(f."PM2.5"), 1) AS Mean_PM25,
      ROUND(AVG(f."PM10"), 1) AS Mean_PM10,
      MAX(f.AQI) AS Peak_AQI
    FROM fact_station_day f
    INNER JOIN dim_stations s ON f.StationId = s.StationId
    WHERE f.AQI IS NOT NULL AND s.City != ""
    GROUP BY s.City, Year
    HAVING COUNT(f.Date) >= 100
    ORDER BY Year DESC, Mean_AQI DESC
    LIMIT 15;
  '
  res1 <- dbGetQuery(con, q1)
  
  # ----------------------------------------------------------------------------
  # Query 2: Multi-Table JOIN with HAVING for Severe Exceedance Auditing
  # ----------------------------------------------------------------------------
  q2 <- "
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
  "
  res2 <- dbGetQuery(con, q2)
  
  # ----------------------------------------------------------------------------
  # Query 3: Multi-Pollutant Relational Join against Criteria Standards
  # ----------------------------------------------------------------------------
  q3 <- "
    SELECT 
      p.Pollutant,
      p.FullName,
      p.NAAQS_24hr_Limit,
      p.Unit,
      p.PrimarySource
    FROM dim_pollutants p
    ORDER BY p.NAAQS_24hr_Limit ASC;
  "
  res3 <- dbGetQuery(con, q3)
  
  message("   Relational SQL Queries Executed Successfully.")
  
  return(list(
    annual_summary     = list(sql = q1, data = res1),
    severe_exceedances = list(sql = q2, data = res2),
    pollutant_metadata = list(sql = q3, data = res3)
  ))
}

# Alias for backwards compatibility
run_syllabus_sql_queries <- run_relational_sql_queries
