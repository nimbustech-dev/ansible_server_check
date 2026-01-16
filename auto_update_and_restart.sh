#!/bin/bash
# Git pull 후 API 서버 자동 재시작 스크립트
# 중앙 서버(192.168.0.18)에서 사용

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "🔄 코드 업데이트 및 서버 재시작 중..."
echo ""

# 1. Git pull
echo "📥 Git pull 실행 중..."
git pull origin develop

if [ $? -ne 0 ]; then
    echo "❌ Git pull 실패"
    exit 1
fi

echo "✅ 코드 업데이트 완료"
echo ""

# 2. API 서버 재시작
echo "🔄 API 서버 재시작 중..."

# 서버 종료
if [ -f "$SCRIPT_DIR/api_server.pid" ]; then
    PID=$(cat "$SCRIPT_DIR/api_server.pid")
    if ps -p $PID > /dev/null 2>&1; then
        echo "   기존 서버 종료 중... (PID: $PID)"
        kill $PID 2>/dev/null
        sleep 2
        if ps -p $PID > /dev/null 2>&1; then
            kill -9 $PID 2>/dev/null
        fi
        rm -f "$SCRIPT_DIR/api_server.pid"
    fi
fi

# 서버 시작
echo "   새 서버 시작 중..."
cd "$SCRIPT_DIR"
./start_api_server.sh

echo ""
echo "✅ 업데이트 및 재시작 완료!"
echo "   API 서버: http://192.168.0.18:8000"
