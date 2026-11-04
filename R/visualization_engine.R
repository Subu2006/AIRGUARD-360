# ==============================================================================
# AIRGUARD 360: National Air Quality Intelligence & Decision-Support System
# File: R/visualization_engine.R
# Architecture: Visualization Suite (ggplot2, Plotly, Leaflet GIS) & Decision Engines
# Author: Subrat Panigrahi (B.Tech Computer Science & Engineering)
# Open-Source Repository: https://github.com/Subu2006/AIRGUARD-360
# ==============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(plotly)
  library(dplyr)
  library(scales)
  library(leaflet)
  library(zoo)
})

# Source theme and configuration if not in environment
if (!exists("theme_airguard")) {
  source("R/config.R")
}

# ==============================================================================
# SECTION 1: CORE VISUALIZATION HELPERS & INTERACTIVE WIDGETS
# ==============================================================================

#' Helper to generate an elegant Plotly empty-state placeholder
plot_empty_message <- function(message_text = "No observations available for the selected filters.") {
  plot_ly() %>%
    layout(
      xaxis = list(visible = FALSE, showgrid = FALSE),
      yaxis = list(visible = FALSE, showgrid = FALSE),
      annotations = list(
        list(
          text = paste0("<b>", message_text, "</b>"),
          xref = "paper", yref = "paper",
          x = 0.5, y = 0.5,
          showarrow = FALSE,
          font = list(size = 14, color = "#64748B")
        )
      ),
      margin = list(t = 20, b = 20, l = 20, r = 20)
    )
}

#' Calibrated CPCB Statutory Air Quality Speedometer / Gauge
plot_aqi_gauge <- function(aqi_val, city_name = "Selected City") {
  if (is.null(aqi_val) || is.na(aqi_val) || is.nan(aqi_val)) {
    return(plot_empty_message("No AQI reading available."))
  }
  
  val <- min(500, max(0, round(as.numeric(aqi_val), 1)))
  
  tier_col <- if (val <= 50) "#00B050" 
              else if (val <= 100) "#92D050" 
              else if (val <= 200) "#EAB308" 
              else if (val <= 300) "#F97316" 
              else if (val <= 400) "#EF4444" 
              else "#7030A0"
              
  tier_name <- if (val <= 50) "Good" 
               else if (val <= 100) "Satisfactory" 
               else if (val <= 200) "Moderate" 
               else if (val <= 300) "Poor" 
               else if (val <= 400) "Very Poor" 
               else "Severe"

  plot_ly(
    type = "indicator",
    mode = "gauge+number",
    value = val,
    title = list(text = paste0("<b>", city_name, " Ambient AQI</b><br><span style='font-size:12px;color:", tier_col, ";font-weight:bold;'>", tier_name, "</span>"), font = list(size = 13)),
    gauge = list(
      axis = list(range = list(0, 500), tickwidth = 1, tickcolor = "#475569"),
      bar = list(color = tier_col, thickness = 0.3),
      bgcolor = "#F8FAFC",
      borderwidth = 1,
      bordercolor = "#E2E8F0",
      steps = list(
        list(range = c(0, 50), color = "#DCFCE7"),
        list(range = c(50, 100), color = "#FEF9C3"),
        list(range = c(100, 200), color = "#FEF08A"),
        list(range = c(200, 300), color = "#FED7AA"),
        list(range = c(300, 400), color = "#FECACA"),
        list(range = c(400, 500), color = "#E9D5FF")
      ),
      threshold = list(
        line = list(color = "#DC2626", width = 3),
        thickness = 0.75,
        value = 300
      )
    )
  ) %>%
    layout(
      margin = list(t = 40, b = 20, l = 25, r = 25),
      font = list(family = "Inter, sans-serif")
    )
}

# ==============================================================================
# SECTION 2: TEMPORAL TRENDS, RANKINGS & STOICHIOMETRY
# ==============================================================================

