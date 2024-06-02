library(quantmod)
library(RPostgreSQL)
library(DBI)
library(stocks)
library(plyr)
library(ggplot2)

# DB에서 기간, 거래량, 주가범위 조건에 따른 symbols 가져오기 
getSymbols_period_volume_price_frequency <- function(start_date,end_date,min_volume,max_volume,min_close, max_close,frequenct){
  tryCatch({    
    con <-dbConnect(RPostgres::Postgres(), dbname="quantdb", host="localhost", port=5432, user="quant",password="quant14")
    query <- paste0("select symbol from stock 
                     where (trading_date >='",start_date,"' and trading_date <= '",end_date,"')
                     and ( volume >= ",min_volume," and volume <=  ",max_volume,")
                     and (close >=",min_close," and close <=",max_close,")
                     group by symbol
                     having  count(symbol) >= ",frequenct," ;")
    res <- dbSendQuery(con, query)
    data <- dbFetch(res)
    dbClearResult(res)
    dbDisconnect(con)
  }, error = function(e){
    print(paste('Error0:'))
    dbDisconnect(con)
  }) 
  return (as.character(data[,1]))
}

# 특정 주식의 stock data 가저오기 
getStock_from_to <-function(symbol,from_trading_date, to_trading_date) {
  tryCatch({    
    con <-dbConnect(RPostgres::Postgres(), dbname="quantdb", host="localhost", port=5432, user="quant",password="quant14")
    query <- paste0("select trading_date, open, high,low,close,volume, adjusted from stock 
                     where symbol = '",symbol,"'
                     and trading_date >='",from_trading_date,"'
                     and trading_date <='",to_trading_date,"' ;")
    res <- dbSendQuery(con, query)
    data <- dbFetch(res)
    dbClearResult(res)
    dbDisconnect(con)
  }, error = function(e){
    print(paste('Error0:'))
    dbDisconnect(con)
  }) 
  return (data)
}

# 특정 주식의 sharpeRatio 계산하기
getSharpeRatio_from_to <- function(symbols,from_trading_date, to_trading_date){
  sharpe_ratio <- c()
  for(j in (1:length(symbols))){
    temp_df <- getStock_from_to(symbols[j],from_trading_date, to_trading_date)
    symbol_close <- temp_df[, 5]
    #print(symbol_close)
    
    sharpe_ratio[length(sharpe_ratio)+1] <- sharpe(prices = symbol_close)
    # cat(symbols[j], ' ', sharpe_ratio[j],'\n')
  }
  return (round(sharpe_ratio,3))
}


#조건에 맞는 주식을 찾아 sharpe ratio를 추출해서 보여줌
us_sharpe_start <- function(start_date,end_date,min_volume,max_volume,min_close, max_close,frequenct){
  symbols <-getSymbols_period_volume_price_frequency(start_date,end_date,min_volume,max_volume,min_close, max_close,frequenct)
  mydf <<- data.frame()
  sharpe_ratio <- getSharpeRatio_from_to(symbols,start_date,end_date)
  df <- cbind.data.frame(symbols, sharpe_ratio, stringsAsFactors = F)
  df <- arrange(df,desc(sharpe_ratio))
  print(df)
  #mydf <<- df[1:30,]
  #mydf <<- df[df$sharpe_ratio >0,]  # sharpe_ratio가 0보다 큰것만 
  #print (mydf)
  #  filepath <- paste0("./sharpe_ratio_results/",Sys.Date(),format(Sys.time(), "%S"),".csv" )
  filepath <- paste0("./us_sharperatio/",start_date,"_",end_date,"_",min_close,"_",max_close,".csv" )
  write.csv(df,filepath,row.names = FALSE)
}





# us_sharpe_start와 동일한데 차트로 보여줌
draw_recent_sharpe <- function(start_date,end_date,min_volume,max_volume,min_close, max_close,frequenct){
  symbols <-getSymbols_period_volume_price_frequency(start_date,end_date,min_volume,max_volume,min_close, max_close,frequenct)
  symbol_sharpe_df <<- data.frame()
  sharpe_ratio <- getSharpeRatio_from_to(symbols,start_date,end_date)
  
  df <- cbind.data.frame(symbols, sharpe_ratio, stringsAsFactors = F)
  df <- arrange(df,desc(sharpe_ratio))
  print(df)
  # print(symbol_sharpe_df)
  symbol_sharpe_df <<- na.omit(df[1:30,])
  # print (symbol_sharpe_df)
  ggplot(symbol_sharpe_df,aes(x=symbols,y=sharpe_ratio))+geom_bar(stat="identity")
}



#소형주
# us_sharpe_start('2022-11-14','2022-12-02',2000000,6000000,100,1000,13)
#대형주
# us_sharpe_start('2022-11-14','2022-12-02',100000,7000000,1000,9000,13)




getPeriod_sharperatio <- function(ticker, fromDate, toDate){
  tickers <- c()
  symbol_sharperatio <- c()
  asfDate <- as.Date(fromDate)
  astDate <- as.Date(toDate)
  
  gap <- as.integer(astDate-asfDate)
  # print(gap)
  
  toTempDate <- c(astDate)
  tempDate <-astDate
  for(x in (1:(gap%/%21))){
    tempDate <- tempDate - 21
    toTempDate <- c(toTempDate, tempDate)
    endDate <- format(toTempDate,"%Y-%m-%d")
  }
  fromTempDate <-toTempDate-18
  startDate <- format(fromTempDate,"%Y-%m-%d")
  # print(startDate)
  # print(endDate)
  
  period_df <- data.frame(startDate,endDate)
  # print(period_df)
  
  for( i in (1: nrow(period_df))){
    tickers <- c(tickers, ticker)
    # print(getSharpeRatio('TSLA', period_df[i,1], period_df[i,2]))
    symbol_sharperatio <- c(symbol_sharperatio,getSharpeRatio_from_to(ticker, period_df[i,1], period_df[i,2]))
  }
  period_df[,"symbol"] <- c(tickers)
  period_df[,"sharpe"] <- c(symbol_sharperatio)
  
  return (period_df)
}

draw_line <- function (symbols, startDate, endDate){
  sharpes <- data.frame()
  # symbols <- c('TSLA','AAPL','HON','TEAM','PEP')
  
  for( i in (1:length(symbols))){
    # print(symbols[i])
    temp_sharpe <- getPeriod_sharperatio(symbols[i],startDate,endDate)
    sharpes <- rbind(sharpes,temp_sharpe)
  }
  
  ggplot(data = sharpes, aes (x=endDate, y=sharpe, color= symbol, group = symbol)) + 
    geom_line() + 
    facet_wrap(~ symbol)
  
  # return (sharpes)
}


# 100달러 이상 
# top2022 <-c('TPL','MCK','CVX','KRTX','ENPH','NOC','CI','MUSA','WTM','LMT')
# 50달러 이상 
# top2022 <-c('MDGL','AMR','HES','TPL','MPC','XOM','NBR','FSLR','UFPT','VLO')

# 20달러 이상 
# top2022 <-c('TMDX','RXDX','PDS','MDGL','CHKEW','CEIX','AXSM','AMR','AKRO')

# draw_line(top2022,'2022-01-01','2022-12-31')

#draw_recent_sharpe('2022-12-21','2023-01-11',200,60000000000,1,1000000,13,'2022-12-21')

#소형주
# us_sharpe_start('2023-05-25','2023-06-15',10000000,200000000,100,1000,13)
#대형주
# us_sharpe_start('2023-05-22','2023-06-12',100000,7000000,1000,9000,13)
args = commandArgs(trailingOnly=TRUE)
us_sharpe_start(args[1],args[2],args[3],args[4],args[5],args[6],args[7])