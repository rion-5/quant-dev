preprocess_data <- function(symbols, start_date, end_date) {
  # 빈 데이터프레임 초기화
  all_data <- data.frame()
  
  for (i in 1:length(symbols)) {
    # 각 심볼의 데이터를 가져오기
    temp_df <- getStock_from_to(symbols[i], start_date, end_date)
    
    # 해당 심볼을 나타내는 열 추가
    temp_df$symbol <- symbols[i]
    
    # 일일 수익률 계산 (NA를 첫 번째에 추가)
    temp_df$return <- c(NA, diff(temp_df$adjusted) / head(temp_df$adjusted, -1))
    
    # 가져온 데이터를 누적하여 하나의 데이터프레임에 저장
    all_data <- rbind(all_data, temp_df)
  }
  
  return(all_data)
}
