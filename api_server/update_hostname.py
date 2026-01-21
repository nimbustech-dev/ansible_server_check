#!/usr/bin/env python3
"""
데이터베이스에 저장된 호스트명 업데이트 스크립트
사용법: python3 update_hostname.py
"""
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from database import SessionLocal
from models import CheckResult
from sqlalchemy import text

def update_hostname(old_hostname, new_hostname, check_type=None, id=None):
    """
    호스트명 업데이트
    
    Args:
        old_hostname: 변경할 기존 호스트명
        new_hostname: 새로운 호스트명
        check_type: 점검 유형 필터 (선택, None이면 모든 점검 유형)
        id: 특정 ID만 업데이트 (선택, None이면 모든 매칭 레코드)
    """
    db = SessionLocal()
    try:
        # 업데이트할 레코드 조회
        query = db.query(CheckResult).filter(CheckResult.hostname == old_hostname)
        
        if id:
            query = query.filter(CheckResult.id == id)
        
        if check_type:
            query = query.filter(CheckResult.check_type == check_type)
        
        results = query.all()
        
        if not results:
            print(f"❌ 호스트명 '{old_hostname}'에 해당하는 레코드를 찾을 수 없습니다.")
            if id:
                print(f"   (ID: {id})")
            if check_type:
                print(f"   (점검 유형: {check_type})")
            return
        
        print(f"📋 업데이트 대상: {len(results)}건")
        print(f"   기존 호스트명: {old_hostname}")
        print(f"   새 호스트명: {new_hostname}")
        print()
        
        # 미리보기
        print("업데이트될 레코드:")
        print("-" * 80)
        for r in results[:10]:  # 최대 10개만 미리보기
            print(f"  ID: {r.id:4d} | 점검유형: {r.check_type:10s} | 호스트명: {r.hostname:20s} | 점검시간: {r.check_time}")
        if len(results) > 10:
            print(f"  ... 외 {len(results) - 10}건")
        print("-" * 80)
        print()
        
        # 확인
        confirm = input(f"정말로 {len(results)}건의 호스트명을 '{old_hostname}' → '{new_hostname}'로 변경하시겠습니까? (yes/no): ")
        
        if confirm.lower() not in ['yes', 'y']:
            print("취소되었습니다.")
            return
        
        # 업데이트 실행
        updated_count = 0
        for result in results:
            result.hostname = new_hostname
            updated_count += 1
        
        db.commit()
        print(f"✅ {updated_count}건의 호스트명이 성공적으로 업데이트되었습니다!")
        
    except Exception as e:
        db.rollback()
        print(f"❌ 오류 발생: {e}")
        raise
    finally:
        db.close()


def list_hostnames():
    """현재 저장된 모든 호스트명 목록 조회"""
    db = SessionLocal()
    try:
        query = text("""
            SELECT hostname, check_type, COUNT(*) as count, MAX(created_at) as last_check
            FROM check_results
            GROUP BY hostname, check_type
            ORDER BY hostname, check_type
        """)
        
        result = db.execute(query)
        rows = result.fetchall()
        
        if not rows:
            print("❌ 데이터가 없습니다.")
            return
        
        print("\n" + "=" * 80)
        print("현재 저장된 호스트명 목록:")
        print("=" * 80)
        print(f"{'호스트명':<30} | {'점검유형':<15} | {'건수':<8} | {'최근점검시간'}")
        print("-" * 80)
        
        for row in rows:
            hostname, check_type, count, last_check = row
            last_check_str = str(last_check)[:19] if last_check else "N/A"
            print(f"{hostname:<30} | {check_type:<15} | {count:<8} | {last_check_str}")
        
        print("=" * 80)
        print(f"총 {len(rows)}개 호스트명/점검유형 조합\n")
        
    except Exception as e:
        print(f"❌ 오류 발생: {e}")
    finally:
        db.close()


if __name__ == "__main__":
    print("=" * 80)
    print("호스트명 업데이트 도구")
    print("=" * 80)
    print()
    
    while True:
        print("\n메뉴:")
        print("1. 호스트명 목록 조회")
        print("2. 호스트명 업데이트 (전체)")
        print("3. 호스트명 업데이트 (특정 ID)")
        print("4. 호스트명 업데이트 (특정 점검 유형만)")
        print("5. 종료")
        print()
        
        try:
            choice = input("선택 (1-5): ").strip()
            
            if choice == "1":
                list_hostnames()
            
            elif choice == "2":
                old_hostname = input("기존 호스트명: ").strip()
                new_hostname = input("새 호스트명: ").strip()
                if old_hostname and new_hostname:
                    update_hostname(old_hostname, new_hostname)
                else:
                    print("❌ 호스트명을 입력해주세요.")
            
            elif choice == "3":
                try:
                    id = int(input("업데이트할 레코드 ID: ").strip())
                    old_hostname = input("기존 호스트명: ").strip()
                    new_hostname = input("새 호스트명: ").strip()
                    if old_hostname and new_hostname:
                        update_hostname(old_hostname, new_hostname, id=id)
                    else:
                        print("❌ 호스트명을 입력해주세요.")
                except ValueError:
                    print("❌ 올바른 ID를 입력해주세요.")
            
            elif choice == "4":
                old_hostname = input("기존 호스트명: ").strip()
                new_hostname = input("새 호스트명: ").strip()
                check_type = input("점검 유형 (os/was/mariadb/postgresql/cubrid, 엔터 시 전체): ").strip()
                if old_hostname and new_hostname:
                    update_hostname(old_hostname, new_hostname, check_type=check_type if check_type else None)
                else:
                    print("❌ 호스트명을 입력해주세요.")
            
            elif choice == "5":
                print("종료합니다.")
                break
            
            else:
                print("❌ 올바른 메뉴를 선택해주세요.")
        
        except KeyboardInterrupt:
            print("\n\n종료합니다.")
            break
        except Exception as e:
            print(f"❌ 오류: {e}\n")
