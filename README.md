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
# Network
Present the relations of ingredients in network graphs. Each ingredient is a vertice in the network.
Go through each recipe, connect all ingredients that appears in one recipe and increase the weight of links between them by 1. The picture below shows the network of all ingredients.
![Alt text](/network_1.png?raw=true "Title")
As we can see in above graph, there are too many vertices and links in the network. Let's reduce the complexity of network, so we can see some meaningful relations between ingredients. Therefore, I deleted all links with weight less than 5, so we get the graph below.
![Alt text](/network_2.png?raw=true "Title")
Since some links are deleted, some vertices are isolated. In the connected graph, there are some large dots. They are some very commen ingredients. For example,
---------|-----------|
salt     | onion     |
---------|-----------|
Let's also delete them, since they doesn't provide much infrmation. Then we get the graph below.
![Alt text](/network_3.png?raw=true "Title")
# Random Forest
Importance of variables
![Alt text](/rf_1.png?raw=true "Title")
Analyze variables
![Alt text](/rf_2.png?raw=true "Title")
