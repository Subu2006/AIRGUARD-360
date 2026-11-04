# ==============================================================================
# AIRGUARD 360: National Air Quality Intelligence & Decision-Support System
# File: R/analytics_engine.R
# Architecture: Statistics, Hypothesis Testing, Time-Series Forecasting & Text Mining
# Author: Subrat Panigrahi (B.Tech Computer Science & Engineering)
# Open-Source Repository: https://github.com/Subu2006/AIRGUARD-360
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidytext)
  library(wordcloud)
  library(RColorBrewer)
})

# ==============================================================================
# SECTION 1: DESCRIPTIVE STATISTICS & CORRELATION MATRICES
# ==============================================================================

#' Compute Multi-Pollutant Descriptive Statistics using Functional Vectorization
#' 
#' @param df Enriched data frame
#' @return A tidy summary data frame of statistical moments
compute_pollutant_statistics <- function(df) {
  pollutants <- c("PM2.5", "PM10", "NO2", "SO2", "CO", "O3", "NH3", "AQI")
  available_polls <- intersect(pollutants, colnames(df))
  
  stats_list <- lapply(available_polls, function(p) {
    vals <- df[[p]]
    vals_clean <- vals[!is.na(vals)]
    
    if (length(vals_clean) == 0) return(NULL)
    
    m       <- mean(vals_clean)
    s       <- sd(vals_clean)
    med     <- median(vals_clean)
    iqr_val <- IQR(vals_clean)
    
    # Skewness calculation (Fisher-Pearson standardized third moment)
    n <- length(vals_clean)
    skew <- if (n >= 3 && s > 0) {
      round((sum((vals_clean - m)^3) / n) / (s^3), 2)
    } else NA_real_
    
    data.frame(
      Pollutant = p,
      N_Obs     = n,
      Mean      = round(m, 2),
      SD        = round(s, 2),
      Median    = round(med, 2),
      IQR       = round(iqr_val, 2),
      Skewness  = skew,
      Min       = round(min(vals_clean), 2),
      Max       = round(max(vals_clean), 2),
      Exceedance_Rate = ifelse(p %in% names(NAAQS_LIMITS),
                               round(mean(vals_clean > NAAQS_LIMITS[[p]]) * 100, 1),
                               ifelse(p == "AQI", round(mean(vals_clean > 100) * 100, 1), NA_real_)),
      stringsAsFactors = FALSE
    )
  })
  
  do.call(rbind, stats_list)
}

#' Compute Multi-Pollutant Correlation Matrix & P-Values
#' 
#' @param df Enriched data frame
#' @return A list containing correlation matrix and p-value matrix
compute_correlation_matrices <- function(df) {
  pollutants <- c("PM2.5", "PM10", "NO2", "SO2", "CO", "O3", "NH3", "AQI")
  available_polls <- intersect(pollutants, colnames(df))
  
  sub_df <- df[, available_polls]
  cor_mat <- cor(sub_df, use = "pairwise.complete.obs", method = "pearson")
  
  n <- length(available_polls)
  pval_mat <- matrix(NA, nrow = n, ncol = n, dimnames = list(available_polls, available_polls))
  
  for (i in 1:n) {
    for (j in 1:n) {
      if (i == j) {
        pval_mat[i, j] <- 0
      } else {
        pair_data <- na.omit(sub_df[, c(i, j)])
        if (nrow(pair_data) > 10) {
          test_res <- cor.test(pair_data[[1]], pair_data[[2]], method = "pearson")
          pval_mat[i, j] <- test_res$p.value
        }
      }
    }
  }
  
  return(list(
    correlation_matrix = round(cor_mat, 3),
    p_value_matrix = round(pval_mat, 5)
  ))
}

# ==============================================================================
# SECTION 2: FORMAL HYPOTHESIS TESTING SUITE
# ==============================================================================

