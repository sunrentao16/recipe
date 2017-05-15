---
title: "Recipe project Incubator"
author: "Rentao Sun"
date: "May 13, 2017"
output: html_document
---


# get recipe data from web & clean data ###
```{r, warning= F, message=FALSE}
library(rvest)
library(lubridate) # time duration
# get links function
source("get_links.R")
# modify url_table
source("modify_url_table.R")
# get recipe from one url
source("get_recipe.R")
# get recipe form a table of urls, return a list of recipe
source("get_all_recipes.R")
# convert recipe_list to a data frame
source("convert_to_df.R")
```

```{r eval= F}
# website of recipes
path <- "https://www.bigoven.com/recipes/main-dish"
# get links to recipe
url_table <- get_links(path,'/recipes/main-dish/') %>% unique()
url_table <- modify_url_table(url_table) %>% unlist() # add '?page=6' to get more recipe
# grab recipe information from each web pages
recipe_list <- get_all_recipes(url_table)
# convert recipe information to data frame
df_l <- convert_to_df(recipe_list)
# save data
write.csv(df_l, 'recipe_bigOven.csv')
# load data
df_l <- read.csv('recipe_bigOven.csv')
```
![Alt text](/network_1.png?raw=true "Title")
