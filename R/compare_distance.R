#' Calculate Distance between Coordinates, Determine Shortest Distance Origin and Calculates MDC (Method of Double Confirmation)
#'
#' Calculates distances between latitude and longitude pairs, creating corresponding distance columns.
#' Adds a column identifying the shortest distance source if specified.
#'
#' @param df A dataframe containing latitude and longitude columns.
#' @param lat_col1 Column name for the first latitude.
#' @param lon_col1 Column name for the first longitude.
#' @param lat_col2 Column name for the second latitude.
#' @param lon_col2 Column name for the second longitude.
#' @param lat_col3 Column name for the third latitude.
#' @param lon_col3 Column name for the third longitude.
#' @param dist_prefix Prefix for the new distance columns.
#' @param short_distance Logical value. If TRUE, determines the shortest distance source and adds a corresponding column indicating from which services the shortest distances are obtained. Default is FALSE.
#' @param mdc Logical value. If TRUE, computes the Method of Double Confirmation (MDC). Adds three columns, each corresponding to a specific Geocoding service. The MDC attributes points based on the shortest distance column to the two services that provided the closest coordinates. If only one coordinate is available, no points are attributed. Default is FALSE.
#' @param summarize_mdc Logical value. If TRUE, computes a new data frame, summarizing the count of the MDC for each of the three services, enabling to rank them.
#' @param cep_confirmation Logical Value. If TRUE, the columns with the input_addr, output_addr_1, output_addr_2, output_addr_3 must be provided. Uses the extr_cep function to extract CEP from the four provided addresses. The subsector_as_zip can be set to TRUE if 5 digits CEPs must be considered. Default is FALSE
#' @param cep_comparison Logical Value. If TRUE, the columns with the input_addr, output_addr_1, output_addr_2, output_addr_3 must be provided, it also demands that cep_confirmation = TRUE. Uses the compare_cep to compare the CEP from the input_addr with the three outputs CEPs. The strick_check can be set to TRUE to evaluate the five digits CEPs, if subsector_as_zip = TRUE is recommended that strict_check = TRUE. Default is FALSE.
#' @param input_addr Column with the complete description of address used in the geocoding process.
#' @param output_addr_1 Column with the complete returned address description from the first geocoding service.
#' @param output_addr_2 Column with the complete returned address description from the first geocoding service.
#' @param output_addr_3 Column with the complete returned address description from the second geocoding service.
#' @param subsector_as_zip Logical. If TRUE, can extracts a 5-digit subsector pattern as ZIP code when available. Default is FALSE.
#' @param strict_check Logical indicating whether to perform strict checking on 5-digit ZIP codes. If TRUE, evaluates 5-digit codes; if FALSE, evaluates only 8-digit codes. Default is FALSE.
#' @return The input data frame with added distance columns and, if specified, columns indicating the shortest distance origin and MDC confirmation points. When summarize_mdc = TRUE, returns a list with the original data frame and a summarized data frame with the count of the MDC for each Geocoding service.
#'
#' @import dplyr
#' @import geosphere
#' @import stringr
#' @import magrittr
#'
#' @details
#' This function computes distances between latitude and longitude pairs, generating new columns in the dataframe for each pairwise distance based on the given `dist_prefix`, indicating the source of the shortest distance obtained from Geocoding services.
#' Distances are calculated using the Haversine formula, resulting in kilometers.
#' The function creates three distance columns: \cr
#' - `dist_prefix_1_2`: Distance between 'lat_col1' and `lon_col1` with `lat_col2` and `lon_col2`. \cr
#' - `dist_prefix_1_3`: Distance between `lat_col1` and `lon_col1` with `lat_col3` and `lon_col3`. \cr
#' - `dist_prefix_2_3`: Distance between `lat_col2` and `lon_col2` with `lat_col3` and `lon_col3`. \cr
#' \cr
#' If `short_distance = TRUE`, a new column is appended to the dataframe, identifying the origin of the shortest distance from Geocoding services. \cr
#' The `mdc = TRUE` option is available only if `short_distance = TRUE`. It computes the Method of Double Confirmation, adding three new columns, each representing a Geocoding service. Points are attributed based on the closest coordinates confirmed through the shortest distance column. This feature can be used to rank the quality of Geocoding services. \cr
#' All new columns are appended to the input dataframe. \cr
#'
#' \cr
#' For more details about the Method of Double Confirmation (MDC), visit: https://feac.org.br/wp-content/uploads/2023/10/Geocodificacao_FEAC.pdf?portfolioCats=3105#new_tab \cr
#' \cr
#'
#' @examples
#' library(geosphere)
#' library(dplyr)
#' library(stringr)
#' library(stringi)
#' library(magrittr)
#'
#' df <- data.frame(
#'   input_address = c("Address_1", "Address_1", "Address_1", "Address_1", "Address_1", "Address_1", "Address_1"),
#'   lat1 = c(-22.71704, -22.71258, -22.77704, -22.74704, NA, NA, NA),
#'   lon1 = c(-46.91200, -46.90435, -46.97200, -46.91200, NA, NA, NA),
#'   lat2 = c(-22.72704, -22.71268, -22.72304, NA, -22.72704, NA, NA),
#'   lon2 = c(-46.93200, -46.90435, -46.99200, NA, -46.92435, NA, NA),
#'   lat3 = c(-22.75704, -22.71258, NA, NA, NA, -22.77704, NA),
#'   lon3 = c(-46.92430, -46.90435, NA, NA, NA, -46.92439, NA)
#' )
#'
#' df_list <- compare_distance(df, "lat1", "lon1", "lat2", "lon2", "lat3", "lon3", "dis", short_distance = TRUE, mdc = TRUE, summarize_mdc = TRUE)
#'
#' original_df <- df_list$df
#' print(original_df)
#' # Expected Return
#' # address   |  lat1    |  lon1  |  lat2  |  lon2  |  lat3  |  lon3  | dis_1_2 | dis_1_3 | dis_2_3 | shortest_distance |    dis_1  |    dis_2  |    dis_3  |
#' # Address_1 | -22.7170 | -46.91 | -22.72 | -46.93 | -22.75 | -46.92 |  2.33   |  4.62   | 3.43    |     dis_1_2       |      1    |     1     |     0     |
#' # Address_2 | -22.7125 | -46.90 | -22.71 | -46.90 | -22.71 | -46.90 |  0.01   |    0    | 0.01    |     dis_1_3       |      1    |     0     |     1     |
#' # Address_3 | -22.7770 | -46.97 | -22.72 | -46.99 |   NA   |   NA   |  6.35   |    NA   |   NA    |     dis_1_2       |      1    |     1     |     0     |
#' # Address_4 | -22.747  | -46.91 |   NA   |   NA   |   NA   |   NA   |   NA    |    NA   |   NA    | just lat1 and lon1|      0    |     0     |     0     |
#' # Address_5 |    NA    |    NA  | -22.72 | -46.92 |   NA   |   NA   |   NA    |    NA   |   NA    | just lat2 and lon2|      0    |     0     |     0     |
#' # Address_6 |    NA    |    NA  |   NA   |   NA   | -22.77 | -46.92 |   NA    |    NA   |   NA    | just lat3 and lon3|      0    |     0     |     0     |
#' # Address_7 |    NA    |    NA  |   NA   |   NA   |   NA   |   NA   |   NA    |    NA   |   NA    |   No Coordinates  |      0    |     0     |     0     |
#'
#' mdc_summary <- df_list$mdc_summary
#' print(mdc_summary)
#' # Expected Return
#' # | dis_1 | dis_2 | dis_3 |
#' # |   3   |   2   |   1   |
#'
#' @export
#' @rdname compare_distance
compare_distance <- function(df, lat_col1, lon_col1, lat_col2, lon_col2, lat_col3, lon_col3,
                             dist_prefix, short_distance = FALSE, mdc = FALSE, summarize_mdc = FALSE,
                             cep_confirmation = FALSE, input_addr = NULL, output_addr_1 = NULL,
                             output_addr_2 = NULL, output_addr_3 = NULL, subsector_as_zip = FALSE,
                             cep_comparison = FALSE, strict_check = FALSE) {
  cols <- list(
    c(lat_col1, lon_col1, lat_col2, lon_col2, paste0(dist_prefix, "_1_2")),
    c(lat_col1, lon_col1, lat_col3, lon_col3, paste0(dist_prefix, "_1_3")),
    c(lat_col2, lon_col2, lat_col3, lon_col3, paste0(dist_prefix, "_2_3"))
  )

  for (col in cols) {
    lat1 <- df[[col[1]]]
    lon1 <- df[[col[2]]]
    lat2 <- df[[col[3]]]
    lon2 <- df[[col[4]]]

    df[[col[5]]] <- distHaversine(cbind(lon1, lat1), cbind(lon2, lat2)) / 1000
  }

  if (short_distance) {
    df$shortest_distance <- as.character(apply(df[, c(paste0(dist_prefix, "_1_2"), paste0(dist_prefix, "_1_3"), paste0(dist_prefix, "_2_3"))], 1, function(x) names(df[, c(paste0(dist_prefix, "_1_2"), paste0(dist_prefix, "_1_3"), paste0(dist_prefix, "_2_3"))])[which.min(x)]))

    `%!in%` <- function(x, table) {
      !x %in% table
    }

    df$shortest_distance <-
      case_when(
        !df$shortest_distance %in% c(paste0(dist_prefix, "_1_2"), paste0(dist_prefix, "_1_3"), paste0(dist_prefix, "_2_3")) & is.na(df[[lat_col1]]) & is.na(df[[lat_col2]]) & is.na(df[[lat_col3]]) ~ "No Coordinates",
        !df$shortest_distance %in% c(paste0(dist_prefix, "_1_2"), paste0(dist_prefix, "_1_3"), paste0(dist_prefix, "_2_3")) & is.na(df[[lat_col1]]) & is.na(df[[lat_col2]]) & !is.na(df[[lat_col3]]) ~ paste("just", names(df[lat_col3]), "and", names(df[lon_col3]), sep = " "),
        !df$shortest_distance %in% c(paste0(dist_prefix, "_1_2"), paste0(dist_prefix, "_1_3"), paste0(dist_prefix, "_2_3")) & is.na(df[[lat_col1]]) & !is.na(df[[lat_col2]]) & is.na(df[[lat_col3]]) ~ paste("just", names(df[lat_col2]), "and", names(df[lon_col2]), sep = " "),
        !df$shortest_distance %in% c(paste0(dist_prefix, "_1_2"), paste0(dist_prefix, "_1_3"), paste0(dist_prefix, "_2_3")) & !is.na(df[[lat_col1]]) & is.na(df[[lat_col2]]) & is.na(df[[lat_col3]]) ~ paste("just", names(df[lat_col1]), "and", names(df[lon_col1]), sep = " "),
        TRUE ~ as.character(df$shortest_distance)
      )

  }

  if (mdc) {
    prefix <- gsub("_.*", "", dist_prefix) # Extract the part of dist_prefix before the underscore
    API_NAME1 <- paste0(prefix, "_1")
    API_NAME2 <- paste0(prefix, "_2")
    API_NAME3 <- paste0(prefix, "_3")

    df[[API_NAME1]] <- as.integer(
      df$shortest_distance %in% c(paste0(dist_prefix, "_1_2"), paste0(dist_prefix, "_1_3"))
    )
    df[[API_NAME2]] <- as.integer(
      df$shortest_distance %in% c(paste0(dist_prefix, "_1_2"), paste0(dist_prefix, "_2_3"))
    )
    df[[API_NAME3]] <- as.integer(
      df$shortest_distance %in% c(paste0(dist_prefix, "_1_3"), paste0(dist_prefix, "_2_3"))
    )
  }

  if (cep_confirmation) {
    if (!is.null(input_addr) && !is.null(output_addr_1) && !is.null(output_addr_2) && !is.null(output_addr_3)) {
      df$input_addr_cep <- extr_cep(df[[input_addr]], subsector_as_zip = subsector_as_zip)

      df$output_addr_cep_1 <- extr_cep(df[[output_addr_1]], subsector_as_zip = subsector_as_zip)
      df$output_addr_cep_2 <- extr_cep(df[[output_addr_2]], subsector_as_zip = subsector_as_zip)
      df$output_addr_cep_3 <- extr_cep(df[[output_addr_3]], subsector_as_zip = subsector_as_zip)
    } else {
      stop("Please provide all four address columns for CEP confirmation.")
    }
  }

  if (cep_comparison) {
    if (cep_confirmation && !is.null(input_addr) && !is.null(output_addr_1) && !is.null(output_addr_2) && !is.null(output_addr_3)) {
      df$comparison_cep_input_output_1 <- compare_cep(df, "input_addr_cep", "output_addr_cep_1", strict_check = strict_check)
      df$comparison_cep_input_output_2 <- compare_cep(df, "input_addr_cep", "output_addr_cep_2", strict_check = strict_check)
      df$comparison_cep_input_output_3 <- compare_cep(df, "input_addr_cep", "output_addr_cep_3", strict_check = strict_check)
    } else {
      stop("CEP comparison requires CEP confirmation columns. Please enable cep_confirmation and provide all required columns.")
    }
  }

  if (summarize_mdc) {
    if (mdc) {
      mdc_summary <- data.frame(
        API_NAME1 = sum(df[[API_NAME1]], na.rm = TRUE),
        API_NAME2 = sum(df[[API_NAME2]], na.rm = TRUE),
        API_NAME3 = sum(df[[API_NAME3]], na.rm = TRUE)
      )

      colnames(mdc_summary) <- gsub("^API_", "API_dis_", colnames(mdc_summary)) # Update column names

      result <- list(original_data = df, mdc_summary = mdc_summary)
      return(result)
    } else {
      stop("MDC argument must be TRUE to compute the MDC summary.")
    }
  }

  return(df)
}