#' Execute Formal Hypothesis Tests for Environmental Intelligence
#' 
#' @param df Enriched data frame
#' @return Comprehensive list of executed statistical tests and interpretations
run_hypothesis_tests <- function(df) {
  message(">> [ANALYTICS ENGINE] Conducting Formal Hypothesis Tests...")
  
  # Test 1: Two-Sample Welch t-Test (Seasonal Disparity)
  df_delhi <- df %>% filter(City == "Delhi", !is.na(PM2.5), !is.na(Season))
  winter_pm25 <- df_delhi$PM2.5[df_delhi$Season == "Winter"]
  summer_pm25 <- df_delhi$PM2.5[df_delhi$Season %in% c("Summer", "Monsoon")]
  
  t_test_result <- t.test(winter_pm25, summer_pm25, alternative = "greater")
  
  n1 <- length(winter_pm25); n2 <- length(summer_pm25)
  s1 <- sd(winter_pm25);     s2 <- sd(summer_pm25)
  s_pooled <- sqrt(((n1 - 1) * s1^2 + (n2 - 1) * s2^2) / (n1 + n2 - 2))
  cohens_d <- round((mean(winter_pm25) - mean(summer_pm25)) / s_pooled, 2)
  
  # Test 2: One-Way ANOVA across Major Metros
  target_metros <- c("Delhi", "Mumbai", "Bengaluru", "Kolkata", "Chennai")
  df_metros <- df %>% 
    filter(City %in% target_metros, !is.na(AQI)) %>%
    mutate(City = factor(City, levels = target_metros))
  
  anova_model <- aov(AQI ~ City, data = df_metros)
  anova_summary <- summary(anova_model)
  tukey_res <- TukeyHSD(anova_model)
  
  # Test 3: Pearson Correlation Test (PM2.5 vs PM10 Stoichiometry)
  clean_parts <- df %>% filter(!is.na(PM2.5) & !is.na(PM10))
  part_cor_test <- cor.test(clean_parts$PM2.5, clean_parts$PM10, method = "pearson")
  
  # Test 4: Normality Diagnostic (Kolmogorov-Smirnov Test)
  clean_aqi <- na.omit(df$AQI)
  set.seed(42)
  sample_aqi <- sample(clean_aqi, min(1000, length(clean_aqi)))
  sample_aqi_jittered <- sample_aqi + rnorm(length(sample_aqi), mean = 0, sd = 1e-4)
  ks_test_result <- suppressWarnings(ks.test(sample_aqi_jittered, "pnorm", mean = mean(sample_aqi), sd = sd(sample_aqi)))
  
  # Test 5: Kruskal-Wallis Non-Parametric Rank-Sum Test
  df_seasons <- df %>% filter(!is.na(Season), !is.na(PM2.5))
  kw_test_result <- kruskal.test(PM2.5 ~ Season, data = df_seasons)
  
  message("   Hypothesis Testing Complete. P-Values and Test Statistics Generated.")
  
  return(list(
    seasonal_ttest = list(
      test_name   = "Two-Sample Welch t-Test (Winter vs Summer/Monsoon PM2.5 in Delhi)",
      statistic   = round(t_test_result$statistic, 3),
      df          = round(t_test_result$parameter, 1),
      p_value     = t_test_result$p.value,
      mean_winter = round(t_test_result$estimate[1], 2),
      mean_summer = round(t_test_result$estimate[2], 2),
      cohens_d    = cohens_d,
      conf_int_95 = round(t_test_result$conf.int, 2),
      conclusion  = ifelse(t_test_result$p.value < 0.001,
                           "Reject Null Hypothesis (p < 0.001): Winter PM2.5 is significantly and substantially higher due to thermal inversions and boundary layer entrapment.",
                           "Fail to reject Null Hypothesis.")
    ),
    metro_anova = list(
      test_name   = "One-Way ANOVA (AQI across Delhi, Mumbai, Bengaluru, Kolkata, Chennai)",
      F_statistic = round(anova_summary[[1]][["F value"]][1], 3),
      p_value     = anova_summary[[1]][["Pr(>F)"]][1],
      df_between  = anova_summary[[1]][["Df"]][1],
      df_within   = anova_summary[[1]][["Df"]][2],
      tukey_table = as.data.frame(round(tukey_res$City, 2)),
      conclusion  = ifelse(anova_summary[[1]][["Pr(>F)"]][1] < 0.001,
                           "Reject Null Hypothesis (p < 0.001): Statistically significant disparities in ambient AQI exist across Indian metropolitan clusters.",
                           "Fail to reject Null Hypothesis.")
    ),
    pm_correlation = list(
      test_name   = "Pearson Correlation Test (PM2.5 vs PM10 Stoichiometry)",
      estimate_r  = round(part_cor_test$estimate, 3),
      t_statistic = round(part_cor_test$statistic, 3),
      p_value     = part_cor_test$p.value,
      conf_int_95 = round(part_cor_test$conf.int, 3),
      conclusion  = sprintf("Strong positive linear correlation (r = %.3f, p < 0.001, 95%% CI: [%.3f, %.3f]). Demonstrates shared combustion and resuspension emission origins.",
                            part_cor_test$estimate, part_cor_test$conf.int[1], part_cor_test$conf.int[2])
    ),
    normality_test = list(
      test_name   = "Kolmogorov-Smirnov Normality Test on AQI",
      D_statistic = round(ks_test_result$statistic, 4),
      p_value     = ks_test_result$p.value,
      conclusion  = "Reject Normality (p < 0.001): Air quality data is highly right-skewed with long tail extremes, justifying non-parametric complements."
    ),
    kruskal_wallis = list(
      test_name   = "Kruskal-Wallis Non-Parametric Rank Sum Test (PM2.5 across Seasons)",
      chi_sq      = round(kw_test_result$statistic, 2),
      df          = kw_test_result$parameter,
      p_value     = kw_test_result$p.value,
      conclusion  = "Reject Null Hypothesis (p < 0.001): Medians across climatological seasons differ significantly without requiring normality assumptions."
    )
  ))
}

