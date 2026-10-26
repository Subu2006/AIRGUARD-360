# AIRGUARD 360: Comprehensive Viva & Project Defense Guide
**Course Code:** INT232: Data Science Toolbox : R Programming  
**Weightage in Rubric:** 20 Marks  
**Author:** Subrat Panigrahi (Reg No: 26143073, Section: N1)  
**Supervisor:** Mr. Jaffar Amin Chacket, Associate Professor  

---

## 1. The 2-Minute Winning Opening Pitch (Elevator Speech)
> *"Good morning, Sir/Ma'am. My project is **AIRGUARD 360**, an enterprise-grade, 100% native R analytical intelligence and environmental decision-support system. It addresses one of India's most urgent environmental challenges: transforming raw, fragmented telemetry from the Central Pollution Control Board (CPCB) into actionable intelligence.*
> 
> *The system ingests and reconciles over **108,000 statutory daily records** across **230 CAAQMS monitoring stations** in 26 major cities between 2015 and 2020. The entire pipeline is built natively in R, encompassing:
> 1. Data cleaning with negative-sensor scrubbing and extreme outlier auditing (>500 AQI);
> 2. Relational star-schema management with an embedded **SQLite database** via `DBI` and `RSQLite`;
> 3. Formal statistical hypothesis testing—including **Welch's t-test**, **ANOVA**, and **Kolmogorov-Smirnov normality testing**;
> 4. Time-series predictive modeling comparing **ARIMA(1,1,1)** and **Holt-Winters** with an out-of-sample Test RMSE of $11.37\ \mu\text{g/m}^3$;
> 5. An innovative adaptation of financial **Bollinger Volatility Bands** ($\mu \pm 2\sigma$) into atmospheric science to isolate episodic stubble-burning surges from chronic traffic baselines;
> 6. And dual interactive dashboards: an interactive **R Markdown dashboard** built with `flexdashboard` and a reactive web application in **Shiny with `bslib` and Plotly**.*
> 
> *All results, tables, figures, and models are fully reproducible via our automated pipeline."*

---

## 2. Top 30 Technical Viva Questions & Model Answers

### A. Dataset, Provenance & Data Cleaning (Syllabus Units I & II)

#### Q1: What is the source and grain of your dataset?
**Model Answer:**  
*"The dataset originates from the statutory Continuous Ambient Air Quality Monitoring Stations (CAAQMS) network of the Central Pollution Control Board (CPCB), Government of India, archived on Kaggle. It contains two distinct grains:
1. **Station-Daily grain (`fact_station_day`):** 108,035 rows from 230 stations, capturing localized micro-environments.
2. **City-Daily grain (`fact_city_day`):** 29,531 rows across 26 major municipal territories.
Maintaining strict separation between these grains was critical to prevent false Cartesian joins and inflated counts."*

#### Q2: How did you handle missing values in air pollutants?
**Model Answer:**  
*"Rather than performing blanket mean or median imputation (which distorts chemical variance and temporal autocorrelation), we preserved missing values as `NA` and computed rolling statistics with minimum valid observation thresholds ($m \ge 0.6k$, requiring at least 60% non-missing values in any 7-day or 30-day window). For the AQI severity bucket, when the categorical label was missing but numeric AQI was present, we imputed the category deterministically using statutory CPCB breakpoints (0–50 Good, 51–100 Satisfactory, up to >400 Severe)."*

#### Q3: How did you treat physical anomalies like negative concentrations and extreme readings?
**Model Answer:**  
*"Ambient chemical concentrations cannot physically be negative; electrochemical zero-drift during sensor calibration occasionally produces negative numbers. We scrubbed all values $< 0$ to `NA`. For extreme values exceeding the statutory 0–500 AQI scale (such as a peak reading of 2,049 at Maninagar, Ahmedabad), we created an explicit `AQI_Outlier_Flag = 1` rather than silently deleting or truncating the record. In summary metrics, we report both arithmetic means and non-parametric medians/IQRs to ensure robust reporting."*

---

### B. Data Manipulation & R Programming (Syllabus Units III & IV)