#' Temporal Trend Line Chart with Moving Average and Statutory Thresholds
plot_temporal_trend <- function(df, target_city = "Delhi", target_var = "PM2.5", 
                                start_date = NULL, end_date = NULL, interactive = TRUE) {
  sub_df <- df %>% filter(as.character(City) == as.character(target_city))
  
  if (!is.null(start_date)) sub_df <- sub_df %>% filter(Date >= as.Date(start_date))
  if (!is.null(end_date))   sub_df <- sub_df %>% filter(Date <= as.Date(end_date))
  
  if (nrow(sub_df) == 0 || !(target_var %in% colnames(sub_df))) {
    if (interactive) {
      return(plot_empty_message(sprintf("No %s observations recorded for %s in the selected period.", target_var, target_city)))
    } else {
      return(ggplot() + annotate("text", x = 1, y = 1, label = "No data available", color = "#64748B") + theme_void())
    }
  }
  
  valid_vals <- sub_df[[target_var]][!is.na(sub_df[[target_var]])]
  if (length(valid_vals) == 0) {
    if (interactive) {
      return(plot_empty_message(sprintf("All %s readings for %s are unrecorded/NA.", target_var, target_city)))
    } else {
      return(ggplot() + annotate("text", x = 1, y = 1, label = "All readings NA", color = "#64748B") + theme_void())
    }
  }
  
  ma_col <- paste0(target_var, "_MA7")
  if (!(ma_col %in% colnames(sub_df))) {
    sub_df[[ma_col]] <- round(stats::filter(sub_df[[target_var]], rep(1/7, 7), sides = 1), 1)
  }
  
  limit_val <- NAAQS_LIMITS[[target_var]]
  
  p <- ggplot(sub_df, aes(x = Date, y = .data[[target_var]])) +
    geom_line(color = "#94A3B8", alpha = 0.5, linewidth = 0.5) +
    geom_line(aes(y = .data[[ma_col]]), color = THEME_COLORS$primary, linewidth = 1.0, na.rm = TRUE) +
    labs(
      title = sprintf("%s Concentration Trajectory: %s", target_var, target_city),
      subtitle = "Grey: Raw Daily Readings | Blue: 7-Day Moving Average | Red Dashed: NAAQS 24-hr Standard",
      x = "Date", y = sprintf("%s Concentration", target_var)
    ) +
    theme_airguard()
  
  if (!is.null(limit_val)) {
    p <- p + geom_hline(yintercept = limit_val, color = THEME_COLORS$danger, linetype = "dashed", linewidth = 0.8)
  }
  
  if (interactive) {
    ggplotly(p, tooltip = c("x", "y"))
  } else {
    p
  }
}

#' Bar Chart of Location Rankings (Hotspots / EVI)
plot_city_rankings <- function(df, target_var = "AQI", top_n = 10, interactive = TRUE) {
  if (target_var == "EVI") {
    if (file.exists("outputs/tables/hotspot_vulnerability_ranking.csv")) {
      hotspots <- read.csv("outputs/tables/hotspot_vulnerability_ranking.csv", stringsAsFactors = FALSE)
      ranking_df <- hotspots %>%
        slice_head(n = top_n) %>%
        select(City, Mean_Val = EVI_Score) %>%
        mutate(City = factor(City, levels = rev(City)))
    } else {
      target_var <- "AQI"
    }
  }
  
  if (target_var != "EVI") {
    if (!(target_var %in% colnames(df))) target_var <- "AQI"
    ranking_df <- df %>%
      group_by(City) %>%
      summarise(Mean_Val = mean(.data[[target_var]], na.rm = TRUE), .groups = "drop") %>%
      filter(!is.na(Mean_Val) & !is.nan(Mean_Val)) %>%
      arrange(desc(Mean_Val)) %>%
      slice_head(n = top_n) %>%
      mutate(City = factor(City, levels = rev(City)))
  }
  
  if (nrow(ranking_df) == 0) {
    if (interactive) return(plot_empty_message("No ranking data available."))
    return(ggplot() + annotate("text", x = 1, y = 1, label = "No data") + theme_void())
  }
  
  label_title <- ifelse(target_var == "EVI", "Environmental Vulnerability Index (EVI)", sprintf("Mean %s", target_var))
  
  p <- ggplot(ranking_df, aes(x = Mean_Val, y = City, fill = Mean_Val)) +
    geom_col(width = 0.7, show.legend = FALSE) +
    scale_fill_gradient(low = "#F59E0B", high = "#EF4444") +
    geom_text(aes(label = round(Mean_Val, 1)), hjust = -0.15, size = 3.5, fontface = "bold", color = "#1E293B") +
    labs(
      title = sprintf("Top %d Hotspots by %s", min(top_n, nrow(ranking_df)), label_title),
      x = label_title, y = ""
    ) +
    theme_airguard() +
    theme(panel.grid.major.y = element_blank())
  
  if (interactive) {
    ggplotly(p, tooltip = c("x", "y"))
  } else {
    p
  }
}

