# Sample Data
df <- data.frame(
  col_cep1 = c("12345677", "12345678", "12345", "12345", "12345"),
  col_cep2 = c("12345678", "12345678", "54321", "123", "12345")
)

test_that("CEP Matching Test: Only eight-digit CEPs that are equal are considered a match", {
  expect_equal(compare_cep(df, "col_cep1", "col_cep2", strict_check = FALSE),
    c(0, 1, NA, NA, NA)
  )
})
#> Test passed

test_that("CEP Matching Test: Five and eight-digit CEPs that are equal are considered a match", {
  expect_equal(compare_cep(df, "col_cep1", "col_cep2", strict_check = TRUE),
    c(0, 1, 0, NA, 1)
  )
})
#> Test passed
