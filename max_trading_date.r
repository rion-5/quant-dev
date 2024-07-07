library(DBI)
library(RPostgres)

con <-dbConnect(RPostgres::Postgres(),host="localhost", user="quant", password="quant14", dbname="quantdb",port="8080")
query <- ("SELECT MAX(TRADING_DATE) FROM STOCK;")

df <- dbGetQuery(con, query)
print(df)

dbDisconnect(con)
