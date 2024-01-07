test_that("CEP Extraction Test: Only eight digits CEP pattern extraction works!", {

  address <- c("12345-678 Some Street, City, Country", "No ZIP code in this address", "Only subsector 12345")

  expect_equal(extr_cep(address),
                        c("12345678", NA, NA))
})
#> Tested passed

test_that("CEP Extraction Test: Five and Eight digits CEP pattern extraction works!", {

  address <- c("12345-678 Some Street, City, Country", "No ZIP code in this address", "Only subsector 12345")

  expect_equal(extr_cep(address, subsector_as_zip = TRUE),
               c("12345678", NA, "12345"))
})
#> Tested passed
