## code to prepare `tf_water` dataset goes here

library(tinyForestR)

library(osmdata); library(tidyverse)

safe_water <- safely(get_water_features, otherwise = NA_real_)

tf_water <- map(1:nrow(tf_latest_sf_uk), \(x) safe_water(tf_latest_sf_uk[x, ], tf_id = tf_latest_sf_uk$tf_id[x]), .progress = TRUE)

tf_water <- map(tf_water, "result")

map(tf_water, "b")

tf_water <- tf_water[-c(28, 31, 42, 44, 61, 82, 92:95, 159, 162:163, 178, 180:185, 190:196)]

tf_water <- map(1:length(tf_water), \(x) bind_cols(tf_water[[x]]$b, tf_water[[x]]$d))

usethis::use_data(tf_water, overwrite = TRUE)