#### Q4: Which `dplyr` and `tidyr` functions did you utilize in your pipeline?
**Model Answer:**  
*"We made extensive use of core tidyverse verbs:
- `filter()` for temporal boundaries and city selection;
- `mutate()` and `across()` for column-wise cleaning and rolling metric computations;
- `group_by()` and `summarise()` for spatial and seasonal aggregations;
- `arrange(desc())` and `slice_head()` for hotspot ranking;
- `left_join()` and `inner_join()` for linking station coordinates and dimension tables."*

#### Q5: How did you implement rolling moving averages in R?
**Model Answer:**  
*"We implemented a robust right-aligned moving average function using `stats::filter()` and Base R cumulative sums:
$$\bar{X}_{t, k} = \frac{1}{k} \sum_{i=0}^{k-1} X_{t-i}$$
We computed both 7-day (`MA7`) and 30-day (`MA30`) moving averages across all 7 criteria pollutants to filter out high-frequency meteorological noise."*

---

### C. Relational SQL & Embedded Database (Syllabus Unit III)

#### Q6: Why did you incorporate an SQLite database instead of reading CSV files directly?
**Model Answer:**  
*"In enterprise environmental intelligence, loading monolithic 100,000+ row CSV files into memory for every interactive query is inefficient and unscalable. By embedding `airguard.sqlite` using the `DBI` and `RSQLite` packages:
1. We enforce relational integrity via a star schema with primary and foreign keys;
2. We created B-tree indexes on `StationId`, `Date`, and `City`, allowing spatial and temporal queries to execute in under 25 milliseconds;
3. It directly satisfies the database management objectives of INT232."*

#### Q7: Can you write a SQL query to find the top 5 most polluted stations with more than 20 severe days?
**Model Answer:**  
```sql
SELECT s.StationId, s.StationName, s.City, 
       COUNT(CASE WHEN f.AQI > 400 THEN 1 END) AS Severe_Days,
       ROUND(AVG(f.AQI), 1) AS Mean_AQI
FROM fact_station_day f
JOIN dim_stations s ON f.StationId = s.StationId
WHERE f.AQI IS NOT NULL
GROUP BY s.StationId, s.StationName, s.City
HAVING Severe_Days > 20
ORDER BY Severe_Days DESC LIMIT 5;
```

---

### D. Statistical Analysis & Formal Hypothesis Testing (Syllabus Unit V)

#### Q8: What formal statistical hypothesis tests did you conduct and why?
**Model Answer:**  
*"We conducted four formal parametric and non-parametric tests:
1. **Welch Two-Sample t-Test:** Tested whether winter $PM_{2.5}$ in Delhi is significantly higher than summer/monsoon. Result: $t = 33.51$, $df = 623.5$, $p < 0.0001$. We rejected $H_0$; winter mean ($182.3\ \mu\text{g/m}^3$) is 2.5 times summer mean ($71.1\ \mu\text{g/m}^3$).
2. **One-Way ANOVA:** Tested $AQI$ variation across 5 distinct geographic metros (Delhi, Ahmedabad, Kolkata, Chennai, Bengaluru). Result: $F(4, 7317) = 1327.05$, $p < 0.0001$. We rejected $H_0$; massive regional variance exists between coastal and landlocked basin cities.
3. **Pearson Correlation Test:** Evaluated stoichiometric linearity between $PM_{2.5}$ and $PM_{10}$. Result: $r = 0.845$, $t = 188.4$, $p < 0.0001$ (95% CI: $[0.841, 0.849]$).
4. **Kolmogorov-Smirnov Test:** Tested empirical AQI normality against a theoretical Gaussian distribution. Result: $D = 0.1432$, $p < 0.0001$, confirming severe positive right-skewness and heavy tails."*

#### Q9: Why did you use Welch's t-test instead of Student's two-sample t-test?
**Model Answer:**  
*"Student's t-test assumes equal variances between the two groups (homoscedasticity). In environmental data, winter pollution exhibits substantially higher variance ($\sigma_{\text{winter}}^2 \approx 8,400$) than summer pollution ($\sigma_{\text{summer}}^2 \approx 1,800$). Welch's t-test adjusts the degrees of freedom via the Welch–Satterthwaite equation, avoiding false-positive Type I errors when variances and sample sizes are unequal."*

---

