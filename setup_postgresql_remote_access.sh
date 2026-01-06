#!/bin/bash
# PostgreSQL 원격 접속 설정 스크립트
# OS 담당자 요청: 5432 포트 오픈 및 원격 접속 허용

echo "=========================================="
echo "PostgreSQL 원격 접속 설정"
echo "=========================================="
echo ""
echo "이 스크립트는 다음을 설정합니다:"
echo "1. 방화벽에서 5432 포트 열기"
echo "2. pg_hba.conf에서 원격 접속 허용"
echo "3. postgresql.conf에서 listen_addresses = '*' 설정"
echo ""
read -p "계속하시겠습니까? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "취소되었습니다."
    exit 1
fi

# PostgreSQL 버전 확인
echo "1. PostgreSQL 버전 확인..."
PG_VERSION=$(sudo -u postgres psql -t -c "SHOW server_version_num;" 2>/dev/null | head -1 | tr -d ' ' | cut -c1-2)

if [ -z "$PG_VERSION" ]; then
    echo "❌ PostgreSQL 버전을 확인할 수 없습니다."
    echo "   PostgreSQL이 설치되어 있고 실행 중인지 확인하세요."
    exit 1
fi

echo "✅ PostgreSQL 버전: ${PG_VERSION}"

PG_HBA="/etc/postgresql/${PG_VERSION}/main/pg_hba.conf"
PG_CONF="/etc/postgresql/${PG_VERSION}/main/postgresql.conf"

if [ ! -f "$PG_HBA" ]; then
    echo "❌ pg_hba.conf 파일을 찾을 수 없습니다: $PG_HBA"
    exit 1
fi

if [ ! -f "$PG_CONF" ]; then
    echo "❌ postgresql.conf 파일을 찾을 수 없습니다: $PG_CONF"
    exit 1
fi

echo ""
echo "2. pg_hba.conf 설정 (원격 접속 허용)..."
echo "   파일: $PG_HBA"

# 기존 원격 접속 설정 확인
if grep -q "^host.*all.*all.*0.0.0.0/0.*md5" "$PG_HBA"; then
    echo "   ✅ 이미 원격 접속이 허용되어 있습니다"
else
    # 백업 생성
    sudo cp "$PG_HBA" "${PG_HBA}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "   📋 백업 생성: ${PG_HBA}.backup.*"
    
    # 원격 접속 허용 추가
    echo "" | sudo tee -a "$PG_HBA" > /dev/null
    echo "# 원격 접속 허용 (OS 담당자 요청)" | sudo tee -a "$PG_HBA" > /dev/null
    echo "host    all    all    0.0.0.0/0    md5" | sudo tee -a "$PG_HBA" > /dev/null
    echo "   ✅ 원격 접속 허용 설정 추가됨"
fi

echo ""
echo "3. postgresql.conf 설정 (listen_addresses)..."
echo "   파일: $PG_CONF"

# listen_addresses 설정 확인 및 수정
if grep -q "^listen_addresses = '\*'" "$PG_CONF" || grep -q "^listen_addresses='\*'" "$PG_CONF"; then
    echo "   ✅ 이미 listen_addresses = '*' 로 설정되어 있습니다"
else
    # 백업 생성
    sudo cp "$PG_CONF" "${PG_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "   📋 백업 생성: ${PG_CONF}.backup.*"
    
    # 기존 listen_addresses 주석 처리 또는 수정
    if grep -q "^#listen_addresses" "$PG_CONF"; then
        # 주석 해제 및 수정
        sudo sed -i "s/^#listen_addresses.*/listen_addresses = '*'/" "$PG_CONF"
        echo "   ✅ listen_addresses 주석 해제 및 '*' 설정"
    elif grep -q "^listen_addresses" "$PG_CONF"; then
        # 기존 값 수정
        sudo sed -i "s/^listen_addresses.*/listen_addresses = '*'/" "$PG_CONF"
        echo "   ✅ listen_addresses를 '*'로 수정"
    else
        # 없으면 추가
        echo "" | sudo tee -a "$PG_CONF" > /dev/null
        echo "# 원격 접속 허용 (OS 담당자 요청)" | sudo tee -a "$PG_CONF" > /dev/null
        echo "listen_addresses = '*'" | sudo tee -a "$PG_CONF" > /dev/null
        echo "   ✅ listen_addresses = '*' 추가됨"
    fi
fi

echo ""
echo "4. 방화벽 설정 (5432 포트 열기)..."

# ufw 확인
if command -v ufw &> /dev/null; then
    if sudo ufw status | grep -q "5432"; then
        echo "   ✅ 포트 5432가 이미 열려있습니다"
    else
        echo "   🔓 포트 5432 열기 중..."
        sudo ufw allow 5432/tcp
        echo "   ✅ 포트 5432 열림"
    fi
# firewalld 확인
elif command -v firewall-cmd &> /dev/null; then
    if sudo firewall-cmd --list-ports | grep -q "5432/tcp"; then
        echo "   ✅ 포트 5432가 이미 열려있습니다"
    else
        echo "   🔓 포트 5432 열기 중..."
        sudo firewall-cmd --permanent --add-port=5432/tcp
        sudo firewall-cmd --reload
        echo "   ✅ 포트 5432 열림"
    fi
else
    echo "   ⚠️  ufw 또는 firewalld를 찾을 수 없습니다."
    echo "   방화벽 설정을 수동으로 확인하세요:"
    echo "   - 포트 5432 (PostgreSQL) 허용 필요"
fi

echo ""
echo "5. PostgreSQL 재시작..."
sudo systemctl restart postgresql

if [ $? -eq 0 ]; then
    echo "   ✅ PostgreSQL 재시작 완료"
else
    echo "   ❌ PostgreSQL 재시작 실패"
    echo "   설정 파일을 확인하세요."
    exit 1
fi

echo ""
echo "6. 설정 확인..."

# PostgreSQL 상태 확인
if sudo systemctl is-active --quiet postgresql; then
    echo "   ✅ PostgreSQL 실행 중"
else
    echo "   ❌ PostgreSQL이 실행되지 않습니다"
    exit 1
fi

# 포트 리스닝 확인
if sudo ss -tlnp | grep -q ":5432"; then
    echo "   ✅ 포트 5432 리스닝 중"
else
    echo "   ⚠️  포트 5432가 리스닝되지 않습니다"
fi

# 현재 IP 주소 확인
LOCAL_IP=$(hostname -I | awk '{print $1}')
echo ""
echo "=========================================="
echo "설정 완료!"
echo "=========================================="
echo ""
echo "PostgreSQL 원격 접속 정보:"
echo "  호스트: $LOCAL_IP"
echo "  포트: 5432"
echo "  데이터베이스: ansible_checks"
echo "  사용자: ansible_user"
echo ""
echo "연결 테스트:"
echo "  psql -h $LOCAL_IP -p 5432 -U ansible_user -d ansible_checks"
echo ""
echo "⚠️  보안 주의사항:"
echo "  - 현재 설정은 모든 IP(0.0.0.0/0)에서 접근 가능합니다"
echo "  - 프로덕션 환경에서는 특정 IP만 허용하도록 수정하세요"
echo "  - 예: host all all 192.168.0.0/24 md5"
echo ""

