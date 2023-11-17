## os open data
## 
## 
## 
library(needs)
needs(fs, sf, here, devtools, mapview, tidyverse)

tf_data <- readr::read_csv("/Users/julianflowers/Library/CloudStorage/GoogleDrive-julian.flowers12@gmail.com/My Drive/dissertation/data/tf_latest_1.csv")

tf_buff <- tf_data |>
    st_as_sf(coords = c("lon", "lat"), crs = 4326) |>
    st_transform(27700) |>
    st_buffer(1000)

unzip("/Users/julianflowers/tiny_forest_thesis/data/oproad_gpkg_gb.zip", exdir = "/Users/julianflowers/tiny_forest_thesis/data")

p <- here::here("/Users/julianflowers/tiny_forest_thesis/data")

f <- dir_ls(p)
f


roads <- read_sf("/Users/julianflowers/tiny_forest_thesis/data/Data/oproad_gb.gpkg", "road_link")


road_tf <- st_intersection(tf_buff, roads)

## rood_length per tf

road_tf_length <- road_tf |>
    group_by(tf_id) |>
    summarise(road_length = sum(length))

road_tf_length |> write_sf("road_length.gpkg")

road_tf_length[100,] |>
    mapview()

road_tf_length |>
    ggplot() +
    geom_sf(aes(colour = tot_length)) +
    scale_colour_viridis_c()


## built up areas
## 
## 

st_layers("/Users/julianflowers/Library/CloudStorage/GoogleDrive-julian.flowers12@gmail.com/My Drive/dissertation/data/OS_Open_Built_Up_Areas.gpkg")


built_up <- read_sf("/Users/julianflowers/Library/CloudStorage/GoogleDrive-julian.flowers12@gmail.com/My Drive/dissertation/data/OS_Open_Built_Up_Areas.gpkg", 
                    layer = "OS_Open_Built_Up_Extents")

built_up_tf <- st_intersection(tf_buff, built_up)



built_sum <- built_up_tf |>
    mutate(calc_area = st_area(geometry)) |>
    group_by(tf_id) |>
    summarise(built_area = sum(calc_area)) |>
    mutate(built_area = units::drop_units(built_area))



 built_sum |>  write_sf("built_area.gpkg")


## 
## woodland from open zoomstack - this doesn't nmake sense ----

woodland <- read_sf("/Users/julianflowers/tiny_forest_thesis/data/OS_Open_Zoomstack.gpkg", layer="woodland")

woodland_tf <- st_join(tf_buff, woodland, st_join = st_intersects) |>
    arrange(tf_id)


wood_sum <- woodland_tf |>
    group_by(tf_id) |>
    mutate(n = n(), w_area = st_area(geometry)) |>
    summarise(wood_area = sum(w_area),
              sum_n = sum(n), 
              wood_area = wood_area / sum_n) |>
    arrange(tf_id)

tf_buff[5,] |> mapview()

# woody features e.g. hedgerows ----
## get reference 

woody <- read_sf("/Users/julianflowers/tinyForestR/large-data/woody_features.shp")

woody_tf <- st_intersection(tf_buff, woody) 

woody_tf_summ <- woody_tf |>
    st_drop_geometry() |>
    group_by(tf_id) |>
    summarise(hedge_len = sum(SHAPE_Leng)) 
    


## rivers -----
## 

river <- st_read("/Users/julianflowers/tiny_forest_thesis/data/Data/oprvrs_gb.gpkg", layer = "watercourse_link")

river_tf <- st_intersection(tf_buff, river)

river_tf_length <- river_tf |>
    group_by(tf_id) |>
    summarise(r_len = sum(length))

## fresh water ----

source_url("https://github.com/julianflowers/tinyForestR/blob/main/R/get_os_water.R?raw=TRUE")

safe_water <- safely(os_ngd_api_call_water, otherwise = NA_real_)

water <- map(1:nrow(tf_buff), \(x) safe_water(tf_buff[x,] |> st_transform(4326), 
                                                         offset = 0, 
                                                         api_key = Sys.getenv("OSDATAHUB")),
                                                         .progress = TRUE)

ids <- tf_buff[["tf_id"]]


water_1 <- map(water, "result") |>
    map("os_lc") 
water_d <- map(water_1, dim) |>
    map(1) |>
    map(\(x) x[which(x > 0)])  |>
    enframe() |>
    unnest('value') |>
    #print(n = 203)
    pluck("name")
   
ids <- ids[water_d]

water_tf <-  map_dfr(1:length(ids), \(x) water_1[water_d][[x]] |> mutate(tf_id = ids[x]))

water_tf_summary <- water_tf |>
    select(tf_id, osid, toid, dscrptn = description, oslndst = oslandcovertierb) |>
    st_make_valid() |>
    mutate(w_area = st_area(geometry)) |>
    st_cast("MULTILINESTRING") |>
    mutate(w_length = st_length(geometry)) |>
    group_by(tf_id, dscrptn) |>
    summarise(area_w = sum(w_area), 
              len_w = sum(w_length))
    
water_tf_summary_w <- water_tf_summary |>
    st_drop_geometry() |>
    mutate(area_w = units::drop_units(area_w), 
           len_w = units::drop_units(len_w)) |>
    pivot_wider(names_from = dscrptn, values_from = c("area_w", "len_w"), values_fill = 0) |>
    janitor::clean_names()
    

## priority habitats ----
## https://naturalengland-defra.opendata.arcgis.com/datasets/Defra::priority-habitats-inventory-england/about

ph <- read_sf('/Users/julianflowers/tiny_forest_thesis/data/Priority_Habitats_Inventory_England_189523467436769964.gpkg')

ph_tf <- st_intersection(tf_buff, ph)

ph_tf_sum <- ph_tf |>
    count(tf_id) |>
    mutate(ph_area = st_area(geometry))

woody_tf_summ |>
    st_drop_geometry() |>
    left_join(built_sum |> st_drop_geometry(), by = "tf_id") |>
    left_join(road_tf_length |> st_drop_geometry(), by = "tf_id") |>
    #left_join(river_tf_length |> st_drop_geometry(), by = "tf_id") |>
    left_join(water_tf_summary_w, by = "tf_id") |>
    left_join(ph_tf_sum, by = "tf_id") |>
    #glimpse()
    select(tf_id:road_length, p_patches = n, ph_area, contains("still"), contains("open_reservoi"), 
           contains("len_w_waterc")) |>
        write_csv("/Users/julianflowers/tiny_forest_thesis/data/wood_road.csv")

    
