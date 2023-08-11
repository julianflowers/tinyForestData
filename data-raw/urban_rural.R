## code to prepare `urban_rural` dataset goes here

library(tidyverse)

scot_ur <- read_csv("~/Library/CloudStorage/Dropbox/Mac (2)/Desktop/tinyForestR/data/tf_urban_classification_scotland.csv")
eng_ur <- read_csv("~/Library/CloudStorage/Dropbox/Mac (2)/Desktop/tinyForestR/data/tf_urban_classification.csv")

scot_ur <- scot_ur |>
  select(c(tf_id:forest_age, UR8Name)) |>
  rename(UR_class = UR8Name)

eng_ur <- eng_ur |>
  select(c(tf_id:forest_age, rural_urban_classification_2011_10_fold)) |>
  rename(UR_class = rural_urban_classification_2011_10_fold)

tf_urban_classification <- bind_rows(eng_ur, scot_ur)

usethis::use_data(tf_urban_classification, overwrite = TRUE)