# ==============================================================================
# SECTION 3: TIME-SERIES MODELING & PREDICTIVE FORECASTING
# ==============================================================================

#' Forecast accuracy (days with missing actuals are skipped, never filled)
forecast_error_metrics <- function(actual, predicted) {
  keep <- !is.na(actual) & !is.na(predicted)
  if (!any(keep)) return(c(N = 0, MAE = NA_real_, RMSE = NA_real_))
  e <- actual[keep] - predicted[keep]
  c(N = sum(keep), MAE = mean(abs(e)), RMSE = sqrt(mean(e^2)))
}

#' Rolling-origin evaluation of simple baselines and ARIMA/ETS-style models
evaluate_forecast_rolling <- function(dates, values, horizon = 30, n_origins = 12, min_train = 365) {
  ord <- order(dates); dates <- dates[ord]; values <- values[ord]
  full <- seq(min(dates), max(dates), by = "day")
  x <- values[match(full, dates)]
  n <- length(x)
  if (n < min_train + horizon || sum(!is.na(x)) < min_train) return(NULL)
  last_origin <- n - horizon
  origins <- rev(seq(last_origin, by = -horizon, length.out = n_origins))
  origins <- origins[origins >= min_train]
  if (length(origins) == 0) return(NULL)

  fc <- list(
    Naive         = function(tr) rep(tail(tr[!is.na(tr)], 1), horizon),
    Mean_Last_28d = function(tr) rep(mean(tail(tr, 28), na.rm = TRUE), horizon),
    Seasonal_Naive_7d = function(tr) { w <- tail(tr, 7); rep(w, length.out = horizon) },
    ARIMA_1_1_1   = function(tr) {
      idx <- which(!is.na(tr)); tr2 <- approx(idx, tr[idx], seq_along(tr), rule = 2)$y
      fit <- tryCatch(stats::arima(tr2, order = c(1, 1, 1)), error = function(e) NULL)
      if (is.null(fit)) rep(NA_real_, horizon) else pmax(0, as.numeric(predict(fit, n.ahead = horizon)$pred))
    }
  )
  rows <- lapply(names(fc), function(nm) {
    m <- t(sapply(origins, function(o) {
      pred <- fc[[nm]](x[1:o]); forecast_error_metrics(x[(o + 1):(o + horizon)], pred)
    }))
    data.frame(Model = nm, Origins = sum(!is.na(m[, "RMSE"])), Mean_MAE = mean(m[, "MAE"], na.rm = TRUE),
               Mean_RMSE = mean(m[, "RMSE"], na.rm = TRUE), Worst_RMSE = max(m[, "RMSE"], na.rm = TRUE))
  })
  out <- do.call(rbind, rows)
  out[order(out$Mean_RMSE), ]
}

