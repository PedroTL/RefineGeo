#' Calculate Distance between Coordinates, Determine Shortest Distance Origin and Calculates MDC (Method of Double Confirmation)
#'
#' Calculates distances between latitude and longitude pairs, creating corresponding distance columns.
#' Adds a column identifying the shortest distance source if specified.
#' Adds a column for each geocoding service imputing the MDC.
#'
#'
#' @param df A dataframe containing latitude, longitude and address columns.
#' @param lat_col1,lon_col1,lat_col2,lon_col2,lat_col3,lon_col3 Column name for each latidude and longitude provided by the three Geocoding services.
#' @param dist_prefix Prefix for the new distance columns.
#' @param short_distance Logical value. If `TRUE`, determines the shortest distance source and adds a corresponding column indicating from which services the shortest distances are obtained. Default is FALSE.
#' @param mdc Logical value. If `TRUE`, computes the Method of Double Confirmation (MDC). Adds three columns, each corresponding to a specific Geocoding service. The MDC attributes a 'scores points' based on the shortest distance column to the two services that provided the closest coordinates. If only one coordinate is available, no points are attributed. Default is `FALSE`.
#' @param summarize_mdc Logical value. If `TRUE`, computes a new data frame, summarizing the count of the MDC for each of the three services, enabling to rank them.
#' @param cep_confirmation Logical Value. If `TRUE`, the columns with the `input_addr`, `output_addr_1`, `output_addr_2`, `output_addr_3` must be provided. Uses the `extr_cep` function to extract CEP from the four provided addresses. The `subsector_as_zip` can be set to `TRUE` if 5 digits CEPs must be considered. Default is `FALSE`
#' @param cep_comparison Logical Value. If `TRUE`, the columns with the `input_addr`, `output_addr_1`, `output_addr_2`, `output_addr_3` must be provided, it also demands that `cep_confirmation = TRUE`. Uses the compare_cep to compare the CEP from the input_addr with the three outputs CEPs. The `strict_check` can be set to `TRUE` to evaluate the five digits CEPs, if `subsector_as_zip = TRUE` is recommended that `strict_check = TRUE.` Default is `FALSE`.
#' @param input_addr Column with the complete description of address used in the geocoding process.
#' @param output_addr_1,output_addr_2,output_addr_3 Column with the complete returned address description for each of the three Geocoding services.
#' @param subsector_as_zip Logical. If `TRUE`, can extracts a 5-digit subsector pattern as ZIP code when available. Default is `FALSE`.
#' @param strict_check Logical indicating whether to perform strict checking on 5-digit ZIP codes. If `TRUE`, evaluates 5-digit codes; if `FALSE`, evaluates only 8-digit codes. Default is `FALSE`.
#' @param final_coordinate Logical Value. If `TRUE` appends two columns of final latitude and longitude provided the MDC methodology. Default is `FALSE`.
#' @returns An object of the same type as `.data`. The output has the fallowing proprieties:
#'
#' * Added distances columns between the pairwise comparison of three Geocoding services.
#' * If specified by `short_distance = TRUE` adds a column with the name of the shortest distance between Geocoding services.
#' * If specified by `cep_confirmation` adds four columns, assigning the respectively CEP contained in the `input_addr`, `output_addr_1`, `output_addr_2`, `output_addr_3`.
#' * If specified by `cep_comparison` adds three columns, comparing if the CEP found in the `input_addr` is the same as the ones found in the `output_addr_1`, `output_addr_2`, `output_addr_3`.
#' * If specified by `mdc = TRUE` adds three columns, assigning one 'score point' for each Geocoding service when they confirmed each other by means of the coordinate being the shortest between the three.
#' * If specified by `summarize_mdc` returns a list whit the original data frame whit the appended columns and a summarized mdc counting each confirmation point by the `mdc` for each of the three Geocoding services.
#' * If specified by `final_coordinate` return in the original data frame with two new appended columns with final coordinates selected by the MDC method. `summarize_mdc` must be `TRUE` to get final coordinates by `final_coordinate = TRUE`.
#'
#' @seealso
#'    [clean_address()] for convenient address cleaning
#'    [extr_cep()] for convenient CEP pattern extraction
#'    [compare_cep()] for convenient CEP patter comparison
#'    [geosphere::distHaversine()] for calculating distances
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
#' * `dist_prefix_1_2`: Distance between `lat_col1` and `lon_col1` with `lat_col2` and `lon_col2`. \cr
#' * `dist_prefix_1_3`: Distance between `lat_col1` and `lon_col1` with `lat_col3` and `lon_col3`. \cr
#' * `dist_prefix_2_3`: Distance between `lat_col2` and `lon_col2` with `lat_col3` and `lon_col3`. \cr
#' \cr
#' * If `short_distance = TRUE`, a new column is appended to the dataframe, identifying the origin of the shortest distance from Geocoding services. \cr
#' * The `mdc = TRUE` option is available only if `short_distance = TRUE`. It computes the Method of Double Confirmation, adding three new columns, each representing a Geocoding service. Points are attributed based on the closest coordinates confirmed through the shortest distance column. This feature can be used to rank the quality of Geocoding services. \cr
#' * The `summarize_mdc = TRUE` options is available only if `mdc = TRUE`. It computes a new data frame, summarizing the count of points for each geocoding service. This enables the services to be ranked. \cr
#' * The `cep_confirmation = TRUE` works with 4 addresses columns, one being the input given to the geocoding services and three outputs addresses. Under the hood, it uses the `extr_cep` to extract CEP from the four string, argument `subsector_as_zip = TRUE` allows five digits CEPs to be considered. \cr
#' * The `cep_comparison = TRUE` works when `cep_confirmation = TRUE` and all the 4 addresses columns are provided. Under the hood uses the `compare_cep` to check if the CEP found in the input address is the same as the CEPs found in the three outputs addresses. The `strict_check = TRUE` evaluate CEPs whit five digits in the equality. It is recommended that if `subsector_as_zip = TRUE`, `strict_check = TRUE` as well. \cr
#' * All new columns are appended to the input data frame. \cr
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
#'   input_address = c("Addr_1", "Addr_1", "Addr_1", "Addr_1", "Addr_1", "Addr_1", "Addr_1"),
#'   lat1 = c(-22.71704, -22.71258, -22.77704, -22.74704, NA, NA, NA),
#'   lon1 = c(-46.91200, -46.90435, -46.97200, -46.91200, NA, NA, NA),
#'   lat2 = c(-22.72704, -22.71268, -22.72304, NA, -22.72704, NA, NA),
#'   lon2 = c(-46.93200, -46.90435, -46.99200, NA, -46.92435, NA, NA),
#'   lat3 = c(-22.75704, -22.71258, NA, NA, NA, -22.77704, NA),
#'   lon3 = c(-46.92430, -46.90435, NA, NA, NA, -46.92439, NA)
#' )
#'
#' df_list <- get_best_coords(df, "lat1", "lon1", "lat2", "lon2", "lat3", "lon3",
#'                           "dis", short_distance = TRUE, mdc = TRUE, summarize_mdc = TRUE)
#'
#' original_df <- df_list$df
#' print(original_df)
#'
#' mdc_summary <- df_list$mdc_summary
#' print(mdc_summary)
#'
#' @export
#' @rdname get_best_coords
get_best_coords <- function(df, lat_col1, lon_col1, lat_col2, lon_col2, lat_col3, lon_col3,
                            dist_prefix, short_distance = FALSE, mdc = FALSE, summarize_mdc = FALSE,
                            cep_confirmation = FALSE, input_addr = NULL, output_addr_1 = NULL,
                            output_addr_2 = NULL, output_addr_3 = NULL, subsector_as_zip = FALSE,
                            cep_comparison = FALSE, strict_check = FALSE, final_coordinate = FALSE) {

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
    df$shortest_distance <- apply(df[, c(paste0(dist_prefix, "_1_2"), paste0(dist_prefix, "_1_3"), paste0(dist_prefix, "_2_3"))], 1, function(x) names(df[, c(paste0(dist_prefix, "_1_2"), paste0(dist_prefix, "_1_3"), paste0(dist_prefix, "_2_3"))])[which.min(x)])

    `%!in%` <- function(x, table) {
      !x %in% table
    }

    df$shortest_distance <- case_when(
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

    df[[API_NAME1]] <- as.integer(df$shortest_distance %in% c(paste0(dist_prefix, "_1_2"), paste0(dist_prefix, "_1_3")))
    df[[API_NAME2]] <- as.integer(df$shortest_distance %in% c(paste0(dist_prefix, "_1_2"), paste0(dist_prefix, "_2_3")))
    df[[API_NAME3]] <- as.integer(df$shortest_distance %in% c(paste0(dist_prefix, "_1_3"), paste0(dist_prefix, "_2_3")))
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
      if (!final_coordinate) {
        return(result)
      }
    } else {
      stop("MDC argument must be TRUE to compute the MDC summary.")
    }
  }

  if (final_coordinate) {
    if (summarize_mdc) {
      df <- result$original_data
      mdc_rank <- result$mdc_summary

      rank1 <- names(mdc_rank)[which.max(mdc_rank)]
      rank3 <- names(mdc_rank)[which.min(mdc_rank)]
      rank2 <- names(mdc_rank)[-c(which(mdc_rank == max(mdc_rank), arr.ind = TRUE), which(mdc_rank == min(mdc_rank), arr.ind = TRUE))]

      df <- df |>
        mutate(final_lat = case_when(
          comparison_cep_input_output_1 == 1 & comparison_cep_input_output_2 == 1 & comparison_cep_input_output_3 == 1 ~ case_when(
            endsWith(shortest_distance, "1_2") ~ case_when(
              endsWith(rank1, "1") & endsWith(rank2, "2") | endsWith(rank3, "2") ~ lat1,
              endsWith(rank2, "1") & endsWith(rank3, "2") ~ lat1,
              endsWith(rank2, "1") & endsWith(rank1, "2") ~ lat2,
              endsWith(rank3, "1") & endsWith(rank1, "2") | endsWith(rank2, "2") ~ lat2
            ),
            endsWith(shortest_distance, "1_3") ~ case_when(
              endsWith(rank1, "1") & endsWith(rank2, "3") | endsWith(rank3, "3") ~ lat1,
              endsWith(rank2, "1") & endsWith(rank3, "3") ~ lat1,
              endsWith(rank2, "1") & endsWith(rank1, "3") ~ lat3,
              endsWith(rank3, "1") & endsWith(rank1, "3") | endsWith(rank2, "3") ~ lat3
            ),
            endsWith(shortest_distance, "2_3") ~ case_when(
              endsWith(rank1, "2") & endsWith(rank2, "3") | endsWith(rank3, "3") ~ lat2,
              endsWith(rank2, "2") & endsWith(rank3, "3") ~ lat2,
              endsWith(rank2, "2") & endsWith(rank1, "3") ~ lat3,
              endsWith(rank3, "2") & endsWith(rank1, "3") | endsWith(rank2, "3") ~ lat3
            )
          ),
          comparison_cep_input_output_1 == 1 & comparison_cep_input_output_2 == 1 & comparison_cep_input_output_3 == 0 ~ case_when(
            endsWith(shortest_distance, "1_2") ~ case_when(
              endsWith(rank1, "1") & endsWith(rank2, "2") | endsWith(rank3, "2") ~ lat1,
              endsWith(rank2, "1") & endsWith(rank3, "2") ~ lat1,
              endsWith(rank2, "1") & endsWith(rank1, "2") ~ lat2,
              endsWith(rank3, "1") & endsWith(rank1, "2") | endsWith(rank2, "2") ~ lat2
            ),
            endsWith(shortest_distance, "1_3") ~ lat1,
            endsWith(shortest_distance, "2_3") ~ lat2
          ),
          comparison_cep_input_output_1 == 1 & comparison_cep_input_output_2 == 0 & comparison_cep_input_output_3 == 1 ~ case_when(
            endsWith(shortest_distance, "1_2") ~ lat1,
            endsWith(shortest_distance, "1_3") ~ case_when(
              endsWith(rank1, "1") & endsWith(rank2, "3") | endsWith(rank3, "3") ~ lat1,
              endsWith(rank2, "1") & endsWith(rank3, "3") ~ lat1,
              endsWith(rank2, "1") & endsWith(rank1, "3") ~ lat3,
              endsWith(rank3, "1") & endsWith(rank1, "3") | endsWith(rank2, "3") ~ lat3
            ),
            endsWith(shortest_distance, "2_3") ~ lat3
          ),
          comparison_cep_input_output_1 == 0 & comparison_cep_input_output_2 == 1 & comparison_cep_input_output_3 == 1 ~ case_when(
            endsWith(shortest_distance, "1_2") ~ lat2,
            endsWith(shortest_distance, "1_3") ~ lat1,
            endsWith(shortest_distance, "2_3") ~ case_when(
              endsWith(rank1, "2") & endsWith(rank2, "3") | endsWith(rank3, "3") ~ lat2,
              endsWith(rank2, "2") & endsWith(rank3, "3") ~ lat2,
              endsWith(rank2, "2") & endsWith(rank1, "3") ~ lat3,
              endsWith(rank3, "2") & endsWith(rank1, "3") | endsWith(rank2, "3") ~ lat3
            )
          ),
          comparison_cep_input_output_1 == 1 & comparison_cep_input_output_2 == 0 & comparison_cep_input_output_3 == 0 |
            comparison_cep_input_output_1 == 1 & is.na(comparison_cep_input_output_2) & is.na(comparison_cep_input_output_3) ~ lat1,
          comparison_cep_input_output_1 == 0 & comparison_cep_input_output_2 == 1 & comparison_cep_input_output_3 == 0 |
            is.na(comparison_cep_input_output_1) & comparison_cep_input_output_2 == 1 & is.na(comparison_cep_input_output_3) ~ lat2,
          comparison_cep_input_output_1 == 0 & comparison_cep_input_output_2 == 0 & comparison_cep_input_output_3 == 1 |
            is.na(comparison_cep_input_output_1) & is.na(comparison_cep_input_output_2) & comparison_cep_input_output_3 == 1 ~ lat3,
          comparison_cep_input_output_1 == 0 & comparison_cep_input_output_2 == 0 & comparison_cep_input_output_3 == 0 |
            is.na(comparison_cep_input_output_1) & is.na(comparison_cep_input_output_2) & is.na(comparison_cep_input_output_3) ~ case_when(
              endsWith(shortest_distance, "1_2") ~ case_when(
                endsWith(rank1, "1") & endsWith(rank2, "2") | endsWith(rank3, "2") ~ lat1,
                endsWith(rank2, "1") & endsWith(rank3, "2") ~ lat1,
                endsWith(rank2, "1") & endsWith(rank1, "2") ~ lat2,
                endsWith(rank3, "1") & endsWith(rank1, "2") | endsWith(rank2, "2") ~ lat2
              ),
              endsWith(shortest_distance, "1_3") ~ case_when(
                endsWith(rank1, "1") & endsWith(rank2, "3") | endsWith(rank3, "3") ~ lat1,
                endsWith(rank2, "1") & endsWith(rank3, "3") ~ lat1,
                endsWith(rank2, "1") & endsWith(rank1, "3") ~ lat3,
                endsWith(rank3, "1") & endsWith(rank1, "3") | endsWith(rank2, "3") ~ lat3
              ),
              endsWith(shortest_distance, "2_3") ~ case_when(
                endsWith(rank1, "2") & endsWith(rank2, "3") | endsWith(rank3, "3") ~ lat2,
                endsWith(rank2, "2") & endsWith(rank3, "3") ~ lat2,
                endsWith(rank2, "2") & endsWith(rank1, "3") ~ lat3,
                endsWith(rank3, "2") & endsWith(rank1, "3") | endsWith(rank2, "3") ~ lat3
              ),
              startsWith(shortest_distance, "just lat1") ~ lat1,
              startsWith(shortest_distance, "just lat2") ~ lat2,
              startsWith(shortest_distance, "just lat3") ~ lat3,
              startsWith(shortest_distance, "No") ~ NA


            )
        ),
        final_lon = case_when(
          comparison_cep_input_output_1 == 1 & comparison_cep_input_output_2 == 1 & comparison_cep_input_output_3 == 1 ~ case_when(
            endsWith(shortest_distance, "1_2") ~ case_when(
              endsWith(rank1, "1") & endsWith(rank2, "2") | endsWith(rank3, "2") ~ lon1,
              endsWith(rank2, "1") & endsWith(rank3, "2") ~ lon1,
              endsWith(rank2, "1") & endsWith(rank1, "2") ~ lon2,
              endsWith(rank3, "1") & endsWith(rank1, "2") | endsWith(rank2, "2") ~ lon2
            ),
            endsWith(shortest_distance, "1_3") ~ case_when(
              endsWith(rank1, "1") & endsWith(rank2, "3") | endsWith(rank3, "3") ~ lon1,
              endsWith(rank2, "1") & endsWith(rank3, "3") ~ lon1,
              endsWith(rank2, "1") & endsWith(rank1, "3") ~ lon3,
              endsWith(rank3, "1") & endsWith(rank1, "3") | endsWith(rank2, "3") ~ lon3
            ),
            endsWith(shortest_distance, "2_3") ~ case_when(
              endsWith(rank1, "2") & endsWith(rank2, "3") | endsWith(rank3, "3") ~ lon2,
              endsWith(rank2, "2") & endsWith(rank3, "3") ~ lon2,
              endsWith(rank2, "2") & endsWith(rank1, "3") ~ lon3,
              endsWith(rank3, "2") & endsWith(rank1, "3") | endsWith(rank2, "3") ~ lon3
            )
          ),
          comparison_cep_input_output_1 == 1 & comparison_cep_input_output_2 == 1 & comparison_cep_input_output_3 == 0 ~ case_when(
            endsWith(shortest_distance, "1_2") ~ case_when(
              endsWith(rank1, "1") & endsWith(rank2, "2") | endsWith(rank3, "2") ~ lon1,
              endsWith(rank2, "1") & endsWith(rank3, "2") ~ lon1,
              endsWith(rank2, "1") & endsWith(rank1, "2") ~ lon2,
              endsWith(rank3, "1") & endsWith(rank1, "2") | endsWith(rank2, "2") ~ lon2
            ),
            endsWith(shortest_distance, "1_3") ~ lon1,
            endsWith(shortest_distance, "2_3") ~ lon2
          ),
          comparison_cep_input_output_1 == 1 & comparison_cep_input_output_2 == 0 & comparison_cep_input_output_3 == 1 ~ case_when(
            endsWith(shortest_distance, "1_2") ~ lon1,
            endsWith(shortest_distance, "1_3") ~ case_when(
              endsWith(rank1, "1") & endsWith(rank2, "3") | endsWith(rank3, "3") ~ lon1,
              endsWith(rank2, "1") & endsWith(rank3, "3") ~ lon1,
              endsWith(rank2, "1") & endsWith(rank1, "3") ~ lon3,
              endsWith(rank3, "1") & endsWith(rank1, "3") | endsWith(rank2, "3") ~ lon3
            ),
            endsWith(shortest_distance, "2_3") ~ lon3
          ),
          comparison_cep_input_output_1 == 0 & comparison_cep_input_output_2 == 1 & comparison_cep_input_output_3 == 1 ~ case_when(
            endsWith(shortest_distance, "1_2") ~ lon3,
            endsWith(shortest_distance, "1_3") ~ lon1,
            endsWith(shortest_distance, "2_3") ~ case_when(
              endsWith(rank1, "2") & endsWith(rank2, "3") | endsWith(rank3, "3") ~ lon2,
              endsWith(rank2, "2") & endsWith(rank3, "3") ~ lon2,
              endsWith(rank2, "2") & endsWith(rank1, "3") ~ lon3,
              endsWith(rank3, "2") & endsWith(rank1, "3") | endsWith(rank2, "3") ~ lon3
            )
          ),
          comparison_cep_input_output_1 == 1 & comparison_cep_input_output_2 == 0 & comparison_cep_input_output_3 == 0 |
            comparison_cep_input_output_1 == 1 & is.na(comparison_cep_input_output_2) & is.na(comparison_cep_input_output_3) ~ lon1,
          comparison_cep_input_output_1 == 0 & comparison_cep_input_output_2 == 1 & comparison_cep_input_output_3 == 0 |
            is.na(comparison_cep_input_output_1) & comparison_cep_input_output_2 == 1 & is.na(comparison_cep_input_output_3) ~ lon2,
          comparison_cep_input_output_1 == 0 & comparison_cep_input_output_2 == 0 & comparison_cep_input_output_3 == 1 |
            is.na(comparison_cep_input_output_1) & is.na(comparison_cep_input_output_2) & comparison_cep_input_output_3 == 1 ~ lon3,
          comparison_cep_input_output_1 == 0 & comparison_cep_input_output_2 == 0 & comparison_cep_input_output_3 == 0 |
            is.na(comparison_cep_input_output_1) & is.na(comparison_cep_input_output_2) & is.na(comparison_cep_input_output_3) ~ case_when(
              endsWith(shortest_distance, "1_2") ~ case_when(
                endsWith(rank1, "1") & endsWith(rank2, "2") | endsWith(rank3, "2") ~ lon1,
                endsWith(rank2, "1") & endsWith(rank3, "2") ~ lon1,
                endsWith(rank2, "1") & endsWith(rank1, "2") ~ lon2,
                endsWith(rank3, "1") & endsWith(rank1, "2") | endsWith(rank2, "2") ~ lon2
              ),
              endsWith(shortest_distance, "1_3") ~ case_when(
                endsWith(rank1, "1") & endsWith(rank2, "3") | endsWith(rank3, "3") ~ lon1,
                endsWith(rank2, "1") & endsWith(rank3, "3") ~ lon1,
                endsWith(rank2, "1") & endsWith(rank1, "3") ~ lon3,
                endsWith(rank3, "1") & endsWith(rank1, "3") | endsWith(rank2, "3") ~ lon3
              ),
              endsWith(shortest_distance, "2_3") ~ case_when(
                endsWith(rank1, "2") & endsWith(rank2, "3") | endsWith(rank3, "3") ~ lon2,
                endsWith(rank2, "2") & endsWith(rank3, "3") ~ lon2,
                endsWith(rank2, "2") & endsWith(rank1, "3") ~ lon3,
                endsWith(rank3, "2") & endsWith(rank1, "3") | endsWith(rank2, "3") ~ lon3
              ),
              startsWith(shortest_distance, "just lat1") ~ lon1,
              startsWith(shortest_distance, "just lat2") ~ lon2,
              startsWith(shortest_distance, "just lat3") ~ lon3,
              startsWith(shortest_distance, "No") ~ NA
            )
        )
        )

      result$original_data <- df

    }


  }

  return(result)

}


