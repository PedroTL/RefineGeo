test_that("clean_address() clean string address", {
  expect_equal(clean_address("Samplê ADReEss  -   Wíth PonctuatìõNs::"), c("SAMPLE ADREESS WITH PONCTUATIONS"))
})
