# # main.R
# source("scripts/data_loading.R")
# source("scripts/data_preprocessing.R")
# source("scripts/analysis.R")
# 
# # 데이터 로드
# ## 최근 15일간의 거래 시작일 종료일
# rangeDate <- start_end_date()
# cat(paste("조회시작일:",rangeDate$start_date,"\n"))
# cat(paste("조회종료일:",rangeDate$end_date,"\n"))
# #sortino ratio 분석 대상 symbol 데이터 로드
# stock_df <- stock_100_1000()
# # library(tidyverse)
# # stock_tb <- as_tibble(stock_df)
# 
# # 데이터 전처리
# #processed_data <- preprocess_data(raw_data)
# symbol_vector <- as.character(stock_df$symbol)
# 
# rawdata_df <- preprocess_data(symbol_vector, rangeDate$start_date, rangeDate$end_date)
# 
# # 분석 실행
# #results <- analyze_data(processed_data)
# sortino_df <- calc_sortinos(symbol_vector, rawdata_df)
# 
# results <- merge(stock_df, sortino_df, by = "symbol", all.x = TRUE)
# # Sortino Ratio 값이 큰 순으로 정렬
# results <- results[order(-results$sortino_ratio), ]
# 
# # 결과 확인
# print(results)

# main.R
library(tidyverse)

# 데이터 로드
source("scripts/data_loading.R")
source("scripts/data_preprocessing.R")
source("scripts/analysis.R")

# 최근 15일간의 거래 시작일과 종료일 설정
rangeDate <- start_end_date()
cat(glue::glue("조회시작일: {rangeDate$start_date}\n\r"))
cat(glue::glue("조회종료일: {rangeDate$end_date}\n\r"))

# Sortino Ratio 분석 대상 symbol 데이터 로드
stock_tb <- stock_100_1000() %>% 
  as_tibble()

# 데이터 전처리
symbol_vector <- stock_tb$symbol

rawdata_tb <- preprocess_data(symbol_vector, rangeDate$start_date, rangeDate$end_date)

# Sortino Ratio 계산
sortino_tb <- calc_sortinos(symbol_vector, rawdata_tb)

# 결과 병합 및 정렬
results <- stock_tb %>%
  left_join(sortino_tb, by = "symbol") %>%
  arrange(desc(sortino_ratio))

# 결과 확인
print(results)