#' Stoichiometric Scatter Plot (PM2.5 vs PM10)
plot_pollutant_scatter <- function(df, target_city = "Delhi", var_x = "PM10", var_y = "PM2.5", 
                                   start_date = NULL, end_date = NULL, interactive = TRUE) {
  sub_df <- df %>% 
    filter(as.character(City) == as.character(target_city))
  
  if (!is.null(start_date)) sub_df <- sub_df %>% filter(Date >= as.Date(start_date))
  if (!is.null(end_date))   sub_df <- sub_df %>% filter(Date <= as.Date(end_date))
  
  if (!(var_x %in% colnames(sub_df)) || !(var_y %in% colnames(sub_df))) {
    if (interactive) return(plot_empty_message("Selected variables are not available in the dataset."))
    return(ggplot() + annotate("text", x = 1, y = 1, label = "Variables not found") + theme_void())
  }
  
  sub_df <- sub_df %>% filter(!is.na(.data[[var_x]]), !is.na(.data[[var_y]]))
  
  if (nrow(sub_df) == 0) {
    if (interactive) {
      return(plot_empty_message(sprintf("No simultaneous %s & %s readings for %s.", var_x, var_y, target_city)))
    } else {
      return(ggplot() + annotate("text", x = 1, y = 1, label = "No data") + theme_void())
    }
  }
  
  r_val <- round(cor(sub_df[[var_x]], sub_df[[var_y]], use = "complete.obs"), 3)
  
  p <- ggplot(sub_df, aes(x = .data[[var_x]], y = .data[[var_y]])) +
    geom_point(aes(color = Season), alpha = 0.6, size = 2) +
    scale_color_brewer(palette = "Set1") +
    labs(
      title = sprintf("Particulate Stoichiometry: %s vs %s (%s)", var_y, var_x, target_city),
      subtitle = sprintf("Pearson r = %.3f | Fitted Ordinary Least Squares (OLS) Regression", r_val),
      x = sprintf("%s Concentration", var_x), y = sprintf("%s Concentration", var_y)
    ) +
    theme_airguard()
  
  if (nrow(sub_df) >= 3) {
    p <- p + geom_smooth(method = "lm", color = "#1E293B", linetype = "solid", se = TRUE, linewidth = 0.8)
  }
  
  if (interactive) {
    ggplotly(p, tooltip = c("x", "y", "color"))
  } else {
    p
  }
}

#' Donut Chart of CPCB AQI Category Distribution
plot_aqi_donut <- function(df, target_city = "Delhi") {
  sub_df <- df %>% 
    filter(as.character(City) == as.character(target_city), !is.na(AQI_Bucket))
  
  if (nrow(sub_df) == 0) {
    return(plot_empty_message(sprintf("No categorized AQI records for %s in this timeframe.", target_city)))
  }
  
  cat_counts <- sub_df %>%
    count(AQI_Bucket) %>%
    mutate(
      Percentage = round((n / sum(n)) * 100, 1),
      Color = if (exists("AQI_COLOR_PALETTE")) AQI_COLOR_PALETTE[as.character(AQI_Bucket)] else "#0284C7"
    )
  
  cat_counts$Color[is.na(cat_counts$Color)] <- "#94A3B8"
  
  plot_ly(
    cat_counts,
    labels = ~AQI_Bucket,
    values = ~n,
    type = "pie",
    hole = 0.6,
    textinfo = "label+percent",
    marker = list(colors = ~Color),
    hoverinfo = "text",
    text = ~paste(AQI_Bucket, "<br>Days:", n, "<br>Share:", Percentage, "%")
  ) %>%
    layout(
      title = list(text = sprintf("<b>AQI Severity Distribution: %s</b>", target_city), font = list(size = 14)),
      showlegend = TRUE,
      margin = list(t = 40, b = 20, l = 20, r = 20)
    )
}

# ==============================================================================
# SECTION 3: ADVANCED VISUALIZATIONS (CORRELATION, BOLLINGER, FORECAST)
# ==============================================================================

#' Correlation Heat Map
plot_correlation_heatmap <- function(cor_matrix, interactive = TRUE) {
  if (is.null(cor_matrix) || nrow(cor_matrix) == 0) {
    if (interactive) return(plot_empty_message("Correlation matrix unavailable."))
    return(ggplot() + annotate("text", x = 1, y = 1, label = "No matrix") + theme_void())
  }
  
  cor_df <- as.data.frame(as.table(cor_matrix))
  colnames(cor_df) <- c("Pollutant1", "Pollutant2", "Correlation")
  cor_df$Correlation <- round(as.numeric(cor_df$Correlation), 2)
  
  p <- ggplot(cor_df, aes(x = Pollutant1, y = Pollutant2, fill = Correlation)) +
    geom_tile(color = "white", linewidth = 0.5) +
    geom_text(aes(label = sprintf("%.2f", Correlation)), color = "black", size = 3.5, fontface = "bold") +
    scale_fill_gradient2(low = "#3B82F6", mid = "#F8FAFC", high = "#EF4444", midpoint = 0, limit = c(-1, 1), na.value = "#CBD5E1") +
    labs(
      title = "Multi-Pollutant Pearson Correlation Matrix",
      subtitle = "Values quantify collinearity, shared emissions and atmospheric stoichiometry",
      x = "", y = ""
    ) +
    theme_airguard() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  if (interactive) {
    ggplotly(p, tooltip = c("x", "y", "fill"))
  } else {
    p
  }
}

