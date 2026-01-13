"""
데이터베이스 모델 정의
"""
from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime

Base = declarative_base()


class CheckResult(Base):
    """점검 결과 테이블 모델"""
    __tablename__ = "check_results"
    
    id = Column(Integer, primary_key=True, index=True)
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

