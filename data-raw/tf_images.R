## code to prepare `tf_images` dataset goes here

library(tidyverse);library(tinyForestR)

lls <- tf_latest_sf_uk |>
  st_coordinates() |>
  data.frame() |> 
  bind_cols(tf_id = tf_latest_sf_uk$tf_id)

tf_images <- map(1:nrow(tf_latest_sf_uk), \(x) get_tf_images(zoom = 17, lon = lls$X[x], lat = lls$Y[x], tf_id = lls$tf_id[x], key = "AIzaSyCVgq2b2k414CLphwpShVdoVm-lJUE2HVk"),
                 .progress = TRUE)


usethis::use_data(tf_images, overwrite = TRUE)