#' Bollinger Bands on Air Quality Volatility
plot_bollinger_bands <- function(df, target_city = "Delhi", target_var = "PM2.5", 
                                 start_date = NULL, end_date = NULL, interactive = TRUE) {
  sub_df <- df %>% filter(as.character(City) == as.character(target_city))
  
  if (!is.null(start_date)) sub_df <- sub_df %>% filter(Date >= as.Date(start_date))
  if (!is.null(end_date))   sub_df <- sub_df %>% filter(Date <= as.Date(end_date))
  
  if (!(target_var %in% colnames(sub_df))) target_var <- "PM2.5"
  
  bb_upper_col <- paste0(target_var, "_BB_Upper")
  bb_lower_col <- paste0(target_var, "_BB_Lower")
  bb_mid_col   <- paste0(target_var, "_BB_Mid")
  spike_col    <- paste0(target_var, "_Bollinger_Spike")
  
  if (!(bb_upper_col %in% colnames(sub_df))) {
    sub_df <- sub_df %>% arrange(Date)
    raw_vals <- sub_df[[target_var]]
    mid <- as.numeric(stats::filter(raw_vals, rep(1/20, 20), sides = 1))
    n <- length(raw_vals)
    r_sd <- rep(NA_real_, n)
    for (i in 20:n) {
      w <- raw_vals[(i - 19):i]
      w_clean <- w[!is.na(w)]
      if (length(w_clean) >= 12) r_sd[i] <- sd(w_clean)
    }
    sub_df[[bb_mid_col]]   <- round(mid, 1)
    sub_df[[bb_upper_col]] <- round(mid + (2 * r_sd), 1)
    sub_df[[bb_lower_col]] <- round(pmax(0, mid - (2 * r_sd)), 1)
    sub_df[[spike_col]]    <- ifelse(!is.na(raw_vals) & !is.na(sub_df[[bb_upper_col]]) & raw_vals > sub_df[[bb_upper_col]], 1L, 0L)
  }
  
  sub_df <- sub_df %>% filter(!is.na(.data[[target_var]]), !is.na(.data[[bb_upper_col]]))
  
  if (nrow(sub_df) == 0) {
    if (interactive) {
      return(plot_empty_message(sprintf("Insufficient continuous %s data for %s to establish Bollinger Envelopes.", target_var, target_city)))
    } else {
      return(ggplot() + annotate("text", x = 1, y = 1, label = "Insufficient data", color = "#64748B") + theme_void())
    }
  }
  
  p <- ggplot(sub_df, aes(x = Date)) +
    geom_ribbon(aes(ymin = .data[[bb_lower_col]], ymax = .data[[bb_upper_col]]), fill = "#93C5FD", alpha = 0.3) +
    geom_line(aes(y = .data[[bb_mid_col]]), color = "#2563EB", linewidth = 0.9, linetype = "solid") +
    geom_line(aes(y = .data[[bb_upper_col]]), color = "#EF4444", linewidth = 0.6, linetype = "dashed") +
    geom_line(aes(y = .data[[bb_lower_col]]), color = "#10B981", linewidth = 0.6, linetype = "dashed") +
    geom_line(aes(y = .data[[target_var]]), color = "#1E293B", linewidth = 0.5, alpha = 0.6) +
    geom_point(data = sub_df %>% filter(.data[[spike_col]] == 1),
               aes(y = .data[[target_var]]), color = "#DC2626", size = 2) +
    labs(
      title = sprintf("%s Volatility Bands (Bollinger Metric): %s", target_var, target_city),
      subtitle = "Blue: 20-Day MA | Red Dashed: Upper Band (+2 SD) | Green: Lower Band | Red Dots: Anomaly Surges",
      x = "Date", y = sprintf("%s Concentration", target_var)
    ) +
    theme_airguard()
  
  if (interactive) {
    ggplotly(p, tooltip = c("x", "y"))
  } else {
    p
  }
}

