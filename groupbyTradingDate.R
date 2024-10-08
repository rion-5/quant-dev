library(DBI)
library(RPostgres)

readRenviron(".env")
db_user <- Sys.getenv("DB_USER")
db_pass <- Sys.getenv("DB_PASS")
db_host <- Sys.getenv("DB_HOST")
db_name <- Sys.getenv("DB_NAME")
db_port <- Sys.getenv("DB_PORT")

con <- dbConnect(RPostgres::Postgres(), host = db_host, user = db_user,
                 password = db_pass, dbname = db_name, port = db_port)

query <- ("SELECT trading_date, count(*) FROM STOCK Group by trading_date 
          order by trading_date desc limit 14;")

df <- dbGetQuery(con, query)
print(df)

dbDisconnect(con)