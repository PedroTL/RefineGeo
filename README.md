
# RefineGeo

The goal of RefineGeo is to facilitate the comparison between geocoding
services coordinates. It uses the methodology from the
[study](https://feac.org.br/wp-content/uploads/2023/10/Geocodificacao_FEAC.pdf?portfolioCats=3100%2C3850%2C4090)
of the Geocoding process from the Single Registry (Cadastro Único) of
Campinas.

## Installation

You can install the development version of RefineGeo from
[GitHub](https://github.com/pedroTL) with:

``` r
# install.packages("devtools")
devtools::install_github("PedroTL/RefineGeo")
```

## Introduction

There is at this moment five main functions.

- `clean_address`: Cleans addresses string, removes punctuation,
  accents, double spaces and leave all in caps.
- `extr_cep`: Extracts CEP (Equivalent of Zip Code) from a address
  string, available for 8 and 5 digits patter.
- `compare_cep`: Check between two strings if the CEP is or not a match
  between the two.
- `points_out`: Check for coordinates outside of a municipallity polygon
  boudrie.
- `get_best_coords`: Calculate distance in kilometer between pairwise
  points of three Geocoding services. Explicits the two services with
  shortest distance, compare de CEP equality between CEPs from input
  address and the three outputs addresses strings. Calculates the Method
  of Double Confirmation (MDC), enabiling to rank up each service.

## Example

Let’s say that you have a string address that has pronunciations, double
spaces, and other common problems with input addresses.

``` r
library(RefineGeo)
library(ggplot2)
library(sf)
library(geobr)
```

``` r
# Sample address
address <- c("Rua JosÉ DôIS - -  12345678", "R. DR, JÔSÉ DÓIS  AV: 1 -- (12345)")
clean_address(address)
#> [1] "RUA JOSE DOIS 12345678"    "R DR JOSE DOIS AV 1 12345"
```

A special feature when analyzing addresses and Geocoding is the CEP
known in Brazil as the Código de Endereçamento Postal, the equivalent of
Zip Code. It summarizes the address information in a standard code.

The CEP is divided into 2 parts. The first goes from the digits 1 to 5,
being: - 1: Region - 2: Sub-Region - 3: Sector - 4: Subsector - 5:
Subsector Divisor

With five digits, it’s possible to get polygon information, being a
broad area where the full CEP (8 digits) relies on.

The last three suffixes after the “-” identify individual streets,
special codes, and correios unity. For more information, you can see the
official correio
[website](https://www.correios.com.br/enviar/precisa-de-ajuda/tudo-sobre-cep)

The CEP can be used to work around the quality metrics of different
Geocoding services. Each one gives a metric of quality to the Geocoded
address and the output coordinate. For example, the ArcGIS service gives
a score going from 0-100, Google has a categorized metric with ROOFTOP
being the best score.

When trying to compare the coordinates between services, the individual
metrics can be overwhelming. The CEP can provide a standard method that
is reproducible between services. **The main idea is that if the CEP
that was provided in the input address is the same as the output address
given by the Geocoding service, we could assume good accuracy for that
coordinate.**

Let’s assume that we have two strings, one with the input address and
the other with the output from the Geocoding service. `extr_cep` can be
used to remove CEP patterns from the string.

``` r
# Sample address
input_address <- c("RUA JOSE DOIS 12345678", "R DR JOSE DOIS AV 1 12345")
output_address <- c("RUA JOSE DOIS 12345678", "R DR JOSE DOIS AV 1 12345")

# Extracting CEP
extr_cep(input_address) # Input address CEP
#> [1] "12345678" NA
extr_cep(output_address, subsector_as_zip = TRUE)  # Output address CEP
#> [1] "12345678" "12345"
```

The extr_cep can also explicitly consider 5 digits as CEP if specified
in the `subsector_as_zip`, otherwise, it will just return NA.

The `compare_cep` function works in a data frame structure and returns a
column with a binary value (1 if the CEPs are a match between 2 columns
and 0 if not).

``` r
# Sample data frame
df <- data.frame(cep1 = c("12345", "12345678", "12345", "12345", "12345"),
                 cep2 = c("12345", "12345678", "54321", "123", "12345"))

# Comparing CEPs
compare_cep(df, "cep1", "cep2")                      
#> [1] NA  1 NA NA NA
compare_cep(df, "cep1", "cep2", strict_check = TRUE)
#> [1]  1  1  0 NA  1
```

The `subsector_as_zip` works well with the strict_check. In this case,
if you manage to get extracted CEPs with 5 and 8 digits, the
`compare_cep` allows you to specify with the `strict_check` if you want
to consider 5 digit CEPs in the comparison.

Another useful function is the `points_out.` Usually, when working with
address Geocoding, you might want to visualize and work with spatial
features. In this case, the function works at the municipality level.
The `points_out` basically checks if a given coordinate provided by a
Geocoding service is inside or outside a polygon.

For instance, this example takes a couple of latitudes and longitudes
from the Campinas-SP municipality and then checks if they are inside or
outside the polygon boundary. The returned column in the data frame can
be specified; here I used `out_camp`, It is best practice to keep the
`out` prefix to make interpretation easy. If the value is `TRUE`, then a
given coordinate is indeed outside the polygon.

The function uses the `read_municipality` from `geobr`, so a
`municipality code` must be provided, as well as the `year` and a
`CRS projection`.

``` r
# Sample data
df <- data.frame(lat = c(-22.71704, -22.71258, -22.84277, -22.73391, -22.77165),
                 lon = c(-46.91200, -46.90435, -47.07650, -47.00500, -46.98793))

# Getting the Campinas SHP.
shp_campinas <- read_municipality(code_muni = 3509502, year = 2020) %>%
    st_transform(4326)
#> Downloading: 1.6 kB     Downloading: 1.6 kB     Downloading: 1.8 kB     Downloading: 1.8 kB     Downloading: 1.8 kB     Downloading: 1.8 kB     Downloading: 1.8 kB     Downloading: 1.8 kB     Downloading: 42 kB     Downloading: 42 kB     Downloading: 75 kB     Downloading: 75 kB     Downloading: 120 kB     Downloading: 120 kB     Downloading: 160 kB     Downloading: 160 kB     Downloading: 190 kB     Downloading: 190 kB     Downloading: 210 kB     Downloading: 210 kB     Downloading: 260 kB     Downloading: 260 kB     Downloading: 300 kB     Downloading: 300 kB     Downloading: 300 kB     Downloading: 300 kB     Downloading: 300 kB     Downloading: 300 kB     Downloading: 310 kB     Downloading: 310 kB     Downloading: 610 kB     Downloading: 610 kB     Downloading: 620 kB     Downloading: 620 kB     Downloading: 620 kB     Downloading: 620 kB     Downloading: 620 kB     Downloading: 620 kB     Downloading: 620 kB     Downloading: 620 kB     Downloading: 670 kB     Downloading: 670 kB     Downloading: 680 kB     Downloading: 680 kB     Downloading: 800 kB     Downloading: 800 kB     Downloading: 830 kB     Downloading: 830 kB     Downloading: 880 kB     Downloading: 880 kB     Downloading: 880 kB     Downloading: 880 kB     Downloading: 940 kB     Downloading: 940 kB     Downloading: 970 kB     Downloading: 970 kB     Downloading: 970 kB     Downloading: 970 kB     Downloading: 1,000 kB     Downloading: 1,000 kB     Downloading: 1 MB     Downloading: 1 MB     Downloading: 1 MB     Downloading: 1 MB     Downloading: 1 MB     Downloading: 1 MB     Downloading: 1.1 MB     Downloading: 1.1 MB     Downloading: 1.1 MB     Downloading: 1.1 MB     Downloading: 1.1 MB     Downloading: 1.1 MB     Downloading: 1.2 MB     Downloading: 1.2 MB     Downloading: 1.2 MB     Downloading: 1.2 MB     Downloading: 1.2 MB     Downloading: 1.2 MB     Downloading: 1.3 MB     Downloading: 1.3 MB     Downloading: 1.3 MB     Downloading: 1.3 MB     Downloading: 1.3 MB     Downloading: 1.3 MB     Downloading: 1.3 MB     Downloading: 1.3 MB     Downloading: 1.3 MB     Downloading: 1.3 MB     Downloading: 1.4 MB     Downloading: 1.4 MB     Downloading: 1.4 MB     Downloading: 1.4 MB     Downloading: 1.4 MB     Downloading: 1.4 MB     Downloading: 1.4 MB     Downloading: 1.4 MB

# Transforming Latitude and Longitude in a geometry column
df_sf_point <- st_as_sf(df,
                        coords = c("lon", "lat"),
                        na.fail = FALSE,
                        crs = st_crs(shp_campinas)) # Make the CRS of the points the same as the polygon
# Plot the polygon
ggplot() +
  geom_sf(data = shp_campinas, fill = "blue", color = "black") +
  
  # Add points from df_sf_point
  geom_point(data = df, aes(x = lon, y = lat), color = "red", size = 3) +
  
  # Customize plot labels and theme (if needed)
  labs(x = "Longitude", y = "Latitude", title = "Polygon and Points Map") +
  theme_minimal()
```

<img src="man/figures/README-example_points_out1-1.png" width="100%" />

We can see the problem; some of the points are outside Campinas-SP, so
to find out what the outside points are, the function could help us.

``` r
# Finding if the coordinates are inside or not the polygon
df <- points_out(df, "lat", "lon", "out_camp", code_muni = 3509502, year = 2020, polygon_crs = 4326)
knitr::kable(head(df), align = "c") 
```

|    lat    |    lon    | out_camp |
|:---------:|:---------:|:--------:|
|    NA     |    NA     |   TRUE   |
|    NA     |    NA     |   TRUE   |
| -22.84277 | -47.07650 |  FALSE   |
|    NA     |    NA     |   TRUE   |
| -22.77165 | -46.98793 |  FALSE   |

There we go. Three points are found outside Campinas-SP, this could be
helpful when trying to be more accurate in the analysis.

Finally, we can use the `get_best_coords`. The goal is to find the best
coordinates between the three Geocoding services. The ideal structure of
a data frame for these functions is as follows:

``` r
# Sample data frame
df <- data.frame(
  input_addr = c("Rua X 12345-123", "Rua Y 54321-321", "Rua Y 99999", "Rua Z 11111-888", "Rua Z 22211-888", "Rua Z 11111-832", "Rua Z 11111-328"),
  output_addr_1 = c("Rua X 12345-123", "Rua Y 52321-321", "Rua Y 39999", "Rua Z 11111-888", NA, NA, NA),
  output_addr_2 = c("Rua X 12345-113", "Rua YY 54321-321", "Rua 99999", "Rua G 11111", NA, NA, NA),
  output_addr_3 = c("Rua X 12345-123", "Rua Y 54321-321", "Rua YY 19999", "Rua K 11111", NA, NA, NA),
  lat1 = c(-22.71704, -22.71258, -22.77704, -22.74704, NA, NA, NA),
  lon1 = c(-46.91200, -46.90435, -46.97200, -46.91200, NA, NA, NA),
  lat2 = c(-22.72704, -22.71268, -22.72304, NA, -22.72704, NA, NA),
  lon2 = c(-46.93200, -46.90435, -46.99200, NA, -46.92435, NA, NA),
  lat3 = c(-22.75704, -22.71258, NA, NA, NA, -22.77704, NA),
  lon3 = c(-46.92430, -46.90435, NA, NA, NA, -46.92439, NA)
 )

knitr::kable(head(df), align = "c") 
```

|   input_addr    |  output_addr_1  |  output_addr_2   |  output_addr_3  |   lat1    |   lon1    |   lat2    |   lon2    |   lat3    |   lon3    |
|:---------------:|:---------------:|:----------------:|:---------------:|:---------:|:---------:|:---------:|:---------:|:---------:|:---------:|
| Rua X 12345-123 | Rua X 12345-123 | Rua X 12345-113  | Rua X 12345-123 | -22.71704 | -46.91200 | -22.72704 | -46.93200 | -22.75704 | -46.92430 |
| Rua Y 54321-321 | Rua Y 52321-321 | Rua YY 54321-321 | Rua Y 54321-321 | -22.71258 | -46.90435 | -22.71268 | -46.90435 | -22.71258 | -46.90435 |
|   Rua Y 99999   |   Rua Y 39999   |    Rua 99999     |  Rua YY 19999   | -22.77704 | -46.97200 | -22.72304 | -46.99200 |    NA     |    NA     |
| Rua Z 11111-888 | Rua Z 11111-888 |   Rua G 11111    |   Rua K 11111   | -22.74704 | -46.91200 |    NA     |    NA     |    NA     |    NA     |
| Rua Z 22211-888 |       NA        |        NA        |       NA        |    NA     |    NA     | -22.72704 | -46.92435 |    NA     |    NA     |
| Rua Z 11111-832 |       NA        |        NA        |       NA        |    NA     |    NA     |    NA     |    NA     | -22.77704 | -46.92439 |

To get the coordinates for three distinct services the `tidygeocoder`
package could be of help. The `combine_geocode` accepts a list of
arguments that can provide an input address and receive for three
services the coordinates for each address alongside the output address
found by each service. Pending on the Geocoding service, an API key must
be provided, and fees must be paid.

The workflow of the functions is based on the already-mentioned
methodology. To summarize, the function can work in two main parts.

Firstly, it can take columns with all different latitudes and longitudes
for each service. For that, one dist prefix should be provided: `dist`.
The idea is to compare the distance of each point in kilometers between
services. For example, the output data frame would have three new
columns: `dist_prefix_1_2`, ‘dist_prefix_1_3’, and `dist_prefix_2_3`.
Where the `1_2` entailed the distance between the `lat1` `lon1` and
`lat2` `lon2`.

The `short_distance` argument evaluates the new three distance columns
`dist_prefix_*_*` and picks the shortest value; the input is the name of
the column. In this step, it also handles the problem if the latitudes
and longitudes are not enough to create a distance. This happens in two
situations: there was only one point found by only one service for an
address, or no latitude or longitude was found by any of the services.
In this case, the shortest distance will see what is the only latitude
and longitude available, if there is none.

The `short_distance` is needed to calculate the `mdc`. The idea is to
look to see if a given service has found a coordinate that can be
confirmed by another service. The logic goes to the shortest distance,
looking for validation. So, if three services find coordinates for a
given address, the two closest points will receive a point of
confirmation each. When there are only two services providing
coordinates, both will receive a point regardless of distance. No points
will be given for the only service available with coordinates.

The `summarize_mdc` is available when `mdc` is done. It counts by
Geocoding service how many points were given in the `mdc`, enabling a
rank of quality. Higher values show that a given service has a higher
value of matching in coordinates with other services. This is used as a
tiebreaker in the final selection of coordinates for an address. When
`summarize_mdc` is `TRUE` the return is a list with the original data
frame with appended columns and a summarized data frame with the
frequencies from `mdc`.

``` r
result <- get_best_coords(df, "lat1", "lon1", "lat2", "lon2", "lat3", "lon3", "dis",
                          short_distance = TRUE, 
                          mdc = TRUE, 
                          summarize_mdc = TRUE)
```

``` r
mdc_summary <- result$mdc_summary
knitr::kable(head(mdc_summary), align = "c") 
```

| API_dis_NAME1 | API_dis_NAME2 | API_dis_NAME3 |
|:-------------:|:-------------:|:-------------:|
|       3       |       2       |       1       |

``` r
df <- result$original_data
knitr::kable(head(df), align = "c") 
```

|   input_addr    |  output_addr_1  |  output_addr_2   |  output_addr_3  |   lat1    |   lon1    |   lat2    |   lon2    |   lat3    |   lon3    |  dis_1_2  | dis_1_3  |  dis_2_3  | shortest_distance  | dis_1 | dis_2 | dis_3 |
|:---------------:|:---------------:|:----------------:|:---------------:|:---------:|:---------:|:---------:|:---------:|:---------:|:---------:|:---------:|:--------:|:---------:|:------------------:|:-----:|:-----:|:-----:|
| Rua X 12345-123 | Rua X 12345-123 | Rua X 12345-113  | Rua X 12345-123 | -22.71704 | -46.91200 | -22.72704 | -46.93200 | -22.75704 | -46.92430 | 2.3359090 | 4.628388 | 3.4318723 |      dis_1_2       |   1   |   1   |   0   |
| Rua Y 54321-321 | Rua Y 52321-321 | Rua YY 54321-321 | Rua Y 54321-321 | -22.71258 | -46.90435 | -22.71268 | -46.90435 | -22.71258 | -46.90435 | 0.0111319 | 0.000000 | 0.0111319 |      dis_1_3       |   1   |   0   |   1   |
|   Rua Y 99999   |   Rua Y 39999   |    Rua 99999     |  Rua YY 19999   | -22.77704 | -46.97200 | -22.72304 | -46.99200 |    NA     |    NA     | 6.3522199 |    NA    |    NA     |      dis_1_2       |   1   |   1   |   0   |
| Rua Z 11111-888 | Rua Z 11111-888 |   Rua G 11111    |   Rua K 11111   | -22.74704 | -46.91200 |    NA     |    NA     |    NA     |    NA     |    NA     |    NA    |    NA     | just lat1 and lon1 |   0   |   0   |   0   |
| Rua Z 22211-888 |       NA        |        NA        |       NA        |    NA     |    NA     | -22.72704 | -46.92435 |    NA     |    NA     |    NA     |    NA    |    NA     | just lat2 and lon2 |   0   |   0   |   0   |
| Rua Z 11111-832 |       NA        |        NA        |       NA        |    NA     |    NA     |    NA     |    NA     | -22.77704 | -46.92439 |    NA     |    NA    |    NA     | just lat3 and lon3 |   0   |   0   |   0   |

The second part of the function is about picking the final coordinate
based on the measures of quality. The first is the confirmation of the
CEP, if the input address with the CEP has the same CEP as the output,
it indicates a higher level of quality, and it is the first filter when
picking a final coordinate.

The `cep_confirmation` uses `extr_cep` under the hood for the provided
columns with the addresses. It’s worth mentioning that when
`cep_confimation = TRUE` the address strings must be provided, being
four in total; one is the `input_addr` used in the Geocoding, it is
important that these columns have the CEP information; the other three
are the `output_addr_*`, one for each of the three Geocoding services.
Here, the `subsector_as_zip` can be specified if there is a need to
consider five-digit patterns as CEP in the comparison. The result is
four new columns with the CEP for each address given.

The `cep_comparison` uses `compare_cep` under the hood and demands the
`cep_confirmation = TRUE` alongside all the address columns. This
compares the result of the input address found in the `cep_confirmation`
that extracts the CEP pattern with the other addresses exctracted from
CEPs. It creates three new columns to check if the input CEP is equal to
the output CEP for each of the three services. The `strict_check` can be
set to `TRUE` to evaluate equality between CEPs with five digits. It is
recommended that if the `subsector_as_zip` is `TRUE` the `strict_check`
should be too.

``` r
result <- get_best_coords(df, "lat1", "lon1", "lat2", "lon2", "lat3", "lon3", "dis",
                           short_distance = TRUE, 
                           mdc = TRUE, 
                           summarize_mdc = TRUE,
                           cep_confirmation = TRUE,
                           subsector_as_zip = TRUE,
                           cep_comparison = TRUE,
                           strict_check = TRUE,
                           input_addr = "input_addr",
                           output_addr_1 = "output_addr_1",
                           output_addr_2 = "output_addr_2",
                           output_addr_3 = "output_addr_3")
```

``` r
df <- result$original_data
knitr::kable(head(df), align = "c") 
```

|   input_addr    |  output_addr_1  |  output_addr_2   |  output_addr_3  |   lat1    |   lon1    |   lat2    |   lon2    |   lat3    |   lon3    |  dis_1_2  | dis_1_3  |  dis_2_3  | shortest_distance  | dis_1 | dis_2 | dis_3 | input_addr_cep | output_addr_cep_1 | output_addr_cep_2 | output_addr_cep_3 | comparison_cep_input_output_1 | comparison_cep_input_output_2 | comparison_cep_input_output_3 |
|:---------------:|:---------------:|:----------------:|:---------------:|:---------:|:---------:|:---------:|:---------:|:---------:|:---------:|:---------:|:--------:|:---------:|:------------------:|:-----:|:-----:|:-----:|:--------------:|:-----------------:|:-----------------:|:-----------------:|:-----------------------------:|:-----------------------------:|:-----------------------------:|
| Rua X 12345-123 | Rua X 12345-123 | Rua X 12345-113  | Rua X 12345-123 | -22.71704 | -46.91200 | -22.72704 | -46.93200 | -22.75704 | -46.92430 | 2.3359090 | 4.628388 | 3.4318723 |      dis_1_2       |   1   |   1   |   0   |    12345123    |     12345123      |     12345113      |     12345123      |               1               |               0               |               1               |
| Rua Y 54321-321 | Rua Y 52321-321 | Rua YY 54321-321 | Rua Y 54321-321 | -22.71258 | -46.90435 | -22.71268 | -46.90435 | -22.71258 | -46.90435 | 0.0111319 | 0.000000 | 0.0111319 |      dis_1_3       |   1   |   0   |   1   |    54321321    |     52321321      |     54321321      |     54321321      |               0               |               1               |               1               |
|   Rua Y 99999   |   Rua Y 39999   |    Rua 99999     |  Rua YY 19999   | -22.77704 | -46.97200 | -22.72304 | -46.99200 |    NA     |    NA     | 6.3522199 |    NA    |    NA     |      dis_1_2       |   1   |   1   |   0   |     99999      |       39999       |       99999       |       19999       |               0               |               1               |               0               |
| Rua Z 11111-888 | Rua Z 11111-888 |   Rua G 11111    |   Rua K 11111   | -22.74704 | -46.91200 |    NA     |    NA     |    NA     |    NA     |    NA     |    NA    |    NA     | just lat1 and lon1 |   0   |   0   |   0   |    11111888    |     11111888      |       11111       |       11111       |               1               |              NA               |              NA               |
| Rua Z 22211-888 |       NA        |        NA        |       NA        |    NA     |    NA     | -22.72704 | -46.92435 |    NA     |    NA     |    NA     |    NA    |    NA     | just lat2 and lon2 |   0   |   0   |   0   |    22211888    |        NA         |        NA         |        NA         |              NA               |              NA               |              NA               |
| Rua Z 11111-832 |       NA        |        NA        |       NA        |    NA     |    NA     |    NA     |    NA     | -22.77704 | -46.92439 |    NA     |    NA    |    NA     | just lat3 and lon3 |   0   |   0   |   0   |    11111832    |        NA         |        NA         |        NA         |              NA               |              NA               |              NA               |

Finally, the selection of the final coordinate for an address can be
done…
