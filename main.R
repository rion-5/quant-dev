# main.R
source("scripts/data_loading.R")
#source("scripts/data_preprocessing.R")
#source("scripts/analysis.R")

# 최종 거래일 확인
max_date <- max_trading_date()
print(max_date)

# 최근 14일간의 거래 시작일 종료일
s_e_date <- start_end_date()
print(s_e_date)
# 데이터 로드

# 데이터 전처리
#processed_data <- preprocess_data(raw_data)

# 분석 실행
#results <- analyze_data(processed_data)

# 결과 확인
#print(results)
