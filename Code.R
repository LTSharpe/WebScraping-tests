# load libraries
library(RSelenium)
library(rvest)
library(data.table)
library(magrittr)

rm(list = ls())

source("Functions.R")

# parent url
parent_url <- "https://market.yandex.ru/"

# sections
category_url <- "catalog/"

# category id
cat_id <- 54726 # mobile phones

# generate url for catergory
url <- paste0(parent_url, category_url, cat_id)

# load web-page
# connect to RSelenium (running on docker)
#rD <- RSelenium::rsDriver(browser = "firefox") # open browser
#remDr <- rD[["client"]] # connect to client

# connect to Firefox on docker
remDr <- remoteDriver(
  port = 4444L,
  browserName = "firefox",
  extraCapabilities = 
    makeFirefoxProfile(list(
      permissions.default.image = 2L,
      browser.migration.version = 9999L)
      )
  )
remDr$open() # open connection

# navigate to page
remDr$navigate(url)

wait_time <- 0L
error_msg_not_clickable <- "unknown error: Element.* is not clickable at point"
error_msg_overload <- "unexpected alert open"
error_msg_finish <- "element not visible"

# press button to load more results until all are loaded
chk <- NULL
while(is.null(chk)){
  chk <- pressButton(findButton(remDr, ".pager-more__button"), remDr, ".pager-more__button")
  
  Sys.sleep(wait_time)
}

remDr$screenshot(display = TRUE)

# get page html
page_source <- remDr$getPageSource()[[1]]
page_html <- read_html(page_source)

# close RSelenium & clean not needed objects from memory
remDr$close()
#rD[["server"]]$stop() # if using rsDriver()
rm(remDr, chk, page_source, error_msg_finish, error_msg_not_clickable, error_msg_overload, wait_time)

# main nodes with product details
nodes <- html_nodes(page_html, ".n-snippet-cell2")

# load data from web-page
Data <- data.table(
  # product identifiers
  ID = gsub("model-", "", nodes %>% html_attr("data-id")),
  # product titles
  Title = nodes %>% html_node(".n-snippet-cell2__title") %>% html_text,
  # product main prices
  Main_Price = as.numeric(gsub(
    "[^0-9]", "", nodes %>% html_node(".n-snippet-cell2__main-price") %>% html_text
    )),
  # product lowest prices
  Best_Price = as.numeric(gsub(
    "[^0-9]", "", nodes %>% html_node(".n-snippet-cell2__more-prices-link .price") %>% html_text
    )),
  # product number of quotes
  Quotes = as.numeric(gsub(
    "[^0-9]", "", nodes %>% html_node(".n-snippet-cell2__more-prices-link .link_type_prices") %>% html_text
    )),
  # product rating
  Rating = as.numeric(
    nodes %>% html_node(".rating__value") %>% html_text
    ),
  # product number of votes
  Votes = as.numeric(gsub(
    "[^0-9]", "", nodes %>% html_node(".n-snippet-card2__rating span") %>% html_text
    ))
)
