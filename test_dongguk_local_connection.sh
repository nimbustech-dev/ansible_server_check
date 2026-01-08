#!/bin/bash
# 동국대 서버 로컬 네트워크 연결 테스트

echo "=========================================="
echo "동국대 서버 로컬 네트워크 연결 테스트"
echo "=========================================="
echo ""

DONGUK_IP="192.168.0.23"
LOCAL_IP="192.168.0.22"

echo "동국대 서버 IP: $DONGUK_IP"
echo "로컬 PC IP: $LOCAL_IP"
echo ""

echo "1. Ping 테스트..."
if ping -c 3 -W 2 $DONGUK_IP > /dev/null 2>&1; then
    echo "   ✅ 동국대 서버로 연결 가능"
    ping -c 3 $DONGUK_IP | tail -2
else
    echo "   ❌ 동국대 서버로 연결 불가"
fi
echo ""

echo "2. SSH 포트(22) 접근 테스트..."
if timeout 3 bash -c "echo > /dev/tcp/$DONGUK_IP/22" 2>/dev/null; then
    echo "   ✅ SSH 포트(22) 열려있음"
else
    echo "   ❌ SSH 포트(22) 접근 불가"
    echo "   (SSH 서버가 실행 중이지 않거나 방화벽이 차단할 수 있음)"
fi
echo ""

echo "3. 일반적인 SSH 포트들 테스트..."
for port in 22 2222 2200; do
    if timeout 2 bash -c "echo > /dev/tcp/$DONGUK_IP/$port" 2>/dev/null; then
        echo "   ✅ 포트 $port 열려있음"
    fi
done
echo ""

echo "=========================================="
echo "테스트 완료"
echo "=========================================="
echo ""
echo "다음 단계:"
echo "1. 동국대 서버에서 SSH 접속 정보 확인:"
echo "   - 사용자명 (예: root, admin, dongguk 등)"
echo "   - 비밀번호 또는 SSH 키"
echo "   - SSH 포트 (기본 22)"
echo ""
echo "2. Inventory 파일에 정보 추가"
echo "3. SSH 접속 테스트: ansible -i inventory/dongguk_remote_servers.ini dongguk_servers -m ping"

