# Libraries ====
library(pacman)
p_load(tidyverse, osmextract, sf)

# Create Downloads Directory ====
dir.create("downloads")

# Download Data ====
## GTFS ====
download.file(
  "https://developer.trimet.org/schedule/gtfs.zip",
  "downloads/trimet_gtfs.zip"
)

## Service Boundary====
download.file(
  "https://developer.trimet.org/gis/data/tm_boundary.zip",
  "downloads/service_boundary.zip"
)
unzip(
  "downloads/service_boundary.zip",
  exdir = "downloads/tm_boundary"
)

## OSM Network ====
sevice_boundary_sf <- read_sf(
  "downloads/tm_boundary"
)
oe_get(
  place = sevice_boundary_sf,
  download_directory = "downloads",
  boundary = sevice_boundary_sf,
  # boundary_type = "clipsrc"
)
