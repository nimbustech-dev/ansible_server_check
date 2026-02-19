"""
JWT 발급/검증 및 get_current_user, 역할별 의존성 (admin/maintainer/operator/viewer)
"""
import os
from datetime import datetime, timezone, timedelta
from typing import Optional

from fastapi import HTTPException, Request

from jose import JWTError, jwt

from database import get_user_by_id
from models import User

# 역할 상수
ROLE_ADMIN = "admin"
ROLE_MAINTAINER = "maintainer"
ROLE_OPERATOR = "operator"
ROLE_VIEWER = "viewer"

# JWT 설정 (환경변수 또는 기본값)
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "ansible-report-secret-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_HOURS = 24
COOKIE_NAME = "session"


def _user_role(user: User) -> str:
    """User의 역할 반환 (role 컬럼 없을 때 is_admin으로 추론)"""
    r = getattr(user, "role", None)
    if r in (ROLE_ADMIN, ROLE_MAINTAINER, ROLE_OPERATOR, ROLE_VIEWER):
        return r
    return ROLE_ADMIN if user.is_admin else ROLE_VIEWER


def create_access_token(user_id: int, username: str, role: Optional[str] = None, is_admin: Optional[bool] = None) -> str:
    """JWT 액세스 토큰 생성. role 우선, 없으면 is_admin으로 admin/viewer 구분."""
    expire = datetime.now(timezone.utc) + timedelta(hours=ACCESS_TOKEN_EXPIRE_HOURS)
    r = role if role in (ROLE_ADMIN, ROLE_MAINTAINER, ROLE_OPERATOR, ROLE_VIEWER) else (ROLE_ADMIN if is_admin else ROLE_VIEWER)
    payload = {
        "sub": str(user_id),
        "username": username,
        "role": r,
        "is_admin": r == ROLE_ADMIN,
        "exp": expire,
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def decode_access_token(token: str) -> Optional[dict]:
    """JWT 검증 후 payload 반환, 실패 시 None"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return None


def get_token_from_request(request: Request) -> Optional[str]:
    """쿠키에서 JWT 토큰 추출"""
    return request.cookies.get(COOKIE_NAME)


async def get_current_user(request: Request) -> User:
    """쿠키 JWT 검증 후 User 반환. 미인증 시 401."""
    token = get_token_from_request(request)
    if not token:
        raise HTTPException(status_code=401, detail="로그인이 필요합니다")
    payload = decode_access_token(token)
    if not payload or "sub" not in payload:
        raise HTTPException(status_code=401, detail="로그인이 필요합니다")
    user_id = int(payload["sub"])
    user = get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=401, detail="사용자를 찾을 수 없습니다")
    return user


async def get_current_admin(request: Request) -> User:
    """Admin만 허용 (role == admin)."""
    user = await get_current_user(request)
    if _user_role(user) != ROLE_ADMIN:
        raise HTTPException(status_code=403, detail="관리자만 접근할 수 있습니다")
    return user


async def get_current_maintainer(request: Request) -> User:
    """Maintainer 이상 허용 (admin, maintainer)."""
    user = await get_current_user(request)
    r = _user_role(user)
    if r not in (ROLE_ADMIN, ROLE_MAINTAINER):
        raise HTTPException(status_code=403, detail="권한이 없습니다 (Maintainer 이상 필요)")
    return user


async def get_current_operator(request: Request) -> User:
    """Operator 이상 허용 (admin, maintainer, operator)."""
    user = await get_current_user(request)
    r = _user_role(user)
    if r not in (ROLE_ADMIN, ROLE_MAINTAINER, ROLE_OPERATOR):
        raise HTTPException(status_code=403, detail="권한이 없습니다 (Operator 이상 필요)")
    return user