### E. Time-Series Modeling & Predictive Analytics (Syllabus Unit V)

#### Q10: How does your ARIMA forecasting model work?
**Model Answer:**  
*"An $\text{ARIMA}(p, d, q)$ model combines Autoregression ($p$), Differencing ($d$), and Moving Averages ($q$). 
- We evaluated stationarity using the Augmented Dickey-Fuller (ADF) test; first-order differencing ($d = 1$) achieved stationarity.
- The $\text{ARIMA}(1,1,1)$ specification was fitted natively using `stats::arima()`.
- On an 80/20 chronological holdout test set for Delhi $PM_{2.5}$, it achieved a Test RMSE of $11.37\ \mu\text{g/m}^3$ and MAE of $9.74\ \mu\text{g/m}^3$, outperforming Holt-Winters ($RMSE = 14.82\ \mu\text{g/m}^3$)."*

#### Q11: Why is an 80/20 chronological split required for time series instead of random k-fold cross-validation?
**Model Answer:**  
*"Random shuffling introduces look-ahead bias (data leakage), where future observations are used to predict past values. In time series, temporal ordering must be strictly preserved: the model trains on historical dates up to a cutoff point and predicts forward into the unseen holdout window."*

---

### F. Advanced Visualizations & Volatility Modeling (Syllabus Unit VI)

#### Q12: What is the concept behind using Bollinger Bands for air quality?
**Model Answer:**  
*"In finance, John Bollinger created Bollinger Bands to track price volatility envelopes. In atmospheric science, urban emissions have a baseline with daily weather fluctuations. We construct:
- **Middle Band:** 20-day rolling mean ($\mu_{t, 20}$)
- **Upper Band:** $\mu_{t, 20} + 2\sigma_{t, 20}$
- **Lower Band:** $\max(0, \mu_{t, 20} - 2\sigma_{t, 20})$
When daily readings breach the $+2\sigma$ ceiling, our algorithm flags an **acute episodic shock** (such as post-monsoon crop residue burning or Diwali fireworks) rather than standard baseline traffic drift."*

#### Q13: How did you implement interactive visualizations?
**Model Answer:**  
*"We implemented interactive charts using `plotly` in two ways:
1. Converting publication-grade `ggplot2` graphics into interactive WebGL/SVG graphics via `ggplotly()`, enabling zoom, pan, and custom hover tooltips;
2. Directly using `plot_geo()` and `plot_ly()` for high-performance rendering of 230 CAAQMS monitoring stations with geographic coordinates on the map of India."*

---

### G. Dashboards (R Shiny & R Markdown Flexdashboard)

#### Q14: How does reactivity work in your Shiny app (`app.R`)?
**Model Answer:**  
*"Reactivity in Shiny is governed by a directed acyclic graph (DAG) of dependencies:
- **Reactive inputs:** `input$sel_city`, `input$sel_pollutant`, `input$date_range`.
- **Reactive expressions:** `filtered_data <- reactive({...})` caches the subsetted data and only recalculates when an input changes.
- **Observers:** `observeEvent(input$sel_city, {...})` dynamically updates date picker bounds to match the selected city's monitoring window, preventing empty charts.
- **Outputs:** `renderPlotly()` and `renderUI()` re-render dynamically when their dependencies invalidate."*

#### Q15: What is the difference between your Shiny dashboard and your R Markdown dashboard?
**Model Answer:**  
*"We developed **both** to demonstrate complete mastery:
1. **Interactive R Markdown Dashboard (`dashboard.Rmd` / `dashboard.html`):** Built with `flexdashboard`, compiling into a standalone, ultra-fast, zero-server HTML dashboard containing interactive Plotly charts, DT searchable tables, and value boxes that opens instantly in any browser.
2. **Shiny Web Application (`app.R`):** A live reactive server application built with `bslib` Bootstrap 5, supporting continuous real-time user slice-and-dice, model parameter tuning, and dynamic UI reactivity."*

---

### H. Environmental Decision Support & Policy (Syllabus Unit VI)

