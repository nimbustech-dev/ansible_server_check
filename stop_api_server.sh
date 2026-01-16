#!/bin/bash
# API 서버를 종료하는 스크립트

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PID_FILE="$SCRIPT_DIR/api_server.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "⚠️  PID 파일이 없습니다. API 서버가 실행 중이지 않을 수 있습니다."
    exit 1
fi

PID=$(cat "$PID_FILE")

if ps -p $PID > /dev/null 2>&1; then
    echo "🛑 API 서버 종료 중... (PID: $PID)"
    kill $PID
    
    # 종료 대기
    sleep 2
    
    if ps -p $PID > /dev/null 2>&1; then
        echo "⚠️  정상 종료 실패. 강제 종료 중..."
        kill -9 $PID
        sleep 1
    fi
    
    if ! ps -p $PID > /dev/null 2>&1; then
        rm -f "$PID_FILE"
        echo "✅ API 서버가 종료되었습니다."
    else
        echo "❌ 서버 종료 실패"
        exit 1
    fi
else
    echo "⚠️  프로세스가 실행 중이지 않습니다. PID 파일을 삭제합니다."
    rm -f "$PID_FILE"
fi