#' Predictive Forecast Ribbon Plot
plot_forecast_chart <- function(forecast_res, interactive = TRUE) {
  if (is.null(forecast_res)) {
    return(plot_empty_message("Predictive model output unavailable."))
  }
  
  if (isTRUE(forecast_res$error)) {
    return(plot_empty_message(forecast_res$message))
  }
  
  fc_data <- forecast_res$data
  city    <- forecast_res$city
  var     <- forecast_res$variable
  model   <- forecast_res$metrics$Model_Selected
  
  p <- ggplot(fc_data, aes(x = Date, y = Forecast)) +
    geom_ribbon(data = fc_data %>% filter(Type == "Forecast"),
                aes(ymin = Lower_95, ymax = Upper_95), fill = "#CBD5E1", alpha = 0.6) +
    geom_ribbon(data = fc_data %>% filter(Type == "Forecast"),
                aes(ymin = Lower_80, ymax = Upper_80), fill = "#93C5FD", alpha = 0.6) +
    geom_line(aes(color = Type), linewidth = 1.0) +
    scale_color_manual(values = c("Observed" = "#1E293B", "Forecast" = "#2563EB")) +
    labs(
      title = sprintf("30-Day %s Predictive Forecast: %s (Selected: %s)", var, city, model),
      subtitle = "Dark Ribbon: 80% Prediction Interval | Light Ribbon: 95% Interval",
      x = "Date", y = sprintf("%s Concentration", var)
    ) +
    theme_airguard()
  
  if (interactive) {
    ggplotly(p, tooltip = c("x", "y", "color"))
  } else {
    p
  }
}

# ==============================================================================
# SECTION 4: GEOSPATIAL INTELLIGENCE & LEAFLET GIS MAPPING
# ==============================================================================

#' Static / WebGL CAAQMS Station Map
plot_station_map <- function(station_data, interactive = TRUE) {
  if (is.null(station_data) || nrow(station_data) == 0) {
    if (interactive) return(plot_empty_message("Station geographic coordinates unavailable."))
    return(ggplot() + annotate("text", x = 1, y = 1, label = "No map data") + theme_void())
  }
  
  geo_df <- station_data %>%
    filter(!is.na(Latitude), !is.na(Longitude), 
           Latitude >= 6, Latitude <= 38, Longitude >= 68, Longitude <= 98)
  
  if (nrow(geo_df) == 0) {
    if (interactive) return(plot_empty_message("No valid coordinates within India geographic boundaries."))
    return(ggplot() + annotate("text", x = 1, y = 1, label = "No valid coordinates") + theme_void())
  }
  
  if (interactive) {
    g <- list(
      scope = 'asia',
      showland = TRUE,
      landcolor = toRGB("gray95"),
      subunitcolor = toRGB("gray85"),
      countrycolor = toRGB("gray75"),
      countrywidth = 0.5,
      subunitwidth = 0.5,
      lonaxis = list(range = c(68, 98)),
      lataxis = list(range = c(6, 38)),
      resolution = 50
    )
    
    p <- plot_geo(geo_df, lat = ~Latitude, lon = ~Longitude) %>%
      add_markers(
        text = ~paste0("<b>Station:</b> ", StationName, "<br><b>City:</b> ", City, ", ", State, 
                       if ("Mean_AQI" %in% colnames(geo_df)) paste0("<br><b>Mean AQI:</b> ", round(Mean_AQI, 1)) else ""),
        color = if ("Mean_AQI" %in% colnames(geo_df)) ~Mean_AQI else ~City,
        colors = "Reds",
        size = if ("Mean_AQI" %in% colnames(geo_df)) ~pmax(4, Mean_AQI / 25) else 6,
        hoverinfo = "text"
      ) %>%
      layout(
        title = "National Continuous Ambient Air Quality Monitoring Network (CAAQMS)",
        geo = g,
        margin = list(t = 40, b = 10, l = 10, r = 10)
      )
    return(p)
  } else {
    p <- ggplot(geo_df, aes(x = Longitude, y = Latitude)) +
      geom_point(color = THEME_COLORS$primary, size = 2.5, alpha = 0.8) +
      labs(title = "National CAAQMS Station Coordinates across India", x = "Longitude", y = "Latitude") +
      theme_airguard()
    return(p)
  }
}

