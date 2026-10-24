# AIRGUARD 360: National Air Quality Intelligence, Multi-Pollutant Analytics & Environmental Decision-Support System

[![R](https://img.shields.io/badge/R-4.6.1+-blue.svg)](https://www.r-project.org/)
[![Course](https://img.shields.io/badge/Course-INT232%20Data%20Science%20Toolbox-orange.svg)]()
[![Shiny](https://img.shields.io/badge/Shiny-Interactive%20Dashboard-brightgreen.svg)](https://shiny.posit.co/)
[![Database](https://img.shields.io/badge/Database-SQLite%20Embedded-lightgrey.svg)]()
[![GitHub](https://img.shields.io/badge/GitHub-Repository-black.svg)](https://github.com/Subu2006/AIRGUARD-360)

> **An enterprise-grade, 100% R-based analytical intelligence and environmental decision-support system transforming 108,000+ statutory CPCB ambient air quality observations across India into multi-grain temporal trends, spatial hotspot rankings, formal hypothesis tests, predictive time-series forecasts, and evidence-based Graded Response Action Plan (GRAP) advisories.**

---

## 1. Executive Summary & Architecture

**AIRGUARD 360** was architected for **INT232: Data Science Toolbox : R Programming** at Lovely Professional University. The system processes statutory continuous ambient air quality monitoring (CAAQMS) records published by the Central Pollution Control Board (CPCB), Ministry of Environment, Forest and Climate Change (MoEFCC), Government of India, spanning 2015 to 2020.

```text
AIRGUARD 360/
├── R/
│   ├── 00_config.R              # Regulatory standards (NAAQS), NAQI breakpoints, custom ggplot2 theme
│   ├── 01_data_import.R         # Multi-grain CSV ingestion & embedded SQLite relational setup
│   ├── 02_data_cleaning.R       # Sensor anomaly scrubbing, factor levels, missingness audit, outlier flags
│   ├── 03_feature_engineering.R # IMD seasons, 7/30-day moving averages, 20-day Bollinger volatility bands
│   ├── 04_statistics.R          # Descriptive moments and 4 formal parametric/non-parametric hypothesis tests
│   ├── 05_forecasting.R         # Native Base R time-series modeling (ARIMA & Holt-Winters with out-of-sample metrics)
│   ├── 06_text_mining.R         # Statutory health advisory corpus text mining, tokenization & word cloud
│   ├── 07_visualizations.R      # Publication-grade ggplot2 & Plotly routines, including CAAQMS national station map
│   ├── 08_decision_support.R    # Composite Environmental Vulnerability Index (EVI) & GRAP municipal advisories
│   └── 09_sql_queries.R         # Relational SQL queries executed natively via DBI and RSQLite
├── data/
│   ├── raw/                     # Statutory raw CSV files: station_day.csv, city_day.csv, stations.csv, StationCoordinates.csv
│   ├── processed/               # Cleaned and enriched analytical RDS datasets
│   └── airguard.sqlite          # Embedded indexed SQLite relational database
├── outputs/
│   ├── tables/                  # Empirical CSV/RDS summary tables, correlation matrices, and model metrics
│   └── figures/                 # 9 Publication-quality 300 DPI exported charts
├── reports/
│   ├── airguard_project_report.Rmd     # Master R Markdown academic project report
│   ├── AIRGUARD_360_Project_Report.docx # Formatted Microsoft Word Report (Times New Roman, 1.5 spacing)
│   ├── AIRGUARD_360_Project_Report.pdf  # 41-page publication-grade PDF Report
│   └── AIRGUARD_360_Project_Report.html # Standalone interactive HTML report
├── tests/
│   └── test_shiny_app.R         # Automated verification test suite (100% test pass)
├── app.R                        # Reactive Shiny Dashboard with bslib Bootstrap 5 theme and Plotly
├── run_pipeline.R               # Master end-to-end execution pipeline script
├── generate_figures.R           # Publication figure generator
└── README.md                    # System documentation
```

---

## 2. Key Empirical Findings

All statistical moments and models are derived from genuine execution of the statutory CPCB dataset:

* **Particulate Pollution Burden:** National ambient mean $PM_{2.5} = 67.54\ \mu\text{g/m}^3$ (violating the $60\ \mu\text{g/m}^3$ 24-hr NAAQS standard), with $39.2\%$ of all monitored days in statutory violation. Ambient mean $PM_{10} = 118.45\ \mu\text{g/m}^3$, with $47.3\%$ of monitored days breaching the $100\ \mu\text{g/m}^3$ benchmark.
* **Winter Thermal Inversions (Welch t-Test):** Welch $t = 33.51$, $df = 623.5$, $p < 0.0001$. Winter mean $PM_{2.5}$ in Delhi ($182.26\ \mu\text{g/m}^3$) is over 2.5 times higher than Summer/Monsoon ($71.10\ \mu\text{g/m}^3$) due to shallow planetary boundary layer atmospheric entrapment.
* **Metropolitan Disparities (One-Way ANOVA):** $F(4, 7317) = 1327.05$, $p < 0.0001$, confirming massive, statistically significant regional pollution variance between coastal peninsular metros (Chennai, Bengaluru) and landlocked Indo-Gangetic basin hubs (Delhi, Patna, Lucknow).
* **Particulate Stoichiometry:** Pearson correlation between $PM_{2.5}$ and $PM_{10}$ is $r = 0.845$ ($p < 0.0001$, 95% CI: $[0.841, 0.849]$), demonstrating shared vehicular combustion and resuspension origins.
* **Episodic Surge Detection:** 20-day Bollinger Volatility Bands ($\mu \pm 2\sigma$) successfully isolate acute episodic surges (post-monsoon agricultural stubble burning and festival fireworks) from chronic urban baseline drift.
* **Predictive Forecasting Accuracy:** Native base R ARIMA achieved an out-of-sample holdout Test RMSE of $11.37\ \mu\text{g/m}^3$, MAE of $9.74\ \mu\text{g/m}^3$, and MAPE of $22.1\%$ on Delhi $PM_{2.5}$.

---

## 3. Interactive Shiny Dashboard Features (`app.R`)

The dashboard features six specialized modules:

1. **Executive Overview:** 4 dynamic KPI status cards, multi-pollutant continuous trajectory with 7-day moving averages and statutory NAAQS threshold lines, CPCB category severity donut chart, and dynamic city/pollutant slicers.
2. **Geographic Intelligence:** Interactive spatial map of India displaying 230 CAAQMS monitoring stations with geographic coordinates, top hotspots bar chart, and Environmental Vulnerability Index (EVI) ranking table.
3. **Pollutant Dynamics:** Multi-pollutant Pearson collinearity matrix heatmap and stoichiometric scatter plot with seasonal color clustering and ordinary least squares (OLS) regression.
4. **Volatility & Bollinger Bands:** 20-day moving average envelopes ($\pm 2\sigma$) on ambient PM2.5, PM10, and AQI with highlighted red markers flagging acute episodic anomalies.
5. **Statistical & Predictive Models:** Formal hypothesis test summary cards (Welch t-test, ANOVA, Pearson correlation, Kolmogorov-Smirnov) and forward-looking 30-day ARIMA/Holt-Winters forecast ribbon with 80% and 95% confidence bands.
6. **Decision Support & Relational SQL:** Automated Graded Response Action Plan (GRAP Stages 0 to 4) advisory box, text-mined CPCB environmental health word cloud, and live SQLite database explorer executing relational SQL queries via `RSQLite`.

---

## 4. Quick Start & Reproduction Guide

### Prerequisites
* R (>= 4.0.0, tested on R 4.6.1)
* RStudio (recommended)

### Step 1: Open Project Directory in R
```R
setwd("c:/Users/subra/OneDrive/Desktop/AIRGUARD 360")
```

### Step 2: Install Required CRAN Packages
```R
install.packages(c("shiny", "bslib", "DT", "plotly", "ggplot2", "dplyr", 
                   "tidyr", "lubridate", "DBI", "RSQLite", "tidytext", 
                   "wordcloud", "RColorBrewer", "rmarkdown", "scales"))
```

### Step 3: Run Master Execution Pipeline
Ingests 108,035 station records, cleans data, builds SQLite database, runs hypothesis tests, trains forecasts, and exports summary tables:
```R
source("run_pipeline.R")
```

### Step 4: Generate Publication Figures
Generates all 9 publication-grade 300 DPI figures in `outputs/figures/`:
```R
source("generate_figures.R")
```

### Step 5: Launch Interactive Shiny Dashboard
```R
shiny::runApp("app.R")
```
The application opens automatically in your default browser with auto-bootstrapping fail-safe protection.

### Step 6: Execute Automated Verification Test Suite
```R
source("tests/test_shiny_app.R")
```
Runs comprehensive automated checks across data integrity, SQLite tables, moving averages, predictive models, and Shiny app compilation with zero errors.

---

## 5. Academic Project Reports

The complete formal academic project report is available in the `reports/` folder:
* **Microsoft Word Document:** [`reports/AIRGUARD_360_Project_Report.docx`](reports/AIRGUARD_360_Project_Report.docx) (Formatted strictly per university guidelines: Times New Roman, 1.5 line spacing, structured tables, and figure captions).
* **Publication PDF Document:** [`reports/AIRGUARD_360_Project_Report.pdf`](reports/AIRGUARD_360_Project_Report.pdf) (Comprehensive 41-page technical report with executive summary, EDA, 10 detailed dataset analyses, and glossary).
* **Interactive HTML Report:** [`reports/AIRGUARD_360_Project_Report.html`](reports/AIRGUARD_360_Project_Report.html) (Self-contained interactive report with code folding and table of contents).

---

## 6. Author & Academic Credits

* **Author:** Subrat Panigrahi
* **Registration Number:** 26143073 | Section: N1
* **Programme:** B.Tech Computer Science & Engineering
* **Course:** INT232: Data Science Toolbox : R Programming
* **Faculty Supervisor:** Mr. Jaffar Amin Chacket (30453), Associate Professor
* **Institute:** Lovely School of Computer Science & Engineering, Lovely Professional University, Phagwara, Punjab
* **GitHub Repository:** [https://github.com/Subu2006/AIRGUARD-360](https://github.com/Subu2006/AIRGUARD-360)
