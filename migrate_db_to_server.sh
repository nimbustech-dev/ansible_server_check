#!/bin/bash
# 로컬 PostgreSQL DB를 네이버 클라우드 서버로 마이그레이션

set -e

# 색상 출력
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}DB 마이그레이션 (로컬 → 네이버 클라우드)${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 로컬 DB 정보
LOCAL_DB_HOST="localhost"
LOCAL_DB_PORT="5432"
LOCAL_DB_NAME="ansible_checks"
LOCAL_DB_USER="ansible_user"
LOCAL_DB_PASSWORD="nimbus1234"

# 원격 서버 정보
REMOTE_SERVER_HOST="27.96.129.114"
REMOTE_SERVER_PORT="4433"
REMOTE_SERVER_USER="root"
SSH_KEY="/home/sth0824/.ssh/nimso2026.pem"

# 원격 DB 정보 (서버 내부에서 접속)
REMOTE_DB_HOST="localhost"
REMOTE_DB_PORT="5432"
REMOTE_DB_NAME="ansible_checks"
REMOTE_DB_USER="ansible_user"
REMOTE_DB_PASSWORD="ansible_password_2024"

# 임시 덤프 파일
DUMP_FILE="/tmp/ansible_checks_dump_$(date +%Y%m%d_%H%M%S).sql"

echo -e "${YELLOW}[1/5] 로컬 DB 연결 확인...${NC}"
if ! PGPASSWORD=$LOCAL_DB_PASSWORD psql -h $LOCAL_DB_HOST -p $LOCAL_DB_PORT -U $LOCAL_DB_USER -d $LOCAL_DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${RED}❌ 로컬 DB 연결 실패${NC}"
    echo "   로컬 PostgreSQL이 실행 중인지 확인하세요."
    exit 1
fi
echo -e "${GREEN}✅ 로컬 DB 연결 성공${NC}"
echo ""

echo -e "${YELLOW}[2/5] 로컬 DB 덤프 생성...${NC}"
PGPASSWORD=$LOCAL_DB_PASSWORD pg_dump -h $LOCAL_DB_HOST -p $LOCAL_DB_PORT -U $LOCAL_DB_USER -d $LOCAL_DB_NAME \
    --clean --if-exists --no-owner --no-acl \
    > "$DUMP_FILE"

if [ $? -eq 0 ]; then
    DUMP_SIZE=$(du -h "$DUMP_FILE" | cut -f1)
    echo -e "${GREEN}✅ 덤프 파일 생성 완료: $DUMP_FILE (크기: $DUMP_SIZE)${NC}"
else
    echo -e "${RED}❌ 덤프 파일 생성 실패${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}[3/5] 원격 서버 SSH 접속 확인...${NC}"
if ! ssh -i "$SSH_KEY" -p "$REMOTE_SERVER_PORT" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$REMOTE_SERVER_USER@$REMOTE_SERVER_HOST" "echo 'SSH 연결 성공'" > /dev/null 2>&1; then
    echo -e "${RED}❌ SSH 접속 실패${NC}"
    exit 1
fi
echo -e "${GREEN}✅ SSH 접속 성공${NC}"
echo ""

echo -e "${YELLOW}[4/5] 덤프 파일 업로드...${NC}"
scp -i "$SSH_KEY" -P "$REMOTE_SERVER_PORT" "$DUMP_FILE" "$REMOTE_SERVER_USER@$REMOTE_SERVER_HOST:/tmp/"
echo -e "${GREEN}✅ 덤프 파일 업로드 완료${NC}"
echo ""

echo -e "${YELLOW}[5/5] 원격 서버에 DB 복원...${NC}"
REMOTE_DUMP_FILE="/tmp/$(basename $DUMP_FILE)"
ssh -i "$SSH_KEY" -p "$REMOTE_SERVER_PORT" "$REMOTE_SERVER_USER@$REMOTE_SERVER_HOST" << EOF
    # 원격 DB 연결 확인
    if ! PGPASSWORD=$REMOTE_DB_PASSWORD psql -h $REMOTE_DB_HOST -p $REMOTE_DB_PORT -U $REMOTE_DB_USER -d $REMOTE_DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
        echo "❌ 원격 DB 연결 실패"
        exit 1
    fi
    
    echo "✅ 원격 DB 연결 성공"
    
    # 기존 데이터 백업 (선택사항)
    BACKUP_FILE="/tmp/ansible_checks_backup_\$(date +%Y%m%d_%H%M%S).sql"
    echo "📋 기존 데이터 백업 중..."
    PGPASSWORD=$REMOTE_DB_PASSWORD pg_dump -h $REMOTE_DB_HOST -p $REMOTE_DB_PORT -U $REMOTE_DB_USER -d $REMOTE_DB_NAME \
        --clean --if-exists --no-owner --no-acl \
        > "\$BACKUP_FILE" 2>/dev/null || echo "⚠️  백업 실패 (계속 진행)"
    
    # 덤프 파일 복원
    echo "🔄 DB 복원 중..."
    PGPASSWORD=$REMOTE_DB_PASSWORD psql -h $REMOTE_DB_HOST -p $REMOTE_DB_PORT -U $REMOTE_DB_USER -d $REMOTE_DB_NAME \
        < "$REMOTE_DUMP_FILE" > /dev/null 2>&1
    
    if [ \$? -eq 0 ]; then
        echo "✅ DB 복원 완료"
        
        # 데이터 확인
        RECORD_COUNT=\$(PGPASSWORD=$REMOTE_DB_PASSWORD psql -h $REMOTE_DB_HOST -p $REMOTE_DB_PORT -U $REMOTE_DB_USER -d $REMOTE_DB_NAME -t -c "SELECT COUNT(*) FROM check_results;" 2>/dev/null | tr -d ' ')
        echo "📊 복원된 레코드 수: \$RECORD_COUNT"
    else
        echo "❌ DB 복원 실패"
        exit 1
    fi
    
    # 임시 파일 정리
    rm -f "$REMOTE_DUMP_FILE"
    echo "✅ 임시 파일 정리 완료"
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 마이그레이션 완료!${NC}"
else
    echo -e "${RED}❌ 마이그레이션 실패${NC}"
    exit 1
fi
echo ""

# 로컬 임시 파일 정리
rm -f "$DUMP_FILE"
echo -e "${GREEN}✅ 로컬 임시 파일 정리 완료${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}마이그레이션 완료!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "원격 서버 DB 정보:"
echo "  - 호스트: $REMOTE_SERVER_HOST"
echo "  - 데이터베이스: $REMOTE_DB_NAME"
echo "  - 사용자: $REMOTE_DB_USER"
echo ""
