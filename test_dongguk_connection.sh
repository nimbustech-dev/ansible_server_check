#!/bin/bash
# 동국대 서버 연결 테스트 스크립트

echo "=========================================="
echo "동국대 서버 연결 테스트"
echo "=========================================="
echo ""

# 테스트할 IP 주소들
VPN_IP="26.27.230.192"
LOCAL_IP="172.30.1.36"

echo "1. VPN IP (26.27.230.192) 연결 테스트..."
if ping -c 2 -W 2 $VPN_IP > /dev/null 2>&1; then
    echo "   ✅ VPN IP로 연결 가능"
else
    echo "   ❌ VPN IP로 연결 불가"
fi
echo ""

echo "2. 로컬 IP (172.30.1.36) 연결 테스트..."
if ping -c 2 -W 2 $LOCAL_IP > /dev/null 2>&1; then
    echo "   ✅ 로컬 IP로 연결 가능"
else
    echo "   ❌ 로컬 IP로 연결 불가"
fi
echo ""

echo "3. SSH 포트(22) 접근 테스트..."
echo "   VPN IP (26.27.230.192:22)..."
if timeout 3 bash -c "echo > /dev/tcp/$VPN_IP/22" 2>/dev/null; then
    echo "   ✅ VPN IP의 SSH 포트 열려있음"
else
    echo "   ❌ VPN IP의 SSH 포트 접근 불가"
fi

echo "   로컬 IP (172.30.1.36:22)..."
if timeout 3 bash -c "echo > /dev/tcp/$LOCAL_IP/22" 2>/dev/null; then
    echo "   ✅ 로컬 IP의 SSH 포트 열려있음"
else
    echo "   ❌ 로컬 IP의 SSH 포트 접근 불가"
fi
echo ""

echo "=========================================="
echo "테스트 완료"
echo "=========================================="
echo ""
echo "다음 단계:"
echo "1. SSH 접속 정보 확인 (사용자명, 비밀번호/SSH 키)"
echo "2. Inventory 파일에 정보 추가"
echo "3. SSH 접속 테스트: ansible -i inventory/dongguk_remote_servers.ini dongguk_servers -m ping"

