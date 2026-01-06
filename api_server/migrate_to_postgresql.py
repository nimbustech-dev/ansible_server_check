#!/usr/bin/env python3
"""
SQLite에서 PostgreSQL로 데이터 마이그레이션
"""
import os
import sys
from pathlib import Path

# 현재 디렉토리를 Python 경로에 추가
sys.path.insert(0, str(Path(__file__).parent))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from models import CheckResult as CheckResultModel

def migrate_data():
    """SQLite 데이터를 PostgreSQL로 마이그레이션"""
    
    # 환경변수에서 DATABASE_URL 확인
    postgres_url = os.getenv("DATABASE_URL")
    if not postgres_url or "sqlite" in postgres_url:
        print("❌ DATABASE_URL이 PostgreSQL로 설정되지 않았습니다.")
        print("환경변수 또는 .env 파일에서 DATABASE_URL을 설정하세요.")
        print("예: export DATABASE_URL='postgresql://user:pass@localhost/dbname'")
        return False
    
    # SQLite 연결
    sqlite_file = Path(__file__).parent / "check_results.db"
    if not sqlite_file.exists():
        print("⚠️  SQLite 파일이 없습니다. 마이그레이션할 데이터가 없습니다.")
        return True
    
    sqlite_url = f"sqlite:///{sqlite_file}"
    sqlite_engine = create_engine(sqlite_url)
    sqlite_session = sessionmaker(bind=sqlite_engine)()
    
    # PostgreSQL 연결
    postgres_engine = create_engine(postgres_url)
    postgres_session = sessionmaker(bind=postgres_engine)()
    
    try:
        # PostgreSQL에 테이블 생성
        from models import Base
        Base.metadata.create_all(bind=postgres_engine)
        print("✅ PostgreSQL 테이블 생성 완료")
        
        # SQLite에서 데이터 읽기
        sqlite_results = sqlite_session.query(CheckResultModel).all()
        print(f"📊 SQLite에서 {len(sqlite_results)}건의 데이터 발견")
        
        if len(sqlite_results) == 0:
            print("마이그레이션할 데이터가 없습니다.")
            return True
        
        # PostgreSQL로 데이터 복사
        migrated = 0
        for result in sqlite_results:
            # 중복 체크
            existing = postgres_session.query(CheckResultModel).filter_by(
                check_type=result.check_type,
                hostname=result.hostname,
                check_time=result.check_time
            ).first()
            
            if not existing:
                new_result = CheckResultModel(
                    check_type=result.check_type,
                    hostname=result.hostname,
                    check_time=result.check_time,
                    checker=result.checker,
                    status=result.status,
                    results=result.results,
                    created_at=result.created_at
                )
                postgres_session.add(new_result)
                migrated += 1
        
        postgres_session.commit()
        print(f"✅ {migrated}건의 데이터가 PostgreSQL로 마이그레이션되었습니다.")
        
        return True
        
    except Exception as e:
        postgres_session.rollback()
        print(f"❌ 마이그레이션 실패: {e}")
        return False
    finally:
        sqlite_session.close()
        postgres_session.close()

if __name__ == "__main__":
    print("=" * 60)
    print("SQLite → PostgreSQL 데이터 마이그레이션")
    print("=" * 60)
    print("")
    
    if migrate_data():
        print("")
        print("✅ 마이그레이션 완료!")
        print("이제 API 서버를 재시작하세요.")
    else:
        print("")
        print("❌ 마이그레이션 실패")
        sys.exit(1)

