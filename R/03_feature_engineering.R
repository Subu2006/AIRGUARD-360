# ==============================================================================
# AIRGUARD 360: Environmental Intelligence & Decision-Support System
# File: R/03_feature_engineering.R
# Purpose: Feature Engineering, Temporal Lags, Moving Averages & Bollinger Bands
# INT232 Syllabus Mapping: Unit IV (Dates and timestamps, Math functions, dplyr, pipe)
#                          Unit VI (Bollinger Band analysis for air quality volatility)
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(lubridate)
})

#' Base R Rolling Mean (Right-Aligned)
roll_mean_base <- function(x, k) {
  n <- length(x)
  if (n < k) return(rep(NA_real_, n))
  res <- rep(NA_real_, n)
  # Use cumulative sums for rapid O(N) sliding window
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
  message(">> [AIRGUARD 360] Engineering Analytical & Volatility Features...")
  
  df_enriched <- df_city_daily %>%
    arrange(City, Date) %>%
    mutate(
      # 1. Calendar and Temporal Decompositions (Unit IV)
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
    # 4. Rolling Statistics and Bollinger Bands (Unit VI Syllabus requirement)
    group_by(City) %>%
    mutate(
      # 7-day and 30-day Moving Averages for all criteria pollutants
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
      
      # 20-Day Bollinger Volatility Bands on PM2.5 (Middle = 20-day MA, Upper/Lower = +/- 2 SD)
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
