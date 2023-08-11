## code to prepare `tf_latest_sf_uk` dataset goes here

load("~/Library/CloudStorage/Dropbox/Mac (2)/Desktop/tinyForestR/data/tf_latest_sf_uk.rda")

needs(sf)

usethis::use_data(tf_latest_sf_uk, overwrite = TRUE)
