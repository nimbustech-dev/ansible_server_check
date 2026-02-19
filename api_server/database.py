"""
데이터베이스 연결 및 CRUD 작업
"""
import os
from pathlib import Path
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, Session
from models import Base, CheckResult, User, Server
from typing import Optional, List, Dict, Any, Tuple
from datetime import datetime

# 비밀번호 해시 (bcrypt 직접 사용 - passlib와 bcrypt 5.x 호환 이슈 회피)
def hash_password(password: str) -> str:
    import bcrypt
    raw = password.encode("utf-8")
    if len(raw) > 72:
        raw = raw[:72]
    return bcrypt.hashpw(raw, bcrypt.gensalt()).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    import bcrypt
    raw = plain.encode("utf-8")
    if len(raw) > 72:
        raw = raw[:72]
    try:
        return bcrypt.checkpw(raw, hashed.encode("utf-8"))
    except Exception:
        return False

# .env 파일에서 환경변수 로드 (있는 경우)
env_file = Path(__file__).parent / ".env"
if env_file.exists():
    with open(env_file) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, value = line.split("=", 1)
                os.environ[key.strip()] = value.strip()

# DB 연결 설정 (환경변수 또는 기본값)
# .env 파일 또는 환경변수에서 DATABASE_URL을 읽음
DB_FILE = os.path.join(os.path.dirname(__file__), "check_results.db")
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    f"sqlite:///{DB_FILE}"  # 기본값: SQLite (개발용)
    # PostgreSQL 사용 시: "postgresql://user:password@localhost/dbname"
    # MariaDB 사용 시: "mysql+pymysql://user:password@localhost/dbname"
)

# 엔진 및 세션 생성
# PostgreSQL 연결 풀 설정 (연결 끊김 방지)
if "postgresql" in DATABASE_URL or "postgres" in DATABASE_URL:
    engine = create_engine(
        DATABASE_URL,
        pool_pre_ping=True,  # 연결 유효성 사전 확인
        pool_recycle=3600,   # 1시간마다 연결 재생성
        pool_size=5,         # 연결 풀 크기
        max_overflow=10,     # 추가 연결 허용
        connect_args={
            "client_encoding": "UTF8"  # UTF8 인코딩 설정
        }
    )
else:
    engine = create_engine(
        DATABASE_URL,
        connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {}
    )
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def init_db():
    """데이터베이스 초기화 (테이블 생성)"""
    Base.metadata.create_all(bind=engine)
    print(f"📊 데이터베이스 연결: {DATABASE_URL}")


def check_db_connection() -> Tuple[bool, str]:
    """
    DB 연결 가능 여부 확인
    
    Returns:
        (성공 여부, 메시지)
    """
    try:
        db = SessionLocal()
        try:
            db.execute(text("SELECT 1"))
            return True, "ok"
        finally:
            db.close()
    except Exception as e:
        return False, str(e)


def get_db() -> Session:
    """DB 세션 가져오기"""
    db = SessionLocal()
    try:
        return db
    finally:
        pass  # 세션은 호출자가 닫아야 함


def save_check_result(
    check_type: str,
    hostname: str,
    check_time: str,
    checker: str,
    status: str,
    results: Dict[str, Any]
) -> int:
    """
    점검 결과를 DB에 저장
    
    Returns:
        저장된 레코드의 ID
    """
    db = SessionLocal()
    try:
        check_result = CheckResult(
            check_type=check_type,
            hostname=hostname,
            check_time=check_time,
            checker=checker,
            status=status,
            results=results
        )
        db.add(check_result)
        db.commit()
        db.refresh(check_result)
        return check_result.id
    except Exception as e:
        db.rollback()
        raise e
    finally:
        db.close()


def get_check_results(
    check_type: Optional[str] = None,
    hostname: Optional[str] = None,
    checker: Optional[str] = None,
    limit: int = 100,
    created_after: Optional[datetime] = None,
    created_before: Optional[datetime] = None,
    ids: Optional[List[int]] = None,
) -> List[Dict[str, Any]]:
    """
    점검 결과 조회
    
    Args:
        created_after: 이 시각 이후 created_at
        created_before: 이 시각 이전 created_at
        ids: 지정 시 해당 id만 조회 (다른 필터와 AND)
    
    Returns:
        점검 결과 리스트
    """
    db = SessionLocal()
    try:
        # 연결 유효성 확인 (PostgreSQL의 경우)
        if "postgresql" in DATABASE_URL or "postgres" in DATABASE_URL:
            try:
                db.execute(text("SELECT 1"))
            except Exception:
                # 연결이 끊어진 경우 세션 재생성
                db.close()
                db = SessionLocal()
        
        query = db.query(CheckResult)
        
        # 필터 적용
        if check_type:
            query = query.filter(CheckResult.check_type == check_type)
        if hostname:
            query = query.filter(CheckResult.hostname == hostname)
        if checker:
            query = query.filter(CheckResult.checker == checker)
        if created_after is not None:
            query = query.filter(CheckResult.created_at >= created_after)
        if created_before is not None:
            query = query.filter(CheckResult.created_at <= created_before)
        if ids:
            query = query.filter(CheckResult.id.in_(ids))
        
        # 최신순 정렬 및 제한
        results = query.order_by(CheckResult.created_at.desc()).limit(limit).all()
        
        return [result.to_dict() for result in results]
    except Exception as e:
        # 연결 오류인 경우 재시도
        if "connection" in str(e).lower() or "closed" in str(e).lower():
            db.close()
            db = SessionLocal()
            try:
                query = db.query(CheckResult)
                if check_type:
                    query = query.filter(CheckResult.check_type == check_type)
                if hostname:
                    query = query.filter(CheckResult.hostname == hostname)
                if checker:
                    query = query.filter(CheckResult.checker == checker)
                if created_after is not None:
                    query = query.filter(CheckResult.created_at >= created_after)
                if created_before is not None:
                    query = query.filter(CheckResult.created_at <= created_before)
                if ids:
                    query = query.filter(CheckResult.id.in_(ids))
                results = query.order_by(CheckResult.created_at.desc()).limit(limit).all()
                return [result.to_dict() for result in results]
            except Exception as e2:
                raise e2
        else:
            raise e
    finally:
        db.close()


