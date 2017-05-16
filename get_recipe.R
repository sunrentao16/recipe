# get recipe from one url
get_recipe <- function(urls_recipe, catg = NA){
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
    # rating
    rating <- html_content %>%
      html_nodes(".recipe-detail-star-rating") %>%
      html_text()
    indx_rat <- gregexpr('reviews', rating)[[1]][1]
    tmp_rat <- substr(rating, indx_rat+7, indx_rat + 10)
    rating <- substr(tmp_rat, 1, gregexpr('\r', tmp_rat)[[1]][1]-1) %>% as.numeric()
    # number of photos
    photo <- html_content %>%
      html_nodes("a") %>%
      html_text()
    photo <- photo[grepl('Photos', photo)]
    photo <- substr(photo, gregexpr('\\(', photo)[[1]][1]+1, gregexpr('\\)', photo)[[1]][1]-1) %>% as.numeric()
    # find calorie
    calorie <- html_content %>%
      html_nodes("p") %>%
      html_text()
    calorie <- calorie[grepl('Calories per serving',calorie)]
    if(length(calorie) != 0){
      indx <- gregexpr('\\d',calorie)[[1]]
      calorie <- substr(calorie, indx[1],indx[length(indx)]) %>% as.numeric()
    }else{
      calorie <- NA
    }
    #find numer of serving
    serving_num <- html_content %>%
      html_nodes("p") %>%
      html_text()
    serving_num <- serving_num[grepl('Original recipe makes', serving_num)]
    if(length(serving_num) != 0){
      indx <- gregexpr('\\d',serving_num)[[1]]
      serving_num <- substr(serving_num, indx[1],indx[length(indx)]) %>% as.numeric()
    }else{
      serving_num <- NA
    }
    #find duration of cooking
    duration_text <- html_content %>%
      html_nodes(".duration") %>%
      html_text()
    indx_dur <- gregexpr('\\d', duration_text)[[1]][1] # find the first digit
    duration_text <- substr(duration_text, indx_dur, nchar(duration_text)) # only keep digit part
    dur_split <- strsplit(duration_text, ' ') %>% unlist() # splite
    duration_cook <- duration(Reduce(paste, dur_split)) # convert to duration format
    # name of dishes
    ind_b <- gregexpr('/recipe/',urls_recipe[i])[[1]][1]+8
    sub_str <- substr(urls_recipe[i], ind_b, nchar(urls_recipe[i]))
    ind_e <- gregexpr('/',sub_str)[[1]][1]
    
    # add all together
    info <- list()
    info['name'] <- substr(sub_str, 1, ind_e-1)
    info['catg'] <- catg
    #info['duration_cook'] <- sprintf('%02d:%02d', hour(as.period(duration_cook)), minute(as.period(duration_cook)))
    info['duration_cook'] <- as.numeric(duration_cook)/3600
    info['calorie_per_serving'] <- calorie / serving_num
    info['review'] <- review
    info['rating'] <- rating
    info['photo'] <- photo
    info['serving_num'] <- serving_num
    recipe[[i]] <- c(info, ing_amount)
  }
  return(recipe)
}
