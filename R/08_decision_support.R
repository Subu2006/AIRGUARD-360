# ==============================================================================
# AIRGUARD 360: Environmental Intelligence & Decision-Support System
# File: R/08_decision_support.R
# Purpose: Environmental Vulnerability Index (EVI) & Simulated GRAP Decision Support
# Architecture: Environmental Decision Support, EVI Prioritization & GRAP Advisory Engine
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
})

#' Compute Environmental Vulnerability Index (EVI) for Municipal Hotspot Prioritization
#' 
#' Mathematical Formulation:
#' EVI_c = 0.40 * (Normalized Mean AQI * 100) + 0.40 * (% Severe/Very Poor Days) + 0.20 * (PM2.5 Exceedance Rate)
#' 
#' Tiers:
#' - Tier 1: Critical Emergency (EVI >= 60) -> Immediate red alert & emergency intervention
#' - Tier 2: High Vulnerability (35 <= EVI < 60) -> Active mitigation & industrial surveillance
#' - Tier 3: Moderate / Baseline (EVI < 35) -> Routine maintenance & continuous monitoring
#' 
#' Note: EVI is a custom academic decision-support index designed for INT232 research.
#' It is not an official CPCB statutory ranking.
#' 
#' @param df Enriched city-daily data frame
#' @return Prioritized ranking data frame with Composite EVI scores
compute_hotspot_priority_index <- function(df) {
  message(">> [AIRGUARD 360] Computing Hotspot Vulnerability Index...")
  
  evi_df <- df %>%
    group_by(City, State) %>%
    summarise(
      Total_Days        = n(),
      Mean_AQI          = round(mean(AQI, na.rm = TRUE), 1),
      Max_PM2.5         = round(max(PM2.5, na.rm = TRUE), 1),
      Pct_Severe_Days   = round(mean(AQI_Bucket %in% c("Very Poor", "Severe"), na.rm = TRUE) * 100, 1),
      PM2.5_Exceed_Rate = round(mean(PM2.5_Exceeded, na.rm = TRUE) * 100, 1),
      .groups = "drop"
    ) %>%
    filter(Total_Days >= 30, !is.na(Mean_AQI)) %>%
    mutate(
      # Composite Score Formula (Weighted Multi-Criteria Evaluation):
      # EVI = (0.4 * Scaled Mean AQI) + (0.4 * % Severe Days) + (0.2 * PM2.5 Exceedance Rate)
      AQI_Span = max(Mean_AQI) - min(Mean_AQI),
      AQI_Norm = ifelse(AQI_Span > 0, (Mean_AQI - min(Mean_AQI)) / AQI_Span, 0.5),
      EVI_Score = round((0.4 * (AQI_Norm * 100)) + (0.4 * Pct_Severe_Days) + (0.2 * PM2.5_Exceed_Rate), 1),
      Priority_Tier = case_when(
        EVI_Score >= 60 ~ "Tier 1: Critical Emergency (Immediate Red Alert)",
        EVI_Score >= 35 ~ "Tier 2: High Vulnerability (Active Mitigation)",
        TRUE            ~ "Tier 3: Moderate / Baseline Surveillance"
      )
    ) %>%
    select(-AQI_Span, -AQI_Norm) %>%
    arrange(desc(EVI_Score)) %>%
    mutate(Rank = row_number()) %>%
    select(Rank, City, State, Total_Days, Mean_AQI, Max_PM2.5, Pct_Severe_Days, PM2.5_Exceed_Rate, EVI_Score, Priority_Tier)
  
  return(evi_df)
}

#' Generate Graded Response Action Plan (GRAP) Environmental Advisory Simulation
#' 
#' Maps observed or forecasted AQI to simulated public health and regulatory responses.
#' Note: Educational simulation inspired by Delhi NCR GRAP framework.
#' For operational compliance, users must consult official CAQM / CPCB notifications.
#' 
#' @param aqi Observed or forecasted AQI value
#' @param pm25 Observed or forecasted PM2.5 value
#' @return Structured list containing regulatory actions, citizen advisories, and alert level
generate_environmental_advisory <- function(aqi, pm25 = NA) {
  if (length(aqi) == 0 || is.na(aqi) || is.nan(aqi)) {
    return(list(
      Stage = "Stage 0: Insufficient Data",
      Severity = "No Data Available for Horizon",
      Color = "#94A3B8",
      Authority_Action = "Maintain standard automated sensor calibration and check station diagnostics.",
      Citizen_Advisory = "Check local ambient continuous monitors before outdoor physical activities."
    ))
  }
  
  aqi_val <- as.numeric(aqi[1])
  
  if (aqi_val <= 100) {
    list(
      Stage = "Stage 0: Baseline Surveillance",
      Severity = "Good to Satisfactory (AQI <= 100)",
      Color = "#00B050",
      Authority_Action = "Enforce routine mechanized road sweeping and strict green cover maintenance.",
      Citizen_Advisory = "Air quality is favorable. Normal outdoor exercise and recreational activities are encouraged."
    )
  } else if (aqi_val <= 200) {
    list(
      Stage = "Stage 1: Moderate Alert",
      Severity = "Moderate (AQI 101 - 200)",
      Color = "#EAB308",
      Authority_Action = "Strictly penalize open biomass and municipal solid waste burning; inspect construction sites.",
      Citizen_Advisory = "Sensitive individuals with chronic respiratory ailments should limit intense prolonged outdoor exertion."
    )
  } else if (aqi_val <= 300) {
    list(
      Stage = "Stage 2: Poor Air Quality (GRAP Stage I)",
      Severity = "Poor (AQI 201 - 300)",
      Color = "#F97316",
      Authority_Action = "Deploy anti-smog water sprinklers; enforce diesel genset bans; intensify traffic bottleneck decongestion.",
      Citizen_Advisory = "Reduce prolonged morning outdoor jogging. Wear particulate-filtering N95 respirators near traffic arteries."
    )
  } else if (aqi_val <= 400) {
    list(
      Stage = "Stage 3: Very Poor Air Quality (GRAP Stage II)",
      Severity = "Very Poor (AQI 301 - 400)",
      Color = "#EF4444",
      Authority_Action = "Halt private construction earthworks; prohibit non-essential commercial diesel truck entry.",
      Citizen_Advisory = "Avoid outdoor strenuous activity. Use indoor HEPA air purifiers; keep windows closed during thermal inversions."
    )
  } else {
    list(
      Stage = "Stage 4: Severe+ Emergency (GRAP Stage III & IV)",
      Severity = "Severe+ Emergency (AQI > 400)",
      Color = "#7030A0",
      Authority_Action = "Implement odd-even vehicular rationing; mandate 50% work-from-home across public/private sectors; close primary schools.",
      Citizen_Advisory = "Critical Health Hazard. Children, elderly, and those with cardiovascular or lung disease must stay indoors."
    )
  }
}
