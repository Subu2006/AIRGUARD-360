# Run from project root:  Rscript -e "testthat::test_dir('tests/testthat')"
library(testthat)
library(dplyr)

root <- local({
  d <- normalizePath(getwd())
  while (!file.exists(file.path(d, "R", "config.R")) && dirname(d) != d) d <- dirname(d)
  d
})

for (f in c("R/config.R", "R/analytics_engine.R", "R/visualization_engine.R")) {
  source(file.path(root, f))
}

test_that("advisory handles NA, NaN, NULL, out-of-range", {
  expect_true(grepl("Insufficient|No data", generate_environmental_advisory(NA)$Stage))
  expect_true(grepl("Insufficient|No data", generate_environmental_advisory(NaN)$Stage))
  expect_true(grepl("Insufficient|No data", generate_environmental_advisory(numeric(0))$Stage))
  expect_true(grepl("Out of range|Severe", generate_environmental_advisory(2049)$Stage))
  expect_match(generate_environmental_advisory(350)$Stage, "Very Poor")
})

test_that("AQI band boundaries follow NAQI", {
  expect_match(generate_environmental_advisory(100)$Severity, "Good")
  expect_match(generate_environmental_advisory(150)$Severity, "Moderate")
  expect_match(generate_environmental_advisory(350)$Severity, "Very Poor")
  expect_match(generate_environmental_advisory(450)$Severity, "Severe")
})

test_that("forecast metrics skip missing actuals and handle empty input", {
  m <- forecast_error_metrics(c(1, NA, 3), c(2, 2, 2))
  expect_equal(unname(m["N"]), 2)
  expect_equal(unname(m["MAE"]), 1)
  expect_true(is.na(forecast_error_metrics(c(NA, NA), c(1, 2))["MAE"]))
})

test_that("rolling evaluation returns NULL with insufficient history and ranks models otherwise", {
  d <- as.Date("2018-01-01") + 0:99
  expect_null(evaluate_forecast_rolling(d, rnorm(100)))
  set.seed(1)
  d2 <- as.Date("2016-01-01") + 0:1199
  r <- evaluate_forecast_rolling(d2, 60 + 20 * sin(2 * pi * (0:1199) / 365) + rnorm(1200, 0, 5), n_origins = 6)
  expect_true(all(c("Naive", "ARIMA_1_1_1") %in% r$Model))
  expect_false(is.unsorted(r$Mean_RMSE))
})
