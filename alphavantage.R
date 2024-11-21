library(quantmod)
library(tidyverse)
library(dplyr)
library(alphavantager)
readRenviron(".env")

# API 키 설정
api_key <- Sys.getenv("ALPHA_VANTAGE_API_KEY")
av_api_key(api_key)
# 특정 종목의 일봉 데이터 가져오기 (예: Apple)
getSymbols("AAPL", src = "alphavantage", api.key = api_key)

# 데이터 확인
head(AAPL)

# 특정 주식의 일간 주가 데이터를 가져옵니다 (e.g., Apple Inc.)
stock_data <- av_get(symbol = "AAPL", av_fun = "TIME_SERIES_DAILY")

# 특정 주식의 기본 재무 정보
financial_data <- av_get(symbol = "AAPL", av_fun = "OVERVIEW")


TSLA_financial_data <- av_get(symbol = "TSLA", av_fun = "OVERVIEW")

GOOG_financial_data <- av_get(symbol = "GOOG", av_fun = "OVERVIEW")

# 특정 기간의 데이터 추출
AAPL_subset <- AAPL["2024-09-01/2024-12-31"]

# 기술적 지표 계산 (예: 이동평균)
# AAPL <- AAPL %>% 
#   mutate(MA50 = SMA(Cl(.), n = 50))
AAPL$MA50 <- SMA(Cl(AAPL), n = 50)
# 차트 그리기
chartSeries(AAPL, theme = chartTheme("white"))
addTA(AAPL$MA50, on = 1, col = "blue")


# USD와 KRW의 일간 환율 데이터를 불러오기
fx_data <- av_get(from_symbol = "USD", to_symbol = "KRW", av_fun = "FX_DAILY")
tail(fx_data)

dollar_won <-av_get("USD/KRW", av_fun="CURRENCY_EXCHANGE_RATE")
dollar_won$exchange_rate


#CPI
us_cpi <- av_get(av_fun = "CPI", interval = "monthly") #semiannual
tail(us_cpi)

cpi_value <- us_cpi[us_cpi$timestamp =="2024-10-01", "value"]
formatted_value <- sprintf("%.5f", cpi_value) # 소숫점 아래 5자리 출력
formatted_value
