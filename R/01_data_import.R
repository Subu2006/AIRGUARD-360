# ==============================================================================
# AIRGUARD 360: Environmental Intelligence & Decision-Support System
# File: R/01_data_import.R
# Purpose: Robust Data Ingestion and SQLite Embedded Database Setup
# INT232 Syllabus Mapping: Unit III (Data input/output: CSV, SQL with R), Practical 7
# ==============================================================================

suppressPackageStartupMessages({
  library(DBI)
  library(RSQLite)
  library(dplyr)
})

#' Ingest Raw Environmental Data and Initialize Embedded SQLite Storage
#' 
#' @param raw_dir Character path to directory containing raw CSV files
#' @param db_path Character path to SQLite database file
#' @return A list containing raw data frames and database status
initialize_data_pipeline <- function(raw_dir = "data/raw", db_path = "data/airguard.sqlite") {
  message(">> [AIRGUARD 360] Starting Data Ingestion Pipeline...")
  
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
  
  # 2. Ingest CSVs using Base R read.csv (Unit III requirement)
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
  
  # 3. Create / Connect to Embedded SQLite Database (INT232 Unit III: SQL with R)
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
