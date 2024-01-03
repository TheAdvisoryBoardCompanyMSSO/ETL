
library(xlsx)
library(readxl)
library(dplyr)
library(odbc)
library(stringr)

# Directory containing Excel files
folder_path <- "C:/Box/Box/FunnelDashboard/PDR\ Performance/Originating_Files"

# List Excel files in the directory
excel_files <- list.files(folder_path, pattern = "\\.xlsx$", full.names = TRUE)


# Get the most recent Excel file based on modification time
file_name <- "C:/Box/Box/FunnelDashboard/PDR Performance/Originating_Files/VisitReviewV1.1 FY24.xlsx"


# We need a check to make sure the file was saved today, otherwise the data will not be updated
last_updated <- lubridate::date(file.info(file_name)$mtime)

if (lubridate::date(Sys.Date()) == last_updated) {
  print("Good to go, data is fresh")
  
} else {
  print("Oh boy, data is stale")
}
  


# Read the specified sheet from the Excel file into a df
if (file.exists(file_name)) {
  lob_data <- readxl::read_excel(file_name, sheet = "FY24Summary_ForSQL", col_names = T, col_types = "text")
  #pde_data <- readxl::read_excel(file_name, sheet = "FY24 PDE View", col_names = T, col_types = "text")
} else {
  print("No Excel file found in the specified folder.")
}


# How do we get this into the format we want for uploading 
# Vertical, LOB, FY, FYQ, Date (Year-Month-Day), MQL, MQL Goal, Percent Goal, Visit
#, Visit Goal, % Goal, Exclude, Program Acronym, BusinessLine

# Create two data sets, one for each month
base_columns <- c("Vertical", "LOB", "ProgramAcronym")

first_month <- lob_data %>% select(all_of(base_columns))
second_month <- lob_data %>% select(all_of(base_columns))

# Now we want to get all of the columns with the same month in them
# First let's get the first string out of all of the columns
col_names <- colnames(lob_data)
col_names <- col_names[!col_names %in% base_columns]

first_words <- stringr::word(col_names,1)
unique_words <- unique(first_words)

first_month_col <- lob_data %>% select(contains(unique_words[1]))
second_month_col <- lob_data %>% select(contains(unique_words[2]))


# Getting date for today
today <- Sys.Date()

month <- as.character(lubridate::month(today, label=T, abbr=F))

month_name <- c("January", "February", "March", "April",
                "May", "June", "July", "August", "September",
                "October", "November", "December")

month_fom <- c("2024-01-01", '2024-02-01', '2024-03-01', '2024-04-01', '2024-05-01', '2024-06-01',
               "2023-07-01", '2023-08-01', '2023-09-01-01', '2023-10-01', '2023-11-01', '2023-12-01')


fom_df <- data.frame(month_name, month_fom)

first_month_date <- rep(fom_df[which(month_name == unique_words[1]), "month_fom"], nrow(first_month_col))

first_month <- data.frame(first_month, month_date = first_month_date, first_month_col)

second_month_date <- rep(fom_df[which(month_name == unique_words[2]), "month_fom"], nrow(second_month_col))

second_month <- data.frame(second_month, month_date = second_month_date, second_month_col)

# Clean column names

for(col in 1:ncol(second_month)) {
colnames(second_month)[col] <- sub(unique_words[2], "", colnames(second_month)[col])
}

for(col in 1:ncol(first_month)) {
  colnames(first_month)[col] <- sub(unique_words[1], "", colnames(first_month)[col])
}

# Combine months
combined_data <- rbind(first_month, second_month)

lob_col <- combined_data$LOB

# Add Columns to match SQL
data_for_export <- cbind(combined_data, exclude = 0, lob_consolidated = lob_col)

# Lastly Rename Columns to Align with SQL
sql_colnames <- c("Vertical", "LOB_in_VR", "ProgramAcronym", "Month", "MQL", "MQL_Goal",
                  "Percent_MQL_Goal", "Visit", "Visit_Goal", "Percent_Visit_Goal", "Exclude",
                  "LOB_Consolidated")

colnames(data_for_export) <- sql_colnames

# System Environment password
password <- Sys.getenv("SQL_DB_PWD")

# Connect to database
con <- DBI::dbConnect(odbc::odbc(),
                      Driver   = "ODBC Driver 17 for SQL Server",
                      Server   = "awscitwmdb-p01.myeab.com",
                      Database = "EDSOAnalytics",
                      UID      = "MYEAB/jowilson",
                      PWD 		= password,
                      Trusted_Connection='yes',
                      Port = 1433)

odbc::dbWriteTable(con,  "VisitReview_ETL", data_for_export, row.names = FALSE)


