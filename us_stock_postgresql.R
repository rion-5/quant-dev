library(quantmod)
#library(RPostgreSQL)
library(RPostgres)
library(xts)
library(zoo)
library(TTR)
library(DBI)
readRenviron(".env")
db_user <- Sys.getenv("DB_USER")
db_pass <- Sys.getenv("DB_PASS")
db_host <- Sys.getenv("DB_HOST")
db_name <- Sys.getenv("DB_NAME")
db_port <- Sys.getenv("DB_PORT")

# from to 날짜가 입력되면 날짜 간격을 확장해서 주식데이터를 조회한 후 리턴한다. 
from_to_stock <- function(from_trade_date, to_trade_date, symbol){
  from_date <- as.Date(from_trade_date) - 6
  to_date <- as.Date(to_trade_date) + 1
  trading_data <- na.omit(getSymbols(symbol, src="yahoo", from = from_date, to = to_date, auto.assign=FALSE))  
  # print(trading_data) 
  from_to_trade_date <- paste(from_trade_date, to_trade_date, sep="/")
  return (trading_data[from_to_trade_date])
}

# 사용하지 않음  TTR의 stockSymbols() 사용가능
# symbols_fromDB <- function(){
#   tryCatch({    
#     con <- dbConnect(RMariaDB::MariaDB(), default.file = "./my.cnf", group = "my-db")
#     res <- dbSendQuery(con, "select distinct (symbol) from stock_trading;")
#     data <- dbFetch(res)
#     sym <- data$symbol
#     dbClearResult(res)
#     dbDisconnect(con)
#   }, error = function(e){
#     print(paste('Error1 (symbols_fromDB): ', e))
#   })
#   return (sym)
# }

insert_data <- function(from_date, to_date, symbol){
  print(symbol)
  
  trading_data <- from_to_stock(from_date, to_date, symbol)
  
  for( i in (1:nrow(trading_data))){
    tryCatch({
      con <-dbConnect(RPostgres::Postgres(),host=db_host, user=db_user, password=db_pass, dbname=db_name,port=db_port)

      oneday_data <- trading_data[i,]
      trade_date <- index(oneday_data)
      trade_data <- as.vector(coredata(oneday_data))
      open_price <- trade_data[1]
      high_price <- trade_data[2]
      low_price <- trade_data[3]
      close_price <- trade_data[4]
      trade_volume <- trade_data[5]
      adjusted_price <- trade_data[6]
      insert_date <- Sys.Date()
      
      # print(symbol)
      # print(trade_day)
      # print(open_price)
      # cat(symbol,':',as.character(trade_day),':',open_price,':',high_price,':',low_price,':',close_price,':',trade_volume,':',adjusted_price,'\n')
      
      query <- paste0("insert into stock (symbol,trading_date,open,high,low,close,volume,adjusted,insert_date) values ('",symbol,"','",trade_date,"', ",open_price,",",high_price,",",low_price,",",close_price,",",trade_volume,",",adjusted_price,",'",insert_date,"');")
      #print(query)
      dbSendQuery(con, query)
      dbDisconnect(con)
    }, error = function(e){
      print(paste('Error2 (insert_data):',e))
      dbDisconnect(con)
      
    })
  }
  
}

us_start <- function(from_date, to_date){
  start_time <-Sys.time()  
  # 사용하지 않음
  #  symbols <- symbols_fromDB()
  
  # NASDAQ, NYSE, AMEX 등 exchange에서 Ticker(Symbol)을 가져온다.
  # 그러나, 선택적 exchange가 NASDAQ 만 된다.
  df_symbols <- stockSymbols() 
  
  # 따라서, 일단 전체 Ticker를 가져온 후 data.frame에서 선택적으로 추출한다.
  NASDAQ_symbols <- df_symbols$Symbol[df_symbols$Exchange == "NASDAQ"]
  NYSE_symbols <- df_symbols$Symbol[df_symbols$Exchange == "NYSE"]
  symbols <- append(NASDAQ_symbols, NYSE_symbols)
  
  ###  중간에 멈췄을 때 조치 
  # symbols <- df_symbols$Symbol[df_symbols$Exchange == "NYSE"]
  # symbols <- symbols[symbols >='AMNB']
  
  for(sym in symbols){
    index_number <-match(sym, symbols)
    # if( index_number%%500 == 0) {
    #   Sys.sleep(100) 
    # } 
    tryCatch({
      insert_data(from_date, to_date, sym)
      #print(index_number)
    }, error = function(e){
      print(paste('Error0 (severaldays_insert):',e,sym))
    }) 
  }
  print(start_time)
  print(Sys.time())
} 

#us_start('2023-01-16','2023-01-20')
args = commandArgs(trailingOnly=TRUE)
us_start(args[1],args[2])

