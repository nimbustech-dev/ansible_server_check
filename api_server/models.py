"""
데이터베이스 모델 정의
"""
from sqlalchemy import Column, Integer, String, Boolean, DateTime, JSON
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()


class User(Base):
    """사용자 테이블 (로그인/회원가입/관리자 승인, 역할: admin/maintainer/operator/viewer)"""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    username = Column(String(100), unique=True, nullable=False, index=True)
    email = Column(String(255), unique=True, nullable=True, index=True)
    password_hash = Column(String(255), nullable=False)
    is_approved = Column(Boolean, default=False, nullable=False)
    is_admin = Column(Boolean, default=False, nullable=False)  # 하위 호환; 권한 판단은 role 기준
    role = Column(String(20), nullable=False, default="viewer", index=True)  # admin | maintainer | operator | viewer
    created_at = Column(DateTime, default=datetime.now, nullable=False)

    def to_dict(self):
        """딕셔너리로 변환 (비밀번호 제외)"""
        return {
            "id": self.id,
            "username": self.username,
            "email": self.email or None,
            "is_approved": self.is_approved,
            "is_admin": self.is_admin,
            "role": getattr(self, "role", "viewer") if hasattr(self, "role") else ("admin" if self.is_admin else "viewer"),
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


class CheckItem(Base):
    """점검 유형별 세부 항목 (관리자에서 추가/삭제, 활성화 여부). 신규 점검 시 활성화된 항목만 반영."""
    __tablename__ = "check_items"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    check_type = Column(String(50), nullable=False, index=True)  # os, was, mariadb, postgresql, cubrid, tomcat
    item_key = Column(String(100), nullable=False, index=True)   # results 내 키 (cpu, memory, installation 등)
    display_name = Column(String(200), nullable=True)             # UI 표시명
    enabled = Column(Boolean, nullable=False, default=True)
    sort_order = Column(Integer, nullable=False, default=0)
    created_at = Column(DateTime, default=datetime.now, nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "check_type": self.check_type,
            "item_key": self.item_key,
            "display_name": self.display_name or self.item_key,
            "enabled": self.enabled,
            "sort_order": self.sort_order,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class Server(Base):
    """점검 대상 서버 (관리자 콘솔에서 추가/수정/삭제). SSH 인증: key_file | password."""
    __tablename__ = "servers"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(255), nullable=False, index=True)  # 호스트명/표시명
    ip = Column(String(64), nullable=False, index=True)  # ansible_host
    os_type = Column(String(50), nullable=False, default="linux")  # linux, windows, 기타
    ssh_port = Column(Integer, nullable=False, default=22)
    ssh_user = Column(String(100), nullable=False, default="root")
    check_enabled = Column(Boolean, nullable=False, default=True)  # 점검 대상 여부
    memo = Column(String(500), nullable=True)
    ssh_auth_type = Column(String(20), nullable=False, default="key_file")  # key_file | password
    ssh_key_path = Column(String(500), nullable=True)  # Ansible 실행 머신 기준 키 파일 경로
    ssh_password_encrypted = Column(String(500), nullable=True)  # 비밀번호 암호화 저장
    created_at = Column(DateTime, default=datetime.now, nullable=False)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now, nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "ip": self.ip,
            "os_type": self.os_type,
            "ssh_port": self.ssh_port,
            "ssh_user": self.ssh_user,
            "check_enabled": self.check_enabled,
            "memo": self.memo or None,
            "ssh_auth_type": getattr(self, "ssh_auth_type", "key_file") or "key_file",
            "ssh_key_path": getattr(self, "ssh_key_path", None),
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

