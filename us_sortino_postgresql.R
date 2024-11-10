library(quantmod)
library(RPostgres)
library(DBI)
library(stocks)
library(plyr)
library(TTR)
library(ggplot2)

readRenviron(".env")
db_user <- Sys.getenv("DB_USER")
db_pass <- Sys.getenv("DB_PASS")
db_host <- Sys.getenv("DB_HOST")
db_name <- Sys.getenv("DB_NAME")
db_port <- Sys.getenv("DB_PORT")

# DB에서 기간, 거래량, 주가범위 조건에 따른 symbols 가져오기
getSymbols_period_volume_price_frequency <- function(start_date,
                                                     end_date,
                                                     min_volume,
                                                     max_volume,
                                                     min_close,
                                                     max_close,
                                                     frequenct) {
  tryCatch({
    con <- dbConnect(
      RPostgres::Postgres(),
      host = db_host,
      user = db_user,
      password = db_pass,
      dbname = db_name,
      port = db_port
    )
    query <- paste0(
      "select symbol from stock
                     where (trading_date >='",
      start_date,
      "' and trading_date <= '",
      end_date,
      "')
                     and ( volume >= ",
      min_volume,
      " and volume <=  ",
      max_volume,
      ")
                     and (close >=",
      min_close,
      " and close <=",
      max_close,
      ")
                     group by symbol
                     having  count(symbol) >= ",
      frequenct,
      " ;"
    )
    res <- dbSendQuery(con, query)
    data <- dbFetch(res)
    dbClearResult(res)
    dbDisconnect(con)
  }, error = function(e) {
    print(paste('Error0:'))
    dbDisconnect(con)
  })
  return (as.character(data[, 1]))
}

# 특정 주식의 stock data 가저오기
getStock_from_to <- function(symbol,
                             from_trading_date,
                             to_trading_date) {
  tryCatch({
    con <- dbConnect(
      RPostgres::Postgres(),
      host = db_host,
      user = db_user,
      password = db_pass,
      dbname = db_name,
      port = db_port
    )
    query <- paste0(
      "select trading_date, open, high,low,close,volume, adjusted from stock
                     where symbol = '",
      symbol,
      "'
                     and trading_date >='",
      from_trading_date,
      "'
                     and trading_date <='",
      to_trading_date,
      "' ;"
    )
    res <- dbSendQuery(con, query)
    data <- dbFetch(res)
    dbClearResult(res)
    dbDisconnect(con)
  }, error = function(e) {
    print(paste('Error0:'))
    dbDisconnect(con)
  })
  
  return (data)
}

# 특정 주식의 Sortino Ratio 계산하기
getsortinoRatio_from_to <- function(symbols,
                                    from_trading_date,
                                    to_trading_date) {
  sortino_ratio <- c()
  for (j in (1:length(symbols))) {
    temp_df <- getStock_from_to(symbols[j], from_trading_date, to_trading_date)
    symbol_close <- temp_df$close
    #print(symbol_close)
    
    sortino_ratio[length(sortino_ratio) + 1] <- sortino(prices = symbol_close)
    # cat(symbols[j], ' ', sortino_ratio[j],'\n')
  }
  return (round(sortino_ratio, 3))
}

#조건에 맞는 주식을 찾아 sortino ratio를 추출해서 보여줌
us_sortino_start <- function(start_date,
                             end_date,
                             min_volume,
                             max_volume,
                             min_close,
                             max_close,
                             frequenct) {
  symbols <- getSymbols_period_volume_price_frequency(start_date,
                                                      end_date,
                                                      min_volume,
                                                      max_volume,
                                                      min_close,
                                                      max_close,
                                                      frequenct)
  mydf <<- data.frame()
  sortino_ratio <- getsortinoRatio_from_to(symbols, start_date, end_date)
  df <- cbind.data.frame(symbols, sortino_ratio, stringsAsFactors = F)
  df <- arrange(df, desc(sortino_ratio))
  print(df)
  #mydf <<- df[1:30,]
  #mydf <<- df[df$sortino_ration >0,]  # sortino가 0보다 큰것만
  #print (mydf)
  #  filepath <- paste0("./sortino_ratio_results/",Sys.Date(),format(Sys.time(), "%S"),".csv" )
  filepath <- paste0(
    "./us_sortinoratio/",
    start_date,
    "_",
    end_date,
    "_",
    min_close,
    "_",
    max_close,
    ".csv"
  )
  write.csv(df, filepath, row.names = FALSE)
}




# us_sortino_start와 동일한데 차트로 보여줌
draw_recent_sortino <- function(start_date,
                                end_date,
                                min_volume,
                                max_volume,
                                min_close,
                                max_close,
                                frequenct) {
  symbols <- getSymbols_period_volume_price_frequency(start_date,
                                                      end_date,
                                                      min_volume,
                                                      max_volume,
                                                      min_close,
                                                      max_close,
                                                      frequenct)
  symbol_sortino_df <<- data.frame()
  sortino_ratio <- getsortinoRatio_from_to(symbols, start_date, end_date)
  
  df <- cbind.data.frame(symbols, sortino_ratio, stringsAsFactors = F)
  df <- arrange(df, desc(sortino_ratio))
  print(df)
  # print(symbol_sortino_df)
  symbol_sortino_df <<- na.omit(df[1:30, ])
  # print (symbol_sortino_df)
  ggplot(symbol_sortino_df, aes(x = symbols, y = sortino_ratio)) + geom_bar(stat =
                                                                              "identity")
}


#소형주
# draw_recent_sortino('2023-04-24','2023-05-12',2000000,6000000,100,1000,13)
#대형주
# draw_recent_sortino('2023-04-24','2023-05-12',100000,7000000,1000,9000,13)



getPeriod_sortinoratio <- function(ticker, fromDate, toDate) {
  tickers <- c()
  symbol_sortinoratio <- c()
  asfDate <- as.Date(fromDate)
  astDate <- as.Date(toDate)
  
  gap <- as.integer(astDate - asfDate)
  # print(gap)
  
  toTempDate <- c(astDate)
  tempDate <- astDate
  for (x in (1:(gap %/% 21))) {
    tempDate <- tempDate - 21
    toTempDate <- c(toTempDate, tempDate)
    endDate <- format(toTempDate, "%Y-%m-%d")
  }
  fromTempDate <- toTempDate - 18
  startDate <- format(fromTempDate, "%Y-%m-%d")
  # print(startDate)
  # print(endDate)
  
  period_df <- data.frame(startDate, endDate)
  # print(period_df)
  
  for (i in (1:nrow(period_df))) {
    tickers <- c(tickers, ticker)
    # print(getsortinoRatio('TSLA', period_df[i,1], period_df[i,2]))
    symbol_sortinoratio <- c(symbol_sortinoratio,
                             getsortinoRatio_from_to(ticker, period_df[i, 1], period_df[i, 2]))
  }
  period_df[, "symbol"] <- c(tickers)
  period_df[, "sortino"] <- c(symbol_sortinoratio)
  
  return (period_df)
}

draw_line <- function (symbols, startDate, endDate) {
  sortinos <- data.frame()
  # symbols <- c('TSLA','AAPL','HON','TEAM','PEP')
  
  for (i in (1:length(symbols))) {
    # print(symbols[i])
    temp_sortino <- getPeriod_sortinoratio(symbols[i], startDate, endDate)
    sortinos <- rbind(sortinos, temp_sortino)
  }
  
  ggplot(data = sortinos, aes (
    x = endDate,
    y = sortino,
    color = symbol,
    group = symbol
  )) +
    geom_line() +
    facet_wrap( ~ symbol)
  
  # return (sortinos)
}

# 100달러 이상
# top2022 <-c('TPL','MCK','CVX','KRTX','ENPH','NOC','CI','MUSA','WTM','LMT')
# 50달러 이상
# top2022 <-c('MDGL','AMR','HES','TPL','MPC','XOM','NBR','FSLR','UFPT','VLO')
# 20달러 이상 : 제약회사 급등주들이 많아 의미없음
# top2022 <-c('TMDX','RXDX','PDS','MDGL','CHKEW','CEIX','AXSM','AMR','AKRO')
# draw_line(top2022,'2022-01-01','2022-12-31')

#소형주
#draw_line(getSymbols_period_volume_price_frequency('2023-04-24','2023-05-12',2000000,6000000,100,1000,13),'2023-02-01','2023-05-12')
#대형주
#draw_line(getSymbols_period_volume_price_frequency('2023-04-24','2023-05-12',100000,7000000,1000,9000,13),'2023-02 -01','2023-05-12')


#소형주
# us_sortino_start('2023-05-25','2023-06-15',5000000,200000000,100,1000,13)
#대형주
# us_sortino_start('2023 - 05 - 22','2023 - 06 - 12',100000,7000000,1000,9000,13)

#사용례
# Rscript us_sortino_postgresql.R '2023-05-26' '2023-06-16' 5000000 200000000 100 1000 13
args = commandArgs(trailingOnly=TRUE)
us_sortino_start(args[1],args[2],args
                 [3],args[4],args[5],args[6],args[7])