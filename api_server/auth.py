"""
JWT 발급/검증 및 get_current_user, get_current_admin 의존성
"""
import os
from datetime import datetime, timezone, timedelta
from typing import Optional

from fastapi import HTTPException, Request

from jose import JWTError, jwt

from database import get_user_by_id
from models import User

# JWT 설정 (환경변수 또는 기본값)
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "ansible-report-secret-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_HOURS = 24
COOKIE_NAME = "session"


def create_access_token(user_id: int, username: str, is_admin: bool) -> str:
    """JWT 액세스 토큰 생성"""
    expire = datetime.now(timezone.utc) + timedelta(hours=ACCESS_TOKEN_EXPIRE_HOURS)
    payload = {
        "sub": str(user_id),
        "username": username,
        "is_admin": is_admin,
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
    """get_current_user + is_admin 검사. 관리자 아님 시 403."""
    user = await get_current_user(request)
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="관리자만 접근할 수 있습니다")
    return user
