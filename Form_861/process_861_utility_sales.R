
# Libraries=====================================================================
library(tidyverse)
library(readxl)
library(janitor)

# Function: isolates specific customer base sales===============================
clip_customer_base_sales <- function(df, customer_base) {
  
  # Always find residential column to specify when utility metadata ends
  metadata_ends <- which(tolower(colnames(df)) == "residential") - 1
  
  # Find which columns relate to the specific customer base utility sales
  # customer base: residential/industrial/commercial
  customer_base_idx <- which(tolower(colnames(df)) == customer_base)
  
  # Columns that are always available: Data year, utility number, utility name, state
  df_sales <- df[c(1:metadata_ends, c(customer_base_idx:(customer_base_idx+2)))] %>%
    drop_na(1) %>%
    row_to_names(row_number = 1) %>%
    clean_names() %>%
    distinct() %>%
    # Sometimes "thousand_dollars" is written as "thousands_dollars"
    # we need to standardize this column name to "thousand_usd"
    rename(any_of(c("thousand_dollars" = "thousands_dollars"))) %>%
    rename(thousand_usd = thousand_dollars,
           mWh = megawatthours,
           customer_count = count) %>%
    # Remove columns where there is no utility name
    # (to remove rows that just have spreadsheet notes)
    filter(!is.na(utility_name)) %>%
    select(data_year, utility_number, utility_name, state, thousand_usd, mWh, customer_count) %>%
    mutate(
      data_year = as.numeric(data_year),
      utility_number = as.numeric(utility_number),
      # Tranform column types to numeric for rate calculation
      thousand_usd = as.numeric(thousand_usd),
      mWh = as.numeric(mWh),
      customer_count = as.numeric(customer_count)
    ) %>%
    # Calculate rate in cents per kWh
    # thousand usd * (1000 usd) * (100 cents per usd)
    # kWh = mWh * 1000
    mutate(rate_c_per_kWh = (thousand_usd * 1000 * 100) / (mWh * 1000)) %>%
    # Add customer base as an additional column
    mutate(customer_base = customer_base)
  
  return(df_sales)
}

# Function: Clip utility sales data=============================================
clip_utility_sales <- function(df) {
  
  # Residential customer utility sales
  res_sales <- clip_customer_base_sales(df, "residential")
  # Industrial customer utility sales
  ind_sales <- clip_customer_base_sales(df, "industrial")
  # Commercial customer utility sales
  comm_sales <- clip_customer_base_sales(df, "commercial")
  
  # Combine all customer base sales together
  sales <- res_sales %>%
    bind_rows(ind_sales) %>%
    bind_rows(comm_sales)
  
  return(sales)
}

# Function: that processes utility sales data 
process_utility_sales <- function(form_861_fps) {
  # Aggregator dataframe that contains all metadata
  utility_sales <- data.frame()
  
  # Iterate through all files to clean and process utility sales data
  for (curr_fp in form_861_fps) {
    
    print(paste0("Processing utility sales for: ", curr_fp))
    
    sales_sheet_names <- excel_sheets(curr_fp)
    # Not processing utility decoupled data
    sales_sheet_names <- sales_sheet_names[sales_sheet_names != "Decoupled"]

    # Combining state and territory utility data
    # (have different names for the sheets across different years)
    for (sheet_idx in 1:length(sales_sheet_names)) {
      # Read the current sheet of data
      curr_sheet <- suppressMessages(read_excel(path = curr_fp, sheet = sales_sheet_names[sheet_idx]))
      
      # Collecting all metadata across all years into 1 dataframe
      utility_sales <- utility_sales %>%
        bind_rows(
          curr_sheet %>%
            clip_utility_sales()
        ) %>%
        distinct()
    }
  }
  
  return(utility_sales)
}