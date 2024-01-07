test_that("CEP Extraction Test: Only eight digits CEP pattern extraction works!", {
  expect_equal(extr_cep(c("12345-678 Some Street, City, Country", "No ZIP code in this address", "Only subsector 12345")),
                        c("12345678", NA, NA))
})
#> Tested passed

test_that("CEP Extraction Test: Five and Eight digits CEP pattern extraction works!", {
  expect_equal(extr_cep(c("12345-678 Some Street, City, Country", "No ZIP code in this address", "Only subsector 12345"), subsector_as_zip = TRUE),
               c("12345678", NA, "12345"))
})
#> Tested passed
