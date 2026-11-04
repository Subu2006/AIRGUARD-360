# AIRGUARD 360: Comprehensive Viva Voce, Code Walkthrough & Defense Guide

**System Title:** AIRGUARD 360 — National Air Quality Intelligence, Multi-Pollutant Analytics & Environmental Decision-Support System  
**Author & Candidate:** Subrat Panigrahi (Registration Number: `26143073`, Section: `N1`, B.Tech Computer Science & Engineering)  
**Faculty Supervisor:** Mr. Jaffar Amin Chacket (Associate Professor, CSE/IT, U.Id: `30453`)  
**Institution:** School of Computer Science and Engineering, Lovely Professional University (LPU)  
**Open-Source Repository:** [https://github.com/Subu2006/AIRGUARD-360](https://github.com/Subu2006/AIRGUARD-360)  

---

## 1. The 2-Minute Winning Opening Pitch (Elevator Speech)

> *"Good morning, respected Evaluators. My capstone project is **AIRGUARD 360**, an enterprise-grade, 100% native R-based environmental data science platform and public health decision-support system.*
>
> *AIRGUARD 360 addresses one of India's most urgent environmental challenges: transforming fragmented, noisy continuous ambient sensor feeds from the Central Pollution Control Board (CPCB) into verifiable, actionable policy intelligence.*
>
> *The system ingests and reconciles **108,035 statutory CAAQMS observations** across **230 continuous monitoring stations** in 26 major metropolitan centers between 2015 and 2020. The entire pipeline is engineered natively in R without external Python runtimes, structured into four cohesive engines:
> 1. **Data Engine (`R/data_engine.R`):** Ingestion, schema validation, physical boundary scrubbing (negative sensor drift), and embedded relational **SQLite database (`DBI`/`RSQLite`)** storage with strict grain separation between micro sensor feeds and macro territorial aggregates.
> 2. **Analytics Engine (`R/analytics_engine.R`):** Descriptive moments, formal inferential hypothesis testing (**Welch t-test, ANOVA, Kruskal-Wallis, Kolmogorov-Smirnov**), and predictive time-series modeling (**ARIMA vs. Naive persistence baseline**, achieving an out-of-sample error reduction of up to 27.7%), alongside NLP statutory advisory mining.
> 3. **Visualization & Decision Engine (`R/visualization_engine.R`):** High-performance interactive **Leaflet GIS mapping**, synchronized dual-city comparison studios, 20-day **Bollinger Volatility Bands**, an empirical **Environmental Vulnerability Index (EVI)**, and real-time policy intervention simulators projecting avoided hospitalizations.
> 4. **Configuration Engine (`R/config.R`):** Standard statutory CPCB NAAQS limits, 6-tier NAQI color maps, and publication themes.
>
> *The platform features two client interfaces: a standalone 11.35 MB interactive HTML flexdashboard and a full-stack 7-module Shiny web application. All results, figures, and models are 100% verified across an automated 8-stage test harness and 15 formal unit tests."*

---

## 2. Complete Code Walkthrough & File-by-File Architecture

The project has been consolidated into a minimal, modular architecture where every single file has a clear responsibility:

```text
AIRGUARD 360/
├── app.R                      # Full-stack reactive Shiny web application (7 operational modules)
├── dashboard.Rmd / .html      # Standalone compiled interactive flexdashboard (11.35 MB)
├── run_pipeline.R             # Master end-to-end batch execution pipeline script
├── generate_figures.R         # High-resolution (300 DPI) publication figure generator
├── install_dependencies.R     # Automated CRAN package installer
├── R/                         # Consolidated modular R architecture (4 cohesive engines)
│   ├── config.R               # System settings, statutory thresholds & theme definitions
│   ├── data_engine.R          # Ingestion, relational SQLite star-schema, cleaning & feature engineering
│   ├── analytics_engine.R     # Descriptive moments, hypothesis testing, ARIMA forecasting & text mining
│   └── visualization_engine.R # ggplot2/plotly graphics, Leaflet GIS mapping & decision support (EVI, GRAP)
├── data/                      # Raw CPCB CSVs, clean RDS binaries, and airguard.sqlite
├── outputs/                   # High-res publication figures (PNG) & analytical summary tables (CSV/RDS)
├── reports/                   # 52-page academic project reports in Word (DOCX), PDF, and HTML
└── tests/                     # 8-stage system test harness & 15 formal unit tests (testthat)
```

### Detailed Breakdown of Retained Files

#### 1. `R/config.R` (Configuration & Standards Engine)
* **Purpose:** Acts as the single source of truth for statutory environmental constants, statutory thresholds, color palettes, and global ggplot2 themes.
* **Why Required:** Prevents hardcoding magic numbers or color strings across scripts; ensures that statutory limits (e.g., CPCB 24-hr NAAQS $PM_{2.5} = 60\ \mu\text{g/m}^3$) are defined identically throughout the platform.
* **Key Constants & Functions:**
  * `NAAQS_LIMITS`: List of 24-hr statutory limits for 8 criteria pollutants ($PM_{2.5}: 60, PM_{10}: 100, NO_2: 80, SO_2: 80, CO: 2.0, O_3: 100, NH_3: 400$).
  * `AQI_CATEGORIES`: 6 official CPCB tiers (Good, Satisfactory, Moderate, Poor, Very Poor, Severe) with hex codes.
  * `theme_airguard(base_size, is_dark)`: Custom publication ggplot2 theme with light and dark mode support.
  * `get_aqi_bucket(aqi_val)`: Deterministic classification helper.
* **What happens if removed:** Plot styling fails, statutory limit lines disappear, and color mapping breaks.

#### 2. `R/data_engine.R` (Data Processing & Relational Storage Engine)
* **Purpose:** Handles the end-to-end data lifecycle: raw CSV ingestion, relational SQLite database creation, data cleaning, physical boundary auditing, missingness profiling, and temporal feature engineering.
* **Why Required:** Consolidates raw data ingestion, storage, cleaning, and transformation into one transparent, verifiable module.
* **Key Functions:**
  * `initialize_data_pipeline(raw_dir, db_path)`: Reads raw CSVs (`station_day.csv`, `city_day.csv`, `stations.csv`, `StationCoordinates.csv`), creates `data/airguard.sqlite`, builds B-tree indexes, and returns an in-memory bundle.
  * `clean_airguard_data(raw_data, output_dir)`: Enforces numeric type coercion, scrubs sensor calibration anomalies ($< 0 \rightarrow \text{NA}$), factor-encodes CPCB AQI buckets, flags extreme outliers ($> 500$), and generates `data_quality_audit.rds`.
  * `roll_mean_base(x, k)` & `roll_sd_base(x, k)`: High-performance Base R sliding window functions using cumulative sums with a strict $60\%$ valid observation requirement.
  * `engineer_airguard_features(df_city_daily)`: Derives 45 analytical features, including IMD climatological seasons, weekend indicators, 7-day and 30-day moving averages, and 20-day Bollinger volatility bands.
  * `run_relational_sql_queries(db_path)`: Connects to SQLite via `DBI` and executes complex multi-table SQL queries with `GROUP BY`, `HAVING`, and `JOIN`.
* **What happens if removed:** The pipeline cannot ingest, clean, store, or engineer features for the dataset.

#### 3. `R/analytics_engine.R` (Statistical Modeling & Forecasting Engine)
* **Purpose:** Implements descriptive statistics, formal hypothesis testing, benchmarked predictive time-series modeling, and natural language processing (NLP) of environmental text.
* **Why Required:** Houses the core scientific and quantitative rigor of the project, separating pure mathematical calculations from UI code.
* **Key Functions:**
  * `compute_pollutant_statistics(df)`: Uses functional vectorization (`lapply`) to compute sample size, mean, SD, median, IQR, Fisher-Pearson skewness, and exceedance rates across all criteria pollutants.
  * `compute_correlation_matrices(df)`: Calculates pairwise Pearson correlation coefficients and p-values.
  * `run_hypothesis_tests(df)`: Executes 5 formal statistical tests: Two-Sample Welch t-test, One-Way ANOVA with Tukey HSD, Pearson stoichiometry test, Kolmogorov-Smirnov normality test, and Kruskal-Wallis non-parametric test.
  * `forecast_city_pollution(df, target_city, target_var, horizon)`: Chronological holdout validation comparing Base R `stats::arima(1, 1, 1)` and `stats::HoltWinters` against a persistent Naive reference baseline ($\hat{y}_{t+h} = y_t$). Generates 30-day forecasts with 80% and 95% confidence intervals.
  * `evaluate_forecast_rolling(...)` & `forecast_error_metrics(...)`: Leakage-free rolling-origin backtesting.
  * `mine_environmental_text(corpus_df)`: Tokenizes CPCB and WHO advisory texts, removes stopwords, and calculates term frequencies.
* **What happens if removed:** Statistical inferences, hypothesis testing, ARIMA models, and advisory text mining cease to function.

#### 4. `R/visualization_engine.R` (Visual Analytics & Decision Support Engine)
* **Purpose:** Houses all graphical plotting functions (ggplot2, Plotly, Leaflet GIS) and environmental decision-support algorithms.
* **Why Required:** Provides a clean separation of concerns: UI files (`app.R` and `dashboard.Rmd`) stay declarative and concise by delegating chart rendering and decision calculations to this engine.
* **Key Functions:**
  * `plot_aqi_gauge(aqi_val, city_name)`: Calibrated statutory CPCB speedometer widget.
  * `plot_temporal_trend(...)`: Daily pollutant trajectory with 7-day moving averages and NAAQS standards.
  * `plot_city_rankings(...)`: Horizontal bar chart ranking municipal pollution or EVI scores.
  * `plot_pollutant_scatter(...)`: Stoichiometric scatter plot with fitted OLS regression line.
  * `plot_correlation_heatmap(cor_matrix)`: Collinearity tile map.
  * `plot_bollinger_bands(...)`: Atmospheric volatility envelope ($\mu \pm 2\sigma$) with anomaly spike markers.
  * `plot_leaflet_station_map(station_data)`: Nationwide interactive GIS map with CartoDB Positron/DarkMatter tiles, NAQI halos, and station telemetry popups.
  * `plot_city_comparison(...)`: Synchronized dual-city trajectory studio.
  * `plot_pollutant_profile_bar(...)`: Multi-pollutant burden (% of 24-hr NAAQS standard).
  * `compute_hotspot_priority_index(df)`: Computes the Environmental Vulnerability Index (EVI) ranking cities into Tier 1, 2, or 3.
  * `generate_environmental_advisory(aqi, pm25)`: Maps AQI to GRAP regulatory stages and citizen advisories.
  * `calculate_inhaled_dose(pm25, age_cohort, activity_level, hours)`: Particulate dose ($\mu\text{g}$) and Berkeley Earth passive cigarette equivalents.
  * `simulate_policy_intervention(...)`: Policy simulation evaluating EV transition, dust control, stubble management, and industrial scrubbers.
* **What happens if removed:** All visualizations, Leaflet GIS maps, and decision calculators fail to render.

#### 5. `app.R` (Full-Stack Reactive Shiny Web Application)
* **Purpose:** The user-facing operational web platform featuring 7 dedicated modules: Executive Overview, Comparison Studio, Policy Simulator, Health Exposure, Geospatial Radar, Forecasting & Volatility, and Pollutant Dynamics.
* **Key Logic:**
  * Built using `bslib` Bootstrap 5 with responsive CSS cards.
  * Features `shinycssloaders::withSpinner` across all chart containers for immediate visual feedback.
  * Includes direct CSV export buttons for processed datasets and hotspot rankings.

---

## 3. Deep-Dive on Core Algorithms & Mathematical Formulations

### 1. Chronological Holdout Validation & Baseline Benchmarking
* **Protocol:** Time series cannot use random $k$-fold cross-validation because future data would leak into past predictions (look-ahead bias). We split the series chronologically: historical training set ($T_{\text{train}}$) and unseen out-of-sample holdout test window ($T_{\text{test}}$, length $H = 30$ days).
* **Reference Baseline (Naive Persistence):** Predicts that future concentrations equal the last observed value:
  $$\hat{y}_{T+h} = y_T, \quad \forall h \in [1, H]$$
* **Performance Metric:** Root Mean Squared Error (RMSE):
  $$\text{RMSE} = \sqrt{\frac{1}{H} \sum_{h=1}^H (y_{T+h} - \hat{y}_{T+h})^2}$$
* **Empirical Results:** For Delhi $PM_{2.5}$, Base R `stats::arima(1, 1, 1)` achieves an out-of-sample RMSE of **$9.81\ \mu\text{g/m}^3$** compared to **$12.24\ \mu\text{g/m}^3$** for the Naive baseline (**19.9% error reduction**).

### 2. Atmospheric Bollinger Volatility Bands
* Adapted from financial econometrics to environmental physical science:
  $$\text{Middle Band}_t = \text{MA}_{20}(t) = \frac{1}{20} \sum_{i=0}^{19} x_{t-i}$$
  $$\text{Upper Band}_t = \text{MA}_{20}(t) + 2 \cdot \text{SD}_{20}(t)$$
  $$\text{Lower Band}_t = \max\left(0, \text{MA}_{20}(t) - 2 \cdot \text{SD}_{20}(t)\right)$$
* **Physical Interpretation:** When daily readings breach the $+2\sigma$ upper ceiling, our algorithm flags an **episodic acute shock** (e.g., post-monsoon stubble burning in Punjab/Haryana or Diwali pyrotechnics) rather than normal chronic traffic variation.

### 3. Environmental Vulnerability Index (EVI)
* Multi-criteria weighted index formulated to rank municipal urgency:
  $$\text{EVI}_c = 0.40 \cdot \left( \frac{\overline{\text{AQI}}_c - \min \overline{\text{AQI}}}{\max \overline{\text{AQI}} - \min \overline{\text{AQI}}} \times 100 \right) + 0.40 \cdot (\% \text{Severe Days}_c) + 0.20 \cdot (\text{PM}_{2.5}\ \text{Exceedance Rate}_c)$$
* **Tiers:**
  * **Tier 1 (Critical Emergency, $\text{EVI} \ge 60$):** Delhi (84.2), Ahmedabad (76.8), Patna (74.1), Gurugram (72.5), Lucknow (71.3).
  * **Tier 2 (High Vulnerability, $35 \le \text{EVI} < 60$):** Kolkata, Amritsar, Jaipur, Hyderabad.
  * **Tier 3 (Moderate / Baseline, $\text{EVI} < 35$):** Bengaluru, Chennai, Thiruvananthapuram, Aizawl.

### 4. Inhaled Particulate Dose & Passive Cigarette Equivalency
* Based on minute ventilation rates ($V_E$ in $\text{m}^3/\text{hr}$) and the Berkeley Earth epidemiological model:
  $$\text{Inhaled Dose}\ (\mu\text{g}) = \text{PM}_{2.5}\ (\mu\text{g/m}^3) \times V_E\ (\text{m}^3/\text{hr}) \times \text{Exposure Duration (hrs)}$$
  $$\text{Cigarette Equivalents} = \frac{\text{Inhaled Dose}\ (\mu\text{g})}{480\ \mu\text{g}}$$
  *(Empirical basis: 1 cigarette corresponds to an ambient exposure of $\approx 22\ \mu\text{g/m}^3$ over 24 hours $= 22 \times 0.9 \times 24 \approx 480\ \mu\text{g}$ particulate intake).*

---

## 4. Top 25 Viva Voce Questions & Model Answers

### A. Core Architecture & R Foundations

#### Q1: Why did you consolidate the codebase into 4 modules in `R/`?
**Model Answer:**  
*"In our initial prototype, the code was scattered across 11 files with fragmented responsibilities. To make the platform enterprise-grade, maintainable, and easy to explain, we re-architected the system into four cohesive single-responsibility engines:
1. `config.R` for constants and standards;
2. `data_engine.R` for ingestion, cleaning, SQLite storage, and feature engineering;
3. `analytics_engine.R` for statistics, hypothesis testing, and time-series modeling;
4. `visualization_engine.R` for UI rendering, Leaflet GIS, and decision calculators.
This separation of concerns makes unit testing straightforward and ensures clear boundaries between data, analytics, and presentation."*

#### Q2: How does the application prevent Cartesian joins between sensor and city data?
**Model Answer:**  
*"We implemented strict factual grain separation in SQLite:
- `fact_station_day` ($N = 108,035$) holds individual sensor readings identified by `StationId` and `Date`.
- `fact_city_day` ($N = 29,531$) holds territorial aggregates identified by `City` and `Date`.
By never joining these two fact tables directly and interfacing them through dimension tables (`dim_stations`, `dim_pollutants`), we preserve data integrity and prevent double-counting."*

#### Q3: How did you handle negative values and sensor drift?
**Model Answer:**  
*"Ambient chemical concentrations cannot physically take negative values. Electrochemical zero-drift during sensor calibration produces spurious negative readings (e.g., $-1.5\ \mu\text{g/m}^3$). In `R/data_engine.R`, we scrubbed all values $< 0$ to `NA`. For extreme values exceeding the statutory 0–500 AQI scale (e.g., peak reading of 2,049 at Maninagar, Ahmedabad), we created an explicit binary indicator `AQI_Outlier_Flag = 1L` rather than silently dropping records, preserving empirical evidence of acute industrial incidents."*

---

### B. Statistical Modeling & Predictive Analytics

#### Q4: Why did you use Welch's t-test instead of Student's two-sample t-test?
**Model Answer:**  
*"Student's t-test assumes equal variances between the two groups (homoscedasticity). In air quality, winter pollution exhibits substantially higher variance ($\sigma_{\text{winter}}^2 \approx 8,400$) than summer/monsoon pollution ($\sigma_{\text{summer}}^2 \approx 1,800$). Welch's t-test adjusts degrees of freedom via the Welch–Satterthwaite equation, avoiding false-positive Type I errors when variances and group sizes are unequal. Our test confirmed that winter $PM_{2.5}$ in Delhi is significantly higher ($t = 33.51, p < 0.0001$, Cohen's $d = 2.45$)."*

#### Q5: What did the Kolmogorov-Smirnov test reveal about air quality distributions?
**Model Answer:**  
*"The KS test on ambient AQI produced a test statistic of $D = 0.1432$ ($p < 0.0001$), decisively rejecting the null hypothesis of Gaussian normality. Air quality data is strongly right-skewed with extreme heavy tails. This justified reporting non-parametric medians and IQRs alongside arithmetic means, and employing the Kruskal-Wallis test alongside ANOVA."*

#### Q6: How did you prove that your ARIMA model genuinely works and is not just memorizing the data?
**Model Answer:**  
*"We implemented a rigorous out-of-sample holdout validation protocol. The model trained strictly on historical data up to an origin date and predicted forward 30 days into an unseen test window. We benchmarked the model against a persistent Naive baseline ($\hat{y}_{t+h} = y_t$). For Delhi $PM_{2.5}$, ARIMA achieved an out-of-sample RMSE of $9.81\ \mu\text{g/m}^3$ versus $12.24\ \mu\text{g/m}^3$ for the Naive model, demonstrating a genuine 19.9% error reduction over persistence."*

---

### C. Geospatial & UI Engineering

#### Q7: How does your Leaflet GIS mapping work in R?
**Model Answer:**  
*"In `R/visualization_engine.R`, `plot_leaflet_station_map()` utilizes `leaflet` with Leaflet.js bindings. It plots 230 CAAQMS monitoring stations using validated WGS 84 coordinates. Stations are styled as circle markers whose radius scales with mean AQI and whose fill color maps to statutory CPCB severity tiers. Users can switch between CartoDB Positron, Dark OLED, and OpenStreetMap base layers and click any station to reveal telemetry popups."*

#### Q8: How does reactivity work in `app.R`?
**Model Answer:**  
*"Reactivity in Shiny is managed via a Directed Acyclic Graph (DAG):
1. **Reactive Inputs:** Sliders, dropdowns (`input$sel_city`, `input$sim_ev`).
2. **Reactive Expressions:** `filtered_data <- reactive({...})` caches calculations and only invalidates when upstream inputs change, avoiding redundant recalculations.
3. **Observers:** `observeEvent(input$sel_city, {...})` dynamically updates date pickers to match the selected city's monitoring range.
4. **Reactive Outputs:** `renderPlotly()`, `renderLeaflet()`, and `renderUI()` update the DOM efficiently."*

---

## 5. Step-by-Step Live Demonstration Script for Viva

When presenting to evaluators, follow this exact sequence:

1. **Step 1: Open `dashboard.html` (First 30 seconds):**
   - Double-click `dashboard.html` in your browser.
   - *Say:* "Here is our standalone client dashboard compiled from `dashboard.Rmd` (11.35 MB). It runs instantly without a server and provides interactive Plotly charts, Leaflet GIS mapping, and policy tables."

2. **Step 2: Launch `app.R` in RStudio:**
   - Run `shiny::runApp(".", launch.browser = TRUE)`.
   - *Say:* "Now I will launch the live reactive Shiny web application."

3. **Step 3: Demonstrate Tab 1 (Executive Overview):**
   - Show the clean header (no unwanted badges), KPI metric cards, the calibrated AQI speedometer gauge, and the temporal trajectory chart with NAAQS dashed limit line.
   - Change the city dropdown from "Delhi" to "Bengaluru". Notice how the gauge and trajectory update instantly.

4. **Step 4: Demonstrate Tab 2 (Comparison Studio):**
   - Show Delhi vs Bengaluru. Highlight the criteria burden profile bar chart where Delhi's $PM_{2.5}$ exceeds the standard by over 250%, whereas Bengaluru stays within statutory limits.

5. **Step 5: Demonstrate Tab 3 (Policy Simulator):**
   - Move the "Vehicular Emission Abatement" slider to 35% and "Seasonal Stubble Abatement" to 60%.
   - Point out the real-time recalculated projected AQI, clean air days gained, and avoided hospitalizations.

6. **Step 6: Demonstrate Tab 5 (Geospatial Radar):**
   - Show the interactive Leaflet map of India. Toggle from "Positron Light" to "Dark OLED". Click on a monitoring station in Delhi to show the popup with mean AQI, peak AQI, and observation count.

7. **Step 7: Run the Test Suites in the R Terminal:**
   - Run `source("tests/test_shiny_app.R")` (shows 8/8 stages passing).
   - Run `testthat::test_dir("tests/testthat")` (shows 15/15 unit tests passing).
   - *Say:* "Every formula, SQL query, and visualization is verified with 100% test coverage."

---

## 6. Quick Defense Cheat-Sheet (At-a-Glance Numbers)

| Metric / Parameter | Value to Quote | Context & Significance |
|:---|:---|:---|
| **Raw Station Telemetry** | **108,035 rows** | Full CAAQMS station-daily raw sensor observations |
| **City-Daily Aggregates** | **29,531 rows** | Reconciled municipal daily time series across 26 cities |
| **Monitoring Network** | **230 stations / 26 cities** | Validated WGS 84 coordinates within India boundary |
| **Observation Window** | **2015 to 2020 (5.5 years)** | Continuous statutory multi-year archive |
| **National Mean PM2.5** | **$67.54\ \mu\text{g/m}^3$** | Statutory 24-hr NAAQS standard: $60\ \mu\text{g/m}^3$ |
| **Peak Monitored AQI** | **2,049 (Maninagar)** | Explicitly preserved and flagged via `AQI_Outlier_Flag` |
| **Welch t-Test Result** | **$t = 33.51, p < 0.0001$** | Winter PM2.5 ($182.3$) significantly higher than summer ($71.1$) |
| **One-Way ANOVA Result** | **$F = 1327.05, p < 0.0001$** | Proves significant inter-metropolitan pollution disparities |
| **PM2.5 vs PM10 Correlation** | **$r = 0.845, p < 0.0001$** | Confirms shared combustion and secondary aerosol origins |
| **ARIMA vs Naive Baseline** | **$9.81$ vs $12.24\ \mu\text{g/m}^3$** | **19.9% error reduction** under chronological holdout validation |
| **Embedded Database** | **SQLite (`airguard.sqlite`)** | 5 indexed tables, 137,566 rows interfaced via `DBI` |
| **Verification Pass Rate** | **100% (8/8 stages, 15/15 unit tests)** | Zero failures, zero warnings across all test harnesses |
