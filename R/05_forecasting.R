# ==============================================================================
# AIRGUARD 360: Environmental Intelligence & Decision-Support System
# File: R/05_forecasting.R
# Purpose: Predictive Analytics using Base R Time Series (ARIMA & Holt-Winters)
# INT232 Syllabus Mapping: CO5 (Predictive Analytics Fundamentally), Unit IV (Math/Stats)
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
})

#' Build and Validate Time-Series Forecasts for City-Level Air Quality
#' 
#' Uses native Base R stats::arima and stats::HoltWinters for maximum reproducibility,
#' robustness, and zero external DLL dependency.
#' 
#' @param df Enriched city-daily data frame
#' @param target_city Name of the city to model (default: "Delhi")
#' @param target_var Column name to forecast (default: "PM2.5")
#' @param horizon Forecast horizon in days (default: 30)
#' @return A list containing forecast data, evaluation metrics, and fitted models
forecast_city_pollution <- function(df, target_city = "Delhi", target_var = "PM2.5", horizon = 30) {
  message(sprintf(">> [AIRGUARD 360] Training Native Time-Series Models for %s (%s)...", target_city, target_var))
  
  # 1. Filter and prepare regular daily series
  city_data <- df %>%
    filter(as.character(City) == as.character(target_city), !is.na(Date)) %>%
    arrange(Date)
  
  if (nrow(city_data) == 0 || !(target_var %in% colnames(city_data))) {
    return(list(
      error = TRUE,
      message = sprintf("No historical records available for %s (%s).", target_city, target_var),
      city = target_city,
      variable = target_var
    ))
  }
  
  valid_count <- sum(!is.na(city_data[[target_var]]))
  if (valid_count < 30) {
    return(list(
      error = TRUE,
      message = sprintf("Limited continuous observations for %s (%s): %d valid days (minimum 30 required for time-series modeling).", 
                        target_city, target_var, valid_count),
      city = target_city,
      variable = target_var
    ))
  }
  
  # Ensure continuous daily timeline with linear interpolation
  full_dates <- data.frame(Date = seq.Date(min(city_data$Date), max(city_data$Date), by = "day"))
  merged_ts_df <- full_dates %>%
    left_join(city_data %>% select(Date, Target = all_of(target_var)), by = "Date")
  
  # Base R zoo-free linear interpolation
  target_vals <- merged_ts_df$Target
  na_idx <- which(is.na(target_vals))
  if (length(na_idx) > 0) {
    valid_idx <- which(!is.na(target_vals))
    if (length(valid_idx) >= 2) {
      target_vals <- approx(x = valid_idx, y = target_vals[valid_idx], xout = seq_along(target_vals), rule = 2)$y
    } else {
      target_vals[is.na(target_vals)] <- mean(target_vals, na.rm = TRUE)
    }
  }
  merged_ts_df$Target_Clean <- pmax(0, target_vals)
  
  # Base R ts object with 7-day weekly frequency
  ts_full <- ts(merged_ts_df$Target_Clean, frequency = 7)
  
  # ----------------------------------------------------------------------------
  # 2. Out-of-Sample Validation (Train-Test Split)
  # ----------------------------------------------------------------------------
  n_total <- length(ts_full)
  n_test  <- min(as.integer(horizon), max(7L, floor(n_total * 0.15)))
  n_train <- n_total - n_test
  
  ts_train <- ts(ts_full[1:n_train], frequency = 7)
  ts_test  <- as.numeric(ts_full[(n_train + 1):n_total])
  
  calc_metrics <- function(actual, predicted) {
    err  <- actual - predicted
    mae  <- mean(abs(err), na.rm = TRUE)
    rmse <- sqrt(mean(err^2, na.rm = TRUE))
    denom <- ifelse(actual <= 0, 1e-3, actual)
    mape <- mean(abs(err / denom), na.rm = TRUE) * 100
    c(MAE = round(mae, 2), RMSE = round(rmse, 2), MAPE = round(min(mape, 999), 1))
  }
  
  # Model A: Base R Autoregressive Integrated Moving Average
  fit_arima_train <- tryCatch({
    stats::arima(ts_train, order = c(1, 1, 1))
  }, error = function(e1) {
    tryCatch({
      stats::arima(ts_train, order = c(1, 0, 0))
    }, error = function(e2) {
      tryCatch({
        stats::arima(ts_train, order = c(0, 1, 1))
      }, error = function(e3) NULL)
    })
  })
  
  if (!is.null(fit_arima_train)) {
    pred_arima_obj <- predict(fit_arima_train, n.ahead = n_test)
    pred_arima     <- pmax(0, as.numeric(pred_arima_obj$pred))
    metrics_arima  <- calc_metrics(ts_test, pred_arima)
  } else {
    pred_arima    <- rep(mean(ts_train), n_test)
    metrics_arima <- c(MAE = 999, RMSE = 999, MAPE = 999)
  }
  
  # Model B: Base R Holt-Winters Exponential Smoothing
  fit_hw_train <- tryCatch({
    stats::HoltWinters(ts_train, gamma = FALSE)
  }, error = function(e1) {
    tryCatch({
      stats::HoltWinters(ts_train, beta = FALSE, gamma = FALSE)
    }, error = function(e2) NULL)
  })
  
  if (!is.null(fit_hw_train)) {
    pred_hw_obj <- tryCatch(predict(fit_hw_train, n.ahead = n_test), error = function(e) NULL)
    if (!is.null(pred_hw_obj)) {
      pred_hw    <- pmax(0, as.numeric(pred_hw_obj))
      metrics_hw <- calc_metrics(ts_test, pred_hw)
    } else {
      metrics_hw <- c(MAE = 999, RMSE = 999, MAPE = 999)
    }
  } else {
    metrics_hw <- c(MAE = 999, RMSE = 999, MAPE = 999)
  }
  
  best_model_name <- ifelse(metrics_arima["RMSE"] <= metrics_hw["RMSE"], "ARIMA", "Holt-Winters")
  if (metrics_arima["RMSE"] == 999 && metrics_hw["RMSE"] == 999) best_model_name <- "ARIMA"
  
  # ----------------------------------------------------------------------------
  # 3. Final Model Training on Full Data & Future Projection
  # ----------------------------------------------------------------------------
  horizon_int <- as.integer(horizon)
  
  if (best_model_name == "ARIMA" || is.null(fit_hw_train)) {
    final_model <- tryCatch({
      stats::arima(ts_full, order = c(1, 1, 1))
    }, error = function(e1) {
      tryCatch({
        stats::arima(ts_full, order = c(1, 0, 0))
      }, error = function(e2) {
        stats::arima(ts_full, order = c(0, 1, 0))
      })
    })
    
    final_pred  <- predict(final_model, n.ahead = horizon_int)
    fc_mean     <- pmax(0, as.numeric(final_pred$pred))
    fc_se       <- as.numeric(final_pred$se)
    
    fc_lower_80 <- pmax(0, fc_mean - (1.28 * fc_se))
    fc_upper_80 <- fc_mean + (1.28 * fc_se)
    fc_lower_95 <- pmax(0, fc_mean - (1.96 * fc_se))
    fc_upper_95 <- fc_mean + (1.96 * fc_se)
  } else {
    final_model <- tryCatch({
      stats::HoltWinters(ts_full, gamma = FALSE)
    }, error = function(e) {
      stats::HoltWinters(ts_full, beta = FALSE, gamma = FALSE)
    })
    
    final_pred_mat <- tryCatch({
      predict(final_model, n.ahead = horizon_int, prediction.interval = TRUE, level = 0.95)
    }, error = function(e) NULL)
    
    if (!is.null(final_pred_mat)) {
      fc_mean     <- pmax(0, as.numeric(final_pred_mat[, "fit"]))
      fc_lower_95 <- pmax(0, as.numeric(final_pred_mat[, "lwr"]))
      fc_upper_95 <- pmax(0, as.numeric(final_pred_mat[, "upr"]))
      fc_lower_80 <- pmax(0, fc_mean - 0.7 * (fc_mean - fc_lower_95))
      fc_upper_80 <- fc_mean + 0.7 * (fc_upper_95 - fc_mean)
    } else {
      # Fallback to ARIMA
      final_model <- stats::arima(ts_full, order = c(1, 0, 0))
      final_pred  <- predict(final_model, n.ahead = horizon_int)
      fc_mean     <- pmax(0, as.numeric(final_pred$pred))
      fc_se       <- as.numeric(final_pred$se)
      fc_lower_80 <- pmax(0, fc_mean - (1.28 * fc_se))
      fc_upper_80 <- fc_mean + (1.28 * fc_se)
      fc_lower_95 <- pmax(0, fc_mean - (1.96 * fc_se))
      fc_upper_95 <- fc_mean + (1.96 * fc_se)
    }
  }
  
  # Construct Projection Table
  last_date <- max(merged_ts_df$Date)
  future_dates <- seq.Date(last_date + 1, by = "day", length.out = horizon_int)
  
  forecast_df <- data.frame(
    Date     = future_dates,
    Forecast = round(fc_mean, 1),
    Lower_80 = round(fc_lower_80, 1),
    Upper_80 = round(fc_upper_80, 1),
    Lower_95 = round(fc_lower_95, 1),
    Upper_95 = round(fc_upper_95, 1),
    Type     = "Forecast"
  )
  
  historical_df <- data.frame(
    Date     = tail(merged_ts_df$Date, 90),
    Forecast = round(tail(merged_ts_df$Target_Clean, 90), 1),
    Lower_80 = NA_real_,
    Upper_80 = NA_real_,
    Lower_95 = NA_real_,
    Upper_95 = NA_real_,
    Type     = "Observed"
  )
  
  combined_fc_df <- rbind(historical_df, forecast_df)
  
  metrics_summary <- data.frame(
    Model_Selected = best_model_name,
    ARIMA_RMSE     = metrics_arima["RMSE"],
    ARIMA_MAE      = metrics_arima["MAE"],
    ARIMA_MAPE     = metrics_arima["MAPE"],
    HW_RMSE        = metrics_hw["RMSE"],
    HW_MAE         = metrics_hw["MAE"],
    HW_MAPE        = metrics_hw["MAPE"],
    Test_Horizon   = n_test
  )
  
  message(sprintf("   Best Model: %s (Test RMSE: %.2f, MAE: %.2f, MAPE: %.1f%%)",
                  best_model_name,
                  metrics_summary[[paste0(ifelse(best_model_name == "ARIMA", "ARIMA", "HW"), "_RMSE")]],
                  metrics_summary[[paste0(ifelse(best_model_name == "ARIMA", "ARIMA", "HW"), "_MAE")]],
                  metrics_summary[[paste0(ifelse(best_model_name == "ARIMA", "ARIMA", "HW"), "_MAPE")]]))
  
  return(list(
    error       = FALSE,
    data        = combined_fc_df,
    metrics     = metrics_summary,
    final_model = final_model,
    city        = target_city,
    variable    = target_var
  ))
}
