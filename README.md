

  
# Recipe
1. [Collected recipe data from website bigOven.com.](README.md#Grab-recipe-data-from-web-&-clean-data)
2. [Applied network method to explore the relation of different ingredients in recipes.]
3. [Applied random forest and generalized linear regression method to analyze the relation between rating of the recipe and ohter variables.]


# Grab recipe data from web & clean data
```{r, warning= F, message=FALSE}
library(rvest) # Grab data from web
library(lubridate) # time duration
source("get_links.R") # get links function
source("modify_url_table.R") # modify url_table, add '?page=6' to visit more webpages
source("get_recipe.R") # get recipe from one url
source("get_all_recipes.R") # get recipe form a table of urls, return a list of recipe
source("convert_to_df.R") # convert recipe_list to a data frame
```
# Network
Present the relations of ingredients in network graphs. Each ingredient is a vertice in the network.
Go through each recipe, connect all ingredients that appears in one recipe and increase the weight of links between them by 1. The picture below shows the network of all ingredients.
![Alt text](/network_1.png?raw=true "Title")
As we can see in above graph, there are too many vertices and links in the network. Let's reduce the complexity of network, so we can see some meaningful relations between ingredients. Therefore, I deleted all links with weight less than 5, so we get the graph below.
![Alt text](/network_2.png?raw=true "Title")
Since some links are deleted, some vertices are isolated. In the connected graph, there are some large dots. They are some very commen ingredients. For example,

|salt     | onion     |
|---------|-----------|

Let's also delete them, since they doesn't provide much infrmation. Then we get the graph below.
![Alt text](/network_3.png?raw=true "Title")
# Random Forest
Importance of variables
![Alt text](/rf_1.png?raw=true "Title")
Analyze variables
![Alt text](/rf_2.png?raw=true "Title")
# Lasso

# Recommendation 
