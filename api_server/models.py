"""
데이터베이스 모델 정의
"""
from sqlalchemy import Column, Integer, String, Boolean, DateTime, JSON
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()


class User(Base):
    """사용자 테이블 (로그인/회원가입/관리자 승인)"""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    username = Column(String(100), unique=True, nullable=False, index=True)
    email = Column(String(255), unique=True, nullable=True, index=True)
    password_hash = Column(String(255), nullable=False)
    is_approved = Column(Boolean, default=False, nullable=False)
    is_admin = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=datetime.now, nullable=False)

    def to_dict(self):
        """딕셔너리로 변환 (비밀번호 제외)"""
        return {
            "id": self.id,
            "username": self.username,
            "email": self.email or None,
            "is_approved": self.is_approved,
            "is_admin": self.is_admin,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class CheckResult(Base):
    """점검 결과 테이블 모델"""
    __tablename__ = "check_results"
    
    # PostgreSQL의 경우 시퀀스가 데이터베이스에 생성되어 있어야 함
    # fix_postgresql_sequence.sh 스크립트로 시퀀스를 생성하고 연결해야 함
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    check_type = Column(String(50), index=True, nullable=False)  # "os", "was", "mariadb" 등
    hostname = Column(String(255), index=True, nullable=False)
    check_time = Column(String(50), nullable=False)  # ISO8601 형식
    checker = Column(String(100), index=True)  # 담당자 이름
    status = Column(String(20), index=True)  # "success", "warning", "error"
    results = Column(JSON, nullable=False)  # 점검 결과 데이터 (JSON)
    created_at = Column(DateTime, default=datetime.now, nullable=False)
    
    def to_dict(self):
        """딕셔너리로 변환"""
        return {
            "id": self.id,
            "check_type": self.check_type,
            "hostname": self.hostname,
            "check_time": self.check_time,
            "checker": self.checker,
            "status": self.status,
            "results": self.results,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }

