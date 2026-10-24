# ==============================================================================
# AIRGUARD 360: Figure Generation Suite
# File: generate_figures.R
# Purpose: Generate high-resolution publication-quality figures for Report & Presentation
# ==============================================================================

message(">> [FIGURE ENGINE] Generating Publication-Quality Figures...")

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(wordcloud)
  library(RColorBrewer)
})

source("R/00_config.R")
source("R/07_visualizations.R")

dir.create("outputs/figures", showWarnings = FALSE, recursive = TRUE)

df_city_daily <- readRDS("data/processed/airguard_enriched.rds")
cor_mat_df    <- read.csv("outputs/tables/correlation_matrix.csv", row.names = 1)
cor_matrix    <- as.matrix(cor_mat_df)
word_freqs    <- read.csv("outputs/tables/advisory_word_frequencies.csv", stringsAsFactors = FALSE)

# 1. Figure 1: Temporal Trajectory for Delhi
p1 <- plot_temporal_trend(df_city_daily, target_city = "Delhi", target_var = "PM2.5", 
                          start_date = "2019-01-01", end_date = "2020-07-01", interactive = FALSE)
ggsave("outputs/figures/fig1_temporal_trajectory_delhi.png", p1, width = 9, height = 5, dpi = 300)

# 2. Figure 2: Top Hotspots Ranking
p2 <- plot_city_rankings(df_city_daily, target_var = "AQI", top_n = 10, interactive = FALSE)
ggsave("outputs/figures/fig2_hotspots_ranking.png", p2, width = 8, height = 5, dpi = 300)

# 3. Figure 3: Stoichiometric Scatter Plot
p3 <- plot_pollutant_scatter(df_city_daily, target_city = "Delhi", var_x = "PM10", var_y = "PM2.5", interactive = FALSE)
ggsave("outputs/figures/fig3_stoichiometry_scatter.png", p3, width = 8, height = 5.5, dpi = 300)

# 4. Figure 4: Correlation Heatmap
p4 <- plot_correlation_heatmap(cor_matrix, interactive = FALSE)
ggsave("outputs/figures/fig4_correlation_heatmap.png", p4, width = 7.5, height = 6, dpi = 300)

# 5. Figure 5: Bollinger Volatility Bands
p5 <- plot_bollinger_bands(df_city_daily, target_city = "Delhi", 
                           start_date = "2019-06-01", end_date = "2020-03-01", interactive = FALSE)
ggsave("outputs/figures/fig5_bollinger_volatility_bands.png", p5, width = 9.5, height = 5, dpi = 300)

# 6. Figure 6: Advisory Word Cloud
png("outputs/figures/fig6_advisory_wordcloud.png", width = 1800, height = 1500, res = 300)
palette <- brewer.pal(8, "Dark2")
wordcloud::wordcloud(
  words = word_freqs$word,
  freq = word_freqs$Frequency,
  min.freq = 1,
  max.words = 45,
  random.order = FALSE,
  rot.per = 0.25,
  colors = palette,
  scale = c(3.2, 0.7)
)
dev.off()

# 7. Figure 7: National CAAQMS Geographic Station Network Map
if (file.exists("outputs/tables/station_geo_summary.csv")) {
  station_geo <- read.csv("outputs/tables/station_geo_summary.csv", stringsAsFactors = FALSE)
  p7 <- plot_station_map(station_geo, interactive = FALSE)
  ggsave("outputs/figures/fig7_station_network_map.png", p7, width = 8, height = 8, dpi = 300)
}

# 8. Figure 8: Seasonal PM2.5 Concentration Disparity Boxplot
p8 <- ggplot(df_city_daily %>% filter(!is.na(Season), !is.na(PM2.5)), aes(x = Season, y = PM2.5, fill = Season)) +
  geom_boxplot(outlier.alpha = 0.2, outlier.size = 1) +
  geom_hline(yintercept = 60, color = "#DC2626", linetype = "dashed", linewidth = 0.8) +
  scale_fill_brewer(palette = "Set2") +
  coord_cartesian(ylim = c(0, 350)) +
  labs(
    title = "Seasonal PM2.5 Concentration Disparity Across Monitored Indian Cities",
    subtitle = "Red Dashed Line: NAAQS 24-hr Standard (60 ug/m3) | Demonstrates Severe Winter Thermal Inversions",
    x = "Climatological Season", y = "PM2.5 Concentration (ug/m3)"
  ) +
  theme_airguard() +
  theme(legend.position = "none")
ggsave("outputs/figures/fig8_seasonal_pollution_disparity.png", p8, width = 8.5, height = 5, dpi = 300)

# 9. Figure 9: Predictive Forecast Ribbon Plot
if (file.exists("outputs/tables/forecast_delhi_pm25.rds")) {
  fc_delhi <- readRDS("outputs/tables/forecast_delhi_pm25.rds")
  p9 <- plot_forecast_chart(fc_delhi, interactive = FALSE)
  ggsave("outputs/figures/fig9_forecast_delhi.png", p9, width = 9, height = 5, dpi = 300)
}

message(">> [FIGURE ENGINE] All 9 publication figures generated in outputs/figures/")
