# ==============================================================================
# AIRGUARD 360: Environmental Intelligence & Decision-Support System
# File: R/00_config.R
# Purpose: Central configuration, standard thresholds, color palettes, and themes
# INT232 Syllabus Mapping: Unit I (Environment), Unit VI (Visualization Themes)
# ==============================================================================

# Ensure standard options
options(stringsAsFactors = FALSE, scipen = 999)

# ------------------------------------------------------------------------------
# 1. Project Metadata and Provenance Declarations
# ------------------------------------------------------------------------------
PROJECT_NAME        <- "AIRGUARD 360"
PROJECT_SUBTITLE    <- "An Interactive Air Quality Intelligence, Multi-Pollutant Analytics & Environmental Decision-Support System"
DATA_PROVENANCE     <- "Central Pollution Control Board (CPCB), India (Distributed via Kaggle historical archive)"
HISTORICAL_COVERAGE <- "2015-01-01 to 2020-07-01"
SYSTEM_DISCLAIMER   <- "Historical Retrospective System: Developed for academic research, data exploration, and simulated decision support under INT232. Does not provide live telemetry, statutory GRAP directives, or medical counsel."

# Standard Color Palette for UI and Plots
THEME_COLORS <- list(
  primary   = "#1F77B4",
  secondary = "#10B981",
  success   = "#059669",
  warning   = "#F59E0B",
  danger    = "#EF4444",
  dark      = "#0F172A",
  light     = "#F8FAFC",
  muted     = "#94A3B8"
)

# ------------------------------------------------------------------------------
# 2. Official CPCB National Ambient Air Quality Standards (NAAQS) - 24-hr Limits
# Source: Central Pollution Control Board, Gazette of India, 2009
# ------------------------------------------------------------------------------
NAAQS_LIMITS <- list(
  PM2.5   = 60,   # ug/m3 (24-hr)
  PM10    = 100,  # ug/m3 (24-hr)
  NO2     = 80,   # ug/m3 (24-hr)
  SO2     = 80,   # ug/m3 (24-hr)
  CO      = 2.0,  # mg/m3 (8-hr short-term screening comparator)
  O3      = 100,  # ug/m3 (8-hr short-term screening comparator)
  NH3     = 400,  # ug/m3 (24-hr)
  Benzene = 5.0   # ug/m3 (Annual)
)

# ------------------------------------------------------------------------------
# 3. Official CPCB National Air Quality Index (NAQI) Breakpoints & Colors
# Source: CPCB National Air Quality Index Guidelines, 2014-2015
# ------------------------------------------------------------------------------
AQI_CATEGORIES <- data.frame(
  Bucket = c("Good", "Satisfactory", "Moderate", "Poor", "Very Poor", "Severe"),
  Min_AQI = c(0, 51, 101, 201, 301, 401),
  Max_AQI = c(50, 100, 200, 300, 400, 500),
  Severity_Rank = 1:6,
  Color_Hex = c("#00B050", "#92D050", "#EAB308", "#F97316", "#EF4444", "#7030A0"),
  stringsAsFactors = FALSE
)

# Named vector for ggplot2 and plotly scale mapping
AQI_COLOR_PALETTE <- setNames(AQI_CATEGORIES$Color_Hex, AQI_CATEGORIES$Bucket)
AQI_COLOR_MAP     <- AQI_COLOR_PALETTE

# Climatological season palette (Indian Meteorological Department definitions)
SEASON_PALETTE <- c(
  "Winter"       = "#3B82F6",  # Cool Blue
  "Summer"       = "#F59E0B",  # Warm Amber
  "Monsoon"      = "#10B981",  # Rainy Emerald Green
  "Post-Monsoon" = "#8B5CF6"   # Transition Purple
)

# ------------------------------------------------------------------------------
# 4. Standard Publication Plotting Theme (ggplot2)
# ------------------------------------------------------------------------------
theme_airguard <- function(base_size = 12, is_dark = FALSE) {
  if (is_dark) {
    ggplot2::theme_minimal(base_size = base_size) +
      ggplot2::theme(
        plot.background   = ggplot2::element_rect(fill = "#0F172A", color = NA),
        panel.background  = ggplot2::element_rect(fill = "#0F172A", color = NA),
        text              = ggplot2::element_text(color = "#F8FAFC", family = "sans"),
        axis.text         = ggplot2::element_text(color = "#94A3B8"),
        axis.title        = ggplot2::element_text(color = "#F1F5F9", face = "bold"),
        panel.grid.major  = ggplot2::element_line(color = "#1E293B", linewidth = 0.4),
        panel.grid.minor  = ggplot2::element_line(color = "#1E293B", linewidth = 0.2),
        plot.title        = ggplot2::element_text(face = "bold", size = base_size * 1.25, color = "#FFFFFF"),
        plot.subtitle     = ggplot2::element_text(size = base_size * 0.95, color = "#94A3B8", margin = ggplot2::margin(b = 10)),
        legend.position   = "bottom",
        legend.background = ggplot2::element_rect(fill = "#0F172A", color = NA),
        legend.text       = ggplot2::element_text(color = "#E2E8F0"),
        strip.text        = ggplot2::element_text(color = "#FFFFFF", face = "bold")
      )
  } else {
    ggplot2::theme_minimal(base_size = base_size) +
      ggplot2::theme(
        plot.background   = ggplot2::element_rect(fill = "#FFFFFF", color = NA),
        panel.background  = ggplot2::element_rect(fill = "#FFFFFF", color = NA),
        text              = ggplot2::element_text(color = "#1E293B", family = "sans"),
        axis.text         = ggplot2::element_text(color = "#475569"),
        axis.title        = ggplot2::element_text(color = "#0F172A", face = "bold"),
        panel.grid.major  = ggplot2::element_line(color = "#F1F5F9", linewidth = 0.5),
        panel.grid.minor  = ggplot2::element_blank(),
        plot.title        = ggplot2::element_text(face = "bold", size = base_size * 1.2, color = "#0F172A"),
        plot.subtitle     = ggplot2::element_text(size = base_size * 0.9, color = "#64748B", margin = ggplot2::margin(b = 10)),
        legend.position   = "bottom",
        legend.background = ggplot2::element_blank(),
        legend.text       = ggplot2::element_text(color = "#334155"),
        strip.text        = ggplot2::element_text(color = "#0F172A", face = "bold")
      )
  }
}
