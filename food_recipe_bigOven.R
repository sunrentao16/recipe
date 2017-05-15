# 1------------------------------------------------------------
lapply(c('rvest', 'lubridate'), install.packages)

library(rvest)

library(lubridate) # time duration

# path <- "https://www.bigoven.com/"



# 1-----------------------------------------------

### get recipe data from web & clean data ###

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



# 2----------------------------------------------

path <- "https://www.bigoven.com/recipes/main-dish"



url_table <- get_links(path,'/recipes/main-dish/') %>% unique()



url_table <- modify_url_table(url_table) %>% unlist() # add '?page=6' to get more recipe



recipe_list <- get_all_recipes(url_table)



df_l <- convert_to_df(recipe_list)

# save data

write.csv(df_l, 'recipe_bigOven.csv')

# load data

df_l <- read.csv('recipe_bigOven.csv')

df_l <- df_l[, 2:ncol(df_l)] # delete first row which is row num



# 3-----------------------------------------------

# handle NAs and recipes with few ingredients

clean_data <- function(df_rcp){

  # handel NAs

  for(i in 8:ncol(df_rcp)){

    df_rcp[ ,i] <- as.numeric(df_rcp[,i])

    # replace NAs by median

    df_rcp[is.na(df_rcp[,i]), i] <- df_rcp[!is.na(df_rcp[,i]), i] %>% unique() %>% median()

    ## replace negative value

    df_rcp[df_rcp[, i] < 0, i] <- -1 * df_rcp[df_rcp[, i] < 0, i]

    ## replace extramly large value

    tmp_median <- df_rcp[, i] %>% unique() %>% median()

    df_rcp[df_rcp[, i] > tmp_median*5, i] <- tmp_median

  }

  # delete rows with few ingredients

  delete_row <- c()

  for(i in 1:nrow(df_rcp)){

    if(sum(df_rcp[i, 8:ncol(df_rcp)] != 0) < 6){

      delete_row <- c(delete_row, i)

    }

  }

  df_rcp <- df_rcp[-1*delete_row, ]

  return(df_rcp)

}



# analyze cluster

analyze_cluster <- function(df_rcp, cluster_num = 7){

  library(fpc)

  library(cluster)

  # delete constant column

  delete_col <- c()

  for(i in 8:ncol(df_rcp)){

    # analyze data

    # remove constant column

    if(var(df_rcp[,i])==0){

      delete_col <- c(delete_col, i)

    }

  }

  if(length(delete_col) != 0){

    df_rcp <- df_rcp[,-1*delete_col] 

  }

  # K means

  cls <- kmeans((df_rcp[,8:ncol(df_rcp)]), cluster_num)

  clust <- cls$cluster 

  # visualize

  plotcluster(df_rcp[, 8:ncol(df_rcp)], clust)

  #

  # More complex

  clusplot(df_rcp[, 8:ncol(df_rcp)], clust, color=TRUE, shade=TRUE, 

           labels=2, lines=0)

  #

  df_rcp$cluster <- clust

  print(table(clust)) 

  keep_cls <- c(1:cluster_num)[table(clust) >50]

  #

  tmp_df <- data.frame()

  for(i in seq_along(keep_cls)){

    tmp_df <- rbind(tmp_df, df_rcp[df_rcp$cluster == keep_cls[i],])

  }

  df_rcp <- tmp_df

  return(df_rcp)

}



#

df_rcp <- df_l

df_rcp <- clean_data(df_rcp)

df_rcp <- analyze_cluster(df_rcp)



for(i in 1:30){

  df_rcp <- analyze_cluster(df_rcp)

}



#

library(RSKC)

#

df_x <- df_l[8:ncol(df_l)]

# SVD

library(irlba)

M1 <- as.matrix(df_x)

s <- irlba(M1, nu = 0, nv=10)

M1_reduced <- as.matrix(M1 %*% s$v)

clust_kmeans <- kmeans(M1, 10)

summary(silhouette(clust_kmeans$cluster, dist(M1_reduced)))

clust <- clust_kmeans$cluster









# 4------------------------------------

# Network 
install.packages('dplyr')
library(dplyr)
install.packages('igraph')
library(igraph)
# install.packages('network') 

# install.packages('sna')

# install.packages('ndtv')

# install.packages('visNetwork')


# build the network of ingredient

df_x <- df_l[2:nrow(df_l), 10:ncol(df_l)]

ingredient <- names(df_x)

vert_raw <- data.frame(ids = 1:length(ingredient), ingredient = ingredient)

links_raw <- data.frame(id1 = NA, id2 = NA, weight = 0)



# construct links

for(r in 1:nrow(df_x)){

  linked_node <- which(df_x[r,] != 0 | is.na(df_x[r,])) # all ingredients in same recipe

  if(length(linked_node) > 1){

    all_cb <- combn(length(linked_node), 2) # all combinations

    for(c in 1:ncol(all_cb)){

      tmp_df = data.frame(id1 = linked_node[all_cb[1,c]],

                          id2 = linked_node[all_cb[2,c]],

                          weight = 1)

      links_raw <- rbind(links_raw, tmp_df)

    }

  }

}

links_raw <- links_raw[2:nrow(links_raw), ] # delete 1st row :NAs.

