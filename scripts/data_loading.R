source("scripts/dbms_dml.R")

# 미국 주식시장 휴일 설정 함수 (from db)
us_stock_holidays <- function(year) {
  query <- paste0( "SELECT holiday_date
            FROM market_holidays
            WHERE EXTRACT(YEAR FROM holiday_date) = '", year , "' ;")
  return(request_quantdb(query))
}

# 최근 거래일자 조회 (from db)
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

# 특정 주식의 stock data 가저오기 ((from db))
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

# 특정주식 조건에 따라 가져오기 (from db)
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



# from to 날짜 간격을 확장해서 주식데이터를 조회한 후 리턴한다. (from yahoo)

library(quantmod)

stockDataRange <- function(symbol,from_trade_date, to_trade_date){
  from_date <- as.Date(from_trade_date) - 6
  to_date <- as.Date(to_trade_date) + 1
  trading_data <- na.omit(quantmod::getSymbols(symbol, src="yahoo", from = from_date, 
                                     to = to_date, auto.assign=FALSE))  
  # print(trading_data) 
  from_to_trade_date <- paste(from_trade_date, to_trade_date, sep="/")
  return (trading_data[from_to_trade_date])
}


# NASDAQ, NYSE 의 Ticker 가져오기 (use TTR package )

NASDAQ_NYSE_ticker <- function(){
  
  df_symbols <- TTR::stockSymbols() 
  NASDAQ_symbols <- df_symbols$Symbol[df_symbols$Exchange == "NASDAQ"]
  NYSE_symbols <- df_symbols$Symbol[df_symbols$Exchange == "NYSE"]
  symbols <- append(NASDAQ_symbols, NYSE_symbols)
  
  return(symbols)
}