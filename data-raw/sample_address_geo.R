# Prepare `sample_address` data set
sample_address_geo <- data.table::fread("data-raw/sample_address_geo.csv", sep = ";")

# Making the sample_address_geo.csv file available
usethis::use_data(sample_address_geo, overwrite = TRUE)
