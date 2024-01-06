#' Check Points Within a Municipality Polygon
#'
#' This function checks whether the given latitude and longitude points are within the specified municipality polygon.
#'
#' @param df A dataframe containing latitude and longitude columns.
#' @param lat A string indicating the column name for latitude.
#' @param lon A string indicating the column name for longitude.
#' @param out_col_name A string indicating the name for the output column containing the result.
#' @param code_muni The municipality code for the area of interest.
#' @param year The year of the municipality data.
#' @param polygon_crs The coordinate reference system (CRS) for the municipality polygon.
#' @return Returns a dataframe with an additional column specifying whether the points are within the specified polygon.
#'
#' @import geobr
#' @import sf
#' @import dplyr
#' @import magrittr
#' @importFrom data.table :=
#'
#' @details
#' This function reads municipality polygon data, transforms the points to the specified CRS,
#' and checks if the points are within the municipality polygon. It then creates a new column in the dataframe
#' indicating whether the points are inside the polygon and then assign NA to coordinates in the outside.
#'
#' @examples
#' library(dplyr)
#' library(sf)
#' library(geobr)
#' library(magrittr)
#'
#' df <- data.frame(lat = c(-22.71704, -22.71258, -22.84277, -22.73391, -22.77165),
#'                  lon = c(-46.91200, -46.90435, -47.07650, -47.00500, -46.98793))
#'
#' df <- points_out(df, "lat", "lon", "out_camp", code_muni = 3509502, year = 2020, polygon_crs = 4326)
#' print(df)
#' # Expected Return:
#' # |   lat  |  lon   | out_camp |
#' # |   NA   |   NA   | TRUE     |
#' # |   NA   |   NA   | TRUE     |
#' # | -22.84 | -47.08 | FALSE    |
#' # |   NA   |   NA   | TRUE     |
#' # | -22.77 | -46.99 | FALSE    |
#'
#' @export
#' @rdname out_camp
points_out <- function(df, lat, lon, out_col_name, code_muni, year, polygon_crs) {
  shp_municipality <- read_municipality(code_muni = code_muni, year = year) %>%
    st_transform(polygon_crs) # Transform to specified CRS if needed

  df_sf_point <- st_as_sf(df,
                          coords = c(lon, lat),
                          na.fail = FALSE,
                          crs = st_crs(shp_municipality) # Make the CRS of the points the same as the polygon
  )

  df <- df %>%
    mutate(out_name = !st_within(df_sf_point, shp_municipality), # Check if points are within the municipality polygon
           out_name = as.logical(out_name),
           out_name = ifelse(is.na(out_name), FALSE, out_name),
           lat = ifelse(out_name, NA, .data[[lat]]),
           lon = ifelse(out_name, NA, .data[[lon]])) %>%
    mutate(!!out_col_name := as.logical(out_name)) %>%
    select(-out_name)

  return(df)
}
