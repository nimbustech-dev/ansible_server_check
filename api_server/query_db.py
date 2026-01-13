#!/usr/bin/env python3
"""
PostgreSQL 데이터베이스 직접 조회 스크립트
사용법: python3 query_db.py
"""
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from database import engine
from sqlalchemy import text

def run_query(sql_query):
    """SQL 쿼리 실행"""
    try:
        with engine.connect() as conn:
            result = conn.execute(text(sql_query))
            
            # 컬럼명 가져오기
            columns = result.keys()
            
            # 결과 출력
            print("\n" + "=" * 80)
            print("쿼리 결과:")
            print("=" * 80)
            
            # 헤더 출력
            print(" | ".join([f"{col:20}" for col in columns]))
            print("-" * 80)
            
            # 데이터 출력
            rows = result.fetchall()
            for row in rows:
                print(" | ".join([f"{str(val)[:20]:20}" for val in row]))
            
            print(f"\n총 {len(rows)}건 조회됨")
            print("=" * 80)
            
    except Exception as e:
        print(f"❌ 오류 발생: {e}")

if __name__ == "__main__":
    print("PostgreSQL 데이터베이스 조회 도구")
    print("종료하려면 'exit' 또는 'quit' 입력\n")
    
    # 기본 쿼리 예시
    print("예시 쿼리:")
    print("1. SELECT * FROM check_results LIMIT 10;")
    print("2. SELECT checker, check_type, COUNT(*) FROM check_results GROUP BY checker, check_type;")
    print("3. SELECT * FROM check_results WHERE checker = '강하나';")
    print()
    
    while True:
        try:
            query = input("SQL> ").strip()
            
            if query.lower() in ['exit', 'quit', 'q']:
                print("종료합니다.")
                break
            
            if not query:
                continue
            
            if not query.endswith(';'):
                query += ';'
            
            run_query(query)
            print()
            
        except KeyboardInterrupt:
            print("\n종료합니다.")
            break
        except Exception as e:
            print(f"오류: {e}\n")

