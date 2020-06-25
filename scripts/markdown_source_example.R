# Example script to source from markdown
library(tidyverse)

d = read_csv("data/clean_vern.csv")

pops = d %>% 
  group_by(site, lat, long, elev_m) %>% 
  summarize(N = n()) %>% 
  arrange(elev_m) %>% 
  rename(Population = site, Latitude = lat, Longitude = long, "Elevation (m)" = elev_m) %>% 
  ungroup() %>% 
  mutate_at(c("Latitude", "Longitude"), round, 3)


height_hist = ggplot(d, aes(x = height_cm, fill = site)) +
  geom_histogram()

