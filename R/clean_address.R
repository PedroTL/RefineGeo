#' Clean Address Function
#'
#' This function cleans an address by removing punctuation, converting to uppercase,
#' removing accents, and removing extra white space.
#'
#' @param x A character vector or string containing the address to be cleaned.
#' @return A vector of the same length whit cleaned address in standardized formatting.
#'
#' @seealso
#'    [stringr::str_replace_all()] for replacing matches pattern with new text
#'    [stringr::str_squish()] for removing whitespace
#'    [stringi::stri_trans_general()] for text ransformation
#'    [toupper()] for changing the string to upper case
#'
#' @import stringr
#' @import stringi
#'
#' @details
#' This function standardizes the formatting of an address by performing the following steps:
#' 1. Removes punctuation marks from the address.
#' 2. Converts the entire address to uppercase.
#' 3. Removes accents and special characters.
#' 4. Removes extra white space to ensure uniform spacing between words.
#' The cleaned address is returned with standardized formatting.
#'
#' @examples
#' library(stringr)
#' library(stringi)
#' x <- c("Samplê ADReEss  -   Wíth PonctuatìõNs::")
#' clean_address(x) # Returns "SAMPLE ADDRESS WITH PONCTUATION"
#'
#' @export
#' @rdname clean_address
clean_address <- function(x) {
  # Error handling for non-character inputs
  if (!is.character(x)) {
    stop("Input must be a character vector or string.")
  }

  # Remove punctuation
  cleaned_address <- stringr::str_replace_all(x, "[[:punct:]]", "")

  cleaned_address <- stringr::str_replace_all(x, "[[:punct:]´]", "")

  # Convert to uppercase
  cleaned_address <- toupper(cleaned_address)

  # Remove accents
  cleaned_address <- stringi::stri_trans_general(cleaned_address, "Latin-ASCII")

  # Remove extra whitespace
  cleaned_address <- stringr::str_squish(cleaned_address)

  return(cleaned_address)
}
