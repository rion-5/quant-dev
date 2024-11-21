library(rvest)
library(DBI)
library(RPostgres)
library(dplyr)

# PostgreSQL 연결 설정
con <- dbConnect(
  RPostgres::Postgres(),
  dbname = "quantdb",
  host = "localhost",
  port = 5432,
  user = "quant",
  password = "quant14"
)

# 티커 리스트
tickers <- c("TSLA", "AAPL", "NVDA")

# 데이터 크롤링 및 저장
for (ticker in tickers) {
  url <- paste0("https://finance.yahoo.com/quote/", ticker, "/key-statistics")
  webpage <- read_html(url)
  
  # 데이터 추출 (XPath는 데이터 위치에 따라 조정 필요)
  market_cap <- webpage %>% html_nodes(xpath = '//tr[th[contains(text(),"Market Cap")]]/td') %>% html_text(trim = TRUE)
  peg_ratio <- webpage %>% html_nodes(xpath = '//tr[th[contains(text(),"PEG Ratio")]]/td') %>% html_text(trim = TRUE)
  week_52_change <- webpage %>% html_nodes(xpath = '//tr[th[contains(text(),"52-Week Change")]]/td') %>% html_text(trim = TRUE)
  beta <- webpage %>% html_nodes(xpath = '//tr[th[contains(text(),"Beta")]]/td') %>% html_text(trim = TRUE)
  shares_short <- webpage %>% html_nodes(xpath = '//tr[th[contains(text(),"Shares Short")]]/td') %>% html_text(trim = TRUE)
  avg_vol_3_months <- webpage %>% html_nodes(xpath = '//tr[th[contains(text(),"Avg Vol (3 month)")]]/td') %>% html_text(trim = TRUE)
  avg_vol_10_day <- webpage %>% html_nodes(xpath = '//tr[th[contains(text(),"Avg Vol (10 day)")]]/td') %>% html_text(trim = TRUE)
  
  # 데이터 저장
  data <- data.frame(
    ticker = ticker,
    market_cap = market_cap,
    peg_ratio = peg_ratio,
    week_52_change = week_52_change,
    beta = beta,
    shares_short = shares_short,
    avg_vol_3_months = avg_vol_3_months,
    avg_vol_10_day = avg_vol_10_day
  )
  
  dbWriteTable(con, "yahoo_statistics", data, append = TRUE, row.names = FALSE)
}

# 연결 종료
dbDisconnect(con)
