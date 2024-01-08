#' Extract CEP from Address
#'
#' This function extracts an 8-digit or 5-digit CEP from a string representing an address.
#'
#' @param addresses A character vector or string containing the address information.
#' @param subsector_as_zip Logical. If `TRUE`, can extracts a 5-digit sub-sector pattern as CEP, when available. Default is `FALSE.`
#' @return A vector of the same length with 8-digit. If specified also returns 5-digit CEP when is found, otherwise NA.
#'
#' @import stringi
#' @import stringr
#'
#' @details
#' This function attempts to extract an 8-digit CEP from a provided address string.
#' It removes punctuation, converts the address to uppercase, and attempts to find a pattern
#' matching either an 8-digit CEP or a 5-digit CEP followed by a hyphen and a 3-digit extension.
#' If the `subsector_as_zip` argument is `TRUE`, it will attempt to extract a 5-digit sub-sector pattern as a CEP
#' when an 8-digit CEP is not found.
#'
#' @examples
#' library(stringr)
#' library(stringi)
#' library(dplyr)
#'
#' extr_cep("12345-678 Some Street, City, Country")  # Returns "12345678"
#' extr_cep("No ZIP code in this address")  # Returns NA
#' extr_cep(c("12345-678 Some Street", "No ZIP code here"))  # Returns "12345678" and NA
#' extr_cep("Only subsector 12345", subsector_as_zip = TRUE)  # Returns "12345"
#'
#' @export
#' @rdname ext_cep
extr_cep <- function(addresses, subsector_as_zip = FALSE) {
  # Error handling for non-character inputs
  if (!is.character(addresses)) {
    stop("Input must be a character vector or string.")
  }

  # Clean addresses: remove punctuation, convert to uppercase, etc.
  cleaned_addresses <- clean_address(addresses)

  # Initialize a vector to store the extracted CEPs
  ceps <- vector("list", length = length(addresses))

  for (i in seq_along(addresses)) {
    # Extract ZIP code pattern: 8-digit number
    cep_8_digits <- str_extract(cleaned_addresses[i], "\\b\\d{8}\\b")

    if (subsector_as_zip) {
      # Extract ZIP code pattern: 5-digit number only if subsector_as_zip is TRUE
      cep_5_digits <- str_extract(cleaned_addresses[i], "\\b\\d{5}\\b")

      # Check for 5-digit ZIP code pattern if no 8-digit pattern found
      if (is.na(cep_8_digits) && !is.na(cep_5_digits)) {
        ceps[[i]] <- cep_5_digits
      } else {
        ceps[[i]] <- cep_8_digits
      }
    } else {
      ceps[[i]] <- cep_8_digits
    }
  }

  return(unlist(ceps))
}



