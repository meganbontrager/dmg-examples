# Data for this is on box and too much to put in this repo 
# But example code for making a list of files, reading and binding all of them:

# Compile herbarium specimen image data

library(tidyverse)
library(readxl)

# Stem sizes and notes ----

# These data are in Excel files on the Dimensions Box drive

# To read in and combine multiple files
# Get list of files based on common file name end (there will 1 per species)
# Set path to box folder relative to location of this repository
files = list.files(pattern = "image_data.xlsx", path = "../../../Box/StreptanthusDimensions/HerbariumStudy/data/", full.names = TRUE); files

# Read in and combine (map_df is kind of similar to apply type functions)
# Files is the list of file names, readxlsx is the function to use on all.
sizes = map_df(files, ~read_xlsx(., na = "NA", col_types = c("numeric", "text", "text", "text", "text", "text", "numeric", "numeric", "text"))) %>% 
  # Filter drops rows according to a condition
  filter(!is.na(plant)) 

sizes_clean = sizes %>% 
  # Make counter initials all lowercase, because it was inconsistently entered
  # Mutate makes new columns. If you use the same name, it will overwrite the old column
  mutate(initials = tolower(initials),
         # There was some vocabulary confusion in a column, replace inferred with assumed
         entire_plant_confidence = str_replace(tolower(entire_plant_confidence), pattern = "inferred", replacement = "assumed"))

write.csv(sizes, "data/sizes.csv", row.names = FALSE)
