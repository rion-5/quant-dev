# library(PerformanceAnalytics)
# 
# calc_sortinos <- function(symbols, rawdata) {
#   # 빈 데이터프레임 초기화
#   all_data <- data.frame()
#   
#   for (i in 1:length(symbols)) {
#     # 각 심볼의 데이터를 가져오기
#     symbol_data <- subset(rawdata, symbol == symbols[i])
#     
#     # 수익률 데이터에서 NA 제거 후 Sortino Ratio 계산
#     if (nrow(symbol_data) > 0) {  # symbol_data가 비어있지 않을 때만 진행
#       clean_returns <- na.omit(symbol_data$return)
#       
#       if (length(clean_returns) > 0) {  # 수익률이 존재할 경우
#         # Sortino Ratio 계산
#         sortino_ratio <- SortinoRatio(clean_returns, MAR = 0)  # MAR: Minimum Acceptable Return (기본값 0)
#         
#         # 심볼과 Sortino Ratio를 담은 데이터프레임 생성
#         temp_df <- data.frame(symbol = symbols[i], sortino_ratio = sortino_ratio)
#         
#         # 누적하여 하나의 데이터프레임에 저장
#         all_data <- rbind(all_data, temp_df)
#       }
#     }
#   }
# 
#   return(all_data)
# }


library(PerformanceAnalytics)
library(tidyverse)

calc_sortinos <- function(symbols, rawdata) {
  # 각 심볼에 대해 Sortino Ratio를 계산
  results <- symbols %>%
    map_df(~ {
      symbol_data <- rawdata %>%
        filter(symbol == .x) %>%   # 해당 심볼의 데이터 필터링
        drop_na(return)            # NA 제거
      
      if (nrow(symbol_data) > 0) {
        sortino_ratio <- SortinoRatio(symbol_data$return, MAR = 0)  # Sortino Ratio 계산
        tibble(symbol = .x, sortino_ratio = sortino_ratio)          # 결과를 tibble로 생성
      } else {
        tibble()  # 데이터가 없으면 빈 tibble 반환
      }
    })
  
  return(results)
}
