## code to prepare `tf_landuse` dataset goes here

library(sf)

load("~/Library/CloudStorage/Dropbox/Mac (2)/Desktop/tinyForestR/data/geo_tf.rda")



usethis::use_data(geo_tf, overwrite = TRUE)
