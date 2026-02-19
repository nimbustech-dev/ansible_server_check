"""
서버 SSH 비밀번호 암호화/복호화 (Fernet).
환경변수 ENCRYPTION_KEY 또는 ANSIBLE_SERVER_ENCRYPTION_KEY 사용.
키는 긴 문자열(비밀번호)이면 PBKDF2로 파생, base64url이면 그대로 Fernet 키로 사용.
"""
import os
import base64
from typing import Optional

_FERNET_KEY: Optional[bytes] = None


def _get_fernet_key() -> bytes:
    """환경변수에서 Fernet용 키 로드."""
    global _FERNET_KEY
    if _FERNET_KEY is not None:
        return _FERNET_KEY
    raw = os.getenv("ENCRYPTION_KEY") or os.getenv("ANSIBLE_SERVER_ENCRYPTION_KEY")
    if not raw or not raw.strip():
        raise ValueError(
            "ENCRYPTION_KEY or ANSIBLE_SERVER_ENCRYPTION_KEY must be set to store/decrypt server passwords"
        )
    raw = raw.strip()
    from cryptography.fernet import Fernet
    try:
        if len(raw) == 44 and raw.replace("-", "").replace("_", "").isalnum():
            key = raw.encode("ascii")
            Fernet(key)
        else:
            raise ValueError("not base64url")
    except Exception:
        from cryptography.hazmat.primitives import hashes
        from cryptography.hazmat.backends import default_backend
        from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=b"ansible-server-inventory",
            iterations=100000,
            backend=default_backend(),
        )
        key = base64.urlsafe_b64encode(kdf.derive(raw.encode("utf-8")))
    _FERNET_KEY = key
    return key


def encrypt_password(plain: str) -> str:
    """평문 비밀번호를 암호화해 base64 문자열로 반환."""
    from cryptography.fernet import Fernet
    key = _get_fernet_key()
    f = Fernet(key)
    return f.encrypt(plain.encode("utf-8")).decode("ascii")


def decrypt_password(encrypted: str) -> str:
    """암호화된 비밀번호를 복호화해 평문 반환."""
    from cryptography.fernet import Fernet
    if not encrypted:
        return ""
    key = _get_fernet_key()
    f = Fernet(key)
    return f.decrypt(encrypted.encode("ascii")).decode("utf-8")
