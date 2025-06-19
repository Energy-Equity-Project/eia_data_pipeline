
# Libraries=====================================================================
library(tidyverse)
library(janitor)
library(readxl)

# Source functions and scripts==================================================
source("Form_861/process_861_utility_metadata.R")
source("Form_861/process_861_utility_sales.R")

# Directory structure===========================================================
datadir <- "../../Data/EIA/861/Form 861 - unzipped"
outdir <- "outputs"

# Data cleaning process=========================================================

# Find all sales data
sales_files <- list.files(
  path = datadir,
  pattern = "^Sales_Ult_Cust_[0-9][0-9][0-9][0-9]\\.xlsx",
  full.names = TRUE
)


# Get utility metadata across all files and years
utility_metadata <- process_utility_metadata(sales_files)

write.csv(
  utility_metadata,
  file.path(outdir, "form_861_utility_metadata.csv"),
  row.names = FALSE
)

# Get utility sales and rates across all files and years
utility_sales <- process_utility_sales(sales_files) # Note: adjustments are still included in sales data

write.csv(
  utility_sales,
  file.path(outdir, "form_861_utility_sales.csv"),
  row.names = FALSE
)
