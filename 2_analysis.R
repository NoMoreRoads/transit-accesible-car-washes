# Libraries ====
library(pacman)
p_load(tidyverse, tidycensus, osmdata, r5r, sf, tidytransit, osmextract)

# Settings ====
options(java.parameters = "-Xmx2G")
options(tigris_use_cache = TRUE)

# Load Data ====
## From Files ====
service_boundary_sf <- read_sf(
  "downloads/tm_boundary"
)

## From APIS ====
### Census ====
pop_bgs <- get_acs(
  geography = "block group",
  variables = "B01003_001",
  cache_table = T,
  year = 2023,
  state = "OR",
  county = c("multnomah", "washington", "clackamas"),
  geometry = T,
  survey = "acs5"
) %>%
  st_point_on_surface() %>%
  st_transform(4326) %>%
  rename(id = GEOID)

### Open Street Map ====
service_boundary_bb <- service_boundary_sf %>%
  st_transform(4326) %>%
  st_bbox()
op_query <- opq(bbox = service_boundary_bb)
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

osm_features_points <- osm_features %>%
  keep_at(at = \(x) str_detect(x, "osm_")) %>%
  bind_rows() %>%
  st_point_on_surface() %>%
  rename(id = osm_id) %>%
  mutate(
    car_wash = if_else(amenity == "car_wash", T, F, F),
    car_repair = if_else(shop == "car_repair", T, F, F),
    gas_station = if_else(amenity == "fuel", T, F, F)
  ) %>%
  select(id, name, car_wash, car_repair, gas_station)

# Initial Data Processing ====

# Create Route ====
r5r_network <- build_network("downloads")

ttm <- travel_time_matrix(
  r5r_network,
  origins = pop_bgs,
  destinations = osm_features_points,
  mode = c("WALK", "TRANSIT"),
  departure_datetime = as.POSIXct("2026/01/07 12:00"),
  max_trip_duration = 45
)

# Analyze ====
population_by_destination <- ttm %>%
  as_tibble() %>%
  left_join(pop_bgs %>% st_drop_geometry(), by = join_by(from_id == id)) %>%
  left_join(
    osm_features_points %>% st_drop_geometry(),
    by = join_by(to_id == id)
  ) %>%
  mutate(
    people_30_mins = if_else(travel_time_p50 <= 30, estimate, 0),
    people_45_mins = if_else(travel_time_p50 <= 30, 0, travel_time_p50),
    points = people_30_mins + (people_45_mins * 0.5)
  ) %>%
  group_by(to_id, name, car_wash, car_repair, gas_station) %>%
  summarise(
    people_30_mins = sum(people_30_mins),
    people_45_mins = sum(people_45_mins),
    points = sum(points)
  ) %>%
  pivot_longer(
    cols = c(car_wash, car_repair, gas_station),
    names_to = "destination_type"
  ) %>%
  filter(value) %>%
  select(-value) %>%
  group_by(destination_type) %>%
  arrange(desc(points), .by_group = T) %>%
  mutate(rank = row_number())

spatial_results <- population_by_destination %>%
  left_join(osm_features_points %>% select(id), by = join_by(to_id == id))

mapview::mapview(
  spatial_results %>% st_sf() %>% filter(rank <= 3),
  zcol = "destination_type"
)
