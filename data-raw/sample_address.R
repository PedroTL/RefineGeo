# Prepare `sample_address` data set
sample_address <- data.table::fread("data-raw/sample_address.csv", sep = ";")

# Making the sample_address.csv file available
usethis::use_data(sample_address.csv, overwrite = TRUE)
