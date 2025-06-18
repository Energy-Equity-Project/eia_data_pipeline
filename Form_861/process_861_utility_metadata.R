
# Libraries=====================================================================
library(tidyverse)
library(readxl)
library(janitor)

# Function: clip dataframe to only include metadata of Form 861 utilities=======
clip_utility_metadata <- function(df) {
  
  # Find where metadata ends - where residential revenue, mWh sales and customer count start
  res_idx <- which(df %>% colnames() %>% tolower() == "residential")
  # Isolate columns that only contain data describing utilities (metadata)
  df_metadata <- df[1:res_idx-1] %>%
    drop_na(1) %>%
    row_to_names(row_number = 1) %>%
    clean_names() %>%
    distinct() %>%
    # Remove columns where there is no utility name
    # (to remove rows that just have spreadsheet notes)
    filter(!is.na(utility_name))
  
  return(df_metadata)
}

# Function: processes EIA 861 utility metadata==================================
process_utility_metadata <- function(form_861_fps) {
  
  # Aggregator dataframe that contains all metadata
  utility_metadata <- data.frame()
  
  for (curr_fp in form_861_fps) {
    
    print(paste0("Processing utility metadata for...", curr_fp))
    
    sales_sheet_names <- excel_sheets(curr_fp)
    # Not processing utility decoupled data
    sales_sheet_names <- sales_sheet_names[sales_sheet_names != "Decoupled"]
    sales_sheets <- lapply(sales_sheet_names, read_excel, path = curr_fp)
    
    # Combining state and territory utility data
    # (have different names for the sheets across different years)
    for (sheet_idx in length(sales_sheets)) {
      # Collecting all metadata across all years into 1 dataframe
      utility_metadata <- utility_metadata %>%
        bind_rows(
          sales_sheets[[sheet_idx]] %>%
            clip_utility_metadata()
        ) %>%
        distinct()
    }
  }
  
  return(utility_metadata)
}