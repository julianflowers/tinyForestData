calc_dw_lc_tf <- function(i, start, end){
  
  require(reticulate); require(rgee); require(tidyrgee); if(!require(zoo))install.packages("zoo")
  library(zoo)
  require(stars)
  require(terra)
  require(tinyForestR)
  require(sf)
  require(raster)
  
  #initialise_tf()
  
  ee <- import("ee")
  geemap <- import("geemap")
  geedim <- import("geedim")
  Sys.setenv(RETICULATE_PYTHON = "~/Users/julianflowers/.virtualenvs/tinyforest/bin/python")
  use_virtualenv("tinyforest")
  
  #ee_Authenticate()
  ee_Initialize(drive = TRUE)
  
  ## load image collection
  
  
  ic <- ee$ImageCollection("GOOGLE/DYNAMICWORLD/V1")
  
  ## get latest tf data
  
  tf_ll <- tf_latest_sf_uk |>
    st_coordinates() |>
    data.frame()  |>
    bind_cols(tf_id = tf_latest_sf_uk$tf_id)
  
  ## extract lat, lon, tf_id
  
  lon <- tf_ll$X[i]
  lat <- tf_ll$Y[i]
  tf_id <- tf_ll$tf_id[i]
  
  ## calculate buffers
  
  point <- ee$Geometry$Point(c(lon, lat))$buffer(50)
  buff <- ee$Geometry$Point(c(lon, lat))$buffer(1000)
  start <- start
  end <- end
  
  ## set palette
  
  pal <- c(
    '#419bdf', '#397d49', '#88b053', '#7a87c6', '#e49653', '#dfc35a','#c42811',
    '#a59b8f', '#b39fe1')
  
  
  
  ## extract dw image
  dw <- ic$filterBounds(point)
  dw <- dw$filterDate(start, end)
  dw <- dw$select("label")
  dw <- dw$mode()
  
  ## create temporary directory to store raster
  tmpd <- tempdir()
  
  
  ## export and save image to temp directory as tif
  geemap$ee_export_image(ee_object = dw, filename = paste0(tmpd, "/", tf_id, ".tif"), scale = 10, region = buff)
  
  ## convert buffer to sf format
  tf_buff <- ee_as_sf(buff)
  
  
  ## extract tif file and load to stars and rASTER
  f <- list.files(tmpd, "tif", full.names = TRUE)
  dw_sf <- stars::read_stars(f[1]) 
  dw_r <- raster::raster(f[1])
  dw_r <- setMinMax(dw_r)
  
  ## convert stars object to sf
  dw_sf_1 <- dw_sf |>
    st_as_sf()
  
  ## crop to buffer
  dw_tf <- st_intersection(dw_sf_1, tf_buff)
  
  ## return raster and sf object
  
  return(list(raster = dw_r, dw_sf = dw_tf))
  
}


initialise_tf()
library(furrr)
plan(multisession)
seed = furrr_options(seed = 123)
dw_tfs <- map(1:nrow(tf_latest_sf_uk), \(x) calc_dw_lc_tf(x, start="2023-01-01",end = "2023-08-01"), .progress = TRUE)

stars <- tmpd |>
  fs::dir_ls(regexp = "tif") |> 
  map(read_stars)

tf_stars_sf <- map(stars, st_as_sf)

tf_id_stars <- map(tf_stars_sf, colnames) |>
  map(1) |>
  map_int(parse_number) |>
  enframe() |>
  rename(tf_id = value)

tf_buff <- tf_latest_sf_uk |>
  st_transform(27700) |>
  st_buffer(1000) |>
  st_transform(4326)

sf::sf_use_s2(FALSE)
tf_stars_sf_id <- map(1:196, \(x) tf_stars_sf[[x]] %>% mutate(tf_id = tf_id_stars$tf_id[x]) %>% rename(dw = 1))
tf_stars_sf_id_1 <- map(1:196,  \(x) tf_stars_sf_id[[x]] |> st_intersection(tf_buff), .progress = TRUE)
   
tf_dw_counts <- map_dfr(1:196, \(x) tf_stars_sf_id_1[[x]] |> count(tf_id, dw))
tf_dw_counts |>
  write_sf("tf_dw_counts.geojson")

tf_dw_counts |>
  group_by(tf_id) |>
  mutate(sum_n = sum(n), 
         prop_dw = scales::percent(n/sum_n))
