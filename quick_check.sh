#!/bin/bash
# 동국대 컴퓨터에서 실행할 빠른 정보 확인 스크립트

echo "=========================================="
echo "원격 컴퓨터 SSH 연결 정보 확인"
echo "=========================================="
echo ""

echo "1. 공인 IP 주소:"
curl -s ifconfig.me 2>/dev/null || echo "확인 불가"
echo ""
echo ""

echo "2. 사설 IP 주소:"
hostname -I 2>/dev/null | awk '{print $1}' || ip addr show | grep "inet " | grep -v "127.0.0.1" | head -1 | awk '{print $2}' | cut -d'/' -f1
echo ""

echo "3. SSH 포트:"
if [ -f /etc/ssh/sshd_config ]; then
    PORT=$(grep "^Port" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
    echo "${PORT:-22}"
else
    echo "기본값: 22"
fi
echo ""

echo "4. 사용자명:"
whoami
echo ""

echo "5. SSH 서비스 상태:"
if command -v systemctl >/dev/null 2>&1; then
    systemctl is-active sshd 2>/dev/null || echo "확인 필요"
elif command -v service >/dev/null 2>&1; then
    service ssh status 2>/dev/null | head -1 || echo "확인 필요"
else
    echo "확인 필요"
fi
echo ""

echo "6. 네트워크 인터페이스:"
ip addr show 2>/dev/null | grep -E "inet |inet6 " | grep -v "127.0.0.1" | head -3
echo ""

echo "=========================================="