#' Interactive Leaflet CAAQMS Monitoring Network Map with Multi-Layer Tiles & NAQI Halos
plot_leaflet_station_map <- function(station_data) {
  if (is.null(station_data) || nrow(station_data) == 0) return(NULL)
  
  geo_df <- station_data %>%
    filter(!is.na(Latitude), !is.na(Longitude), 
           Latitude >= 6, Latitude <= 38, Longitude >= 68, Longitude <= 98)
           
  if (nrow(geo_df) == 0) return(NULL)
  
  pal <- colorNumeric(
    palette = c("#10B981", "#EAB308", "#F97316", "#EF4444", "#7E22CE"),
    domain = c(0, 500)
  )
  
  m <- leaflet(geo_df) %>%
    addProviderTiles("CartoDB.Positron", group = "Positron Light") %>%
    addProviderTiles("CartoDB.DarkMatter", group = "Dark OLED") %>%
    addTiles(group = "OpenStreetMap") %>%
    addCircleMarkers(
      lng = ~Longitude, lat = ~Latitude,
      radius = ~scales::rescale(pmin(450, pmax(40, Mean_AQI)), to = c(5, 13)),
      color = ~pal(pmin(500, pmax(0, Mean_AQI))),
      fillColor = ~pal(pmin(500, pmax(0, Mean_AQI))),
      fillOpacity = 0.85,
      weight = 1.5,
      popup = ~paste0(
        "<div style='font-family:Segoe UI, sans-serif; min-width: 190px;'>",
        "<h6 style='margin:0 0 4px 0; font-weight:700; color:#0F172A;'>", StationName, "</h6>",
        "<div style='font-size:11px; color:#64748B; margin-bottom:6px;'>", City, ", ", State, "</div>",
        "<table style='width:100%; font-size:12px; border-collapse:collapse;'>",
        "<tr style='border-bottom:1px solid #E2E8F0;'><td><b>Mean AQI:</b></td><td style='text-align:right; font-weight:bold;'>", round(Mean_AQI, 1), "</td></tr>",
        "<tr style='border-bottom:1px solid #E2E8F0;'><td><b>Peak AQI:</b></td><td style='text-align:right; color:#DC2626; font-weight:bold;'>", round(Peak_AQI, 1), "</td></tr>",
        "<tr style='border-bottom:1px solid #E2E8F0;'><td><b>Mean PM2.5:</b></td><td style='text-align:right;'>", round(Mean_PM25, 1), " µg/m³</td></tr>",
        "<tr><td><b>Observations:</b></td><td style='text-align:right;'>", Total_Observations, "</td></tr>",
        "</table>",
        "</div>"
      ),
      label = ~paste0(StationName, " (AQI: ", round(Mean_AQI, 1), ")")
    ) %>%
    addLayersControl(
      baseGroups = c("Positron Light", "Dark OLED", "OpenStreetMap"),
      options = layersControlOptions(collapsed = FALSE)
    )
    
  return(m)
}

# ==============================================================================
# SECTION 5: MULTI-CITY COMPARISON & STOICHIOMETRIC PROFILES
# ==============================================================================

#' Multi-City Dual Trajectory Comparison Studio
plot_city_comparison <- function(df, city_a = "Delhi", city_b = "Bengaluru", 
                                 target_var = "PM2.5", start_date = NULL, end_date = NULL, 
                                 interactive = TRUE) {
  sub_df <- df %>%
    filter(as.character(City) %in% c(as.character(city_a), as.character(city_b)))
  
  if (!is.null(start_date)) sub_df <- sub_df %>% filter(Date >= as.Date(start_date))
  if (!is.null(end_date))   sub_df <- sub_df %>% filter(Date <= as.Date(end_date))
  
  if (nrow(sub_df) == 0 || !(target_var %in% colnames(sub_df))) {
    if (interactive) return(plot_empty_message("No comparative observations available for selected cities and dates."))
    return(ggplot() + annotate("text", x = 1, y = 1, label = "No data") + theme_void())
  }
  
  sub_df <- sub_df %>%
    group_by(City) %>%
    arrange(Date) %>%
    mutate(
      MA7 = round(zoo::rollapply(.data[[target_var]], width = 7, FUN = mean, fill = NA, align = "right", na.rm = TRUE), 1)
    ) %>%
    ungroup()
  
  limit_val <- NAAQS_LIMITS[[target_var]]
  
  p <- ggplot(sub_df, aes(x = Date, y = MA7, color = City)) +
    geom_line(aes(y = .data[[target_var]], group = City), alpha = 0.25, linewidth = 0.4) +
    geom_line(linewidth = 1.1) +
    scale_color_manual(values = c("#0284C7", "#10B981", "#F59E0B", "#EF4444")) +
    labs(
      title = sprintf("Comparative Trajectory: %s vs %s (%s)", city_a, city_b, target_var),
      subtitle = "Solid lines: 7-Day Moving Average | Faint lines: Raw Daily Readings",
      x = "Date", y = sprintf("%s Concentration", target_var),
      color = "City Hub"
    ) +
    theme_airguard()
  
  if (!is.null(limit_val)) {
    p <- p + geom_hline(yintercept = limit_val, color = "#DC2626", linetype = "dashed", linewidth = 0.7)
  }
  
  if (interactive) {
    ggplotly(p, tooltip = c("x", "y", "color"))
  } else {
    p
  }
}

