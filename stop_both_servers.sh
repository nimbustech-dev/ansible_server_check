#!/bin/bash
# 두 개의 API 서버를 모두 종료하는 스크립트

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "🛑 두 개의 API 서버를 종료합니다..."
echo ""

# 포트별 PID 파일
PID_FILES=("$SCRIPT_DIR/api_server_8000.pid" "$SCRIPT_DIR/api_server_8001.pid")
PORTS=(8000 8001)

for i in "${!PID_FILES[@]}"; do
    PID_FILE="${PID_FILES[$i]}"
    PORT="${PORTS[$i]}"
    
    if [ ! -f "$PID_FILE" ]; then
        echo "⚠️  포트 $PORT: PID 파일이 없습니다. 서버가 실행 중이지 않을 수 있습니다."
        continue
    fi
    
    PID=$(cat "$PID_FILE")
    
    if ps -p $PID > /dev/null 2>&1; then
        echo "🛑 포트 $PORT 서버 종료 중... (PID: $PID)"
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
            echo "✅ 포트 $PORT 서버가 종료되었습니다."
        else
            echo "❌ 포트 $PORT 서버 종료 실패"
        fi
    else
        echo "⚠️  포트 $PORT: 프로세스가 실행 중이지 않습니다. PID 파일을 삭제합니다."
        rm -f "$PID_FILE"
    fi
    echo ""
done

echo "✅ 모든 서버 종료 완료"
