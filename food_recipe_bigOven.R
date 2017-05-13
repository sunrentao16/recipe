# 1------------------------------------------------------------
library(XML)
library(rvest)
library(stats)
# path <- "https://www.bigoven.com/"

# 1-----------------------------------------------
### get recipe data from web & clean data ###
# get links function
get_links <- function(path, key_words){
  pg <- read_html(path)
  urls <- pg %>% html_nodes("a") %>% html_attr("href")
  urls_recipe <- urls[grepl(key_words, urls)]
  for(i in seq_along(urls_recipe)){
    if(!grepl("https://www.bigoven.com", urls_recipe[i])){
      urls_recipe[i] <- paste("https://www.bigoven.com", urls_recipe[i], sep="")
    }
  }
  return(urls_recipe)
}

# modify url_table
modify_url_table <- function(url_table){
	url_table <- url_table[c(-1,-8,-9)] # delete asian, european, latin-american
	result <- list()
	for(i in seq_along(url_table)){
	  for(j in 2:6){
	    result <- c(result, paste(url_table[i],'/page/',j, sep=''))
	  }
	}
	result <- c(result, url_table)
	return(result)
}

# get recipe from one url
get_recipe <- function(urls_recipe, catg){
  recipe <- list()
  for(i in seq_along(urls_recipe)){
    html_content <- urls_recipe[i] %>% read_html()
    # ingredients
    ingredient <-  html_content %>%
      html_nodes(".glosslink") %>%
      html_text() %>% tolower() 
    
    # amount
    amount <-  html_content %>%
      html_nodes(".amount") %>%
      html_text()
    amount <- amount[amount != ' ']
    # ingredient -- amount
    ing_amount <- list()
    for(j in seq_along(ingredient)){
      ing_amount[ingredient[j]] <- amount[j]
    }
    #review
    review <- html_content %>%
      html_nodes(".count") %>%
      html_text()
    if(length(review) == 0) review <- 0
    # find calorie
    calorie <- html_content %>%
      html_nodes("p") %>%
      html_text()
    calorie <- calorie[grepl('Calories per serving',calorie)]
    if(length(calorie) != 0){
      indx <- gregexpr('\\d',calorie)[[1]]
      calorie <- substr(calorie, indx[1],indx[length(indx)])
    }else{
      calorie <- NA
    }
    
    # name of dishes
    ind_b <- gregexpr('/recipe/',urls_recipe[i])[[1]][1]+8
    sub_str <- substr(urls_recipe[i], ind_b, nchar(urls_recipe[i]))
    ind_e <- gregexpr('/',sub_str)[[1]][1]
    
    # add all together
    info <- list()
    info['name'] <- substr(sub_str, 1, ind_e-1)
    info['catg'] <- catg
    info['calorie'] <- calorie
    info['review'] <- review
    recipe[[i]] <- c(info, ing_amount)
  }
  return(recipe)
}

# get recipe form a table of urls, return a list of recipe
get_all_recipes <- function(url_table){
  # add category 
  catg <- rep(NA, length(url_table))
  for( i in seq_along(url_table)){
    ind <- gregexpr('/main-dish/', url_table[i])[[1]][1]
    catg[i] <- substr(url_table[i], ind+11, nchar(url_table[i]))
  }
  url_catg <- data.frame( urls = url_table, category = catg)
  # get recipe in a list
  recipe_list <- list()
  for( i in 1:dim(url_catg)[1]){
    url_recipe <- get_links(as.character(url_catg[i,1]), "/recipe/") %>% unique()
    recipe_tmp <- get_recipe(url_recipe, as.character(url_catg[i,2])) %>% unique()
    recipe_list <- c(recipe_list, recipe_tmp)
    # save each file
    #lapply(recipe_tmp, write, paste("recipe_data_bigOven/recipe_list_",i,".txt", sep=';'), append=TRUE, ncolumns=50, sep=';')
    print(i)
    #Sys.sleep(5) # HTTP error 429
  }
  return(recipe_list)
}

