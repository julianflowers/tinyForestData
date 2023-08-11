## code to prepare `monthly_mean_ndvi_tf` dataset goes here

load("~/Library/CloudStorage/Dropbox/Mac (2)/Desktop/tinyForestR/data/monthly_mean_ndvi_tf.rda")

usethis::use_data(monthly_mean_ndvi_tf, overwrite = TRUE)
