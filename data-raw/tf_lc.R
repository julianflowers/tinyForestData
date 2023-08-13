## code to prepare `tf_lc` dataset goes here

tf_lc <- read_csv("data/tf_lc.csv")

usethis::use_data(tf_lc, overwrite = TRUE)
