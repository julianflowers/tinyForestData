## code to prepare `tf_dw_counts` dataset goes here

tf_dw_counts <- read_sf("tf_dw_counts_1.geojson")

usethis::use_data(tf_dw_counts, overwrite = TRUE)
