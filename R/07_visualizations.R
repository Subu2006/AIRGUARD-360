# ==============================================================================
# AIRGUARD 360: Environmental Intelligence & Decision-Support System
# File: R/07_visualizations.R
# Purpose: Comprehensive Basic & Advanced Visualizations (ggplot2 & Plotly)
# INT232 Syllabus Mapping: Unit VI (Basic: Scatter, Line, Bar, Pie/Donut;
#                                  Advanced: Heat Map, Bollinger Bands; Plotly)
# ==============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(plotly)
  library(dplyr)
  library(scales)
})

# Source theme if not already in environment
if (!exists("theme_airguard")) {
  source("R/00_config.R")
}

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

# ------------------------------------------------------------------------------
# 1. Basic Visualizations: Temporal Trend Line Chart
# ------------------------------------------------------------------------------
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
  
  # Ensure target variable has at least some valid non-NA values
  valid_vals <- sub_df[[target_var]][!is.na(sub_df[[target_var]])]
  if (length(valid_vals) == 0) {
    if (interactive) {
      return(plot_empty_message(sprintf("All %s readings for %s are unrecorded/NA.", target_var, target_city)))
    } else {
      return(ggplot() + annotate("text", x = 1, y = 1, label = "All readings NA", color = "#64748B") + theme_void())
    }
  }
  
  # Determine 7-day Moving Average column safely
  ma_col <- paste0(target_var, "_MA7")
  if (!(ma_col %in% colnames(sub_df))) {
    # Compute on the fly if not present in dataframe
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

# ------------------------------------------------------------------------------
# 2. Basic Visualizations: Bar Chart of Location Rankings (Hotspots / EVI)
# ------------------------------------------------------------------------------
plot_city_rankings <- function(df, target_var = "AQI", top_n = 10, interactive = TRUE) {
  if (target_var == "EVI") {
    # If EVI is requested, pull directly from EVI table or compute
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

# ------------------------------------------------------------------------------
# 3. Basic Visualizations: Stoichiometric Scatter Plot
# ------------------------------------------------------------------------------
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
  
  # Compute correlation for informative subtitle
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
  
  # Add regression line only if enough points exist
  if (nrow(sub_df) >= 3) {
    p <- p + geom_smooth(method = "lm", color = "#1E293B", linetype = "solid", se = TRUE, linewidth = 0.8)
  }
  
  if (interactive) {
    ggplotly(p, tooltip = c("x", "y", "color"))
  } else {
    p
  }
}

# ------------------------------------------------------------------------------
# 4. Basic Visualizations: Donut Chart of CPCB AQI Buckets
# ------------------------------------------------------------------------------
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
      Color = AQI_COLOR_MAP[as.character(AQI_Bucket)]
    )
  
  # Fallback color if any mapping missing
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

# ------------------------------------------------------------------------------
# 5. Advanced Visualizations: Correlation Heat Map (Unit VI)
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# 6. Advanced Visualizations: Bollinger Bands on Air Quality Volatility (Unit VI)
# ------------------------------------------------------------------------------
plot_bollinger_bands <- function(df, target_city = "Delhi", target_var = "PM2.5", 
                                 start_date = NULL, end_date = NULL, interactive = TRUE) {
  sub_df <- df %>% filter(as.character(City) == as.character(target_city))
  
  if (!is.null(start_date)) sub_df <- sub_df %>% filter(Date >= as.Date(start_date))
  if (!is.null(end_date))   sub_df <- sub_df %>% filter(Date <= as.Date(end_date))
  
  if (!(target_var %in% colnames(sub_df))) target_var <- "PM2.5"
  
  # Check if precomputed Bollinger columns exist, otherwise compute dynamically
  bb_upper_col <- paste0(target_var, "_BB_Upper")
  bb_lower_col <- paste0(target_var, "_BB_Lower")
  bb_mid_col   <- paste0(target_var, "_BB_Mid")
  spike_col    <- paste0(target_var, "_Bollinger_Spike")
  
  if (!(bb_upper_col %in% colnames(sub_df))) {
    # Dynamically calculate 20-day MA and SD
    sub_df <- sub_df %>% arrange(Date)
    raw_vals <- sub_df[[target_var]]
    mid <- as.numeric(stats::filter(raw_vals, rep(1/20, 20), sides = 1))
    # Rolling SD
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
  
  # Filter to rows with valid data
  sub_df <- sub_df %>% filter(!is.na(.data[[target_var]]), !is.na(.data[[bb_upper_col]]))
  
  if (nrow(sub_df) == 0) {
    if (interactive) {
      return(plot_empty_message(sprintf("Insufficient continuous %s data for %s to establish Bollinger Envelopes.", target_var, target_city)))
    } else {
      return(ggplot() + annotate("text", x = 1, y = 1, label = "Insufficient data", color = "#64748B") + theme_void())
    }
  }
  
  p <- ggplot(sub_df, aes(x = Date)) +
    # Volatility Envelope Ribbon
    geom_ribbon(aes(ymin = .data[[bb_lower_col]], ymax = .data[[bb_upper_col]]), fill = "#93C5FD", alpha = 0.3) +
    # 20-Day Moving Average
    geom_line(aes(y = .data[[bb_mid_col]]), color = "#2563EB", linewidth = 0.9, linetype = "solid") +
    # Upper Band (+2 SD)
    geom_line(aes(y = .data[[bb_upper_col]]), color = "#EF4444", linewidth = 0.6, linetype = "dashed") +
    # Lower Band (-2 SD)
    geom_line(aes(y = .data[[bb_lower_col]]), color = "#10B981", linewidth = 0.6, linetype = "dashed") +
    # Actual Pollutant Line
    geom_line(aes(y = .data[[target_var]]), color = "#1E293B", linewidth = 0.5, alpha = 0.6) +
    # Highlight Volatility Spikes
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

# ------------------------------------------------------------------------------
# 7. Advanced Visualizations: Predictive Forecast Ribbon Plot (CO5)
# ------------------------------------------------------------------------------
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
    # 95% Interval Ribbon
    geom_ribbon(data = fc_data %>% filter(Type == "Forecast"),
                aes(ymin = Lower_95, ymax = Upper_95), fill = "#CBD5E1", alpha = 0.6) +
    # 80% Interval Ribbon
    geom_ribbon(data = fc_data %>% filter(Type == "Forecast"),
                aes(ymin = Lower_80, ymax = Upper_80), fill = "#93C5FD", alpha = 0.6) +
    # Main Trajectory Line
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

# ------------------------------------------------------------------------------
# 8. Geographic Visualizations: National Monitoring Network Map
# ------------------------------------------------------------------------------
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

