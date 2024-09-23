library(DBI)
library(RPostgres)

readRenviron("/Users/rion5/Project/R/quant-dev/.env")

db_user <- Sys.getenv("DB_USER")
db_pass <- Sys.getenv("DB_PASS")
db_host <- Sys.getenv("DB_HOST")
db_name <- Sys.getenv("DB_NAME")
db_port <- Sys.getenv("DB_PORT")

request_quantdb <- function(query) {
  tryCatch({
    # DB 연결 생성
    con <- dbConnect(
      RPostgres::Postgres(),
      host = db_host,
      user = db_user,
      password = db_pass,
      dbname = db_name,
      port = db_port
    )
    # 쿼리 실행 및 데이터 가져오기
    res <- dbSendQuery(con, query)
    data <- dbFetch(res)
    # 연결 정리
    dbClearResult(res)
    dbDisconnect(con)
    return(data)
  }, error = function(e) {
    # 에러 발생 시 메시지 출력 및 연결 종료
    print(paste("Error:", e$message))
    dbDisconnect(con)
    return(NULL)
  })
}

insert_quantdb <- function(query) {
  con <- NULL
  tryCatch({
    # DB 연결 생성
    con <- dbConnect(
      RPostgres::Postgres(),
      host = db_host,
      user = db_user,
      password = db_pass,
      dbname = db_name,
      port = db_port
    )
    
    # 쿼리 실행
    dbSendQuery(con, query)
    
  }, error = function(e) {
    # 에러 발생 시 메시지 출력
    print(paste('Error (insert_quantdb):', e))
    
  }, finally = {
    # 연결이 존재하면 닫기
    if (!is.null(con)) {
      dbDisconnect(con)
    }
  })
}