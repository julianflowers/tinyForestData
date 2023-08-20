library(sf); library(tidyverse); library(tictoc);library(data.table); library(furrr)
rasters_sf

geo_tf


join_os_dw <- function(x){
  
  tf_ids <- pluck(tf_latest_sf_uk, "tf_id")
  
  j1 <- rasters_sf[[x]] |>
    st_join(geo_tf |>
              filter(tf_id == tf_ids[x]), join = st_intersects)

  return(j1)
  
}

tf_ids <- pluck(tf_latest_sf_uk, "tf_id")

tic()
test1 <- join_os_dw(3)
toc()


data.table::setDTthreads(10)

setDT(test1)[, .N, by = .(dscrptn,  `/var/folders/bk/jrqs03tx5mq9s28mhml5xzhm0000gn/T/Rtmpn5lOp5/dw.tif`)]

rasters_sf[[2]]

geo_tf |>
  filter(tf_id == tf_ids[2])

options(future.globals.MaxSize=1048576000)
plan(multisession)
seed <- furrr_options(seed = 12)
1000*1024^2

tic()
tf_os_dw <- map(1:196, \(x) join_os_dw(x), .progress = TRUE)
toc()

tf_os_dw <- map(1:196, \(x) tf_os_dw[[x]] |> rename(dw = 1))

tf_os_dw_dt <- map(1:196, \(x) tf_os_dw[[x]] |> setDT())

tf_os_dw_dt <- map(1:196, \(x) tf_os_dw_dt[[x]][, .N, by = .(dscrptn, dw)], .progress = TRUE)
tf_os_dw_dt_1 <- map(1:196, \(x) tf_os_dw_dt[[x]][, tf_id := tf_ids[x]], .progress = TRUE)

summ_tf_os_dw <- list_rbind(tf_os_dw_dt_1)

summ_tf_os_dw |>
  fwrite("data/summary-os-dw-tf.csv")


summ_tf_os_dw[, .N, by = .(tf_id)] |>
  View()
 