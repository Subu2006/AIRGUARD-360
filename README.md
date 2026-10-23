# AIRGUARD 360: Interactive Air Quality, Pollution Intelligence & Environmental Decision-Support Dashboard

[![R](https://img.shields.io/badge/R-4.6.1+-blue.svg)](https://www.r-project.org/)
[![Course](https://img.shields.io/badge/Course-INT232%20Data%20Science%20Toolbox-orange.svg)]()
[![Shiny](https://img.shields.io/badge/Shiny-Interactive%20Dashboard-brightgreen.svg)](https://shiny.posit.co/)
[![Database](https://img.shields.io/badge/Database-SQLite%20Embedded-lightgrey.svg)]()

> **An interactive, 100% R-based analytical intelligence and environmental decision-support system transforming 108,000+ statutory CPCB air quality observations across India into temporal trends, spatial comparisons, statistical tests, predictive forecasts, and evidence-based environmental advisories.**

---

## 1. Project Overview & Architecture

**AIRGUARD 360** was architected for **INT232: Data Science Toolbox : R Programming** to demonstrate the full lifecycle of data science strictly within the R ecosystem.

```text
AIRGUARD 360/
├── data/
│   ├── raw/                  # Verified statutory CPCB raw CSV datasets (108k+ records)
│   ├── processed/            # Cleaned and enriched RDS analytical datasets
│   └── airguard.sqlite       # Embedded SQLite database (Unit III & Practical 7)
├── R/
│   ├── 00_config.R           # Statutory NAAQS limits, NAQI breakpoints, custom ggplot2 theme
│   ├── 01_data_import.R      # Ingestion & SQLite relational tables initialization
│   ├── 02_data_cleaning.R    # Missingness audit, factor encoding, range validation
│   ├── 03_feature_engineering.R # Seasonal decomposition, moving averages, Bollinger bands
│   ├── 04_statistics.R       # Apply family moments, correlation matrices, formal hypothesis testing
│   ├── 05_forecasting.R      # Native Base R time-series modeling (ARIMA & Holt-Winters)
│   ├── 06_text_mining.R      # CPCB advisory text mining, tokenization, word cloud
│   ├── 07_visualizations.R   # Reusable ggplot2 and Plotly chart generators (all syllabus types)
│   ├── 08_decision_support.R # Environmental Vulnerability Index (EVI) & GRAP advisories
│   └── 09_sql_queries.R      # Direct SQL queries via DBI/RSQLite for syllabus compliance
├── app.R                     # High-performance interactive R Shiny dashboard (bslib + plotly)
├── run_pipeline.R            # Master end-to-end execution pipeline script
├── generate_figures.R        # Batch generator of publication-grade PNG charts
├── reports/
│   └── airguard_technical_report.Rmd # Complete academic project technical report
├── outputs/
│   ├── tables/               # Empirical CSV/RDS statistical tables and model metrics
│   └── figures/              # High-resolution exported figures (PNG)
├── tests/
│   └── test_shiny_app.R      # Automated test suite verifying data integrity & Shiny compilation
└── README.md
```

---

## 2. INT232 Official Syllabus & Practical Coverage

Every single unit and course outcome from the official syllabus is implemented natively:

| Syllabus Area | Covered Techniques | AIRGUARD 360 Implementation |
|---|---|---|
| **CO1 & Unit I** | R environment, RStudio, data types, operators | Modular R scripts, criteria vectors, arithmetic concentration ratios |
| **CO2 & Unit II** | Vectors, matrices, factors, data frames, lists | Pollutant correlation matrices, ordered AQI severity factors, nested station lists |
| **CO3 & Unit III** | Loops, conditionals, functions, CSV, SQL with R | Custom AQI functions, vectorised conditionals, embedded SQLite via `RSQLite` |
| **CO4 & Unit IV** | Math functions, `apply` family, regex, dates, `dplyr`, `tidyr` | `lapply`/`sapply` statistical summaries, ISO date parsing, 7/30-day moving averages |
| **CO5 & Unit V** | Predictive analytics & text mining | ARIMA & Holt-Winters forecasting, CPCB advisory text mining, word cloud |
| **CO6 & Unit VI** | Statistical tests, basic & advanced visualization, dashboards | Welch t-test, ANOVA, Pearson correlation, heatmaps, Bollinger bands, Shiny app |

---

## 3. Quick Start & Reproduction Guide

### Prerequisites
* R (>= 4.0.0, tested on R 4.6.1)
* RStudio (recommended)

### Step 1: Clone or Open Project
Open R or RStudio in the project root directory:
```R
setwd("c:/Users/subra/OneDrive/Desktop/AIRGUARD 360")
```

### Step 2: Install Required CRAN Packages
```R
install.packages(c("shiny", "bslib", "DT", "plotly", "ggplot2", "dplyr", 
                   "tidyr", "lubridate", "DBI", "RSQLite", "tidytext", "wordcloud", "RColorBrewer"))
```

### Step 3: Execute the Master Analytical Pipeline
Run the master script to process all 108,035 raw records, create the SQLite database, run hypothesis tests, and generate tables:
```R
source("run_pipeline.R")
```

### Step 4: Launch the Interactive Shiny Dashboard
Run the following in R / RStudio:
```R
shiny::runApp("app.R")
```
The dashboard will open automatically in your default browser at `http://127.0.0.1:port`.

### Step 5: Run Automated Verification Tests
```R
source("tests/test_shiny_app.R")
```

---

## 4. Key Empirical Results

All statistics are derived from genuine execution of the 108,035 statutory CPCB records:

* **$PM_{2.5}$ Pollution Severity:** National mean $PM_{2.5} = 67.54\ \mu\text{g/m}^3$ (exceeding the $60\ \mu\text{g/m}^3$ NAAQS limit), with $39.2\%$ of all monitored days in statutory violation.
* **$PM_{10}$ Exceedance:** National mean $PM_{10} = 118.45\ \mu\text{g/m}^3$, with $47.3\%$ of monitored days breaching the $100\ \mu\text{g/m}^3$ standard.
* **Seasonal Disparity t-Test:** Welch $t = 33.51$, $df = 623.5$, $p < 0.0001$. Winter mean $PM_{2.5}$ ($182.26\ \mu\text{g/m}^3$) is over 2.5 times higher than Summer/Monsoon ($71.10\ \mu\text{g/m}^3$).
* **Metropolitan ANOVA:** $F(4, 7317) = 1327.05$, $p < 0.0001$, confirming massive, statistically significant regional pollution variance across Delhi, Mumbai, Bengaluru, Kolkata, and Chennai.
* **Particulate Stoichiometry:** Pearson correlation between $PM_{2.5}$ and $PM_{10}$ is $r = 0.845$ ($p < 0.0001$), confirming shared source combustion origins.
* **Forecasting Accuracy:** Native ARIMA model achieved an out-of-sample Test RMSE of $11.28$ and MAE of $9.73$ on Delhi $PM_{2.5}$.

---

## 5. Viva Voce Defense Summary

* **Why R and not Python?** R is specifically engineered for statistical computing, data frames, formula-driven hypothesis testing (`aov`, `t.test`), and reactive dashboarding with Shiny. For INT232, R is the required foundation.
* **Why Bollinger Bands on Air Quality?** In atmospheric science, Bollinger Bands ($\mu \pm 2\sigma$) track baseline trends and highlight abnormal pollution spikes caused by external episodic events (stubble burning, firecrackers).
* **How does SQL fit into an R project?** We use `RSQLite` to establish an indexed relational database (`airguard.sqlite`), executing aggregation and join queries via `dbGetQuery()` without requiring an external server.