# ---------- User CRUD ----------


def get_user_by_username(username: str) -> Optional[User]:
    """username으로 사용자 조회"""
    db = SessionLocal()
    try:
        return db.query(User).filter(User.username == username).first()
    finally:
        db.close()


def get_user_by_id(user_id: int) -> Optional[User]:
    """id로 사용자 조회"""
    db = SessionLocal()
    try:
        return db.query(User).filter(User.id == user_id).first()
    finally:
        db.close()


def create_user(username: str, password: str, email: Optional[str] = None) -> User:
    """회원가입: 사용자 생성. 비밀번호는 해시 후 저장. 기본 역할 viewer."""
    db = SessionLocal()
    try:
        user = User(
            username=username,
            email=email or None,
            password_hash=hash_password(password),
            is_approved=False,
            is_admin=False,
            role="viewer",
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        return user
    except Exception as e:
        db.rollback()
        raise e
    finally:
        db.close()


def get_all_users() -> List[User]:
    """가입자 목록 (승인 대기 포함) - 관리자용"""
    db = SessionLocal()
    try:
        return db.query(User).order_by(User.created_at.desc()).all()
    finally:
        db.close()


def set_user_approved(user_id: int, approved: bool) -> Optional[User]:
    """사용자 승인/거부 설정"""
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            return None
        user.is_approved = approved
        db.commit()
        db.refresh(user)
        return user
    except Exception as e:
        db.rollback()
        raise e
    finally:
        db.close()


def delete_user(user_id: int) -> bool:
    """사용자 삭제 (거부 시 선택적으로 사용)"""
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            return False
        db.delete(user)
        db.commit()
        return True
    except Exception as e:
        db.rollback()
        raise e
    finally:
        db.close()


def set_user_role(user_id: int, role: str) -> Optional[User]:
    """사용자 역할 변경. role: admin | maintainer | operator | viewer."""
    if role not in ("admin", "maintainer", "operator", "viewer"):
        return None
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            return None
        user.role = role
        user.is_admin = role == "admin"
        db.commit()
        db.refresh(user)
        return user
    except Exception as e:
        db.rollback()
        raise e
    finally:
        db.close()


# ---------- 서버(점검 대상) CRUD ----------


def list_servers(check_enabled: Optional[bool] = None) -> List[Server]:
    """서버 목록. check_enabled로 필터 가능."""
    db = SessionLocal()
    try:
        q = db.query(Server).order_by(Server.id.asc())
        if check_enabled is not None:
            q = q.filter(Server.check_enabled == check_enabled)
        return q.all()
    finally:
        db.close()


def get_server(server_id: int) -> Optional[Server]:
    """서버 단건 조회."""
    db = SessionLocal()
    try:
        return db.query(Server).filter(Server.id == server_id).first()
    finally:
        db.close()


def create_server(
    name: str,
    ip: str,
    os_type: str = "linux",
    ssh_port: int = 22,
    ssh_user: str = "root",
    check_enabled: bool = True,
    memo: Optional[str] = None,
    ssh_auth_type: str = "key_file",
    ssh_key_path: Optional[str] = None,
    ssh_password: Optional[str] = None,
) -> Server:
    """서버 추가. ssh_password 있으면 암호화해 저장."""
    encrypted = None
    if (ssh_auth_type or "key_file") == "password" and ssh_password and ssh_password.strip():
        try:
            from crypto_util import encrypt_password
            encrypted = encrypt_password(ssh_password)
        except ValueError as e:
            raise ValueError("서버 SSH 비밀번호 저장을 위해 .env에 ENCRYPTION_KEY(또는 ANSIBLE_SERVER_ENCRYPTION_KEY)를 설정하세요.") from e
    db = SessionLocal()
    try:
        s = Server(
            name=name.strip(),
            ip=ip.strip(),
            os_type=(os_type or "linux").strip(),
            ssh_port=ssh_port,
            ssh_user=(ssh_user or "root").strip(),
            check_enabled=check_enabled,
            memo=memo.strip() if memo else None,
            ssh_auth_type=(ssh_auth_type or "key_file").strip(),
            ssh_key_path=ssh_key_path.strip() if ssh_key_path else None,
            ssh_password_encrypted=encrypted,
        )
        db.add(s)
        db.commit()
        db.refresh(s)
        return s
    except Exception as e:
        db.rollback()
        raise e
    finally:
        db.close()


def update_server(
    server_id: int,
    name: Optional[str] = None,
    ip: Optional[str] = None,
    os_type: Optional[str] = None,
    ssh_port: Optional[int] = None,
    ssh_user: Optional[str] = None,
    check_enabled: Optional[bool] = None,
    memo: Optional[str] = None,
    ssh_auth_type: Optional[str] = None,
    ssh_key_path: Optional[str] = None,
    ssh_password: Optional[str] = None,
) -> Optional[Server]:
    """서버 수정. None인 필드는 변경하지 않음. ssh_password 비우면 유지."""
    db = SessionLocal()
    try:
        s = db.query(Server).filter(Server.id == server_id).first()
        if not s:
            return None
        if name is not None:
            s.name = name.strip()
        if ip is not None:
            s.ip = ip.strip()
        if os_type is not None:
            s.os_type = os_type.strip()
        if ssh_port is not None:
            s.ssh_port = ssh_port
        if ssh_user is not None:
            s.ssh_user = ssh_user.strip()
        if check_enabled is not None:
            s.check_enabled = check_enabled
        if memo is not None:
            s.memo = memo.strip() or None
        if ssh_auth_type is not None:
            s.ssh_auth_type = ssh_auth_type.strip()
        if ssh_key_path is not None:
            s.ssh_key_path = ssh_key_path.strip() or None
        if ssh_password is not None and (ssh_auth_type or getattr(s, "ssh_auth_type", "key_file")) == "password":
            if ssh_password.strip():
                try:
                    from crypto_util import encrypt_password
                    s.ssh_password_encrypted = encrypt_password(ssh_password)
                except ValueError as e:
                    raise ValueError("서버 SSH 비밀번호 저장을 위해 .env에 ENCRYPTION_KEY(또는 ANSIBLE_SERVER_ENCRYPTION_KEY)를 설정하세요.") from e
            else:
                s.ssh_password_encrypted = None
        from datetime import datetime
        s.updated_at = datetime.now()
        db.commit()
        db.refresh(s)
        return s
    except Exception as e:
        db.rollback()
        raise e
    finally:
        db.close()


def delete_server(server_id: int) -> bool:
    """서버 삭제."""
    db = SessionLocal()
    try:
        s = db.query(Server).filter(Server.id == server_id).first()
        if not s:
            return False
        db.delete(s)
        db.commit()
        return True
    except Exception as e:
        db.rollback()
        raise e
    finally:
        db.close()


def set_server_check_enabled(server_id: int, enabled: bool) -> Optional[Server]:
    """서버 점검 대상 여부 설정."""
    return update_server(server_id, check_enabled=enabled)


def list_servers_for_inventory() -> List[Dict[str, Any]]:
    """
    동적 inventory용. check_enabled=True인 서버만, hostvars에 ansible_* 및 비밀번호(복호화) 포함.
    반환: [ {"host": "name_or_name_id", "hostvars": {...}}, ... ]
    """
    servers = list_servers(check_enabled=True)
    seen_names = {}
    out = []
    for s in servers:
        name = (s.name or "").strip() or f"server_{s.id}"
        if name in seen_names:
            name = f"{name}_{s.id}"
        seen_names[name] = True
        auth_type = getattr(s, "ssh_auth_type", None) or "key_file"
        hostvars = {
            "ansible_host": s.ip,
            "ansible_port": s.ssh_port,
            "ansible_user": s.ssh_user or "root",
        }
        if auth_type == "key_file":
            kp = getattr(s, "ssh_key_path", None)
            if kp and (kp := (kp or "").strip()):
                hostvars["ansible_ssh_private_key_file"] = kp
        else:
            enc = getattr(s, "ssh_password_encrypted", None)
            if enc:
                try:
                    from crypto_util import decrypt_password
                    hostvars["ansible_ssh_pass"] = decrypt_password(enc)
                except Exception:
                    pass
        out.append({"host": name, "hostvars": hostvars})
    return out


def ensure_admin_user():
    """서버 기동 시 .env의 ADMIN_USERNAME, ADMIN_PASSWORD로 최초 관리자 생성 (없을 때만)"""
    username = os.getenv("ADMIN_USERNAME", "").strip()
    password = os.getenv("ADMIN_PASSWORD", "").strip()
    if not username or not password:
        return
    existing = get_user_by_username(username)
    if existing:
        return
    db = SessionLocal()
    try:
        user = User(
            username=username,
            email=None,
            password_hash=hash_password(password),
            is_approved=True,
            is_admin=True,
            role="admin",
        )
        db.add(user)
        db.commit()
        print("✅ 최초 관리자 계정 생성 완료:", username)
    except Exception as e:
        db.rollback()
        raise e
    finally:
        db.close()

