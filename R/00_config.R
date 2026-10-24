# ==============================================================================
# AIRGUARD 360: Environmental Intelligence & Decision-Support System
# File: R/00_config.R
# Purpose: Central configuration, standard thresholds, color palettes, and themes
# INT232 Syllabus Mapping: Unit I (Environment), Unit VI (Visualization Themes)
# ==============================================================================

# Ensure standard options
options(stringsAsFactors = FALSE, scipen = 999)

# ------------------------------------------------------------------------------
# 1. Official CPCB National Ambient Air Quality Standards (NAAQS) - 24-hr Limits
# Source: Central Pollution Control Board, Gazette of India, 2009
# ------------------------------------------------------------------------------
NAAQS_LIMITS <- list(
  PM2.5   = 60,   # ug/m3
  PM10    = 100,  # ug/m3
  NO2     = 80,   # ug/m3
  SO2     = 80,   # ug/m3
  CO      = 2.0,  # mg/m3
  O3      = 100,  # ug/m3
  NH3     = 400,  # ug/m3
  Benzene = 5.0   # ug/m3 (Annual)
)

# ------------------------------------------------------------------------------
# 2. Official CPCB National Air Quality Index (NAQI) Breakpoints & Colors
# ------------------------------------------------------------------------------
AQI_CATEGORIES <- data.frame(
  Bucket = factor(
    c("Good", "Satisfactory", "Moderate", "Poor", "Very Poor", "Severe"),
    levels = c("Good", "Satisfactory", "Moderate", "Poor", "Very Poor", "Severe"),
    ordered = TRUE
  ),
  Min_AQI = c(0, 51, 101, 201, 301, 401),
  Max_AQI = c(50, 100, 200, 300, 400, 500),
  Color = c("#00B050", "#92D050", "#FFFF00", "#FF7C80", "#C00000", "#7030A0"),
  TextColor = c("#FFFFFF", "#1E1E1E", "#1E1E1E", "#1E1E1E", "#FFFFFF", "#FFFFFF"),
  Health_Advisory = c(
    "Minimal health impact.",
    "Minor breathing discomfort to sensitive people.",
    "Breathing discomfort to people with asthma, lungs and heart diseases.",
    "Breathing discomfort to most people on prolonged exposure.",
    "Respiratory illness on prolonged exposure; significant effect on vulnerable groups.",
    "Affects healthy people and seriously impacts those with existing conditions."
  )
)

# Quick lookup vector for category colors
AQI_COLOR_MAP <- setNames(AQI_CATEGORIES$Color, AQI_CATEGORIES$Bucket)

# ------------------------------------------------------------------------------
# 3. Application Color Palette (Professional Dark & Clean Aesthetic)
# ------------------------------------------------------------------------------
THEME_COLORS <- list(
  primary       = "#1F77B4",
  secondary     = "#2CA02C",
  danger        = "#D62728",
  warning       = "#FF7F0E",
  info          = "#17BECF",
  dark_bg       = "#0F172A",
  card_bg       = "#1E293B",
  card_border   = "#334155",
  text_main     = "#F8FAFC",
  text_muted    = "#94A3B8",
  accent        = "#38BDF8"
)

# ------------------------------------------------------------------------------
# 4. Custom ggplot2 Academic Publication Theme
# ------------------------------------------------------------------------------
theme_airguard <- function(base_size = 12, is_dark = FALSE) {
  if (is_dark) {
    ggplot2::theme_minimal(base_size = base_size) +
      ggplot2::theme(
        plot.background  = ggplot2::element_rect(fill = THEME_COLORS$dark_bg, color = NA),
        panel.background = ggplot2::element_rect(fill = THEME_COLORS$dark_bg, color = NA),
        panel.grid.major = ggplot2::element_line(color = "#1E293B", linewidth = 0.5),
        panel.grid.minor = ggplot2::element_blank(),
        text             = ggplot2::element_text(color = THEME_COLORS$text_main),
        axis.text        = ggplot2::element_text(color = THEME_COLORS$text_muted),
        axis.title       = ggplot2::element_text(color = THEME_COLORS$text_main, face = "bold"),
        plot.title       = ggplot2::element_text(color = THEME_COLORS$text_main, face = "bold", size = base_size * 1.2),
        plot.subtitle    = ggplot2::element_text(color = THEME_COLORS$text_muted, size = base_size * 0.95),
        legend.background = ggplot2::element_rect(fill = THEME_COLORS$dark_bg, color = NA),
        legend.text      = ggplot2::element_text(color = THEME_COLORS$text_main),
        legend.title     = ggplot2::element_text(color = THEME_COLORS$text_main, face = "bold"),
        strip.background = ggplot2::element_rect(fill = THEME_COLORS$card_bg, color = NA),
        strip.text       = ggplot2::element_text(color = THEME_COLORS$text_main, face = "bold")
      )
  } else {
    ggplot2::theme_minimal(base_size = base_size) +
      ggplot2::theme(
        panel.grid.minor = ggplot2::element_blank(),
        panel.grid.major = ggplot2::element_line(color = "#E2E8F0", linewidth = 0.5),
        axis.title       = ggplot2::element_text(face = "bold", color = "#1E293B"),
        axis.text        = ggplot2::element_text(color = "#475569"),
        plot.title       = ggplot2::element_text(face = "bold", size = base_size * 1.2, color = "#0F172A"),
        plot.subtitle    = ggplot2::element_text(size = base_size * 0.95, color = "#64748B"),
        legend.title     = ggplot2::element_text(face = "bold"),
        strip.text       = ggplot2::element_text(face = "bold")
      )
  }
}
