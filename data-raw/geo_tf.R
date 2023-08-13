## code to prepare `geo_tf` dataset goes here


load("/Users/julianflowers/Downloads/geo_tf.rda")

geo_tf <- geo_tf[[5]][[217]]

usethis::use_data(geo_tf, overwrite = TRUE)
