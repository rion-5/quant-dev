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

    
    query <- paste0("insert into stock (symbol,trading_date,open,high,low,close,volume,adjusted,insert_date) values ('",symbol,"','",trade_date,"', ",open_price,",",high_price,",",low_price,",",close_price,",",trade_volume,",",adjusted_price,",'",insert_date,"');")
    
    # print(query)
    insert_quantdb(query)
    
  }
}


insert_chunk_stock_data <- function(symbol, trading_data, chunk_size = 1000) {
  insert_date <- Sys.Date()
  query <- "BEGIN; "
  
  # Chunk 단위로 나누어 처리
  for (i in seq(1, nrow(trading_data), by = chunk_size)) {
    chunk_data <- trading_data[i:min(i + chunk_size - 1, nrow(trading_data)),]
    
    for (j in 1:nrow(chunk_data)) {
      oneday_data <- chunk_data[j,]
      trade_date <- index(oneday_data)
      trade_data <- as.vector(coredata(oneday_data))
      open_price <- trade_data[1]
      high_price <- trade_data[2]
      low_price <- trade_data[3]
      close_price <- trade_data[4]
      trade_volume <- trade_data[5]
      adjusted_price <- trade_data[6]
      
      query <- paste0(query, "INSERT INTO stock (symbol, trading_date, open, high, low, close, volume, adjusted, insert_date) VALUES ('",
                      symbol, "','", trade_date, "', ", open_price, ",", high_price, ",", low_price, ",", close_price, ",",
                      trade_volume, ",", adjusted_price, ", '", insert_date, "'); ")
    }
    
    # Chunk가 끝날 때마다 실행하고 새로운 쿼리 시작
    query <- paste0(query, " COMMIT;")
    insert_quantdb(query)
    
    # 새로운 트랜잭션 시작
    query <- "BEGIN; "
  }
  
  # 마지막 남은 트랜잭션 커밋
  query <- paste0(query, " COMMIT;")
  # print(query)
  # insert_quantdb(query)
}

