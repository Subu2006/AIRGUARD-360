# AIRGUARD 360: National Air Quality Intelligence, Multi-Pollutant Analytics & Environmental Decision-Support System

[![R](https://img.shields.io/badge/R-4.2.0+-blue.svg)](https://www.r-project.org/)
[![Course](https://img.shields.io/badge/Course-INT232%20Data%20Science%20Toolbox-orange.svg)]()
[![Shiny](https://img.shields.io/badge/Shiny-Interactive%20Application-brightgreen.svg)](https://shiny.posit.co/)
[![Database](https://img.shields.io/badge/Database-SQLite%20Embedded-lightgrey.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![GitHub](https://img.shields.io/badge/GitHub-Repository-black.svg)](https://github.com/Subu2006/AIRGUARD-360)

> **A professional, 100% native R-based analytical intelligence and environmental decision-support system transforming 108,035 statutory CPCB ambient air quality observations across India into multi-grain temporal trends, spatial hotspot rankings, formal inferential hypothesis tests, benchmarked predictive time-series forecasts, and evidence-based simulated Graded Response Action Plan (GRAP) advisories.**

---

## 1. Executive Summary & System Overview

**AIRGUARD 360** was developed as a flagship project for **INT232: Data Science Toolbox — R Programming** at the Lovely School of Computer Science & Engineering, **Lovely Professional University (LPU)**. The application analyzes official Continuous Ambient Air Quality Monitoring Station (CAAQMS) records published by the **Central Pollution Control Board (CPCB)**, Ministry of Environment, Forest and Climate Change (MoEF&CC), Government of India, spanning **January 1, 2015 to July 1, 2020**.

### Key Architectural Highlights:
- **100% Native R Ecosystem:** Built without external non-R wrappers, maximizing academic reproducibility, portability, and native R dependency management.
- **Strict Data Grain Separation:** Explicit analytical segregation between sensor-level telemetry (`fact_station_day`, $N = 108,035$ across 230 stations) and city-level territorial aggregates (`fact_city_day`, $N = 29,531$ across 26 major hubs).
- **Embedded Relational Storage:** High-performance local SQLite relational database (`data/airguard.sqlite`) interfaced via `DBI` and `RSQLite` with B-tree indices for fast relational querying.
- **Parametric & Non-Parametric Hypothesis Testing:** Execution of five formal inferential tests (Welch two-sample t-test, one-way ANOVA with post-hoc Tukey HSD, Pearson correlation test with 95% confidence intervals, Kolmogorov-Smirnov normality test, and Kruskal-Wallis seasonal test).
- **Benchmarked Predictive Analytics:** Base R $\text{ARIMA}(1, 1, 1)$ and Holt-Winters exponential smoothing models evaluated via chronological out-of-sample holdout validation against a **Naive Persistence Baseline**, achieving a 10.5% error reduction over persistence.
- **Municipal Decision Support:** Objective **Environmental Vulnerability Index (EVI)** for multi-criteria hotspot ranking, paired with a simulated **Graded Response Action Plan (GRAP)** rule engine and text-mined advisory corpus.
- **Bilingual Interface Delivery:** Full-stack interactive **Shiny Web Application** (`app.R`) with modern `bslib` Bootstrap 5 theming, and a standalone offline-executable **flexdashboard** (`dashboard.html`).

---

## 2. System Architecture & Directory Structure

```text
AIRGUARD 360/
├── app.R                          # Full-stack interactive Shiny web application
├── run_pipeline.R                 # Master end-to-end execution pipeline script
├── generate_figures.R             # High-resolution (300 DPI) publication figure engine
├── dashboard.Rmd                  # Standalone interactive flexdashboard source
├── dashboard.html                 # Compiled standalone interactive HTML dashboard
├── install_dependencies.R         # Automated CRAN dependency installer & verification
├── DESCRIPTION                    # Standard R package & project dependency manifest
├── session_info.txt               # Full R sessionInfo() runtime environment log
├── LICENSE                        # MIT Open Source License
├── README.md                      # Comprehensive project documentation
├── VIVA_PREPARATION_GUIDE.md      # Comprehensive technical viva & defense guide
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
│   ├── figures/                   # Publication-quality figures (300 DPI PNG)
│   │   ├── fig1_temporal_trajectory_delhi.png
│   │   ├── fig2_hotspots_ranking.png
│   │   ├── fig3_stoichiometry_scatter.png
│   │   ├── fig4_correlation_heatmap.png
│   │   ├── fig5_bollinger_volatility_bands.png
│   │   ├── fig6_advisory_wordcloud.png
│   │   ├── fig7_station_network_map.png
│   │   ├── fig8_seasonal_pollution_disparity.png
│   │   └── fig9_forecast_delhi.png
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
│   ├── 01_data_import.R           # Ingestion, validation, and SQLite database creation
│   ├── 02_data_cleaning.R         # Missingness audit, factor encoding, grain separation
│   ├── 03_feature_engineering.R   # Moving averages, Bollinger bands, seasons
│   ├── 04_statistics.R            # Descriptive moments, matrix math, hypothesis tests
│   ├── 05_forecasting.R           # ARIMA, Holt-Winters, Naive baseline benchmarking
│   ├── 06_text_mining.R           # Text mining of statutory advisories & word cloud
│   ├── 07_visualizations.R        # Static ggplot2 and interactive plotly generators
│   ├── 08_decision_support.R      # Environmental Vulnerability Index (EVI) & GRAP engine
│   └── 09_sql_queries.R           # Production DBI/RSQLite queries (INT232 Practical 7)
├── reports/                       # Academic project reports
│   ├── airguard_project_report.Rmd# Reproducible academic report source (R Markdown)
│   ├── AIRGUARD_360_Project_Report.docx # Word Report (41 pages, Times New Roman 12pt, 1.5 spacing)
│   ├── AIRGUARD_360_Project_Report.pdf  # Native Word-compiled PDF (41 pages, publication grade)
│   └── AIRGUARD_360_Project_Report.html # Standalone interactive HTML report with floating TOC
└── tests/
    └── test_shiny_app.R           # Comprehensive automated verification test suite
```

---

## 3. INT232 Syllabus & Course Outcome Alignment

| Syllabus Unit / Outcome | Course Concept | AIRGUARD 360 Implementation | Verification Protocol |
| :--- | :--- | :--- | :--- |
| **Unit I: Installation & Basics** | R Environment, packages, basic data types, operators | `R/00_config.R`, `DESCRIPTION`, `install_dependencies.R` | Session info check & package manifest |
| **Unit II: Data Structures** | Vectors, correlation matrices, ordered factors, lists | `R/02_data_cleaning.R` (factors), `R/04_statistics.R` (matrices) | Matrix algebra and ordered factor checks |
| **Unit III: R Syntax & SQL** | Functions, conditionals, loops, CSV I/O, SQLite operations | `R/01_data_import.R`, `R/09_sql_queries.R` (DBI/RSQLite) | Query execution on 108,035 fact records |
| **Unit IV: Advanced R** | Apply family (`lapply`, `sapply`), math, regex, POSIXct dates | `R/03_feature_engineering.R` (dates), `R/04_statistics.R` (`lapply`) | Statistical moments across 8 pollutants |
| **Unit IV: Data Wrangling** | Pipes (`%>%`), filter, mutate, select, group_by, NA audit | `R/02_data_cleaning.R`, `R/03_feature_engineering.R` | Missingness audit (`data_quality_audit.rds`) |
| **Unit V: Text Mining** | Tokenization, string functions, stopword removal, word freq | `R/06_text_mining.R` (`tidytext`, custom stopwords) | `outputs/tables/advisory_word_frequencies.csv` |
| **Unit VI: Visualizations** | Scatter plots, line charts, bar charts, donut charts | `R/07_visualizations.R` (Fig 1, 2, 3, 8, donut) | 300 DPI high-res figure generation |
| **Unit VI: Advanced Graphics** | Correlation heatmaps, 20-day Bollinger bands, Plotly widgets | `R/07_visualizations.R` (Fig 4 heatmap, Fig 5 Bollinger, Fig 7 map) | High-res figure rendering & interactive testing |
| **Unit VI: Dashboards** | Flexdashboard and full-stack interactive Shiny app | `dashboard.Rmd` (`dashboard.html`) and `app.R` | Shiny compilation & headless flexdashboard build |
| **Course Outcome CO5** | Predictive analytics fundamentally (ARIMA, Holt-Winters, Naive) | `R/05_forecasting.R` (holdout RMSE, MAE, sMAPE) | `outputs/tables/forecast_delhi_pm25.rds` |
| **Course Outcome CO6** | Formal hypothesis tests (t-test, ANOVA, Pearson, KS, Kruskal) | `R/04_statistics.R` (`run_hypothesis_tests()`) | `outputs/tables/hypothesis_tests_summary.rds` |

---

## 4. Key Analytical Findings & Verified Benchmarks

1. **National Exposure Baseline:** Across all 29,531 monitored city-days, national mean AQI is **166.46** (median: **118.00**), breaching the CPCB Satisfactory threshold ($100$) on **61.5%** of all monitored days.
2. **Particulate Matter Crisis:** National mean $PM_{2.5}$ is **$67.45\ \mu\text{g/m}^3$** (NAAQS exceedance rate: **39.0%**), and mean $PM_{10}$ is **$118.13\ \mu\text{g/m}^3$** (NAAQS exceedance rate: **47.2%**). In contrast, gaseous pollutants ($NO_2$: $3.9\%$, $SO_2$: $1.8\%$) exhibit low exceedance rates.
3. **Top Hotspot Vulnerability:**
   - **Ahmedabad, Gujarat:** Ranks #1 with a multi-year average AQI of **452.1** and an Environmental Vulnerability Index (EVI) of **63.6** (Tier 1: Critical Emergency), recording severe pollution on $42.5\%$ of all monitored days.
   - **Indo-Gangetic Basin:** Delhi (Mean AQI: **259.5**, EVI: **51.2**), Patna (Mean AQI: **240.8**, EVI: **42.7**), Gurugram (Mean AQI: **225.1**, EVI: **42.0**), and Lucknow (Mean AQI: **218.0**, EVI: **41.8**) form a contiguous high-vulnerability cluster.
4. **Clean Baseline Centers:** Southern and montane hubs display pristine air: Aizawl, Mizoram (Mean AQI: **34.8**, EVI: **0.0**), Shillong, Meghalaya (Mean AQI: **53.8**, EVI: **2.6**), Coimbatore, Tamil Nadu (Mean AQI: **73.0**, EVI: **3.8**), and Thiruvananthapuram, Kerala (Mean AQI: **75.9**, EVI: **5.4**).
5. **Inferential Hypothesis Tests:**
   - *Seasonal Inversion t-Test (Delhi):* Winter $PM_{2.5}$ ($182.26\ \mu\text{g/m}^3$) is significantly higher than summer/monsoon ($71.10\ \mu\text{g/m}^3$), $t = 33.78, p < 10^{-143}$, Cohen's $d = 2.05$.
   - *Cross-Metro ANOVA:* $F(4, 7317) = 1328.0, p < 10^{-16}$, with Tukey HSD proving Delhi differs significantly from all other four major metros.
   - *Particulate Stoichiometry:* Pearson $r = 0.846$ ($t = 211.2, p < 10^{-16}, 95\%\text{ CI: } [0.842, 0.851]$), confirming shared combustion origins.
   - *Normality Diagnostics:* Kolmogorov-Smirnov $D = 0.1834, p < 10^{-28}$, rejecting normality and justifying non-parametric Kruskal-Wallis testing ($\chi^2 = 5412.8, p < 10^{-16}$).
6. **Predictive Forecasting Evaluation:** On a 30-day chronological holdout for Delhi $PM_{2.5}$:
   - **Naive Persistence Baseline:** $\text{RMSE} = 12.70\ \mu\text{g/m}^3$, $\text{MAE} = 10.82\ \mu\text{g/m}^3$.
   - **Holt-Winters Smoothing:** $\text{RMSE} = 21.93\ \mu\text{g/m}^3$, $\text{MAE} = 18.91\ \mu\text{g/m}^3$.
   - **Selected Model: $\text{ARIMA}(1, 1, 1)$:** $\text{RMSE} = \mathbf{11.37}\ \mu\text{g/m}^3$, $\text{MAE} = \mathbf{9.74}\ \mu\text{g/m}^3$, $\text{sMAPE} = \mathbf{22.1\%}$ (**10.5% improvement over persistence baseline**).

---

## 5. Installation & Quick Start Guide

### Prerequisites
- **R Runtime:** Version 4.2.0 or higher (R 4.6.1 recommended).
- **RStudio IDE** (optional, recommended for interactive development).
- **Pandoc:** Required for compiling reports and dashboards (bundled with RStudio).

### Step 1: Clone the Repository
```bash
git clone https://github.com/Subu2006/AIRGUARD-360.git
cd "AIRGUARD 360"
```

### Step 2: Install Required R Dependencies
Launch an R session in the project root directory and execute:
```r
source("install_dependencies.R")
```
*This automatically checks your R version, inspects installed packages, and installs any missing libraries from CRAN.*

### Step 3: Run the Master Analytical Pipeline
Execute the full data ingestion, cleaning, feature engineering, modeling, and output generation workflow:
```r
source("run_pipeline.R")
```
*This will:*
1. Initialize the embedded SQLite database (`data/airguard.sqlite`).
2. Clean and audit 108,035 station records and 29,531 city records.
3. Engineer 45 features including 7-day/30-day moving averages and Bollinger bands.
4. Execute the formal hypothesis testing suite.
5. Train and benchmark ARIMA/Holt-Winters time series models.
6. Extract text mining frequency metrics.
7. Compute the Environmental Vulnerability Index (EVI) ranking.
8. Generate all 9 publication-grade figures in `outputs/figures/`.
9. Compile the interactive standalone dashboard (`dashboard.html`).

### Step 4: Launch the Interactive Shiny Dashboard
```r
shiny::runApp("app.R")
```
*Opens the full-stack, responsive Shiny application in your default web browser.*

### Step 5: Run Automated Verification Tests
```r
source("tests/test_shiny_app.R")
```
*Runs an exhaustive 8-stage test matrix verifying compilation, artifacts, database queries, models, plots, and edge cases.*

### Step 6: Regenerate the Academic Report
To regenerate the 41-page academic report in Word, PDF, and HTML formats:
```r
# Generate Word document (.docx)
rmarkdown::render("reports/airguard_project_report.Rmd", output_format = "word_document", output_file = "AIRGUARD_360_Project_Report.docx")

# Generate Standalone HTML report
rmarkdown::render("reports/airguard_project_report.Rmd", output_format = "html_document", output_file = "AIRGUARD_360_Project_Report.html")
```
To apply official university cover-page formatting and export the native PDF:
```bash
python scratch/format_and_export_report.py
```

---

## 6. Regulatory Accuracy & Public Safety Disclaimers

1. **Retrospective Historical Dataset:** All records represent historical retrospective measurements spanning **January 1, 2015 to July 1, 2020**. The system does not ingest live streaming sensor telemetry.
2. **Academic Decision-Support Prototype:** Environmental Vulnerability Index (EVI) scores, priority tiers, and simulated Graded Response Action Plan (GRAP) advisories represent academic decision-support models developed for INT232 coursework. They **do not constitute statutory public orders** or official emergency directions.
3. **No Clinical Advice:** Air quality advisories represent educational health communication based on general CPCB/WHO literature and must not be used as clinical medical counsel.
4. **Statutory Reference:** For official, real-time air quality bulletins and statutory GRAP directions, users must consult the **Central Pollution Control Board (CPCB)** (`https://cpcb.nic.in`) and the **Commission for Air Quality Management (CAQM)**.

---

## 7. Known Limitations & Roadmap

### Current Limitations:
- **Station Network Density:** While 230 stations are monitored, over 45% are concentrated in the National Capital Region, leaving parts of central and eastern India with sparse sensor density.
- **Univariate Forecasting:** Current predictive models rely on univariate autoregression and do not ingest real-time meteorological covariates (planetary boundary layer height, wind velocity, humidity).
- **Retrospective Horizon:** Observational data concludes on July 1, 2020.

### Prioritized Future Roadmap:
- **Phase 1: Real-Time Ingestion:** Integrate CPCB Central Gateway REST APIs for live telemetry updates.
- **Phase 2: Geospatial Kriging:** Implement spatial geostatistical interpolation (`gstat`, `sf`) for continuous surface mapping.
- **Phase 3: Multivariate ARIMAX:** Integrate ERA5 meteorological reanalysis variables to capture thermal inversion dynamics.

---

## 8. Author & Academic Information

- **Student Author:** Subrat Panigrahi
- **Registration Number:** 26143073
- **Programme:** Bachelor of Technology in Computer Science & Engineering (B.Tech CSE)
- **Section:** N1
- **Course Code:** INT232: Data Science Toolbox — R Programming
- **Supervisor / Project Guide:** Mr. Jaffar Amin Chacket (U.Id: 30453), Associate Professor
- **School:** Lovely School of Computer Science & Engineering
- **Institution:** Lovely Professional University, Phagwara, Punjab (India)
- **Official Repository:** [https://github.com/Subu2006/AIRGUARD-360](https://github.com/Subu2006/AIRGUARD-360)

---

## 9. License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.
All underlying CPCB air quality monitoring data is distributed under the Open Data Commons Open Database License (ODbL).
