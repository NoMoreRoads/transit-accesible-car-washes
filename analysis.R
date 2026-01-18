options(java.parameters = "-Xmx2G")
# Libraries ====
library(pacman)
p_load(tidyverse, tidycensus, osmdata, r5r)

# Load Data from APIs ====
## Census ====
pop_blocks <- get_acs(
  geography = "block group",
  variables = "B01003_001",
  cache_table = T,
  year = 2023,
  state = "OR",
  county = "multnomah",
  geometry = T,
  survey = "acs5"
)

## Open Street Map ====
pdx_bb <- getbb(place_name = "Portland, Oregon", format_out = "matrix")
op_query <- opq(bbox = pdx_bb)
osm_query_with_features <- add_osm_features(
  opq = op_query,
  features = list(
    "amenity" = "car_wash",
    "shop" = "car_repair",
    "amenity" = "fuel"
  )
)
osm_features <- osmdata_sf(osm_query_with_features) %>%
  unique_osmdata()
