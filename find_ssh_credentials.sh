#!/bin/bash
# SSH 접속 정보 찾기 스크립트

echo "=========================================="
echo "SSH 접속 정보 찾기"
echo "=========================================="
echo ""

# Windows 사용자 홈 디렉토리
WINDOWS_HOME="/mnt/c/Users/$USER"
if [ ! -d "$WINDOWS_HOME" ]; then
    WINDOWS_HOME="/mnt/c/Users/$(whoami)"
fi

echo "1. PuTTY 설정 파일 확인..."
PUTTY_SESSIONS="$WINDOWS_HOME/AppData/Roaming/PuTTY/sessions"
if [ -d "$PUTTY_SESSIONS" ]; then
    echo "   ✅ PuTTY 설정 디렉토리 발견: $PUTTY_SESSIONS"
    echo "   저장된 세션 목록:"
    ls -1 "$PUTTY_SESSIONS" 2>/dev/null | head -10
    echo ""
    echo "   세션 정보 확인 (예시):"
    if [ -f "$PUTTY_SESSIONS/Default%20Settings" ]; then
        echo "   - Default Settings 파일 존재"
    fi
else
    echo "   ❌ PuTTY 설정 디렉토리 없음"
fi
echo ""

echo "2. SSH 키 파일 확인..."
SSH_DIR="$WINDOWS_HOME/.ssh"
WSL_SSH_DIR="$HOME/.ssh"

if [ -d "$SSH_DIR" ]; then
    echo "   ✅ Windows SSH 디렉토리: $SSH_DIR"
    ls -la "$SSH_DIR" 2>/dev/null | grep -E "\.(pem|key|ppk)$|id_rsa|id_ed25519" || echo "   SSH 키 파일 없음"
fi

if [ -d "$WSL_SSH_DIR" ]; then
    echo "   ✅ WSL SSH 디렉토리: $WSL_SSH_DIR"
    ls -la "$WSL_SSH_DIR" 2>/dev/null | grep -E "\.(pem|key|ppk)$|id_rsa|id_ed25519" || echo "   SSH 키 파일 없음"
fi
echo ""

echo "3. SSH 설정 파일 확인..."
if [ -f "$SSH_DIR/config" ]; then
    echo "   ✅ Windows SSH config 파일 발견:"
    cat "$SSH_DIR/config" 2>/dev/null | grep -A 5 "Host\|HostName\|User\|IdentityFile" || echo "   설정 없음"
fi

if [ -f "$WSL_SSH_DIR/config" ]; then
    echo "   ✅ WSL SSH config 파일 발견:"
    cat "$WSL_SSH_DIR/config" 2>/dev/null | grep -A 5 "Host\|HostName\|User\|IdentityFile" || echo "   설정 없음"
fi
echo ""

echo "4. MobaXterm 설정 확인..."
MOBAXTERM_SESSIONS="$WINDOWS_HOME/AppData/Roaming/MobaXterm/Sessions"
if [ -d "$MOBAXTERM_SESSIONS" ]; then
    echo "   ✅ MobaXterm 설정 디렉토리 발견: $MOBAXTERM_SESSIONS"
    ls -1 "$MOBAXTERM_SESSIONS" 2>/dev/null | head -10
else
    echo "   ❌ MobaXterm 설정 디렉토리 없음"
fi
echo ""

echo "5. 프로젝트 내 설정 파일 확인..."
PROJECT_DIR="/mnt/c/ansible_server_check"
if [ -d "$PROJECT_DIR" ]; then
    echo "   프로젝트 디렉토리에서 SSH 관련 파일 검색..."
    find "$PROJECT_DIR" -type f \( -name "*.pem" -o -name "*.key" -o -name "*ssh*" -o -name "*credential*" \) 2>/dev/null | head -10
fi
echo ""

echo "=========================================="
echo "확인 완료"
echo "=========================================="
echo ""
echo "다음 단계:"
echo "1. 위에서 찾은 정보를 확인하세요"
echo "2. PuTTY나 MobaXterm으로 동국대 서버에 접속해본 적이 있다면,"
echo "   해당 프로그램의 세션 설정을 확인하세요"
echo "3. 서버 관리자(박지빈님)에게 접속 정보를 요청하세요"
echo "4. 동국대 서버에 물리적으로 접근 가능하다면,"
echo "   서버에서 직접 사용자 정보를 확인하세요"