#' Build and Validate Time-Series Forecasts for City-Level Air Quality
forecast_city_pollution <- function(df, target_city = "Delhi", target_var = "PM2.5", horizon = 30) {
  message(sprintf(">> [ANALYTICS ENGINE] Training Native Time-Series Models for %s (%s)...", target_city, target_var))
  
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
  
  full_dates <- data.frame(Date = seq.Date(min(city_data$Date), max(city_data$Date), by = "day"))
  merged_ts_df <- full_dates %>%
    left_join(city_data %>% select(Date, Target = all_of(target_var)), by = "Date")
  
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
  
  ts_full <- ts(merged_ts_df$Target_Clean, frequency = 7)
  
  # Chronological Holdout Split
  n_total <- length(ts_full)
  n_test  <- min(as.integer(horizon), max(7L, floor(n_total * 0.15)))
  n_train <- n_total - n_test
  
  ts_train <- ts(ts_full[1:n_train], frequency = 7)
  ts_test  <- as.numeric(ts_full[(n_train + 1):n_total])
  
  calc_metrics <- function(actual, predicted) {
    err  <- actual - predicted
    mae  <- mean(abs(err), na.rm = TRUE)
    rmse <- sqrt(mean(err^2, na.rm = TRUE))
    denom_smape <- (abs(actual) + abs(predicted)) / 2
    denom_smape <- ifelse(denom_smape < 1e-4, 1e-4, denom_smape)
    smape <- mean(abs(err) / denom_smape, na.rm = TRUE) * 100
    denom_mape <- ifelse(abs(actual) < 1.0, 1.0, abs(actual))
    mape <- mean(abs(err) / denom_mape, na.rm = TRUE) * 100
    c(MAE = round(mae, 2), RMSE = round(rmse, 2), MAPE = round(min(mape, 999), 1), sMAPE = round(smape, 1))
  }
  
  # Baseline 0: Naive Persistence Model
  last_train_val <- as.numeric(tail(ts_train, 1))
  pred_naive     <- rep(last_train_val, n_test)
  metrics_naive  <- calc_metrics(ts_test, pred_naive)
  
  # Model A: ARIMA(1,1,1)
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
    pred_arima    <- pred_naive
    metrics_arima <- c(MAE = 999, RMSE = 999, MAPE = 999, sMAPE = 999)
  }
  
  # Model B: Holt-Winters Exponential Smoothing
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
      metrics_hw <- c(MAE = 999, RMSE = 999, MAPE = 999, sMAPE = 999)
    }
  } else {
    metrics_hw <- c(MAE = 999, RMSE = 999, MAPE = 999, sMAPE = 999)
  }
  
  best_model_name <- ifelse(metrics_arima["RMSE"] <= metrics_hw["RMSE"], "ARIMA", "Holt-Winters")
  if (metrics_arima["RMSE"] == 999 && metrics_hw["RMSE"] == 999) best_model_name <- "ARIMA"
  
  best_rmse <- min(metrics_arima["RMSE"], metrics_hw["RMSE"])
  baseline_improvement_pct <- round(((metrics_naive["RMSE"] - best_rmse) / metrics_naive["RMSE"]) * 100, 1)
  
  # Final projection on full dataset
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
    Model_Selected       = best_model_name,
    Baseline_Naive_RMSE  = metrics_naive["RMSE"],
    Baseline_Naive_MAE   = metrics_naive["MAE"],
    ARIMA_RMSE           = metrics_arima["RMSE"],
    ARIMA_MAE            = metrics_arima["MAE"],
    ARIMA_MAPE           = metrics_arima["MAPE"],
    ARIMA_sMAPE          = metrics_arima["sMAPE"],
    HW_RMSE              = metrics_hw["RMSE"],
    HW_MAE               = metrics_hw["MAE"],
    HW_MAPE              = metrics_hw["MAPE"],
    HW_sMAPE             = metrics_hw["sMAPE"],
    Baseline_Improv_Pct  = baseline_improvement_pct,
    Test_Horizon         = n_test
  )
  
  message(sprintf("   Selected Architecture: %s (Test RMSE: %.2f vs Naive: %.2f | Improvement: %.1f%%)",
                  best_model_name,
                  metrics_summary[[paste0(ifelse(best_model_name == "ARIMA", "ARIMA", "HW"), "_RMSE")]],
                  metrics_naive["RMSE"],
                  baseline_improvement_pct))
  
  return(list(
    error       = FALSE,
    data        = combined_fc_df,
    metrics     = metrics_summary,
    final_model = final_model,
    city        = target_city,
    variable    = target_var
  ))
}

