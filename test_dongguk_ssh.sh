#!/bin/bash
# 동국대 서버 SSH 접속 테스트 스크립트

echo "=========================================="
echo "동국대 서버 SSH 접속 테스트"
echo "=========================================="
echo ""

DONGUK_IP="192.168.0.23"
DONGUK_USER="root"

echo "서버 정보:"
echo "  IP: $DONGUK_IP"
echo "  사용자: $DONGUK_USER"
echo ""

echo "1. SSH 접속 테스트..."
echo "   (비밀번호를 입력하세요)"
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 $DONGUK_USER@$DONGUK_IP "echo 'SSH 접속 성공!' && whoami && hostname"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SSH 접속 성공!"
    echo ""
    echo "2. Ansible 연결 테스트..."
    echo "   (inventory 파일에 비밀번호를 설정한 후 실행하세요)"
    echo "   ansible -i inventory/dongguk_remote_servers.ini dongguk_servers -m ping"
else
    echo ""
    echo "❌ SSH 접속 실패"
    echo "   - 비밀번호를 확인하세요"
    echo "   - 네트워크 연결을 확인하세요"
fi

echo ""
echo "=========================================="
echo "테스트 완료"
echo "=========================================="