#' Multi-Pollutant Benchmark Profile (% of NAAQS Standards)
plot_pollutant_profile_bar <- function(df, city_a = "Delhi", city_b = "Bengaluru", interactive = TRUE) {
  criteria_polls <- c("PM2.5", "PM10", "NO2", "SO2", "CO", "O3")
  
  sub_df <- df %>%
    filter(as.character(City) %in% c(as.character(city_a), as.character(city_b)))
  
  if (nrow(sub_df) == 0) {
    if (interactive) return(plot_empty_message("No data available for multi-pollutant profiling."))
    return(ggplot() + annotate("text", x = 1, y = 1, label = "No data") + theme_void())
  }
  
  prof_df <- sub_df %>%
    group_by(City) %>%
    summarise(across(any_of(criteria_polls), ~ mean(.x, na.rm = TRUE)), .groups = "drop") %>%
    tidyr::pivot_longer(cols = -City, names_to = "Pollutant", values_to = "Mean_Concentration") %>%
    mutate(
      NAAQS_Limit = sapply(Pollutant, function(p) ifelse(!is.null(NAAQS_LIMITS[[p]]), NAAQS_LIMITS[[p]], NA_real_)),
      Pct_of_NAAQS = round((Mean_Concentration / NAAQS_Limit) * 100, 1)
    )
  
  p <- ggplot(prof_df, aes(x = Pollutant, y = Pct_of_NAAQS, fill = City)) +
    geom_col(position = position_dodge(width = 0.75), width = 0.65) +
    geom_hline(yintercept = 100, color = "#DC2626", linetype = "dashed", linewidth = 0.8) +
    scale_fill_manual(values = c("#0284C7", "#10B981", "#F59E0B", "#EF4444")) +
    labs(
      title = sprintf("Criteria Pollutant Burden: %s vs %s (%% of CPCB Standard)", city_a, city_b),
      subtitle = "Red Dashed Line = 100% of Statutory NAAQS Benchmark (Values > 100% exceed standard)",
      x = "Atmospheric Parameter", y = "% of 24-hr NAAQS Standard", fill = "City Hub"
    ) +
    theme_airguard()
  
  if (interactive) {
    ggplotly(p, tooltip = c("x", "y", "fill"))
  } else {
    p
  }
}

#' Policy Intervention & Scenario Projection Visualizer
plot_scenario_projection <- function(df, target_city = "Delhi", 
                                     reduction_pct = 25, 
                                     target_var = "PM2.5", 
                                     interactive = TRUE) {
  sub_df <- df %>%
    filter(as.character(City) == as.character(target_city), !is.na(.data[[target_var]])) %>%
    arrange(Date) %>%
    tail(180)
  
  if (nrow(sub_df) == 0) {
    if (interactive) return(plot_empty_message("Insufficient baseline data for scenario projection."))
    return(ggplot() + annotate("text", x = 1, y = 1, label = "No data") + theme_void())
  }
  
  factor_multiplier <- 1 - (reduction_pct / 100)
  sub_df <- sub_df %>%
    mutate(
      Baseline_MA = round(zoo::rollapply(.data[[target_var]], width = 7, FUN = mean, fill = NA, align = "right", na.rm = TRUE), 1),
      Projected_MA = round(Baseline_MA * factor_multiplier, 1)
    )
  
  p <- ggplot(sub_df, aes(x = Date)) +
    geom_ribbon(aes(ymin = Projected_MA, ymax = Baseline_MA), fill = "#10B981", alpha = 0.25) +
    geom_line(aes(y = Baseline_MA, color = "Historical Baseline"), linewidth = 1.0) +
    geom_line(aes(y = Projected_MA, color = "Projected Intervention"), linewidth = 1.1, linetype = "solid") +
    geom_hline(yintercept = NAAQS_LIMITS[[target_var]], color = "#DC2626", linetype = "dashed", linewidth = 0.7) +
    scale_color_manual(values = c("Historical Baseline" = "#64748B", "Projected Intervention" = "#059669")) +
    labs(
      title = sprintf("Policy Simulation: %s Intervention on %s (%s)", target_city, target_var, paste0("-", reduction_pct, "%")),
      subtitle = "Green Shaded Zone: Environmental & Human Exposure Burden Avoided | Red Dashed: NAAQS Limit",
      x = "Date", y = sprintf("%s Concentration (ug/m3)", target_var),
      color = "Trajectory"
    ) +
    theme_airguard()
  
  if (interactive) {
    ggplotly(p, tooltip = c("x", "y", "color"))
  } else {
    p
  }
}

