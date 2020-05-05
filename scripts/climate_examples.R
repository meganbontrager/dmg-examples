# Examples of dplyr functions for manipulating data 

library(tidyverse)

# This example is with climate NA data, flint BCM script makes data tall already
# Steps are being done separately so you can look at intermediate files, but normally I would combine most of the steps into one chunk with pipes %>% 

# First thing is to make data tall instead of wide
# Read in data
wide_data = read_csv("data/climatena_input_1901-2013AMT.csv")

# This data has one row per combination of specimen and year, and columns for each of four variables in 12 months (month is the number in the variable name)
wide_data

table(wide_data$ID1)
names(wide_data)

# Pivot longer ----

tall_data = wide_data %>% 
  pivot_longer(
    # Specify wwhich columns are being made taller (or which should not be)
    # Could list which shouldn't be:
    # cols = -c(Year, ID1, Latitude, Longitude, Elevation), 
    # Alternatively, can list which should be combined into one tall column.
    # Here I'm using the matches argument since there are 12*4 columns involved, too many to type out.
    # vertical bars mean "or"
    cols = matches("Tmax|Tmin|Tave|PPT"), 
    # specify the name of the new column with all these column names stacked up
    names_to = "variable",
    # specify name of values column where the cell contents are going
    values_to = "value"
    )
  
# Now we have a tall data frame that has a variable column, with all four varables in it:
tall_data

# Separate ----

# But it would be better to have month in a separate column from the variable type (i.e. ppt):

split_month = tall_data %>% 
  # Separate splits a single column into 2+ columns
  # Can specify separating character (i.e., -, _) or the position to separate at, which is what I've done here
  # Convert means it will try to convert to the most logical column type
  separate(variable, -2, into = c("variable", "month"), convert = TRUE)
split_month
# Now variable and month are in separate columns


# Pivot wider ---- 

# Maybe we would rather have one column for each climate variable type
vars_columns = split_month %>% 
  pivot_wider(
    # Specify id columns that shouldn't be spread
    id_cols = c(Year, ID1, Latitude, Longitude, Elevation, month), 
    # Specify where new column names should come from
    names_from = variable, 
    # Specify where values should come from
    values_from = value)

vars_columns

# That's looking pretty useable
# For each site in a given year and month, we have four climate variables

# Maybe we'd rather have year next to month when we look at the data
# Also, I like simpler names than some of these columns have now

# Select ----

data_reordered = vars_columns %>% 
  # With select, you can:  
  # choose a subset of columns in a frame
  # reorder columns (I did this, specified the first five and then everything else)
  # rename columns (which I also did here, but could have included old names with out "=" if I just wanted to keep the name)
  # If you just wanted to rename columns, without dropping any or changing order, can use rename()
  # Helpful tricks: can use starts_with(), everything() etc.
  select(id = ID1, lat = Latitude, long = Longitude, elev = Elevation, year = Year, everything())
data_reordered


# Put them all together with pipes ----

# All the steps above can be consolidated into one chunk:

wide_data = read_csv("data/climatena_input_1901-2013AMT.csv") %>% 
  pivot_longer(
    cols = matches("Tmax|Tmin|Tave|PPT"), 
    names_to = "variable",
    values_to = "value"
  ) %>% 
  separate(variable, -2, into = c("variable", "month"), convert = TRUE) %>% 
  pivot_wider(
    id_cols = c(Year, ID1, Latitude, Longitude, Elevation, month), 
    names_from = variable, 
    values_from = value) %>% 
  select(id = ID1, lat = Latitude, long = Longitude, elev = Elevation, year = Year, everything())
data_reordered


# count, summarise, summarize all, group_by, filter, distinct, pull, mutate, transmute, mutate all, mutate at, rename

# left, right, full, inner
# suffix, by

# bind rows, setdiff, intersect, set equal
# semi join, anti join