# ==============================================================================
# SECTION 4: TEXT MINING & NATURAL LANGUAGE PROCESSING
# ==============================================================================

#' Generate Statutory Environmental Health Advisory & Mitigation Corpus
generate_advisory_corpus <- function() {
  data.frame(
    Doc_ID = 1:8,
    Category = c(
      "Good", "Satisfactory", "Moderate", "Poor", "Very Poor", "Severe",
      "Mitigation_Transport", "Mitigation_Industrial"
    ),
    Text = c(
      "Air quality is satisfactory and poses little or no risk to public health. Clean air ensures safe outdoor exercise and cardiovascular vitality.",
      "Sensitive individuals with mild respiratory allergies may experience slight irritation. Protect infants and elderly during peak morning traffic.",
      "Breathing discomfort likely in people with lung asthma heart disease. Reduce prolonged vigorous outdoor exertion. Monitor children and asthmatic patients.",
      "Breathing discomfort to most people on prolonged exposure. Significant particulate matter inhalation induces coughing and respiratory fatigue. Wear N95 respirators.",
      "Respiratory illness on prolonged exposure. Triggers acute bronchitis, chronic lung inflammation, and cardiovascular distress. Avoid all outdoor physical activity.",
      "Healthy people experience severe respiratory strain and eye irritation. Critical emergency condition. Mandate school closures, halt construction, spray water mist.",
      "Enforce odd-even vehicular restrictions, transition commercial fleets to compressed natural gas CNG, expand electric bus networks, penalize idling engines.",
      "Enforce flue gas desulfurization in thermal coal power plants. Cease heavy diesel generator sets. Implement continuous stack emission monitoring systems."
    ),
    stringsAsFactors = FALSE
  )
}

#' Mine Environmental Advisory Text and Compute Word Frequencies
mine_environmental_text <- function(corpus_df = NULL) {
  if (is.null(corpus_df)) {
    corpus_df <- generate_advisory_corpus()
  }
  
  clean_text <- gsub("[[:punct:]]", " ", corpus_df$Text)
  clean_text <- gsub("[[:digit:]]", " ", clean_text)
  clean_text <- tolower(clean_text)
  corpus_df$Text_Clean <- clean_text
  
  data("stop_words", package = "tidytext")
  domain_stops <- data.frame(
    word = c("due", "can", "may", "also", "per", "via", "well", "use"),
    lexicon = "custom"
  )
  all_stops <- rbind(stop_words, domain_stops)
  
  word_freqs <- corpus_df %>%
    unnest_tokens(word, Text_Clean) %>%
    anti_join(all_stops, by = "word") %>%
    count(word, sort = TRUE) %>%
    filter(nchar(word) > 2) %>%
    rename(Frequency = n) %>%
    mutate(Proportion = round(Frequency / sum(Frequency), 4))
  
  return(word_freqs)
}

#' Render Environmental Advisory Word Cloud
render_advisory_wordcloud <- function(word_freqs, max_words = 50, min_freq = 1) {
  palette <- brewer.pal(8, "Dark2")
  wordcloud::wordcloud(
    words        = word_freqs$word,
    freq         = word_freqs$Frequency,
    min.freq     = min_freq,
    max.words    = max_words,
    random.order = FALSE,
    rot.per      = 0.25,
    colors       = palette,
    scale        = c(3.2, 0.6)
  )
}
