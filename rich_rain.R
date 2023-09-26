library(leaflet); library(mapview); library(tidyverse); library(units)
tf_ndvi_maps

data("seasonal_rainfall_tf")

seas_rain <- seasonal_rainfall_tf |>
  mutate(month = month(date), 
         year = year(date)) 

seas_rain |>
  group_by(year, month) |>
  mutate(mean_rain = mean(rain, na.rm = TRUE)) |>
  ggplot(aes(year, mean_rain, group = tf_id)) +
  geom_point() +
  geom_smooth(method = "loess", se = FALSE) +
    facet_wrap(~ month)
  geom_line(aes(date, mean_rain), data = seas_rain |> filter(month == 1))

  
  seas_rain_w <- seas_rain |>
    select(-date) |>
    pivot_wider(names_from = year, values_from = rain ) |> 
    arrange(month, tf_id)
  
  
  data("tf_latest_sf_uk")

  mapview(tf_latest_sf_uk |>
            filter(tf_id == 290))  
  
  
  data("tf_nbn_df_2010") 
  
 sp_matrix <-  tf_nbn_df_2010 |>
    filter(classs == "Aves") |>
    group_by(tfId) |>
    count(year, tfId, species) |>
    pivot_wider(names_from = species, values_from = n, values_fill = 0)

 richness <- sp_matrix[, -c(1:2)] |>
   vegan::specnumber()

 richness |>
   bind_cols(sp_matrix[, 1:2]) |>
   left_join(seas_rain_w, by = c("tfId" = "tf_id"), relationship = "many-to-many")
 