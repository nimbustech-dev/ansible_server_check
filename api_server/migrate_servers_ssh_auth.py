"""
기존 DB에 servers 테이블에 SSH 인증 컬럼 추가.
- ssh_auth_type (기본 'key_file'), ssh_key_path, ssh_password_encrypted
SQLite / PostgreSQL 모두 동작.

실행: api_server 디렉터리에서 가상환경 Python으로 실행하세요.
  venv/bin/python3 migrate_servers_ssh_auth.py
"""
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
env_file = Path(__file__).parent / ".env"
if env_file.exists():
    with open(env_file) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, value = line.split("=", 1)
                os.environ[key.strip()] = value.strip()

from sqlalchemy import text
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
        for col, sqlite_sql, pg_sql in [
            ("ssh_auth_type", "ALTER TABLE servers ADD COLUMN ssh_auth_type VARCHAR(20) DEFAULT 'key_file'", "ALTER TABLE servers ADD COLUMN ssh_auth_type VARCHAR(20) DEFAULT 'key_file'"),
            ("ssh_key_path", "ALTER TABLE servers ADD COLUMN ssh_key_path VARCHAR(500)", "ALTER TABLE servers ADD COLUMN ssh_key_path VARCHAR(500)"),
            ("ssh_password_encrypted", "ALTER TABLE servers ADD COLUMN ssh_password_encrypted VARCHAR(500)", "ALTER TABLE servers ADD COLUMN ssh_password_encrypted VARCHAR(500)"),
        ]:
            if column_exists(conn, "servers", col):
                print(f"servers.{col} 이미 있음.")
            else:
                url = str(DATABASE_URL).lower()
                stmt = pg_sql if ("postgresql" in url or "postgres" in url) else sqlite_sql
                conn.execute(text(stmt))
                conn.commit()
                print(f"servers.{col} 추가 완료.")
    print("migrate_servers_ssh_auth 완료.")


if __name__ == "__main__":
    main()
