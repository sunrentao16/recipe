# get recipe form a table of urls, return a list of recipe
get_all_recipes <- function(url_table){
  # add category 
  catg <- rep(NA, length(url_table))
  for( i in seq_along(url_table)){
    ind <- gregexpr('/main-dish/', url_table[i])[[1]][1]
    catg_tmp <- substr(url_table[i], ind+11, nchar(url_table[i]))
    if(grepl('/', catg_tmp)){
      catg[i] <- substr(catg_tmp, 1, gregexpr('/', catg_tmp)[[1]][1]-1)
    }else{
      catg[i] <- catg_tmp
    }
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
