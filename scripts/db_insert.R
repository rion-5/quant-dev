source("scripts/dbms_dml.R")

insert_stock_data <- function(symbol,trading_data){
  insert_date <- Sys.Date()
  
  for( i in (1:nrow(trading_data))){
    oneday_data <- trading_data[i,]
    trade_date <- index(oneday_data)
    trade_data <- as.vector(coredata(oneday_data))
    open_price <- trade_data[1]
    high_price <- trade_data[2]
    low_price <- trade_data[3]
    close_price <- trade_data[4]
    trade_volume <- trade_data[5]
    adjusted_price <- trade_data[6]
    
    query <- paste0( "insert into stock (symbol,trading_date,open,high,low,close,volume,adjusted,insert_date) values ('",symbol,"','",trade_date,"', ",open_price,",",high_price,",",low_price,",",close_price,",",trade_volume,",",adjusted_price,",'",insert_date,"');")
    
    insert_quantdb(query)
  }
}
