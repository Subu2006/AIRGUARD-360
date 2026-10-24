# ==============================================================================
# AIRGUARD 360: Environmental Intelligence & Decision-Support System
# File: R/09_sql_queries.R
# Purpose: Direct SQL Queries against Embedded SQLite Database
# INT232 Syllabus Mapping: Unit III (SQL with R), Practical 7 (Perform different SQL queries)
# ==============================================================================

suppressPackageStartupMessages({
  library(DBI)
  library(RSQLite)
})

#' Execute Syllabus-Mandated SQL Queries on Air Quality Database (Practical 7)
#' 
#' @param db_path Path to SQLite file
#' @return A list containing query strings and resulting data frames
run_syllabus_sql_queries <- function(db_path = "data/airguard.sqlite") {
  message(">> [AIRGUARD 360] Executing Relational SQL Queries via DBI/RSQLite...")
  
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
  
  message("   SQL Queries Executed Successfully.")
  
  return(list(
    annual_summary     = list(sql = q1, data = res1),
    severe_exceedances = list(sql = q2, data = res2),
    pollutant_metadata = list(sql = q3, data = res3)
  ))
}
