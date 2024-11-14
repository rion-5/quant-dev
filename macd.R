# 필요한 라이브러리 설치 및 불러오기
if (!require("quantmod")) install.packages("quantmod")
library(quantmod)

# 예시 데이터 다운로드 (Apple Inc. 주가 데이터 사용)
getSymbols("TSLA", from = "2024-01-01", to = "2025-01-01")

# MACD 계산
macd_data <- MACD(Cl(TSLA), nFast = 12, nSlow = 26, nSig = 9, maType = "EMA")

# 시각화
chartSeries(TSLA, theme = chartTheme("white"))
addTA(macd_data$macd, col = "blue", legend = "MACD")
addTA(macd_data$signal, col = "red", legend = "Signal Line")
addTA(macd_data$macd - macd_data$signal, type = "h", col = ifelse(macd_data$macd - macd_data$signal > 0, "green", "red"), legend = "Histogram")
