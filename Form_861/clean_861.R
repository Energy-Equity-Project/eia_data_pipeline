
# Libraries=====================================================================
library(tidyverse)
library(janitor)
library(readxl)

# Source functions and scripts==================================================
source("Form_861/process_861_utility_metadata.R")

# Directory structure===========================================================
datadir <- "../../Data/EIA/861/Form 861 - unzipped"
outdir <- "Form_861/outputs"

# Data cleaning process=========================================================

# Find all sales data
sales_files <- list.files(
  path = datadir,
  pattern = "^Sales_Ult_Cust_[0-9][0-9][0-9][0-9]\\.xlsx",
  full.names = TRUE
)


# Get utility metadata across all files and years
utility_metadata <- process_utility_metadata(sales_files)

# Dataframe to collect all cleaned data
form_861 <- data.frame()


