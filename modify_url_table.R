# modify url_table
modify_url_table <- function(url_table){
	url_table <- url_table[c(-1,-8,-9)] # delete asian, european, latin-american
	result <- list()
	for(i in seq_along(url_table)){
	  for(j in 2:16){
	    result <- c(result, paste(url_table[i],'/page/',j, sep=''))
	  }
	}
	result <- c(result, url_table)
	return(result)
}
