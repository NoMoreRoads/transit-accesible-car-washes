# Libraries ====
library(pacman)
p_load(tidyverse, tidycensus, osmdata)

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
pdx_bb <- getbb(place_name = "Portland, Oregon", format_out = "sf_polygon")
