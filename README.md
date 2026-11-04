# AIRGUARD 360: National Air Quality Intelligence, Multi-Pollutant Analytics & Environmental Decision-Support System

[![R](https://img.shields.io/badge/R-4.2.0+-blue.svg)](https://www.r-project.org/)
[![Architecture](https://img.shields.io/badge/Architecture-100%25%20Native%20R-brightgreen.svg)]()
[![Shiny](https://img.shields.io/badge/Shiny-Interactive%20Enterprise%20App-brightgreen.svg)](https://shiny.posit.co/)
[![Database](https://img.shields.io/badge/Database-SQLite%20Embedded-lightgrey.svg)]()
[![Tests](https://img.shields.io/badge/Tests-8%2F8%20Stages%20Passing%20(100%25)-success.svg)]()
[![Unit Tests](https://img.shields.io/badge/Unit%20Tests-15%2F15%20Passed-success.svg)]()
[![Report](https://img.shields.io/badge/Report-52%20Pages%20Word%2FPDF-purple.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![GitHub](https://img.shields.io/badge/GitHub-Repository-black.svg)](https://github.com/Subu2006/AIRGUARD-360)

> **AIRGUARD 360** is an enterprise-grade, 100% native R-based environmental data science platform, interactive intelligence suite, and public health decision-support system. It transforms **108,035 statutory CAAQMS ambient air quality observations** across India into multi-grain temporal trends, multi-city comparative analytics, policy intervention simulations, personal inhaled dose calculations, formal hypothesis tests, benchmarked predictive time-series forecasts, and evidence-based Graded Response Action Plan (GRAP) advisories.

---

## 1. Executive Summary & Author Credentials

* **Author & Lead Architect:** Subrat Panigrahi (Registration Number: `26143073`, Section: `N1`, Programme: B.Tech Computer Science & Engineering)
* **Faculty Supervisor:** Mr. Jaffar Amin Chacket (Associate Professor, CSE/IT, U.Id: `30453`)
* **Academic Institution:** Lovely Professional University (LPU), Punjab, India
* **Underlying Telemetry:** Official Continuous Ambient Air Quality Monitoring Station (CAAQMS) records published by the **Central Pollution Control Board (CPCB)**, Ministry of Environment, Forest and Climate Change (MoEF&CC), Government of India, spanning **January 1, 2015 to July 1, 2020** (230 stations across 26 major metropolitan hubs).

---

## 2. Key Engineering & Feature Highlights (7 Operational SaaS Modules)

### 🚀 1. Executive Command Center
* Live KPI metric cards with dynamic trend arrows and period comparisons.
* Calibrated CPCB Statutory Air Quality Speedometer / Gauge (`plot_aqi_gauge`) displaying instantaneous air quality tier.
* Interactive LOESS-smoothed temporal trajectory (`plot_temporal_trend`) with statutory 24-hr NAAQS threshold overlays.
* Categorical CPCB NAQI severity distribution donut chart (`plot_aqi_donut`).
* Direct CSV export capabilities for city-daily datasets and national hotspot rankings.

### ⚖️ 2. Head-to-Head Comparison Studio
* Directly contrast pollution trajectories, multi-pollutant stoichiometric profiles, and regulatory compliance between any two Indian metropolitan centers (e.g., **Delhi vs. Bengaluru** or **Mumbai vs. Kolkata**).
* Synchronized dual-scale Plotly time series (`plot_city_comparison`) with 7-day moving averages.
* Multi-pollutant criteria burden profile (`plot_pollutant_profile_bar`) comparing all 6 major criteria pollutants ($PM_{2.5}, PM_{10}, NO_2, SO_2, CO, O_3$) as a percentage of CPCB 24-hr NAAQS limits.

### 🧪 3. Policy Intervention & "What-If" Scenario Simulator
* Dynamic decision-support tool empowering environmental planners and citizens to simulate urban emission abatement strategies.
* Real-time policy abatement sliders:
  * 🚗 **Vehicular Fleet Transition:** 0% to 50% vehicular emission abatement (weight: 28%)
  * 🏗️ **Fugitive Dust Suppression:** 0% to 50% construction and road dust control (weight: 22%)
  * 🌾 **Agricultural Stubble Management:** 0% to 80% seasonal burning prevention (weight: 25%)
  * 🏭 **Industrial Stack Scrubbers:** 0% to 50% industrial emission control (weight: 25%)
* Instant reactive recalculation: Projects new mean AQI, clean air days gained per year, and estimated avoided acute respiratory hospitalizations based on CPCB/WHO epidemiological dose-response functions.

### 🏥 4. Personal Environmental Exposure & Inhaled Particulate Dose Calculator
* Citizen science tool estimating physical particulate intake (micrograms of $PM_{2.5}$) and passive cigarette smoke equivalency (Berkeley Earth model) based on ambient levels and minute ventilation rates ($V_E$).
* Cohort-specific personalization: Children (5–12 yrs), healthy adults, asthmatic/cardiovascular patients, and senior citizens (65+) across resting ($V_E = 0.35–0.45\ \text{m}^3/\text{hr}$), light walking ($0.80–1.10\ \text{m}^3/\text{hr}$), and vigorous exercise ($1.60–2.40\ \text{m}^3/\text{hr}$) durations.
* Recommends respiratory PPE (Cloth vs. Surgical vs. N95/N99) and safe physical activity windows.

### 🗺️ 5. National Geospatial Intelligence & Leaflet GIS Mapping
* Interactive nationwide Leaflet GIS mapping across all 230 continuous monitoring stations with multi-layer cartography (Positron Light, Dark OLED, StreetMap).
* Dynamic color-coded statutory NAQI halos and interactive station telemetry popups (Station name, City, State, Mean AQI, Peak AQI, Mean PM2.5, total observations).
* Objective **Environmental Vulnerability Index (EVI)** classifying cities into three operational priority tiers (Tier 1 Critical Emergency, Tier 2 High Vulnerability, Tier 3 Moderate/Baseline).

### 📈 6. Predictive Forecasting Studio (ARIMA vs. Naive Baseline)
* Native Base R `stats::arima(1, 1, 1)` and `stats::HoltWinters` models evaluated via chronological out-of-sample holdout validation against a persistent **Naive Reference Baseline** ($\hat{y}_{t+h} = y_t$).
* For Delhi $PM_{2.5}$, ARIMA achieves an out-of-sample RMSE of **$9.81\ \mu\text{g/m}^3$** versus **$12.24\ \mu\text{g/m}^3$** for the Naive baseline (a **19.9% error reduction** over persistence).
* Generates 30-day forward projections with 80% and 95% confidence interval ribbons.

### 🔬 7. Atmospheric Chemical Dynamics & Volatility
* Multi-pollutant Pearson correlation matrix heatmap (`plot_correlation_heatmap`) quantifying collinearity and photochemical secondary aerosol formation.
* 20-day Bollinger Volatility Bands (`plot_bollinger_bands`) detecting atmospheric stagnation and acute pollution surge anomalies ($\mu \pm 2\sigma$).
* Particulate stoichiometry scatter plots ($PM_{2.5}$ vs $PM_{10}$) with fitted OLS regression slopes.

---

## 3. Real Application Dashboard Interface Showcase

All figures are genuine, Full-HD (1920x1080) captures directly from the running application:

| Executive Command Center | Head-to-Head Comparison Studio |
| :---: | :---: |
| ![Executive Command Center](outputs/figures/fig10_dashboard_overview.png) | ![Comparison Studio](outputs/figures/fig11_dashboard_comparison.png) |
| *Real-time KPI metric cards, LOESS smoothed trajectory & CPCB AQI distribution* | *Synchronized dual-city comparison (Delhi vs Bengaluru) & criteria burden profiles* |

| Predictive Forecasting Studio | Enterprise Policy Scenario Simulator |
| :---: | :---: |
| ![Forecasting Studio](outputs/figures/fig12_dashboard_forecast.png) | ![Dark Mode Simulator](outputs/figures/fig13_dashboard_darkmode.png) |
| *Native ARIMA vs Naive baseline with 80% & 95% out-of-sample confidence intervals* | *Real-time policy sliders (EV transition, dust control, stubble management)* |

| Nationwide Geospatial Intelligence (Leaflet GIS) |
| :---: |
| ![Geographic Intelligence](outputs/figures/fig14_dashboard_mobile.png) |
| *Interactive 230-station Leaflet GIS map with CartoDB Positron/DarkMatter tiles, NAQI halos, and station telemetry* |

---

## 4. System Directory Structure

The project has been restructured into a compact, cohesive, 4-engine modular architecture:

```text
AIRGUARD 360/
├── app.R                          # Enterprise interactive Shiny web application (7 operational modules)
├── dashboard.Rmd                  # Standalone interactive flexdashboard source
├── dashboard.html                 # Compiled standalone interactive HTML dashboard (11.35 MB)
├── run_pipeline.R                 # Master end-to-end analytical pipeline script
├── generate_figures.R             # High-resolution (300 DPI) publication figure engine
├── install_dependencies.R         # Automated CRAN dependency installer & verification
├── DESCRIPTION                    # Standard R package & project dependency manifest
├── AIRGUARD360.Rproj              # RStudio project configuration file
├── LICENSE                        # MIT Open Source License
├── README.md                      # Comprehensive project documentation & data provenance
├── VIVA_PREPARATION_GUIDE.md      # Comprehensive technical viva & oral defense guide
├── LINKEDIN_POST_KIT.md           # Professional project showcase & publication kit
│
├── R/                             # Consolidated modular R architecture (4 cohesive engines)
│   ├── config.R                   # System settings, statutory CPCB standards, colors & constants
│   ├── data_engine.R              # Ingestion, relational SQLite star-schema, cleaning & feature engineering
│   ├── analytics_engine.R         # Descriptive moments, hypothesis testing, ARIMA forecasting & text mining
│   └── visualization_engine.R     # ggplot2/plotly graphics, Leaflet GIS mapping & decision support (EVI, GRAP)
│
├── data/                          # Statutory CPCB datasets & relational storage
│   ├── airguard.sqlite            # Embedded SQLite relational database (5 tables, 137,566 rows)
│   ├── raw/                       # Immutable raw CPCB datasets & reference dimensions
│   │   ├── station_day.csv        # 108,035 station-daily sensor observations (2015–2020)
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
│
├── outputs/                       # Analytical artifacts & publication assets
│   ├── figures/                   # 14 Publication-quality figures & dashboard screenshots
│   └── tables/                    # Analytical summaries, correlation matrices & model evaluation tables
│       ├── hotspot_vulnerability_ranking.csv # EVI municipal vulnerability rankings
│       ├── station_geo_summary.csv           # Station coordinates and telemetry summary
│       ├── pollutant_summary_stats.csv       # Statistical moments across all criteria pollutants
│       ├── correlation_matrix.csv            # Pairwise Pearson correlation coefficients
│       ├── advisory_word_frequencies.csv     # NLP term frequency distribution
│       ├── hypothesis_tests_summary.rds      # Formal inferential hypothesis test outputs
│       ├── forecast_delhi_pm25.rds           # 30-day forecast projection & metrics
│       └── sql_query_outputs.rds             # Multi-table SQL query results
│
├── reports/                       # Academic documentation & faculty submission packages
│   ├── airguard_project_report.Rmd      # Fully reproducible R Markdown academic report source
│   ├── AIRGUARD_360_Project_Report.docx # Formatted 52-page academic report (Times New Roman 12pt, 1.5 spacing)
│   ├── AIRGUARD_360_Project_Report.pdf  # 52-page publication-quality PDF report with real screenshots
│   └── AIRGUARD_360_Project_Report.html # Standalone interactive HTML academic report
│
└── tests/                         # Quality assurance & verification harnesses
    ├── test_shiny_app.R           # Comprehensive 8-stage automated test matrix (100% passing)
    └── testthat/                  # Formal unit testing suite (15/15 tests passing)
        └── test-core-logic.R
```

---

## 5. Dataset Sources and Complete Data Provenance

| Parameter | Primary Sensor Telemetry | City Aggregates | Monitoring Stations Catalogue | Station Geolocation Metadata |
|---|---|---|---|---|
| **1. Dataset Name** | `station_day.csv` | `city_day.csv` | `stations.csv` | `StationCoordinates.csv` |
| **2. Original Publisher** | Central Pollution Control Board (CPCB), MoEF&CC, Govt of India | Central Pollution Control Board (CPCB), MoEF&CC, Govt of India | CPCB National Ambient Air Monitoring Programme (NAMP) | OpenStreetMap Nominatim & Survey of India Geocoding |
| **3. Exact Source URL** | [CPCB Official Portal](https://cpcb.nic.in/) / [CPCB CAAQMS Archive](https://app.cpcbccr.com/ccr/#/caaqms-dashboard-sub-tree) | [CPCB Official Portal](https://cpcb.nic.in/) | [CPCB Monitoring Network](https://cpcb.nic.in/air-quality-monitoring-network/) | CPCB CAAQMS Station Directory & Geocoded Coordinates |
| **4. Download Repository** | [Kaggle Air Quality in India (CPCB Archive)](https://www.kaggle.com/datasets/rohanrao/air-quality-data-in-india) | [Kaggle Air Quality in India (CPCB Archive)](https://www.kaggle.com/datasets/rohanrao/air-quality-data-in-india) | [Kaggle Air Quality in India (CPCB Archive)](https://www.kaggle.com/datasets/rohanrao/air-quality-data-in-india) | Internal Geocoding Audit against CAAQMS Stations |
| **5. File Format** | Flat CSV (Comma-Separated Values) | Flat CSV (Comma-Separated Values) | Flat CSV (Comma-Separated Values) | Flat CSV (Comma-Separated Values) |
| **6. Dimensions & Records** | **108,035 rows × 16 columns** | **29,531 rows × 16 columns** | **230 rows × 5 columns** | **230 rows × 5 columns** |
| **7. Key Attributes** | `StationId`, `Date`, `PM2.5`, `PM10`, `NO`, `NO2`, `NOx`, `NH3`, `CO`, `SO2`, `O3`, `Benzene`, `Toluene`, `Xylene`, `AQI`, `AQI_Bucket` | `City`, `Date`, `PM2.5`, `PM10`, `NO2`, `SO2`, `CO`, `O3`, `AQI`, `AQI_Bucket` | `StationId`, `StationName`, `City`, `State`, `Status` | `StationId`, `Latitude`, `Longitude`, `CoordinateStatus`, `CoordinateSource` |
| **8. Temporal Coverage** | January 1, 2015 to July 1, 2020 | January 1, 2015 to July 1, 2020 | 2015–2020 Station Operational Status | Validated GRCh38 / WGS 84 Ellipsoid |
| **9. Ingestion Method** | Programmatic ingestion via `read.csv(..., na.strings = c("", "NA", "NULL"))` in `R/data_engine.R` | Ingested via `read.csv(...)` in `R/data_engine.R` | Ingested via `read.csv(...)` in `R/data_engine.R` | Relational left join with `stations.csv` on `StationId` |
| **10. Cleaning & Processing** | Coerced to numeric, physical boundary check (negative values to `NA`), factor encoding for CPCB categories | Checked against station roll-up, outlier flag on AQI > 500, state mapped | Joined with coordinates, validated against official CPCB state rosters | Verified within geographic boundary of India ($6^\circ\text{N} \le \text{Lat} \le 38^\circ\text{N}, 68^\circ\text{E} \le \text{Lon} \le 98^\circ\text{E}$) |
| **11. System Usage** | Fact table `fact_station_day` in SQLite; sensor-level exceedance queries | Fact table `fact_city_day` in SQLite; analytical models, time series, forecasts | Dimension table `dim_stations` in SQLite; filter dropdowns in Shiny | Leaflet interactive GIS mapping (`plot_leaflet_station_map`) |
| **12. Role in Platform** | Provides high-resolution micro-level ground truth across 230 individual stations | Provides macro-level municipal metrics, trends, and policy simulations | Provides station hierarchy and metropolitan categorization | Enables nationwide geospatial visualization and spatial hotspot detection |
| **13. License & Rights** | Open Government Data (OGD) India / Creative Commons Attribution (CC-BY 4.0) | Open Government Data (OGD) India / Creative Commons Attribution (CC-BY 4.0) | CPCB Public Domain Official Release | OpenStreetMap ODbL & Public Domain Geocoding |

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
# Stage-by-stage comprehensive system audit (8/8 stages passing)
source("tests/test_shiny_app.R")

# Formal unit test verification (15/15 unit tests passing)
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

# Render Word document
rmarkdown::render("reports/airguard_project_report.Rmd", output_format = "word_document", output_file = "AIRGUARD_360_Project_Report.docx")
```

---

## 7. Automated Test Suite Results

### A. 8-Stage System Verification (`tests/test_shiny_app.R`)
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

### B. Formal Unit Test Suite (`tests/testthat/test-core-logic.R`)
```text
✔ | F W  S  OK | Context
✔ |         15 | core-logic

══ Results ═════════════════════════════════════════════════════════════════════
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 15 ]
```

---

## 8. Technical Architecture & Theoretical Formulations

### 1. Relational Star Schema & Factual Grain Separation
To avoid the **ecological fallacy** and artificial variance dampening that results from pooling sensor-level readings with territorial averages, AIRGUARD 360 enforces strict grain separation:
* **Micro Grain:** Individual monitoring station sensor telemetry stored in `fact_station_day` ($N = 108,035$).
* **Macro Grain:** City-level territorial averages stored in `fact_city_day` ($N = 29,531$).
* **Dimensions:** `dim_stations` (230 stations), `dim_pollutants` (criteria pollutants with 24-hr standards), `dim_aqi_category` (6 CPCB severity tiers).

### 2. Time-Series Modeling & Baseline Benchmarking
Forecasting models are evaluated under a strict chronological holdout protocol:
$$\text{Test RMSE} = \sqrt{\frac{1}{H} \sum_{h=1}^H (y_{T+h} - \hat{y}_{T+h})^2}$$
* **Naive Persistence Baseline ($\hat{y}_{T+h} = y_T$):** Delhi $PM_{2.5}$ Test RMSE = **$12.24\ \mu\text{g/m}^3$**.
* **Base R ARIMA(1, 1, 1):** Delhi $PM_{2.5}$ Test RMSE = **$9.81\ \mu\text{g/m}^3$** (**19.9% error reduction** over baseline).

### 3. Environmental Vulnerability Index (EVI)
$$\text{EVI}_c = 0.40 \cdot \left( \frac{\overline{\text{AQI}}_c - \min \overline{\text{AQI}}}{\max \overline{\text{AQI}} - \min \overline{\text{AQI}}} \times 100 \right) + 0.40 \cdot (\% \text{Severe Days}_c) + 0.20 \cdot (\text{PM}_{2.5}\ \text{Exceedance Rate}_c)$$
* **Tier 1 (Critical Emergency, $\text{EVI} \ge 60$):** Delhi (84.2), Ahmedabad (76.8), Patna (74.1), Gurugram (72.5), Lucknow (71.3).
* **Tier 2 (High Vulnerability, $35 \le \text{EVI} < 60$):** Kolkata, Amritsar, Jaipur, Hyderabad.
* **Tier 3 (Moderate / Baseline, $\text{EVI} < 35$):** Bengaluru, Chennai, Thiruvananthapuram, Aizawl.

### 4. Personal Inhaled Particulate Dose & Cigarette Equivalency
$$\text{Dose}\ (\mu\text{g}) = \text{PM}_{2.5}\ (\mu\text{g/m}^3) \times V_E\ (\text{m}^3/\text{hr}) \times \text{Exposure Duration (hrs)}$$
$$\text{Cigarette Equivalents} = \frac{\text{Dose}\ (\mu\text{g})}{480\ \mu\text{g}}$$
*(Derived from the Berkeley Earth epidemiological model: 1 cigarette smoked corresponds to an ambient exposure of $\approx 22\ \mu\text{g/m}^3$ over 24 hours).*

---

## 9. Known Limitations

1. **Historical Telemetry Boundary:** The official CPCB CAAQMS archive covers records up to July 1, 2020. It reflects historical retrospective dynamics (including the unprecedented 2020 COVID-19 nationwide lockdown air quality rebound) rather than real-time live IoT streams.
2. **Missing Observations:** Sensor calibration drift and telemetry power outages produce missing values in raw feeds (mean missingness: 19.4% for AQI, 20.0% for PM2.5). The system transparently flags and handles missingness via cumulative-sum rolling windows requiring $\ge 60\%$ valid readings.
3. **Simulation Nature of Policy Sliders:** Abatement weights (28% vehicular, 22% dust, 25% stubble, 25% industry) are derived from CPCB source apportionment studies and represent deterministic policy scenario projections rather than 3D Eulerian photochemical grid simulations (e.g., WRF-Chem).

---

## 10. License & Attribution

This project is released under the **MIT License**. Ambient air quality records are sourced from the **Central Pollution Control Board (CPCB)**, Ministry of Environment, Forest and Climate Change (MoEF&CC), Government of India.
