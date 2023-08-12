## code to prepare `buffer_summary` dataset goes here

buffer_summary <- read_csv("~/Library/CloudStorage/Dropbox/Mac (2)/Desktop/tinyForestR/data/buffer_summary.csv")

usethis::use_data(buffer_summary, overwrite = TRUE)
