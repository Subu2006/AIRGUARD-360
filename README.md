# AIRGUARD 360: National Air Quality Intelligence, Multi-Pollutant Analytics & Environmental Decision-Support System

[![R](https://img.shields.io/badge/R-4.2.0+-blue.svg)](https://www.r-project.org/)
[![Course](https://img.shields.io/badge/Course-INT232%20Data%20Science%20Toolbox-orange.svg)]()
[![Shiny](https://img.shields.io/badge/Shiny-Interactive%20Enterprise%20App-brightgreen.svg)](https://shiny.posit.co/)
[![Database](https://img.shields.io/badge/Database-SQLite%20Embedded-lightgrey.svg)]()
[![Tests](https://img.shields.io/badge/Tests-8%2F8%20Stages%20Passing%20(100%25)-success.svg)]()
[![Report](https://img.shields.io/badge/Report-52%20Pages%20Word%2FPDF-purple.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![GitHub](https://img.shields.io/badge/GitHub-Repository-black.svg)](https://github.com/Subu2006/AIRGUARD-360)

> **AIRGUARD 360** is an enterprise-grade, 100% native R-based environmental data science platform, interactive intelligence suite, and public health decision-support system. It transforms **108,035 statutory CPCB ambient air quality observations** across India into multi-grain temporal trends, multi-city comparative analytics, policy intervention simulations, personal inhaled dose calculations, formal hypothesis tests, benchmarked predictive time-series forecasts, and evidence-based Graded Response Action Plan (GRAP) advisories.

---

## 1. Executive Summary & Academic Credentials

AIRGUARD 360 was engineered as a flagship capstone application for **INT232: Data Science Toolbox — R Programming** at the Lovely School of Computer Science & Engineering, **Lovely Professional University (LPU)**.

* **Student Candidate:** Subrat Panigrahi (Registration Number: `26143073`, Section: `N1`, Programme: B.Tech Computer Science & Engineering)
* **Faculty Supervisor:** Mr. Jaffar Amin Chacket (Associate Professor, CSE/IT, U.Id: `30453`)
* **Academic Session:** 2025–2026 (Semester: August–January 2026)
* **Underlying Data:** Official Continuous Ambient Air Quality Monitoring Station (CAAQMS) records published by the **Central Pollution Control Board (CPCB)**, Ministry of Environment, Forest and Climate Change (MoEF&CC), Government of India, spanning **January 1, 2015 to July 1, 2020** (230 stations across 26 major metropolitan hubs).

---

## 2. Key Engineering & Feature Highlights

### 🚀 1. Interactive Multi-City Comparison Studio
* Directly contrast pollution trajectories, multi-pollutant stoichiometric profiles, and regulatory compliance between any two Indian metropolitan centers (e.g., **Delhi vs. Bengaluru** or **Mumbai vs. Kolkata**).
* Features synchronized dual-scale Plotly time series and a multi-pollutant criteria burden profile comparing all 6 major pollutants ($PM_{2.5}, PM_{10}, NO_2, SO_2, CO, O_3$) as a percentage of CPCB 24-hr NAAQS limits.

### 🧪 2. Policy Intervention & "What-If" Scenario Simulator
* Dynamic decision-support tool empowering environmental planners and citizens to simulate urban emission abatement strategies.
* Interactive policy sliders:
  * 🚗 **EV Fleet Transition**: 0% to 50% vehicular emission abatement
  * 🏗️ **Fugitive Dust Suppression**: 0% to 50% construction dust control
  * 🌾 **Agricultural Stubble Biomass Management**: 0% to 80% seasonal burning prevention
  * 🏭 **Industrial Stack Scrubbers & Clean Fuel**: 0% to 50% industrial emission control
* Real-time reactive recalculation: Instantly projects new mean AQI, clean air days gained per year, and estimated avoided acute respiratory hospitalizations based on CPCB/WHO epidemiological dose-response functions.

### 🏥 3. Personal Health & Inhaled Particulate Dose Calculator
* Citizen science tool estimating physical particulate intake (micrograms of $PM_{2.5}$) and passive cigarette smoke equivalency (Berkeley Earth model) based on ambient levels and minute ventilation rates ($V_E$).
* Cohort-specific personalization: Children, healthy adults, asthmatic/cardiovascular patients, and senior citizens across resting, light walking, and vigorous exercise durations.
* Recommends respiratory PPE (Cloth vs. Surgical vs. N95/N99) and optimal exercise time windows.

### 📈 4. Predictive Time-Series Forecasting (ARIMA vs. Naive Baseline)
* Native Base R `stats::arima(1, 1, 1)` and `stats::HoltWinters` models evaluated via chronological out-of-sample holdout validation against a persistent **Naive Reference Baseline**.
* For Delhi $PM_{2.5}$, ARIMA achieves an out-of-sample RMSE of **$11.37\ \mu\text{g/m}^3$** versus **$12.70\ \mu\text{g/m}^3$** for the Naive baseline (a **10.5% error reduction** over persistence).

### 🗺️ 5. National Geospatial Intelligence & Leaflet GIS Hotspot Ranking
* Interactive nationwide Leaflet GIS mapping across all 230 continuous monitoring stations with multiple base layers (Positron Light, Dark OLED, StreetMap), color-coded statutory NAQI halos, and interactive station telemetry popups.
* Objective **Environmental Vulnerability Index (EVI)** classifying cities into three operational priority tiers (Tier 1 Critical Emergency, Tier 2 High Vulnerability, Tier 3 Moderate/Baseline).

### 🗄️ 6. Strict Relational Grain Separation & Embedded SQLite
* Factual grain integrity: Rigorously segregates sensor-level telemetry (`fact_station_day`, $N = 108,035$) from city-level territorial aggregates (`fact_city_day`, $N = 29,531$).
* Local SQLite relational database (`data/airguard.sqlite`) with 5 indexed tables interfaced via `DBI` and `RSQLite`.

---

## 3. Real Application Dashboard Interface Showcase

| Executive Command Center | Head-to-Head Comparison Studio |
|:---:|:---:|
| ![Executive Command Center](outputs/figures/fig10_dashboard_overview.png) | ![Comparison Studio](outputs/figures/fig11_dashboard_comparison.png) |
| *Dynamic KPI cards, Plotly trajectory smoother & AQI donut* | *Synchronized dual-city comparison & criteria burden profile* |

| Predictive Forecasting Studio | Enterprise Dark Mode & Policy Simulator |
|:---:|:---:|
| ![Forecasting Studio](outputs/figures/fig12_dashboard_forecast.png) | ![Dark Mode Simulator](outputs/figures/fig13_dashboard_darkmode.png) |
| *ARIMA vs. Naive baseline with 80% and 95% confidence intervals* | *High-contrast UI theme with real-time what-if policy sliders* |

---

## 4. System Directory Structure

```text
AIRGUARD 360/
├── app.R                          # Enterprise interactive Shiny web application (8 modules)
├── run_pipeline.R                 # Master end-to-end execution pipeline script
├── generate_figures.R             # High-resolution (300 DPI) publication figure engine
├── dashboard.Rmd                  # Standalone interactive flexdashboard source
├── dashboard.html                 # Compiled standalone interactive HTML dashboard
├── install_dependencies.R         # Automated CRAN dependency installer & verification
├── DESCRIPTION                    # Standard R package & project dependency manifest
├── AIRGUARD360.Rproj              # RStudio project configuration file
├── LICENSE                        # MIT Open Source License
├── README.md                      # Comprehensive project documentation
├── VIVA_PREPARATION_GUIDE.md      # Comprehensive technical viva & oral defense guide
├── LINKEDIN_POST_KIT.md           # Professional project showcase & publication kit
├── data/
│   ├── airguard.sqlite            # Embedded SQLite relational database (5 tables, indexed)
│   ├── raw/                       # Immutable raw CPCB datasets & reference dimensions
│   │   ├── station_day.csv        # 108,035 station-daily sensor observations
│   │   ├── city_day.csv           # 29,531 city-daily territorial aggregates
│   │   ├── stations.csv           # 230 monitoring station catalogue records
│   │   ├── StationCoordinates.csv # 230 stations with validated latitude & longitude
│   │   ├── Dim_Pollutant.csv      # Criteria pollutants with 24-hr NAAQS limits & units
│   │   └── Dim_AQICategory.csv    # Official CPCB 6-tier NAQI breakpoints & colors
│   └── processed/                 # Cleaned, audited, and feature-engineered RDS artifacts
│       ├── airguard_clean.rds     # Clean station fact joined with spatial dimension
│       ├── airguard_city_daily.rds# Clean city-level daily dataset
│       ├── airguard_enriched.rds  # Enriched city dataset with 45 engineered features
│       └── data_quality_audit.rds # Comprehensive missingness audit report
├── outputs/
│   ├── figures/                   # 14 Publication-quality figures & dashboard screenshots
│   │   ├── fig1_temporal_trajectory_delhi.png
│   │   ├── fig2_hotspots_ranking.png
│   │   ├── fig3_stoichiometry_scatter.png
│   │   ├── fig4_correlation_heatmap.png
│   │   ├── fig5_bollinger_volatility_bands.png
│   │   ├── fig6_advisory_wordcloud.png
│   │   ├── fig7_station_network_map.png
│   │   ├── fig8_seasonal_pollution_disparity.png
│   │   ├── fig9_forecast_delhi.png
│   │   ├── fig10_dashboard_overview.png
│   │   ├── fig11_dashboard_comparison.png
│   │   ├── fig12_dashboard_forecast.png
│   │   ├── fig13_dashboard_darkmode.png
│   │   └── fig14_dashboard_mobile.png
│   └── tables/                    # Analytical tables, ranking CSVs, and model RDS outputs
│       ├── pollutant_summary_stats.csv
│       ├── correlation_matrix.csv
│       ├── hotspot_vulnerability_ranking.csv
│       ├── station_geo_summary.csv
│       ├── advisory_word_frequencies.csv
│       ├── hypothesis_tests_summary.rds
│       ├── forecast_delhi_pm25.rds
│       └── sql_query_outputs.rds
├── R/                             # Modular internal R analytical modules
│   ├── 00_config.R                # System parameters, NAAQS limits, color palettes
│   ├── 01_data_import.R           # Data ingestion & SQLite initialization
│   ├── 02_data_cleaning.R         # Schema validation & grain segregation
│   ├── 03_feature_engineering.R   # Rolling averages, seasonality & volatility
│   ├── 04_statistics.R            # Descriptive moments & formal hypothesis tests
│   ├── 05_forecasting.R           # Native ARIMA & Holt-Winters with Naive baseline
│   ├── 05b_forecast_validation.R  # Rolling-origin forecast cross-validation
│   ├── 06_text_mining.R           # Statutory CPCB advisory text mining & cloud
│   ├── 07_visualizations.R        # Visual analytics suite & Plotly generators
│   ├── 08_decision_support.R      # EVI computation & simulated GRAP rule engine
│   └── 09_sql_queries.R           # Complex DBI/RSQLite query execution
├── reports/
│   ├── AIRGUARD_360_Project_Report.docx # Formatted Word report (48 pages, LPU template)
│   ├── AIRGUARD_360_Project_Report.pdf  # Native PDF report (48 pages, vector figures)
│   ├── AIRGUARD_360_Project_Report.html # Interactive HTML report with floating TOC
│   └── airguard_project_report.Rmd      # Fully reproducible R Markdown source
├── scripts/
│   ├── format_and_export_report.py # Automated Word COM formatter & PDF compiler
│   └── update_report_rmd.py        # Report content synchronization utility
└── tests/
    ├── test_shiny_app.R           # Comprehensive 8-stage automated test matrix
    └── testthat/                  # Formal unit tests for analytical logic
        └── test-core-logic.R
```

---

## 5. INT232 Syllabus & Course Outcome Alignment

| Syllabus Unit | Course Outcome | Concrete AIRGUARD Implementation | Core Project Source |
|---|---|---|---|
| **Unit I: R Installation & Workspace** | CO1: Environment Setup | Package checking, workspace auto-locating, typed constants | `R/00_config.R`, `install_dependencies.R` |
| **Unit II: Data Structures & Vectors** | CO1: Data Foundations | S3 dataframes, factor encoding for CPCB categories, matrices | `R/01_data_cleaning.R`, `R/04_statistics.R` |
| **Unit III: Control Flow & Databases** | CO2: Modular Functions | User-defined functions, DBI/RSQLite embedded star schema | `R/01_data_import.R`, `R/08_decision_support.R` |
| **Unit IV: Data Wrangling & Pipelines** | CO3: Data Manipulation | `dplyr`, `tidyr`, rolling windows (`zoo`), missing data audit | `R/02_data_cleaning.R`, `R/03_feature_engineering.R` |
| **Unit V: Visualization Suite** | CO4: Exploratory Graphics | `ggplot2` grammar of graphics, `plotly` WebGL, text cloud | `R/07_visualizations.R`, `dashboard.Rmd` |
| **Unit VI: Statistical Models & Shiny** | CO5, CO6: Inference & Apps | Formal hypothesis testing, ARIMA vs. Naive, full Shiny app | `R/04_statistics.R`, `R/05_forecasting.R`, `app.R` |

---

## 6. Step-by-Step Execution & Reproduction Guide

### Step 1: Install Dependencies
Open R or RStudio in the project root directory and run:

```r
source("install_dependencies.R")
```

### Step 2: Execute the Master Analytical Pipeline
Run the master end-to-end pipeline to ingest raw data, populate SQLite, execute statistical inference, train forecasts, render figures, and compile the flexdashboard:

```r
source("run_pipeline.R")
```

### Step 3: Run the Verification Test Suites
Verify all 8 stages of the system and unit tests:

```r
# Stage-by-stage comprehensive system audit
source("tests/test_shiny_app.R")

# Formal unit test verification
testthat::test_dir("tests/testthat")
```

### Step 4: Launch the Interactive Shiny Application
Launch the reactive dashboard in your default web browser:

```r
shiny::runApp(".", launch.browser = TRUE)
```

### Step 5: Regenerate Academic Reports (Word, PDF, HTML)
```r
# Render interactive HTML report
rmarkdown::render("reports/airguard_project_report.Rmd", output_format = "html_document")

# Render Word document and compile native PDF (requires Microsoft Word on Windows)
system("python scripts/format_and_export_report.py")
```

---

## 7. Automated Test Suite Results

```text
==================================================================
        AIRGUARD 360 : 8-STAGE AUTOMATED VERIFICATION MATRIX
==================================================================
[STAGE 1] Shiny UI & Server Compilation ................. [PASS - 100%]
[STAGE 2] Disk Artifacts & Data Directory ............... [PASS - 100%]
[STAGE 3] SQLite Database & Relational Integrity ........ [PASS - 100%]
[STAGE 4] Statistical Computations & Descriptive Moments . [PASS - 100%]
[STAGE 5] Inferential Hypothesis Testing Engine ......... [PASS - 100%]
[STAGE 6] Visualization Suite & Theme Uniformity ........ [PASS - 100%]
[STAGE 7] Predictive Forecasting Engine (vs. Naive) ..... [PASS - 100%]
[STAGE 8] Environmental Decision Support & Edge Cases ... [PASS - 100%]
==================================================================
OVERALL VERIFICATION RESULT: 8/8 STAGES PASSED (0 FAILURES, 0 WARNINGS)
==================================================================
```

---

## 8. License & Attribution

This project is released under the **MIT License**. Ambient air quality records are sourced from the **Central Pollution Control Board (CPCB)**, Ministry of Environment, Forest and Climate Change, Government of India.
