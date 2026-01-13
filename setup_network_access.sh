#!/bin/bash
# 네트워크 접근 설정 스크립트

echo "=========================================="
echo "네트워크 접근 설정"
echo "=========================================="
echo ""

# 현재 IP 주소 확인
LOCAL_IP=$(hostname -I | awk '{print $1}')
echo "현재 컴퓨터 IP 주소: $LOCAL_IP"
echo ""

# PostgreSQL pg_hba.conf 확인 및 수정
echo "1. PostgreSQL 네트워크 접근 설정..."
PG_VERSION=$(sudo -u postgres psql -t -c "SHOW server_version_num;" | head -1 | tr -d ' ' | cut -c1-2)
PG_HBA="/etc/postgresql/${PG_VERSION}/main/pg_hba.conf"

if [ -f "$PG_HBA" ]; then
    echo "PostgreSQL 설정 파일: $PG_HBA"
    
    # 네트워크 접근 허용 라인 확인
    if ! grep -q "^host.*ansible_checks.*ansible_user" "$PG_HBA"; then
        echo "네트워크 접근 허용 추가 중..."
        sudo tee -a "$PG_HBA" > /dev/null <<EOF

# Ansible 점검 시스템 네트워크 접근 허용
host    ansible_checks    ansible_user    0.0.0.0/0               md5
EOF
        echo "✅ PostgreSQL 네트워크 접근 설정 추가됨"
        
        # PostgreSQL 재시작
        echo "PostgreSQL 재시작 중..."
        sudo systemctl restart postgresql
        echo "✅ PostgreSQL 재시작 완료"
    else
        echo "✅ PostgreSQL 네트워크 접근 이미 설정됨"
    fi
else
    echo "⚠️  PostgreSQL 설정 파일을 찾을 수 없습니다: $PG_HBA"
fi

# 방화벽 포트 확인
echo ""
echo "2. 방화벽 포트 확인..."
if command -v ufw &> /dev/null; then
    if sudo ufw status | grep -q "8000"; then
        echo "✅ 포트 8000이 이미 열려있습니다"
    else
        echo "포트 8000 열기 중..."
        sudo ufw allow 8000/tcp
        echo "✅ 포트 8000 열림"
    fi
else
    echo "⚠️  ufw가 설치되어 있지 않습니다. 방화벽 설정을 수동으로 확인하세요."
fi

# API 서버 설정 확인
echo ""
echo "3. API 서버 설정 확인..."
API_MAIN="/home/sth0824/ansible/api_server/main.py"
if grep -q "host=\"0.0.0.0\"" "$API_MAIN" || grep -q "host=.*0\.0\.0\.0" "$API_MAIN"; then
    echo "✅ API 서버가 네트워크 접근을 허용하도록 설정됨"
else
    echo "⚠️  API 서버가 localhost만 허용할 수 있습니다. 확인 필요"
fi

echo ""
echo "=========================================="
echo "설정 완료"
echo "=========================================="
echo ""
echo "다른 팀원들이 사용할 정보:"
echo ""
echo "1. API 서버 주소:"
echo "   http://$LOCAL_IP:8000/api/checks"
echo ""
echo "2. config/api_config.yml 파일 수정:"
echo "   api_server:"
echo "     url: \"http://$LOCAL_IP:8000/api/checks\""
echo ""
echo "3. API 서버 재시작:"
echo "   ./stop_api_server.sh"
echo "   ./start_api_server.sh"
echo ""
echo "⚠️  보안 주의사항:"
echo "   - 같은 네트워크의 모든 컴퓨터에서 접근 가능합니다"
echo "   - 프로덕션 환경에서는 방화벽과 인증을 추가하세요"