# convert recipe_list to a data frame
convert_to_df <- function(recipe_list){
  # get all ingredients as columns names for data frame
  col_names <- c('name','catg','calorie','review')
  for(i in seq_along(recipe_list)){
    col_names <- c(col_names,
                  names(recipe_list[[i]])[5:length(recipe_list[[i]])]) %>% tolower() %>% unique()
  } 
  col_names <- col_names[!is.na(col_names)]
  # convert recipe to well formated data frame
  # initialize a data frame
  df <- data.frame(cluster = NA)
  df[col_names] <- 0
  for(i in seq_along(recipe_list)){
    tmp_df <- data.frame(cluster = NA)
    tmp_df[col_names] <- 0
    # go through the recipe
    for(j in 1:length(recipe_list[[i]])){
      tmp_col_name <- recipe_list[[i]][j] %>% names() %>% tolower
      #tmp_quant <- parse(text=recipe_ingredient_quant[[i]][j]) %>% eval()
      tmp_amount <- recipe_list[[i]][j]
      tmp_df[tmp_col_name] <- tmp_amount
    }
    df <- rbind(df, tmp_df)
  }
  
  # convert amount to numeric
  for(c in 5:ncol(df)){
    for(r in 1:nrow(df)){
      indx <- gregexpr('\\d', df[r,c])[[1]]
      txt_num <- substr(df[r,c], indx[1],indx[length(indx)]) # get numeric part
      split_txt <- strsplit(txt_num, " ") %>% unlist() # split 
      if(length(split_txt) > 1){
        if(grepl('/', split_txt[2]) & !grepl('\\(', split_txt[2])){
          df[r,c] <- eval(parse(text=paste(split_txt[1],'+',split_txt[2], sep="")))
        }else if(!grepl(',', split_txt[1]) & !grepl('\\(', split_txt[1]) 
                 & !grepl('x', split_txt[1]) ){
          df[r,c] <- eval(parse(text=paste(split_txt[1], sep="")))
        }else{
          df[r,c] <- NA
        }
      }else if(length(split_txt) == 1){
        if(!grepl('\\(', split_txt)){
          df[r,c] <- eval(parse(text=split_txt))
        }
      }else{
        df[r,c] <- NA
      }
      print(c)
      print(r)
    }
  }
  return(df)
}

# 2----------------------------------------------
path <- "https://www.bigoven.com/recipes/main-dish"

url_table <- get_links(path,'/recipes/main-dish/') %>% unique()

url_table <- modify_url_table(url_table) %>% unlist() # add '?page=6' to get more recipe

recipe_list <- get_all_recipes(url_table)

df_l <- convert_to_df(recipe_list)
# save data
write.csv(df_l, 'recipe_bigOven.csv')

# 3-----------------------------------------------
### modeling ###
df_x <- df_l[6:ncol(df_l)]

# SVD
library(irlba)
M1 <- as.matrix(df_x)
s <- irlba(M1, nu = 0, nv=10)
M1_reduced <- as.matrix(M1 %*% s$v)
clust_kmeans <- kmeans(M1, 10)
summary(silhouette(clust_kmeans$cluster, dist(M1_reduced)))
clust <- clust_kmeans$cluster
# visualize
visualize_cluster <- function(df_x, clust){
  library(fpc)
  library(cluster)
  # add cluster to df_x
  df_clust <- cbind(clust, df_x)
  df_x <- df_clust[df_clust$clust == 1
                   , 2:ncol(df_clust)]
  clus <- kmeans((df_x), 10)
  clust <- clus$cluster 
  table(clust)
  #
  #plot(df_x, df_l$cluster)
  #
  plotcluster(df_x, clust)
  #
  # More complex
  clusplot(df_x, clust, color=TRUE, shade=TRUE, 
           labels=2, lines=0)
}

visualize_cluster(df_x, clust)

# analyze cluster

analyze_cluster <- function(df_rcp, cluster_num = 10){
  # delete constant column
  delete_col <- c()
  for(i in 6:ncol(df_rcp)){
    # handle NAs
    df_rcp[ ,i] <- as.numeric(df_rcp[,i])
    df_rcp[is.na(df_rcp[,i]),i] <- df_rcp[!is.na(df_rcp[,i]),i] %>% unique() %>% median()
    # remove constant column
    if(var(df_rcp[,i])==0){
      delete_col <- c(delete_col, i)
    }
  }
  if(length(delete_col) != 0){
    df_rcp <- df_rcp[,-1*delete_col] # delete constant column
  }
  # K means
  cls <- kmeans((df_rcp[, 6:ncol(df_rcp)]), cluster_num)
  clust <- cls$cluster 
  # visualize
  plotcluster(df_rcp[, 6:ncol(df_rcp)], clust)
  #
  # More complex
  clusplot(df_rcp[, 6:ncol(df_rcp)], clust, color=TRUE, shade=TRUE, 
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

df_rcp <- df_l

for(i in 1:30){
  df_rcp <- analyze_cluster(df_rcp)
}


#
library(RSKC)

