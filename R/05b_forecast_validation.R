# ==============================================================================
# AIRGUARD 360 - R/05b_forecast_validation.R
# Purpose: Leakage-free, baseline-referenced forecast evaluation (rolling-origin).
# Why: The original holdout (R/05_forecasting.R) interpolated gaps across the whole series
#      BEFORE splitting, scored one 30-day window only, chose the model on that same window,
#      and had no naive baseline. This module fixes those issues.
# NOTE: Written without an R runtime available; run tests/testthat before relying on it.
# ==============================================================================

#' Forecast accuracy (days with missing actuals are skipped, never filled)
forecast_error_metrics <- function(actual, predicted) {
  keep <- !is.na(actual) & !is.na(predicted)
  if (!any(keep)) return(c(N = 0, MAE = NA_real_, RMSE = NA_real_))
  e <- actual[keep] - predicted[keep]
  c(N = sum(keep), MAE = mean(abs(e)), RMSE = sqrt(mean(e^2)))
}

#' Rolling-origin evaluation of simple baselines and ARIMA/ETS-style models
#'
#' @param dates Date vector; @param values numeric (NA allowed; NOT interpolated)
#' @param horizon forecast horizon in days; @param n_origins number of rolling origins
#' @param min_train minimum observed training days
#' @return data.frame(Model, Origins, Mean_MAE, Mean_RMSE, Worst_RMSE) or NULL if too little data
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
      # interpolate ONLY inside the training window (no future information)
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
