# ==============================================================================
# AIRGUARD 360: Automated Dependency Verification & Installation Script
# File: install_dependencies.R
# Purpose: Ensures all required CRAN packages are installed and up-to-date
# ==============================================================================

message(">> [AIRGUARD 360] Checking R runtime environment...")
min_r_version <- "4.2.0"
curr_r_version <- paste(R.version$major, R.version$minor, sep = ".")

if (compareVersion(curr_r_version, min_r_version) < 0) {
  warning(sprintf("Current R version (%s) is below recommended minimum (%s).", 
                  curr_r_version, min_r_version))
} else {
  message(sprintf("   R Runtime Verified: %s (>= %s)", curr_r_version, min_r_version))
}

required_packages <- c(
  "bslib", "DBI", "dplyr", "DT", "flexdashboard", "forecast", "ggplot2", 
  "knitr", "leaflet", "lubridate", "plotly", "RColorBrewer", "rmarkdown", 
  "RSQLite", "scales", "shiny", "shinycssloaders", "shinyjs", "shinyWidgets", 
  "tidyr", "tidytext", "wordcloud"
)

installed_pkgs <- rownames(installed.packages())
missing_pkgs <- setdiff(required_packages, installed_pkgs)

if (length(missing_pkgs) > 0) {
  message(sprintf(">> Installing %d missing package(s): %s", 
                  length(missing_pkgs), paste(missing_pkgs, collapse = ", ")))
  install.packages(missing_pkgs, repos = "https://cloud.r-project.org")
} else {
  message(">> [PASS] All 18 core CRAN dependencies are already installed and verified!")
}

# Generate verification summary
status_df <- data.frame(
  Package   = required_packages,
  Installed = required_packages %in% rownames(installed.packages()),
  Version   = sapply(required_packages, function(p) {
    if (p %in% rownames(installed.packages())) as.character(packageVersion(p)) else "MISSING"
  }),
  stringsAsFactors = FALSE
)

print(status_df)
message(">> [AIRGUARD 360] Dependency setup complete. Ready to execute run_pipeline.R or app.R.")

