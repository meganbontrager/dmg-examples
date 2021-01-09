# Examples of dplyr functions for manipulating data 
# Megan Bontrager
# 5 May 2020

# See this cheatsheet for more info:
# https://github.com/rstudio/cheatsheets/raw/master/data-transformation.pdf

library(tidyverse)

# This example is with climate NA data, flint BCM script makes data tall already
# Steps are being done separately so you can look at intermediate files, but normally I would combine most of the steps into one chunk with pipes %>% (example given later)



# Pipes ----

# Pipes %>% are a different way of combining functions
# One way of applying 2 functions to a dataframe is like this:
# new_dataframe = function2(function1(old_dataframe, function1arguments), function2arguments)

# Alternaitvely:
# new_dataframe = old_dataframe %>% 
#   function1(arguments) %>% 
#   function2(arguments)

# Functions be arranged horizontally, but stacked is preferred
# new_dataframe = old_dataframe %>% function1(arguments) %>% function2(arguments)

# If you don't specify a new dataframe, the result will print to your console, but not be stored in your environment for future operations.
# You'll notice I do this in some examples so you can just see the head of the output

# When using pipes, you no longer specify dataframes in subsequent lines
# Like this:
# new_dataframe = old_dataframe %>% 
#   function1(column_name)
# Not this:
# new_dataframe = old_dataframe %>% 
#   function1(old_dataframe$column_name)

# Tidyverse functions generally don't require specifying dataframes with a $, and instead, the dataframe is the first argument, with the column separated by a comma
# new_dataframe = function1(old_dataframe, column_name)



# Read in data
wide_data = read_csv("data/climatena_input_1901-2013AMT.csv")

# This data has one row per combination of specimen and year, and columns for each of four variables in 12 months (month is the number in the variable name)
wide_data

table(wide_data$ID1)
names(wide_data)



# Pivot longer----
# Makes wide data tall

