#!/bin/bash
# DB 서버 시작/재시작 스크립트
# API 서버에서 사용하는 PostgreSQL 데이터베이스 서버를 시작합니다

echo "=========================================="
echo "DB 서버 시작/재시작"
echo "=========================================="
echo ""

# PostgreSQL 버전 확인
PG_VERSION=$(psql --version 2>/dev/null | grep -oP '\d+' | head -1)
if [ -z "$PG_VERSION" ]; then
    # systemd 서비스에서 버전 확인 시도
    PG_VERSION=$(systemctl list-units | grep postgresql | grep -oP '\d+' | head -1)
fi

if [ -z "$PG_VERSION" ]; then
    echo "⚠️  PostgreSQL 버전을 확인할 수 없습니다. 기본값(16)을 사용합니다."
    PG_VERSION="16"
fi

echo "📋 PostgreSQL 버전: $PG_VERSION"
echo ""

# PostgreSQL 서비스 이름 확인 (버전별로 다를 수 있음)
SERVICE_NAME="postgresql"

# PostgreSQL 클러스터 시작 시도
echo "🔄 PostgreSQL 클러스터 시작 중..."
if command -v pg_ctlcluster &> /dev/null; then
    sudo pg_ctlcluster ${PG_VERSION} main start 2>/dev/null || echo "   pg_ctlcluster로 시작 시도 완료"
fi

# systemd 서비스 재시작
echo "🔄 PostgreSQL 서비스 재시작 중..."
sudo systemctl restart postgresql

# PostgreSQL 16 서비스가 별도로 있는 경우
if systemctl list-unit-files | grep -q "postgresql@16"; then
    echo "🔄 PostgreSQL 16 서비스 시작 중..."
    sudo systemctl start postgresql@16-main 2>/dev/null || true
fi

# 잠시 대기
sleep 3

# 서버 상태 확인
echo ""
echo "📋 서버 상태 확인 중..."

# 프로세스 확인
if pgrep -x postgres > /dev/null; then
    echo "✅ PostgreSQL 프로세스 실행 중"
else
    echo "⚠️  PostgreSQL 프로세스를 찾을 수 없습니다"
fi

# 포트 리스닝 확인
if sudo ss -tlnp 2>/dev/null | grep -q ":5432" || netstat -tlnp 2>/dev/null | grep -q ":5432"; then
    echo "✅ 포트 5432 리스닝 중"
else
    echo "⚠️  포트 5432가 리스닝되지 않습니다"
    echo "   PostgreSQL이 다른 포트를 사용하거나 아직 시작 중일 수 있습니다"
fi

# 연결 테스트
echo ""
echo "🔍 데이터베이스 연결 테스트 중..."
if PGPASSWORD=nimbus1234 psql -h localhost -U ansible_user -d ansible_checks -c "SELECT 1;" > /dev/null 2>&1; then
    echo "✅ 데이터베이스 연결 성공!"
    echo ""
    echo "📊 데이터베이스 정보:"
    echo "   호스트: localhost"
    echo "   포트: 5432"
    echo "   데이터베이스: ansible_checks"
    echo "   사용자: ansible_user"
else
    echo "⚠️  데이터베이스 연결 실패"
    echo "   수동으로 확인하세요:"
    echo "   psql -h localhost -U ansible_user -d ansible_checks"
fi

echo ""
echo "=========================================="
echo "작업 완료!"
echo "=========================================="
echo ""
echo "💡 API 서버가 실행 중이라면 자동으로 DB에 연결됩니다."
echo "   API 서버 재시작: ./stop_api_server.sh && ./start_api_server.sh"

