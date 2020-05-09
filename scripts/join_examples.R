# Examples of joining multiple data sheets ----

library(tidyverse)

# bind_rows ----

# Scenario 1: the same type of data is in multiple sheets and you want to join them vertically ----
# Fancy example for many files is in read_mult_files script

# Here's an example where vernalization data from different racks was entered in different sheets (wouldn't actually do it that way, but as an example...)

# Read in both files
v1 = read_csv("data/vern_c9_c10_4wk.csv")
v2 = read_csv("data/vern_c11_c12_c13_4wk.csv")

# Check the names are the same
names(v1)
names(v2)

# If there are many columns, you can do: 
setequal(names(v1), names(v2))
# If not TRUE, you can check which are different with:
setdiff(names(v2), names(v1))
setdiff(names(v1), names(v2))

# Intersect is also useful in some cases, if you want to see which/how many items two vectors or data frame have in common
intersect(names(v1), names(v2))
length(intersect(names(v1), names(v2)))

# Note that it's ok if there are some columns that are not in both sheets, you just want to make sure that they are as you expect, and not columns that should be combined (i.e., if you had height_cm and ht_cm, you want those stacked together so they need to have the same names)
# Names can be changed in the excel files OR in your code by putting %>% rename(new_name = old_name) after your read-in line of code.

all_vern = bind_rows(v1, v2)

# Look at this data frame and make sure you're happy with it
all_vern
summary(all_vern)



# left, right, full, inner join ----

# Scenario 2: joining two different sets of measurements on the same individuals ----

# Imagine we had a new measurement on the same set of plants that we wanted to add to our original data frame. 
new_var = read_csv("data/vern_new_var.csv")

# You need to check which id columns will be used to join these. The default will be any columns with the same name.
intersect(names(all_vern), names(new_var))
# In this case, these are fine. If not, I'll show you what you can do later.
# These should be unique combinations within datasheets. you can check with distinct
all_vern %>% select(block, ID, trt, rack) %>% distinct()
new_var %>% select(block, ID, trt, rack) %>% distinct()
# The number of observations (printed) should match the number of obs in the original frame 

# If you look in the environment pane, you'll see that the new_var frame is missing a few observations relative to the first. 
# You can see which with anti_join
# This shows rows in the first dataframe that are missing from the second data frame, based on matching the id columns, which will be printed when you join. Make sure it makes sense to have these, they could be plants that died between measurements etc. 
anti_join(all_vern, new_var)
# Also double check if any are missing in the other direction:
anti_join(new_var, all_vern)

# To join these sheets, you can use left, right, full, or inner joins, depending on how you want unmatched rows treated.
# Switching between left and right is basically the same as switching the order in which you specify the dataframes, so I'll just show left
# Left join keeps all the rows in the first frame you specify, and joins on any rows that match from the second frame. This is the type of join I use 95% of the time.
# If multiple rows match from the second data frame, then they will be duplicated in the output. This is usually not desirable, since you usually don't want to duplicate observations! So always check your row numbers after a left_join, they should be the same as the first dataframe you specify.
v_left = left_join(all_vern, new_var)
dim(all_vern)
dim(v_left)
summary(v_left)
# Notice the missing values in the variable1 column

# inner_join is similar but will drop rows that are not present in both data frames
v_inner = inner_join(all_vern, new_var)
# Notice there are fewer observations in this frame
summary(v_inner)

# full_join keeps any observation that is present in either dataframe. It will also make all possible combinations of the id columns in the two frames, so be careful and make sure the id columns are distinct if you don't want duplications.
v_full = full_join(all_vern, new_var)
# Notice there are more observations in this frame
summary(v_full)

# If you don't want to use the default joining behavior based on columns with the same name, you can use by = 
v_left = left_join(all_vern, new_var, by = c("ID" = "ID", "block" = "block"))
# In this case, any columns with the same name that aren't specified in the by argument will have .x and .y appended to them.
# But, you can use suffix to give them more descriptive names
# This is useful, for example, when you have columns called notes in both (here I just demonstrate with other columns)
v_left = left_join(all_vern, new_var, by = c("ID" = "ID", "block" = "block"), suffix = c("_prevern", "_postvern"))

# semi_join isn't really a join at all, it just filters the first data frame to observations that are present in the second.
v_semi = semi_join(all_vern, new_var)
# Result is similar to v_inner but it didn't add the new variable, just kept the columns already in all_vern


# Scenario 3: You want to join on "higher level" data ----

# E.g., toothpick colors, geographic locations, other site level variables or anything that matches multiple observations in your "lower level" data
# Sometimes these dataframes can be called lookup tables, i.e., based on some ID (color, site, etc) you could look up a characteristic of an observation

# Example with toothpicks
picks = read_csv("data/toothpick_lookup.csv")
picks

# Note that you could have more than one id here, for example, if different picks have different meanings in different years, you could have a year column

# So, the column "code" here matches "pick_type" in the other data, and we're interested in matching these up so we know which day a plant germinated
# Check if everyone has a match in the lookup table
setdiff(picks$code, all_vern$pick_type) # These are ok, they are present in the lookup table, but don't occur in this cohort of plants
setdiff(all_vern$pick_type, picks$code) # Also ok, if a plant had no pick, it won't have a match

# I'll use left join to join them, because I want to keep all the plants, and want to duplicate rows from the picks frame to match the plants 
v_with_picks = left_join(all_vern, picks, by = c("pick_type" = "code")) %>% 
  # We don't need the long pick type description, so drop it
  select(-type)
v_with_picks
# Now we have a new column, day, which was merged on based on pick type

# Same with geographic info

locs = read_csv("data/site_locations.csv")
locs

# OK, we want to join this on by site

v_with_picks
# But uh oh, site is combined with block in the big data frame
# Let's split it off
v_site = v_with_picks %>% 
  separate(block, into = c("site", "block"), sep = " ")
v_site

v_locs = left_join(v_site, locs)
summary(v_locs)

# Note that all these steps could happen at once:
v = bind_rows(v1, v2) %>% 
  left_join(., new_var) %>% 
  separate(block, into = c("site", "block"), sep = " ") %>% 
  left_join(., picks, by = c("pick_type" = "code")) %>% 
  left_join(., locs) %>% 
  write_csv(., "data/clean_vern.csv")

# What if you have no lookup table? ----

# A scenario that sometimes arises is that you need to join sheets in which the id columns aren't well matched. 
# In this case, it can be helpful to make one that you can fill in manually

# For example, with the herbarium data, there's a bunch of taxonomic variation, but I want to be able to join on species-level variables

herb = read_csv("data/herb.csv")
table(herb$scientificName)
# Yikes!

# I will just make a dataframe of all unique naming variations and write it out (this could be done for many different sheets you are trying to merge and the list made the combination of all of them)
species = herb %>% 
  select(scientificName) %>% 
  distinct() %>% 
  arrange(scientificName) %>% 
  write_csv(., "data/name_lookup.csv")

# Then, I filled in this file manually in excel with the names I'm using in analyses
new_names = read_csv("data/name_lookup_filled.csv")
new_names
# I would then join this on to all the frames I'm using, creating a common name column across all of them. 


