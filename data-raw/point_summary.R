## code to prepare `buffer_summary` dataset goes here

point_summary <- read_csv("~/Library/CloudStorage/Dropbox/Mac (2)/Desktop/tinyForestR/data/point_summary.csv")

usethis::use_data(point_summary, overwrite = TRUE)
