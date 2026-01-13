"""
API 서버 설정
"""
import os

# 서버 설정
HOST = os.getenv("API_HOST", "0.0.0.0")
PORT = int(os.getenv("API_PORT", 8000))

# 데이터베이스 설정
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "sqlite:///./check_results.db"  # 기본값: SQLite
    # PostgreSQL: "postgresql://user:password@localhost:5432/dbname"
    # MariaDB: "mysql+pymysql://user:password@localhost:3306/dbname"
)

# 로깅 설정
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")

