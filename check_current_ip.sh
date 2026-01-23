#!/bin/bash
# 현재 IP 확인 및 SSH 접속 테스트 스크립트

echo "=========================================="
echo "네트워크 및 SSH 접속 상태 확인"
echo "=========================================="
echo ""

# 현재 공인 IP 확인
echo "1. 현재 공인 IP 확인..."
CURRENT_IP=$(curl -s ifconfig.me)
echo "   현재 IP: $CURRENT_IP"
echo ""

# 네이버 클라우드 서버 정보
SERVER_HOST="27.96.129.114"
SERVER_PORT="4433"
SERVER_USER="root"
SSH_KEY="/home/sth0824/.ssh/nimso2026.pem"

# SSH 접속 테스트
echo "2. SSH 접속 테스트 (포트 4433)..."
if ssh -i "$SSH_KEY" -p "$SERVER_PORT" -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_HOST" "echo 'SSH 연결 성공'" > /dev/null 2>&1; then
    echo "   ✅ SSH 접속 성공!"
    echo "   현재 IP ($CURRENT_IP)가 ACG에 등록되어 있습니다."
else
    echo "   ❌ SSH 접속 실패"
    echo "   현재 IP ($CURRENT_IP)가 ACG에 등록되어 있지 않습니다."
    echo ""
    echo "   해결 방법:"
    echo "   1. 네이버 클라우드 콘솔 접속"
    echo "   2. 서버 → ACG 메뉴"
    echo "   3. 포트 4433 인바운드 규칙에 $CURRENT_IP 추가"
    echo "   4. 또는 핫스팟 연결 후 접속"
fi
echo ""

# 포트 22 테스트
echo "3. SSH 접속 테스트 (포트 22)..."
if ssh -i "$SSH_KEY" -p 22 -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_HOST" "echo 'SSH 연결 성공'" > /dev/null 2>&1; then
    echo "   ✅ 포트 22 접속 성공!"
else
    echo "   ❌ 포트 22 접속 실패"
    echo "   포트 22는 특정 IP만 허용되어 있습니다."
fi
echo ""

echo "=========================================="
echo "확인 완료"
echo "=========================================="