# aggregate weights
links_raw <- links_raw %>% group_by(id1, id2) %>% summarise(weight = sum(weight))

# create a net

net <- graph_from_data_frame(d=links_raw, vertices=vert_raw, directed=F) 

net <- simplify(net, remove.multiple = F, remove.loops = T) 

#

plot_net <- function(net, v_size = .1, mar = -.7, label= NA , edge = 0, title = NULL){

  # plot

  # Compute node degrees (#links) and use that to set node size:

  deg <- degree(net, mode="all")

  V(net)$size <- deg*v_size

  # vertices color

  V(net)$color <- 1:length(V(net))

  # The labels are currently node IDs.

  # Setting them to NA will render no labels:

  V(net)$label <- label

  # Set edge width based on weight:

  E(net)$width <- E(net)$weight/4

  #change arrow size and edge color:

  # E(net)$arrow.size <- .2

  # E(net)$edge.color <- "gray80"

  # E(net)$width <- 1+E(net)$weight/12

  if(edge == 0){

    plot(net, margin = mar, main = title) 

  }else{

    # edge

    edge.start <- ends(net, es=E(net), names=F)[,1]

    edge.col <- V(net)$color[edge.start]

    plot(net, margin = mar, edge.color=edge.col, edge.curved=.1,  main = title)

  }

}

#
png(filename = 'network_1.png', width = 16, height = 9,
	 pointsize = 1/300, units = 'in', res = 300)
#par(mar=c(5,3,2,2)+0.1)
plot_net(net, mar=-.2, title = "Graph of all ingredients")
dev.off()

# delete edges
s <- 1:nrow(links_raw)

net <- delete.edges(net, s[links_raw$weight < 5])
#
png(filename = 'network_2.png', width = 16, height = 9, pointsize = 1/300, units = 'in', res = 300)
plot_net(net, v_size =.05, mar = -.4)
dev.off()

# top ingredients

deg <- degree(net, mode='all')

top_ingredient <- head(sort(deg, decreasing =T),30) %>% names %>% as.numeric()

vert_raw[top_ingredient,]

# delete vertices

net <- delete.vertices(net, c(as.numeric(names(deg[deg==0])), top_ingredient[1:15]))

deg_2 <- degree(net, mode='all')

s <- 1:length(V(net))

net <- delete.vertices(net, s[deg_2 == 0])


png(filename = 'network_3.png', width = 16, height = 9, pointsize = 1/300, units = 'in', res = 300)
plot_net(net, v_size =.2, mar= -.2, edge = .5)
dev.off()


#

deg <- degree(net, mode='all')

top_ingredient <- head(sort(deg, decreasing =T),30) %>% names %>% as.numeric()

vert_raw[top_ingredient,]







# 5--------------------------

# analyze rating

#delete cluster & names column; delete first row of zeros;

df_rating <- df_l[2:nrow(df_l), 3:ncol(df_l)] 

df_rating <- df_rating[!is.na(df_rating$rating) ,]

df_rating$catg <- as.factor(df_rating$catg)

# handle NA

for(c in 2:ncol(df_rating)){

  df_rating[is.na(df_rating[, c]), c] <- unique(df_rating[, c]) %>% median( na.rm = T)

  df_rating[is.infinite(df_rating[, c]), c] <- unique(df_rating[, c]) %>% median( na.rm = T)

}

#sum(is.infinite(x))

#lapply(df_rating, function(x){sum(is.infinite(x))}) %>% unlist() %>% sum()

#
install.packages('glmnet')
library(glmnet)

data_m <- df_rating

x=model.matrix(rating~.,data_m)

x=x[,-1] # get rid of the intercept

# split data

set.seed(1)

train=sample(1:nrow(x),floor(nrow(x)*.6))

train_x=x[train,]

test_x=x[-train,]

train_y=data_m$rating[train]

test_y=data_m$rating[-train]



# build lasso model

al=0 # 1 for lasso, 0 for ridge

model_lasso=glmnet(train_x,

                   train_y,

                   alpha=al)

plot(model_lasso,xvar="lambda")

#find the best lambda using cross validation

set.seed(1)

cv_error=cv.glmnet(train_x,

                   train_y,

                   alpha=al)

best_lambda=cv_error$lambda.min

log(best_lambda)

# fianl model

model_coef=predict(model_lasso,

                   type="coefficients",

                   s=best_lambda)

model_coef

## test the model

pred_y_lasso=predict(model_lasso,

                     s=best_lambda,

                     newx=test_x)

## MSE(Lasso)

MSE_lasso=mean((pred_y_lasso-test_y)^2)





# 6--------------------------------------

# Random Forest
install.packages('randomForest')
library(randomForest)

model_rf <- randomForest(rating~., df_rating,

                         importance =T,

                         proximity=TRUE)



# Variable Importance Plot
png(filename = 'rf_1.png', width = 16, height = 9, units = 'in', res = 300)
varImpPlot(model_rf,

           sort = T,

           main="Variable Importance",

           n.var=5)
dev.off()

#

MDSplot(model_rf,df_rating$rating)

#

tree <- getTree(model_rf, 3, labelVar=TRUE)

png(filename = 'rf_2.png', width = 16, height = 9, units = 'in', res = 300)
plot(tree)
dev.off()



