## code to prepare `sear` dataset goes here

load("~/Library/CloudStorage/Dropbox/Mac (2)/Desktop/tinyForestR/data/seasonal_rainfall_tf.rda")

usethis::use_data(seasonal_rainfall_tf, overwrite = TRUE)
