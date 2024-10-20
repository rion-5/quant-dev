source("scripts/data_loading.R")
source("scripts/db_insert.R")

is_trading_day <- function(date) {
  weekday <<- weekdays(date)
  if (weekday %in% c("Saturday", "Sunday")) return(FALSE)
  
  year <- as.numeric(format(date, "%Y"))
  holidays <- us_stock_holidays(year)
  
  return(!(date %in% holidays$holiday_date))
}

trading_date <- Sys.Date() - 1
#trading_date <- as.Date('2024-10-10')
# from_date <- as.Date('2023-12-01')
# to_date <- as.Date('2023-12-31')

if (is_trading_day(trading_date)) {
  
  start_time <-Sys.time() 
  
  symbols <- NASDAQ_NYSE_ticker()
  # total_steps <- length(symbols)
  # # Progress bar 생성
  # pb <- txtProgressBar(min = 0, max = total_steps, style = 3)
  for(sym in symbols){
    
    index_number <-match(sym, symbols)
    # if( index_number%%500 == 0) {
    #   Sys.sleep(100) 
    # } 
    tryCatch({
      cat(index_number, format(trading_date,'%Y-%m-%d'), weekday,sym, sep =" ", "\n")
      # # 고정된 위치에서 심볼 업데이트
      # cat(sprintf("\rTicker: %s", sym))
      # flush.console()
      
      # # Progress bar 업데이트
      # setTxtProgressBar(pb, index_number)

      trading_data <- stockDataRange(sym, trading_date, trading_date)
      # print(trading_data)
      insert_stock_data(sym,trading_data)
      # insert_chunk_stock_data(sym,trading_data)
      # print(index_number)
    }, error = function(e){
      cat(paste(sym,'Error0'), sep = "\n")
      #print(paste('Error0: Data Not Found.',e,sym))
    }) 
    

  }
  # 완료 후 Progress bar 닫기
  # close(pb)
  print(start_time)
  print(Sys.time())
  
}