tall_data = wide_data %>% 
  pivot_longer(
    # Specify wwhich columns are being made taller (or which should not be)
    # Could list which columns shouldn't be made taller (i.e., the id columns):
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
# Splits a column into two or more

# It would be better to have month in a separate column from the variable type (i.e. PPT, 7 instead of PPT07):

split_month = tall_data %>% 
  # Separate splits a single column into 2+ columns
  # Can specify separating character (i.e., -, _) or the position to separate at, which is what I've done here
  # Convert means it will try to convert to the most logical column type
  separate(variable, -2, into = c("variable", "month"), convert = TRUE) # convert changes the number to an int, default is to a character
split_month
# Now variable and month are in separate columns


# Pivot wider ---- 
# Make tall data wide

# We would rather have one column for each climate variable type instead of all the climate variable types stacked into a single column
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

# Compare to what we started with:
wide_data
vars_columns
# Much better



# Select ----
# Choose, reorder, rename columns

# Maybe we'd rather have year next to month when we look at the data
# Also, I like simpler names than some of these columns have now

data_reordered = vars_columns %>% 
  # With select, you can:  
  # choose a subset of columns in a frame
  # reorder columns (I did this, specified the first five and then everything else. If I left off everything it would pick only the columns specified by name)
  # rename columns (which I also did here, but could have included old names with out "=" if I just wanted to keep the name)
  # If you just wanted to rename columns, without dropping any or changing order, can use rename()
  # Helpful tricks: can use starts_with(), everything() etc.
  select(id = ID1, lat = Latitude, long = Longitude, elev = Elevation, year = Year, everything())
data_reordered

# If you want to drop a column, you just use "-"
# Eg. drop geographic info
no_geo = data_reordered %>% 
  select(-elev, -lat, -long)
no_geo
# Drop temperature columns
no_temp = data_reordered %>% 
  select(-starts_with("T"))
no_temp


# "Pull" selects a single column and makes it a vector rather than a data frame

lat = data_reordered %>% pull(lat)


# Put them all together ----

# All the major steps above can be consolidated into one chunk. This is usually the code format I'd end up with, though I might write it in steps while troubleshooting.

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



# Distinct ----
# Keep unique combinations

# If we needed to just make a small table of the sites and their geographic info from this dataframe:
# (You'd probably already have this from before you extracted climate, but just for example's sake)

site_table = data_reordered %>% 
  # Select columns of interest
  select(id, lat, long, elev) %>% 
  # Keep only distinct combinations of these columns
  distinct() #  can use to check for duplicates (I.E. upgraded Unique)
site_table

# Now, some examples of summarizing and subsetting this data. 



# Filter ----
# Remove rows from a dataframe based on a condition

recent_clim = data_reordered %>% 
  filter(year > 1980)
# Notice how much smaller this dataframe is
dim(data_reordered)
dim(recent_clim)
summary(data_reordered$year)
summary(recent_clim$year)

# You can also include multiple conditions separated by & or |
clim_8010 = data_reordered %>% 
  filter(year > 1980 & year <= 2010)

# Other flavors of filter:
# Year matches a certain value
example = data_reordered %>% 
  filter(year == 2010)
example

# All years except a certain value
example = data_reordered %>% 
  filter(year != 2010)
example

# Can filter to only rows with ids in a vector of possible values 
example = data_reordered %>% 
  filter(id %in% c("SD241782", "UC1529013"))
# Can use any vector in the above, eg., a column from another dataframe
# This also works with a named vector in your environment, e.g., a list of sites from another dataframe or something.
# The above is equivalent to:
example = data_reordered %>% 
  filter(id == "SD241782"|id == "UC1529013")

# You can also pair with str functions to keep only rows where id contains a certain string, etc.
example = data_reordered %>% 
  filter(str_detect(id, "B") == TRUE)
table(example$id)
table(data_reordered$id)

# Can omit rows with ids in a vector of possible values 
example = data_reordered %>% 
  filter(!(id %in% c("SD241782", "UC1529013")))
example

# Vertical bar means "or"
example = data_reordered %>% 
  filter((year > 1980 & year < 2010) | (year > 1910 & year < 1940))
example

# Note you can wrap these piped chunks in plot code (but I usually don't except during data exploration or for testing)
ggplot(data = data_reordered %>% 
  filter(year > 1980 & year < 2010 | year > 1910 & year < 1940)) +
  geom_histogram(aes(x = year))

# Other useful filter operators: is.na(column), !is.na(), <=, >=



# Arrange ----
# Sorts rows
# Useful for quickly looking at which rows contain outliers, etc.

# Quick look at which sites/years/months were wettest:
data_reordered %>% arrange(-PPT)



# Count ----

# Count is kind of like table and returns counts for each unique combination of the specified variables
data_reordered %>% count(id)
data_reordered %>% count(id, year)



# Group by, mutate, summarize ----

# group_by is SUPER useful. It creates invisible group structure in your dataframe, and all subsequent functions are applied within those groups, until you change the grouping structure or ungroup.
# For a list of summary functions, see cheatsheet
# You can also use custom functions

clim_8010 %>% group_by(id)
# If you use group_by alone (which you wouldn't normally do), the only indication you'll see is text indicating how many groups you have near the top of the printout in the console

# You can specify multiple grouping factors
clim_8010 %>% group_by(id, month)

# group_by is usually used with nutate or summarize.
# mutate calculates within groups, but adds a column and doesn't drop rows. 
# summarize calculates within groups and retains only one row per group

# First, use mutate to calculate summed PPT at each site (across 30 years!)
clim1 = clim_8010 %>% 
  group_by(id) %>% 
  mutate(total_ppt = sum(PPT))
dim(clim1)
clim1
# See the new column?
table(clim1$total_ppt, clim1$id)
# Each site has one value for total ppt, but this is repeated in each of 360 rows

# In contrast, summarize:
clim2 = clim_8010 %>% 
  group_by(id) %>% 
  summarise(total_ppt = sum(PPT))
dim(clim2)
clim2
table(clim2$total_ppt, clim2$id)
# The only columns retained are the grouping variables and the calculated variables, and there is just one row per group

# If you want to retain other columns with summarize, you'll need to add them to the group_by line
# Keep an eye on your row numbers, if they increase when you add grouping variables, make sure that makes sense
# For example, here that might indicate a typo, since each id should have only one location
clim3 = clim_8010 %>% 
  group_by(id, lat, long, elev) %>% 
  summarise(total_ppt = sum(PPT))
clim3

# You can summarize multiple variables at once
clim4 = clim_8010 %>% 
  group_by(id, lat, long, elev) %>% 
  summarise(total_ppt = sum(PPT), 
            mean_temp = mean(Tave), 
            max_ppt = max(PPT))
clim4

# Same with mutate()
clim5 = clim_8010 %>% 
  group_by(id, lat, long, elev) %>% 
  mutate(total_ppt = sum(PPT), 
         mean_temp = mean(Tave), 
         max_ppt = max(PPT))
clim5

# mutate can be used with if_else
clim6 = clim_8010 %>% 
  group_by(id, lat, long, elev) %>% 
  mutate(pre1990 = if_else(year<1990, "yes", "no"))
clim6 %>% sample_n(10)
# I use sample n here to show 10 random rows, rather than the first 10, to check how a variety of years were coded

# Can also skip the if_else and just populate with true/false based on a condition
clim7 = clim_8010 %>% 
  group_by(id, lat, long, elev) %>% 
  mutate(pre1990 = year < 1990)
clim7 %>% sample_n(10)

# transmute is like mutate but drops all columns except the grouping columns and the new one
# I have never really encountered circumstances where I need to use transmute. 
clim_8010 %>% 
  group_by(id, lat, long, elev) %>% 
  transmute(total_ppt = sum(PPT))

# You can also get fancy with summarize _all, _if, _at (and mutate _all, _if, _at)

# summarize_all calculates summary functions for all non-grouping variables
# So here, we're calculating monthly means across the 30 years
# Month and year columns are no longer really useful, but illustrate what is happening
clim_8010 %>% 
  group_by(id, lat, long, elev) %>% 
  summarize_all(.funs = mean) 

# summarize_at calculates summary functions for specified variables
clim_8010 %>% 
  group_by(id, lat, long, elev) %>% 
  summarize_at(.funs = mean, vars(Tave, PPT))
clim_8010 %>% 
  group_by(id, lat, long, elev) %>% 
  # calculates summary for specified variables
  summarize_at(.funs = mean, vars(starts_with("T")))

# summarize_if calculates summary on certain column types
clim_8010 %>% 
  group_by(id, lat, long, elev) %>% 
  # calculates summary for specified variables
  summarize_if(.funs = mean, is.numeric)

  
  
  
# Cumulative functions ----

# A bit random and sloppy.

# Mutate can also be used with cumulative functions. This can be useful if you are looking at things like growing degree days, cumulative germination, etc. You need to pay attention to row order when using cumulative functions.
# Example: look at precipitation accumulation beginning in september of each year
# Will build up code so you can see the process
cumulative_ppt = data_reordered %>% 
  # First need to adjust months to make it easy to call september first month
  mutate(water_month = ifelse(month >= 9, month - 8, month + 4))
# Did that work? take a look
table(cumulative_ppt$water_month)
plot(cumulative_ppt$water_month, cumulative_ppt$month)

cumulative_ppt = data_reordered %>% 
  # First need to adjust months to make it easy to call september first month
  mutate(water_month = ifelse(month >= 9, month - 8, month + 4)) %>% 
  # Arrange by id, year, water month
  arrange(id, year, water_month)
cumulative_ppt

cumulative_ppt = data_reordered %>% 
  # First need to adjust months to make it easy to call september first month
  mutate(water_month = ifelse(month >= 9, month - 8, month + 4)) %>% 
  # Arrange by id, year, water month
  arrange(id, year, water_month) %>% 
  # Now want to group by site and year
  group_by(id, year) %>% 
  # And calculate cumulative ppt
  mutate(c_ppt = cumsum(PPT), 
         # Need to make a grouping variable if we want to plot lines individually (should be a way around this in the plot code?)
         gr = str_c(id, year))

# Filter to the month in each year where 100 mm of rain has accumulated, calculate mean month 
cumulative_ppt %>% 
  filter(c_ppt > 100) %>% 
  group_by(id, year) %>% 
  summarize(first_month = min(water_month)) %>% 
  group_by(id) %>% 
  summarise(mean_month = mean(first_month)) %>% 
  arrange(mean_month)
# Sept = 1, so dec = 4. almost 1.5 months different, on average between early and late sites
# Not sure this is actually how I'd look at inter-annual variation, just an example of how these functions work!

# Can also plot cumulative values (think lines for each year, thick lines for means)
ggplot() +
  geom_line(data = cumulative_ppt, aes(x = water_month, y = c_ppt, color = id, group = gr), alpha = 0.2)  +
  stat_summary(data = cumulative_ppt, geom = "line", aes(x = water_month, y = c_ppt, color = id), size = 2) 
# Chaotic plot, but just an example

# Can use filter in plot code
ggplot() +
  geom_line(data = filter(cumulative_ppt, id == "SD241782"), aes(x = water_month, y = c_ppt, color = id, group = gr), alpha = 0.2)  +
  stat_summary(data = filter(cumulative_ppt, id == "SD241782"), geom = "line", aes(x = water_month, y = c_ppt, color = id), size = 2) 

