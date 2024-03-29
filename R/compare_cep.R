#' Compare Two ZIP Codes for Equality
#'
#' This function compares two CEPs for equality based on specific criteria.
#'
#' @param df A data frame containing the columns with CEP information.
#' @param col_cep1,col_cep2 Column name for the first and second CEP.
#' @param strict_check Logical indicating whether to perform strict checking on 5-digit CEPs.
#'                     If `TRUE`, evaluates 5-digit codes; if `FALSE`, evaluates only 8-digit codes.
#'                     Default is `FALSE.`
#' @return A vector of the same length whit 1s and 0s. This indicates the comparison result for each row of CEPs in the data frame.
#'         Returns NA for rows not adhering to the criteria (e.g., not 8 or 5 digits).
#'
#' @details
#' This function compares two CEPs for equality based on specific criteria.
#' It checks whether the CEP in two columns of a data frame match certain patterns (8 or 5 digits).
#' The `strict_check` argument allows for strict checking of 5-digit codes.
#' If the CEP adhere to the specified criteria, the function returns 1 for a match, 0 for a mismatch,
#' and NA for values not meeting the criteria.
#'
#' @examples
#' df <- data.frame(cep1 = c("12345", "12345678", "12345", "12345", "12345"),
#'                  cep2 = c("12345", "12345678", "54321", "123", "12345"))
#'
#' compare_cep(df, "cep1", "cep2")                      # Returns c(NA, 1, NA, NA, NA)
#' compare_cep(df, "cep1", "cep2", strict_check = TRUE) # Returns c(1, 1, 0, NA, 1)
#'
#' @export
#' @rdname compare_cep
compare_cep <- function(df, col_cep1, col_cep2, strict_check = FALSE) {
  clean_cep <- function(cep) {
    # Remove non-numeric characters, punctuation, and double spaces
    cep <- gsub("[^0-9]", "", cep)
    cep <- gsub("\\s+", " ", cep)
    # Extract first 8 characters
    cep <- substr(cep, 1, 8)
    return(cep)
  }

  # Error handling for column names
  if (!all(c(col_cep1, col_cep2) %in% names(df))) {
    stop("Column names do not exist in the dataframe.")
  }

  # Clean and validate ZIP code pattern for each row
  cep1_cleaned <- clean_cep(df[[col_cep1]])
  cep2_cleaned <- clean_cep(df[[col_cep2]])

  # Perform comparison for each row
  result <- ifelse(nchar(cep1_cleaned) == 8 & nchar(cep2_cleaned) == 8,
                   ifelse(cep1_cleaned == cep2_cleaned, 1, 0),
                   ifelse(strict_check & nchar(cep1_cleaned) == 5 & nchar(cep2_cleaned) == 5 &
                            nchar(df[[col_cep1]]) == 5 & nchar(df[[col_cep2]]) == 5,
                          ifelse(cep1_cleaned == cep2_cleaned, 1, 0), NA))

  return(result)
}
