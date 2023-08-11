## code to prepare `flowers` dataset goes here

load("~/Library/CloudStorage/Dropbox/Mac (2)/Desktop/tinyForestR/data/flowers_filt.rda")

usethis::use_data(flowers_filt, overwrite = TRUE)
