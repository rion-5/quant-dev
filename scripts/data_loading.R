library(DBI)
library(RPostgres)

max_trading_date <- function() {
  query <- "SELECT MAX(TRADING_DATE) FROM STOCK;"
  return (request_quantdb(query))
}

start_end_date <- function() {
  query <- "select min(trading_date) as start_date,
                max(trading_date) as end_date
              from (select distinct trading_date
                    from stock
                    order by trading_date desc limit 14);"
  return (request_quantdb(query))
}

# 특정 주식의 stock data 가저오기
getStock_from_to <- function(symbol, from_trading_date, to_trading_date) {
  query <- paste0(
    "select trading_date, open, high,low,close,volume, adjusted from stock
     where symbol = '",symbol,
    "' and trading_date >='", from_trading_date,
    "' and trading_date <='", to_trading_date, "' 
    order by trading_date ;"
  )
  return (request_quantdb(query))
}

# 특정주식 조건에 따라 가져오기
# 조건: 최근 15일 거래일간 조정종가(adjusted)가 100~1000달러이면서 거래량이 8000000 이상이 13회 이상인 종목

stock_100_1000 <-function(){
  query <-"WITH DateRange AS (
          SELECT MIN(trading_date) AS start_date,
                 MAX(trading_date) AS end_date
          FROM (SELECT DISTINCT trading_date
                FROM stock
                ORDER BY trading_date DESC LIMIT 15)
        )
        select symbol, count(*),
        		round(min(adjusted)::numeric,2) as min_adjusted,
        		round(avg(adjusted)::numeric,2) as avg_adjusted,
        		round(max(adjusted)::numeric,2) as max_adjusted,
        		round(min(volume)::numeric,0) as min_volume,
        		round(max(volume)::numeric,0) as max_volume
        FROM stock
        WHERE trading_date BETWEEN (SELECT start_date FROM DateRange)
                              AND (SELECT end_date FROM DateRange)
        and adjusted between 100 and 1000
        and volume >= 8000000
        group by symbol
        having count(*) >= 13
        order by min_volume desc; "
  return (request_quantdb(query))
}




readRenviron("/Users/rion5/Project/R/quant-dev/.env")

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
