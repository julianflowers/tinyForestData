## process poms data

needs(tidyverse, googledrive, reticulate, sf, broom.mixed)
Sys.setenv(RETICULATE_PYTHON = "/Users/julianflowers/.virtualenvs/tinyforest/bin/python")
use_virtualenv("tinyforest")
py_install("OSGridConverter", envname = "tinyforest")
osng <- import("OSGridConverter")

googledrive::drive_auth()

poms <- drive_download("dissertation/13aed7ac-334f-4bb7-b476-4f1c3da45a13.zip", overwrite = TRUE)

poms1 <- fs::dir_ls("13aed7ac-334f-4bb7-b476-4f1c3da45a13/data", regexp = "csv")

poms_csv <- map(poms1, read_csv)

map(poms_csv, glimpse)

poms_data <- map_dfr(poms_csv, \(x) select(x, sample_id, X1km_square, date, year, habitat_type, target_flower_family, bumblebees:all_insects_total ))
    
poms_data_shape <- poms_data |>
  mutate(date = dmy(date), visit = paste(X1km_square, date, sep = "-")) |>
  filter(nchar(X1km_square) > 5) |>
  arrange(date, X1km_square) |>
  select(sample_id, date, X1km_square, visit, everything())

sq_list <- poms_data_shape |>
  pluck("X1km_square") |>
  unique()


cvt_wgs84 <-  map(1:length(sq_list), \(x) osng$grid2latlong(sq_list[x]) |>  py_to_r() |> as.character() ) |>
  enframe() |>
  unnest("value") |>
  separate(value, c("lat", "lon"), sep = ":") |>
  bind_cols(X1km_square = sq_list) |>
  mutate(lat = parse_number(lat), 
         lon = parse_number(lon)) |>
  left_join(poms_data_shape) |>
  st_as_sf(coords = c("lon", "lat"), crs = 4326) |>
  st_transform(27700)



cvt_wgs84 |>
  ggplot() +
  geom_sf(aes(fill = habitat_type)) +
  geom_sf(data = tf_uk_data_buff) +
  coord_sf()
  

tf_uk_data_buff <- tf_uk_data |>
  st_transform(27700) |>
  st_buffer(10000) |>
  st_intersection(cvt_wgs84)|>
  group_by(tf_id) |>
  group_split()

tf_uk_data_buff[[2]]

get_poms_bd <- function(x){
  
tf_poms <- tf_uk_data_buff[[x]] |>
  mutate(temporal = ifelse(plant_date < date, "pre", "post")) |>
  group_by(date, habitat_type) |>
  select(tf_id, habitat_type, date, visit, bumblebees:all_insects_total) |>
  st_drop_geometry()

spr <- tf_poms[-c(1:5)] |>
  vegan::specpool() 

spr1 <- tf_poms[,-c(1:5)] |>
  vegan::specnumber() |>
  bind_cols(tf_poms[,c(1:5)])

simp <- tf_poms[-c(1:5)] |>
  vegan::diversity("simpson") |>
  bind_cols(tf_poms[,c(1:5)]) 



out <- list(tf_poms, spr = spr, spr1 = spr1, simp = simp)


  
}

poms_tf_bd <- map(1:length(tf_uk_data_buff), \(x) get_poms_bd(x))

poms_tf_bd[[1]]

poms_tf_r_simp <- map_df(poms_tf_bd, "spr1") |>
  left_join(map_df(poms_tf_bd, "simp"), by = c("tf_id", "date", "visit")) |>
  distinct()

poms_tf_r_simp |>
  count(habitat_type.x)

mod <- poms_tf_r_simp |>
  mutate(month = month(date, label = TRUE)) |>
  select(month, habitat_type.x, ...1.x, tf_id)

m0 <- lme4::lmer(...1.x ~ (1|tf_id), data = mod)
broom.mixed::tidy(m0)
broom.mixed::glance(m1)

m1 <- lme4::lmer(...1.x ~ month + habitat_type.x + (1|tf_id), data = mod) 
broom.mixed::tidy(m1, conf.int = TRUE)
broom.mixed::glance(m1)

AIC(m1)
  
  
  summarise(mean_r = mean(...1.x), 
            mean_s = mean(...1.y))
  ggplot(aes(factor(tf_id), 1 - ...1.y)) +
  geom_boxplot()