# ==============================================================================
# SECTION 6: DECISION SUPPORT, EVI RANKING, DOSE & SIMULATION MODELS
# ==============================================================================

#' Compute Environmental Vulnerability Index (EVI) for Municipal Hotspot Prioritization
compute_hotspot_priority_index <- function(df) {
  message(">> [DECISION ENGINE] Computing Hotspot Vulnerability Index...")
  
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
      AQI_Span  = max(Mean_AQI) - min(Mean_AQI),
      AQI_Norm  = ifelse(AQI_Span > 0, (Mean_AQI - min(Mean_AQI)) / AQI_Span, 0.5),
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

#' Calculate Inhaled Particulate Dose & Cigarette Equivalents
calculate_inhaled_dose <- function(pm25, age_cohort = "Healthy Adult", activity_level = "Light Walking", hours = 2.0) {
  # Minute ventilation rates (VE in m3/hr)
  ve_table <- list(
    "Child (5-12 yrs)" = c(Resting = 0.35, Walking = 0.80, Strenuous = 1.60),
    "Healthy Adult"    = c(Resting = 0.45, Walking = 1.10, Strenuous = 2.40),
    "Elderly (65+)"    = c(Resting = 0.40, Walking = 0.90, Strenuous = 1.80),
    "Asthmatic / Sensitive" = c(Resting = 0.45, Walking = 0.95, Strenuous = 1.90)
  )
  
  cohort_key <- if (age_cohort %in% names(ve_table)) age_cohort else "Healthy Adult"
  act_key <- if (activity_level %in% c("Resting / Sedentary", "Resting")) "Resting"
             else if (activity_level %in% c("Light Walking", "Walking")) "Walking"
             else "Strenuous"
             
  ve <- ve_table[[cohort_key]][[act_key]]
  
  dose_ug <- round(pm25 * ve * hours, 1)
  # Berkeley Earth empirical equivalence: ~480 ug of PM2.5 ≈ 1 cigarette smoked
  cigs <- round(dose_ug / 480, 2)
  
  ppe_recommendation <- if (pm25 <= 60) "Standard / None required"
                        else if (pm25 <= 120) "Surgical mask recommended for sensitive cohorts"
                        else if (pm25 <= 250) "N95 / FFP2 particulate respirator strongly advised"
                        else "N99 / P100 respirator mandatory; avoid all outdoor exertion"
                        
  list(
    pm25               = pm25,
    ventilation_rate   = ve,
    hours              = hours,
    inhaled_dose_ug    = dose_ug,
    cigarette_equiv    = cigs,
    ppe_recommendation = ppe_recommendation
  )
}

#' Simulate Urban Policy Interventions on Air Quality
simulate_policy_intervention <- function(baseline_aqi, baseline_pm25, 
                                         ev_abate = 20, dust_abate = 25, 
                                         biomass_abate = 40, industry_abate = 15) {
  # CPCB Source Apportionment Empirical Weights for PM2.5 in Indian Metros
  w_ev       <- 0.28  # Vehicular emissions
  w_dust     <- 0.22  # Construction & road dust
  w_biomass  <- 0.25  # Seasonal biomass & stubble
  w_industry <- 0.25  # Industrial stacks & power plants
  
  total_reduction_pct <- (ev_abate * w_ev) + 
                         (dust_abate * w_dust) + 
                         (biomass_abate * w_biomass) + 
                         (industry_abate * w_industry)
  
  projected_pm25 <- round(pmax(10, baseline_pm25 * (1 - (total_reduction_pct / 100))), 1)
  projected_aqi  <- round(pmax(25, baseline_aqi * (1 - (total_reduction_pct * 0.85 / 100))), 1)
  
  clean_days_gained <- round((total_reduction_pct / 100) * 115)
  avoided_hospitalizations <- round((baseline_pm25 - projected_pm25) * 14.5)
  
  list(
    reduction_pct            = round(total_reduction_pct, 1),
    projected_pm25           = projected_pm25,
    projected_aqi            = projected_aqi,
    clean_days_gained        = clean_days_gained,
    avoided_hospitalizations = avoided_hospitalizations
  )
}
