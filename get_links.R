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