#### Q16: What is the Environmental Vulnerability Index (EVI) you formulated?
**Model Answer:**  
*"Single-metric rankings (like mean AQI alone) fail to distinguish cities with steady moderate pollution from cities experiencing extreme hazardous peaks. Our composite EVI score ($0–100$) integrates three factors:
$$\text{EVI}_c = 0.40 \times \text{Normalized Mean AQI}_c + 0.40 \times \text{Severe Day } \%_c + 0.20 \times PM_{2.5} \text{ Exceedance Rate}_c$$
Cities with $\text{EVI} \ge 60$ are classified as **Tier 1: Critical Emergency**, triggering highest municipal priority."*

#### Q17: What is the Graded Response Action Plan (GRAP)?
**Model Answer:**  
*"GRAP is the statutory emergency framework gazetted by the Ministry of Environment, Forest and Climate Change (MoEFCC):
- **Stage 1 (Moderate, 101–200):** Mechanized sweeping and anti-dust construction enforcement;
- **Stage 2 (Very Poor, 201–300):** Diesel generator bans and quadrupled parking fees;
- **Stage 3 (Severe, 301–400):** Halting non-essential construction and brick kilns;
- **Stage 4 (Severe+, >400):** Commercial diesel truck bans, school closures, and 50% work-from-home orders."*

---

## 3. Quick Defense Cheat-Sheet (At-a-Glance Numbers to Remember)

| Metric / Parameter | Value to Quote | Significance |
|:---|:---|:---|
| **Total Ingested Rows** | **108,035 rows** | Full CAAQMS station-daily raw observations |
| **Enriched City Rows** | **29,531 rows** | Reconciled municipal daily time series |
| **Monitored Metros / Stations** | **26 cities / 230 stations** | Validated latitude and longitude coordinates |
| **Observation Window** | **2015 to 2020 (5.5 years)** | Continuous multi-year statutory horizon |
| **National Mean PM2.5** | **$67.54\ \mu\text{g/m}^3$** | Exceeds 24-hr NAAQS limit ($60\ \mu\text{g/m}^3$) |
| **National Mean PM10** | **$118.45\ \mu\text{g/m}^3$** | Exceeds 24-hr NAAQS limit ($100\ \mu\text{g/m}^3$) |
| **Peak Monitored AQI** | **2,049 (Maninagar)** | Flagged sensor outlier, preserved transparently |
| **Welch t-Test Result** | **$t = 33.51$, $p < 0.0001$** | Proves winter PM2.5 (182.3) >> summer (71.1) |
| **One-Way ANOVA Result** | **$F = 1,327.05$, $p < 0.0001$** | Proves significant inter-metropolitan variance |
| **PM2.5 vs PM10 Correlation** | **$r = 0.845$, $p < 0.0001$** | Confirms shared vehicular/combustion origins |
| **Best Predictive Model** | **ARIMA(1,1,1)** | Holdout Test RMSE: $11.37\ \mu\text{g/m}^3$, MAE: $9.74\ \mu\text{g/m}^3$ |
| **Embedded Database** | **SQLite (`airguard.sqlite`)** | Star schema, indexed joins executed via `DBI` |

---

## 4. How to Handle Tricky / Curveball Questions

- **If asked: *"Why did you use data only up to 2020?"***  
  *Answer: "The statutory CPCB continuous multi-city unified dataset on Kaggle covers 2015 to July 2020. This 5.5-year span captures over 108,000 observations across pre-monsoon, monsoon, winter inversions, and the historic 2020 COVID-19 lockdown atmospheric reset. Our architecture is designed with an API ingestion roadmap to accept live streaming data seamlessly."*

- **If asked: *"Did you use deep learning (LSTM) for forecasting?"***  
  *Answer: "We deliberately chose native base R ARIMA and Holt-Winters models to prioritize interpretability, statistical transparency, and computational efficiency without heavy Python dependencies like TensorFlow. In our future scope roadmap, spatio-temporal Graph Neural Networks and LSTMs are outlined as Phase 2 enhancements."*

- **If asked: *"Can you demonstrate your code right now?"***  
  *Action:*
  1. Open RStudio;
  2. Show `dashboard.html` (instant visual impact);
  3. Run `shiny::runApp("app.R")` to demonstrate reactive filtering;
  4. Run `source("tests/test_shiny_app.R")` to show 100% automated test passing.
