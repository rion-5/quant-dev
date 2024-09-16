library(DBI)
library(RPostgres)

max_trading_date <- function() {
  myquery <- "SELECT MAX(TRADING_DATE) FROM STOCK;"
  return (request_quantdb(myquery))
}

start_end_date <- function() {
  myquery <-"select min(trading_date) as start_date, 
                max(trading_date) as end_date
              from (select distinct trading_date 
                    from stock 
                    order by trading_date desc limit 14);"
  return (request_quantdb(myquery))
}




readRenviron(".env")

db_user <- Sys.getenv("DB_USER")
db_pass <- Sys.getenv("DB_PASS")
db_host <- Sys.getenv("DB_HOST")
db_name <- Sys.getenv("DB_NAME")
db_port <- Sys.getenv("DB_PORT")

request_quantdb <- function(query) {
  tryCatch({
    # DB 연결 생성
    con <- dbConnect(
      RPostgres::Postgres(),
      host = db_host,
      user = db_user,
      password = db_pass,
      dbname = db_name,
      port = db_port
    )
    # 쿼리 실행 및 데이터 가져오기
    res <- dbSendQuery(con, query)
    data <- dbFetch(res)
    # 연결 정리
    dbClearResult(res)
    dbDisconnect(con)
    return(data)
  }, error = function(e) {
    # 에러 발생 시 메시지 출력 및 연결 종료
    print(paste("Error:", e$message))
    dbDisconnect(con)
    return(NULL)
  })
}
