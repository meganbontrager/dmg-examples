# Saving your plots and tables
library(tidyverse)
library(cowplot)

theme_set(theme_cowplot())

d = read_csv("data/clean_vern.csv")

summary(d)
# I'll run some examples with the vernalization data 

# Saving dataframes ----

# How often you save dataframes is up to you, and will depend on the project. 
# I would generally save dataframes coming out of my data prep script. These might be the files I end up publishing with my paper. 
# If I need data in different formats for different analyses, there will be multiple dataframes out of that step. 
# In my opinion, it's good practice to consolidate the steps where you alter your data and save just a few master data frames, instead of, say, writing out new csvs each time you add variables or filter observations. 



# Saving plots ----
# (and making multipanel plots)

# When you're making plots, I really recommend writing the save step into your code. It saves you clicking and as you make edits to either your data or plot code it's easy to always create updated output. It also prevents having a pileup of old stuff by reusing the same file name each time.

# Make a plot of plant height by population:
ggplot(d) +
  geom_boxplot(aes(x = site, y = height_cm, fill = site)) +
  guides(fill = FALSE) +
  labs(x = "Population", y = "Height (cm)")
# I use the ggsave command, you can change the file output type, dimensions etc.
# It will either save the last plot made, or a plot object if you specify one (I'll show that below)
ggsave("plots/height_pop.pdf", height = 4, width = 4, dpi = 72)
# To get the dimensions right, I just try different values and look at the result until I like the ratio of the axes and the text is an appropriate size. 
# This usually results in a size that journals can work with, but if they're really picky, you can specify the size they want and adjust the text, point size, etc in the plot code.

# Make a  plot of plant height vs. length of longest leaf
ggplot(d, aes(x = longest_leaf_mm, y = height_cm, color = site, fill = site)) +
  geom_point(alpha = 0.7) +
  geom_smooth(method = "lm") +
  labs(x = "Longest leaf (mm)", y = "Height (cm)", color = "Site", fill = "Site")
# I use the ggsave command, you can change the file output type, dimensions etc.
# It will either save the last plot made, or a plot object if you specify one
ggsave("plots/height_leaf.pdf", height = 4, width = 4, dpi = 72)


# If you want to make a multipanel plot, save panels as objects
p1 = ggplot(d, aes(x = longest_leaf_mm, y = number_true_leaves, color = site, fill = site)) +
  # jitter a bit to show more points
  geom_jitter(alpha = 0.7, width = 0.2, height = 0.3) +
  geom_smooth(method = "lm") +
  labs(x = "Longest leaf (mm)", y = "Number of leaves", color = "Population", fill = "Population")
# To see a plot that you've put into an object, need to run object name
p1

p2 = ggplot(d, aes(x = site, y = height_cm, fill = site)) +
  # jitter a bit to show more points
  geom_boxplot() +
  guides(fill = FALSE) +
  labs(x = "Population", y = "Plant height (cm)", color = "Site")
p2

plot_grid(p2, p1, labels = c("A.", "B."), rel_widths = c(0.75, 1))
ggsave("plots/size_by_pop.pdf", height = 4, width = 9)

# cowplot has tons of handy functionality I won't describe here but I recommend checking it out


# Saving tables ----

# Running statistical tests and saving the output for tables can be really inefficient in R
# Once I've settled on an analysis, I'll write a bit of code to save the table automatically, so that it's easy to paste into a manuscript.

mod1 = lm(height_cm ~ longest_leaf_mm + site, data = d)
summary(mod1)

# to be finished

