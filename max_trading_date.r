library(DBI)
library(RPostgreSQL)

con <-dbConnect(dbDriver("PostgreSQL"), user="quant", password="quant14", dbname="quantdb",port="5432")
query <- ("SELECT MAX(TRADING_DATE) FROM STOCK;")

df <- dbGetQuery(con, query)

dbDisconnect(con);
