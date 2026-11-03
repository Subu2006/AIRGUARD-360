import os, re

rmd_path = 'reports/airguard_project_report.Rmd'
with open(rmd_path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Update List of Figures
old_lof = """- **Figure 9:** 30-Day Predictive PM2.5 Forecast with 80% and 95% Confidence Intervals for Delhi"""
new_lof = """- **Figure 9:** 30-Day Predictive PM2.5 Forecast with 80% and 95% Confidence Intervals for Delhi
- **Figure 10:** AIRGUARD 360 Interactive Executive Command Center Interface (Real Application Screenshot)
- **Figure 11:** Head-to-Head Multi-City Comparison Studio Interface (Real Application Screenshot)
- **Figure 12:** Out-of-Sample Predictive Forecasting Studio Interface (Real Application Screenshot)
- **Figure 13:** Enterprise Dark-Mode Interface & Policy Intervention Simulator (Real Application Screenshot)
- **Figure 14:** Responsive Mobile Form-Factor View & Health Exposure Dose Calculator (Real Application Screenshot)"""

if old_lof in text:
    text = text.replace(old_lof, new_lof)
    print(">> [SUCCESS] Updated List of Figures in Rmd")
else:
    print(">> [WARNING] old_lof pattern not found directly, trying regex")
    text = re.sub(r"- \*\*Figure 9:\*\* 30-Day Predictive.*Delhi", new_lof, text)

# 2. Update Subsection 4.11 with screenshots
old_sub411 = """### iv. Analysis Results
The dashboard features six specialized functional tabs:
1. **Executive Overview:** Dynamic KPI value boxes, temporal trajectories with 7-day moving averages, and CPCB category donut charts.
2. **Geographic Intelligence:** 230-station interactive CAAQMS map, hotspot ranking bar charts, and searchable EVI datatables.
3. **Pollutant Dynamics:** Pearson correlation heatmaps and stoichiometric scatter plots with linear regression trends.
4. **Volatility & Bollinger Bands:** 20-day volatility bands with episodic surge markers.
5. **Statistical & Predictive Models:** Hypothesis test summaries and 30-day ARIMA/Holt-Winters forecasting with benchmark metrics.
6. **Decision Support & Text Mining:** Simulated GRAP advisories, advisory word cloud, and live SQLite query runner."""

new_sub411 = """### iv. Analysis Results & Enterprise Application Architecture
The operational deployment delivers eight interconnected analytical and decision-support modules rendered natively in R:

1. **Executive Command Center:** Real-time KPI value boxes, dual-scale Plotly trajectories with 7-day moving average smoothers, and statutory CPCB category donut charts.
2. **Head-to-Head Multi-City Comparison Studio:** Interactive side-by-side comparative benchmarking contrasting any two Indian metropolises (e.g., Delhi vs. Bengaluru) across simultaneous time-series trajectories, multi-pollutant criteria burden profiles (% of NAAQS standards), and empirical delta disparity indicators.
3. **Policy Intervention & What-If Scenario Simulator:** Empirical policy planning tool simulating the environmental and public-health impacts of four municipal intervention levers: electric vehicle (EV) fleet transition, construction fugitive dust suppression, seasonal crop residue biomass management, and industrial stack scrubbers. Live reactive recalculation estimates projected mean AQI, clean air days gained, and avoided acute respiratory admissions.
4. **Personal Health & Inhaled Particulate Dose Calculator:** Citizen science utility calculating estimated physical PM2.5 intake mass ($\\mu\\text{g}$) and equivalent passive cigarette smoke consumption using EPA minute ventilation coefficients ($V_E$) tailored to age cohorts (children, healthy adults, asthmatics, seniors) and physical exertion intensity.
5. **Geospatial Intelligence & Hotspots:** Interactive nationwide scattergeo bubble map across all 230 continuous monitoring stations, municipal vulnerability ranking charts, and color-coded priority tier tables.
6. **Predictive Time-Series Forecasting:** Chronological holdout validation comparing ARIMA(1,1,1) and Holt-Winters against a Naive Persistence Baseline with 80% and 95% confidence intervals.
7. **Multi-Pollutant Dynamics & Text Mining:** Pearson collinearity heatmaps, particulate stoichiometry scatter plots, statutory advisory word clouds, and embedded SQLite relational queries.
8. **Academic Credentials & Export Center:** Complete curriculum syllabus mapping and direct one-click CSV export utilities.

### v. Real Application Interface Visualizations

```{r fig10_render, fig.cap="Figure 10: AIRGUARD 360 Interactive Executive Command Center Interface (Real Application Screenshot showing Dynamic City Filters, KPI Metric Cards, and Plotly Trajectory Smoother)", out.width="100%"}
knitr::include_graphics("../outputs/figures/fig10_dashboard_overview.png")
```

\\newpage

```{r fig11_render, fig.cap="Figure 11: Real Application Screenshot of the Multi-City Comparison Studio Contrasting Delhi vs. Bengaluru Multi-Pollutant Burden Profiles and Synchronized Trajectories", out.width="100%"}
knitr::include_graphics("../outputs/figures/fig11_dashboard_comparison.png")
```

\\newpage

```{r fig12_render, fig.cap="Figure 12: Real Application Screenshot of the Predictive Forecasting Studio (Out-of-Sample ARIMA Projections with 80% and 95% Confidence Intervals benchmarked against Naive Baseline)", out.width="100%"}
knitr::include_graphics("../outputs/figures/fig12_dashboard_forecast.png")
```

\\newpage

```{r fig13_render, fig.cap="Figure 13: Real Application Screenshot of Enterprise Dark-Mode Interface & Policy Intervention Scenario Simulator", out.width="100%"}
knitr::include_graphics("../outputs/figures/fig13_dashboard_darkmode.png")
```

\\newpage

```{r fig14_render, fig.cap="Figure 14: Real Application Screenshot of Responsive Mobile Form-Factor View and Personal Environmental Exposure Dose Calculator", out.width="60%", fig.align="center"}
knitr::include_graphics("../outputs/figures/fig14_dashboard_mobile.png")
```"""

if old_sub411 in text:
    text = text.replace(old_sub411, new_sub411)
    print(">> [SUCCESS] Updated Subsection 4.11 in Rmd with real application screenshots")
else:
    print(">> [WARNING] old_sub411 not found directly, performing flexible replacement")
    pattern = r"### iv\. Analysis Results\s+The dashboard features six specialized functional tabs:.*?live SQLite query runner\."
    text = re.sub(pattern, new_sub411, text, flags=re.DOTALL)

with open(rmd_path, 'w', encoding='utf-8') as f:
    f.write(text)

print(">> [SUCCESS] Saved updated reports/airguard_project_report.Rmd")
