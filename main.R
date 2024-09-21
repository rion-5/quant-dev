# main.R
source("scripts/data_loading.R")
source("scripts/data_preprocessing.R")
source("scripts/analysis.R")

# 데이터 로드
## 최근 15일간의 거래 시작일 종료일
rangeDate <- start_end_date()
print(paste("조회시작일:",rangeDate$start_date))
print(paste("조회종료일:",rangeDate$end_date))
#sortino ratio 분석 대상 symbol 데이터 로드
stock_df <- stock_100_1000()

# 데이터 전처리
#processed_data <- preprocess_data(raw_data)
symbol_vector <- as.character(stock_df$symbol)
rawdata_df <- preprocess_data(symbol_vector, rangeDate$start_date, rangeDate$end_date)

# 분석 실행
#results <- analyze_data(processed_data)
sortino_df <- calc_sortinos(symbol_vector, rawdata_df)

results <- merge(stock_df, sortino_df, by = "symbol", all.x = TRUE)
# Sortino Ratio 값이 큰 순으로 정렬
results <- results[order(-results$sortino_ratio), ]

# 결과 확인
print(results)
