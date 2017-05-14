# convert recipe_list to a data frame
convert_to_df <- function(recipe_list){
  # get all ingredients as columns names for data frame
  col_names <- c(names(recipe_list[[1]])[1:6])
  for(i in seq_along(recipe_list)){
    col_names <- c(col_names,
                  names(recipe_list[[i]])[7:length(recipe_list[[i]])]) %>% tolower() %>% unique()
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
  for(c in 7:ncol(df)){
    for(r in 1:nrow(df)){
      indx <- gregexpr('\\d', df[r,c])[[1]]
      txt_num <- substr(df[r,c], indx[1],indx[length(indx)]) # get numeric part
      split_txt <- strsplit(txt_num, " ") %>% unlist() # split 
      split_txt <- split_txt[split_txt != ""] # delete ""
      if(length(split_txt) > 1){
        if(grepl('/', split_txt[2]) & !grepl('\\(', split_txt[2])
           & !grepl('g', split_txt[2]) & !grepl('ml', split_txt[2])){
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
