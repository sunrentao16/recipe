# convert recipe_list to a data frame
convert_to_df <- function(recipe_list){
  # delete problematic recipes
  # recipe_list[c(1483, 853)] <- NULL
  # get all ingredients as columns names for data frame
  col_names <- c(names(recipe_list[[1]])[1:8])
  for(i in seq_along(recipe_list)){
    col_names <- c(col_names,
                  names(recipe_list[[i]])[9:length(recipe_list[[i]])]) %>% tolower() %>% unique()
  } 
  col_names <- col_names[!is.na(col_names)]
  # convert recipe to well formated data frame
  # initialize a data frame
  df <- data.frame(matrix(0, ncol = length(col_names)+1, nrow = length(recipe_list)))
  colnames(df) <- c('cluster', col_names)
  for(i in seq_along(recipe_list)){
    for(j in 1:length(recipe_list[[i]])){
      tmp_col_name <- recipe_list[[i]][j] %>% names() %>% tolower
      #tmp_quant <- parse(text=recipe_ingredient_quant[[i]][j]) %>% eval()
      tmp_amount <- recipe_list[[i]][j]
      df[i, tmp_col_name] <- tmp_amount
    }
  }
  # convert review column to numeric
  for(r in 1:nrow(df)){
    if(df$review[r] != 0){
      tmp_rev <- strsplit(df$review[r], " ") %>% unlist()
      df$review[r] <- tmp_rev[1] %>% as.numeric()
    }
  }
  # convert amount to numeric
  # for(c in 9:ncol(df)){
  #   for(r in 1:nrow(df)){
  #     indx <- gregexpr('\\d', df[r,c])[[1]]
  #     txt_num <- substr(df[r,c], indx[1],indx[length(indx)]) # get numeric part
  #     split_txt <- strsplit(txt_num, " ") %>% unlist() # split 
  #     split_txt <- split_txt[split_txt != ""] # delete ""
  #     if(length(split_txt) > 1){
  #       if(grepl('/', split_txt[2]) & !grepl('\\(', split_txt[2])
  #          & !grepl('g', split_txt[2]) & !grepl('ml', split_txt[2])
  #          & !grepl('lbs', split_txt[2])
  #          & !grepl('cup', split_txt[2])
  #          & !grepl('tea', split_txt[2])){
  #           df[r,c] <- eval(parse(text=paste(split_txt[1],'+',split_txt[2], sep="")))
  #       }else if(!grepl(',', split_txt[1]) 
  #                & !grepl('\\(', split_txt[1]) 
  #                & !grepl('x', split_txt[1]) 
  #                & !grepl('\\)', split_txt[1])){
  #         df[r,c] <- eval(parse(text=paste(split_txt[1], sep="")))
  #       }else{
  #         df[r,c] <- NA
  #       }
  #     }else if(length(split_txt) == 1){
  #       if(!grepl('\\(', split_txt)){
  #         df[r,c] <- eval(parse(text=split_txt))
  #       }
  #     }else{
  #       df[r,c] <- NA
  #     }
  #     print(c)
  #     print(r)
  #   }
  # }
  #
  for(c in 9:ncol(df)){
    for(r in 1:nrow(df)){
      indx <- gregexpr('\\d', df[r,c])[[1]]
      txt_num <- substr(df[r,c], indx[1],indx[length(indx)]) # get numeric part
      split_txt <- strsplit(txt_num, " ") %>% unlist() # split 
      split_txt <- split_txt[split_txt != ""] # delete ""
      if(!grepl(',', split_txt[1]) 
         & !grepl('\\(', split_txt[1]) 
         & !grepl('x', split_txt[1]) 
         & !grepl('\\)', split_txt[1])
         & !grepl('-', split_txt[1])){
          df[r,c] <- eval(parse(text=paste(split_txt[1], sep="")))
      }else{
          df[r,c] <- NA
      }
      print(c)
      print(r)
    }
  }
  return(df)
}
