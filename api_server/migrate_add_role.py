"""
기존 DB에 users.role 컬럼 추가 및 backfill.
- role 컬럼 없으면 추가 (기본값 'viewer')
- 기존 행: is_admin=True -> role='admin', 아니면 role='operator'
SQLite / PostgreSQL 모두 동작.

실행: api_server 디렉터리에서 가상환경 Python으로 실행하세요.
  source venv/bin/activate && python3 migrate_add_role.py
  또는: venv/bin/python3 migrate_add_role.py
"""
import os
import sys
from pathlib import Path

# api_server 기준으로 .env 로드
sys.path.insert(0, str(Path(__file__).resolve().parent))
env_file = Path(__file__).parent / ".env"
if env_file.exists():
    with open(env_file) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, value = line.split("=", 1)
                os.environ[key.strip()] = value.strip()

from sqlalchemy import create_engine, text
from database import DATABASE_URL, engine


def column_exists(conn, table: str, column: str) -> bool:
    url = str(DATABASE_URL).lower()
    if "sqlite" in url:
        r = conn.execute(text(f"PRAGMA table_info({table})"))
        for row in r:
            if row[1] == column:
                return True
        return False
    if "postgresql" in url or "postgres" in url:
        r = conn.execute(
            text(
                "SELECT 1 FROM information_schema.columns WHERE table_name = :t AND column_name = :c"
            ),
            {"t": table, "c": column},
        )
        return r.scalar() is not None
    return False


def main():
    with engine.connect() as conn:
        if column_exists(conn, "users", "role"):
            print("users.role 컬럼이 이미 있습니다. backfill만 수행합니다.")
        else:
            print("users.role 컬럼 추가 중...")
            conn.execute(text("ALTER TABLE users ADD COLUMN role VARCHAR(20) DEFAULT 'viewer'"))
            conn.commit()
            print("role 컬럼 추가 완료.")

        print("기존 행 backfill: is_admin=True -> admin, 아니면 operator")
        url = str(DATABASE_URL).lower()
        if "postgresql" in url or "postgres" in url:
            conn.execute(text("UPDATE users SET role = 'admin' WHERE is_admin = TRUE"))
            conn.execute(text("UPDATE users SET role = 'operator' WHERE is_admin = FALSE"))
        else:
            conn.execute(text("UPDATE users SET role = 'admin' WHERE is_admin = 1"))
            conn.execute(text("UPDATE users SET role = 'operator' WHERE is_admin = 0"))
        conn.commit()
    print("migrate_add_role 완료.")


if __name__ == "__main__":
    main()
