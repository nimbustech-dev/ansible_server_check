#!/bin/bash
# 현재 브랜치의 파일을 네이버 클라우드 서버에 배포

set -e

# 서버 정보
SERVER_HOST="27.96.129.114"
SERVER_PORT="4433"
SERVER_USER="root"
SSH_KEY="/home/sth0824/.ssh/nimso2026.pem"
REMOTE_DIR="/opt/ansible-monitoring"

# 색상 출력
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 현재 브랜치 확인
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}네이버 클라우드 서버 배포${NC}"
echo -e "${GREEN}현재 브랜치: ${CURRENT_BRANCH}${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 1. SSH 접속 테스트
echo -e "${YELLOW}[1/4] SSH 접속 테스트...${NC}"
if ! ssh -i "$SSH_KEY" -p "$SERVER_PORT" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_HOST" "echo 'SSH 연결 성공'" > /dev/null 2>&1; then
    echo -e "${RED}❌ SSH 접속 실패 (핫스팟 연결 확인 필요)${NC}"
    exit 1
fi
echo -e "${GREEN}✅ SSH 접속 성공${NC}"
echo ""

# 2. 프로젝트 파일 업로드
echo -e "${YELLOW}[2/4] 프로젝트 파일 업로드...${NC}"
rsync -avz -e "ssh -i $SSH_KEY -p $SERVER_PORT" \
    --exclude='venv' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.git' \
    --exclude='check_results.db' \
    --exclude='*.log' \
    ./api_server/ "$SERVER_USER@$SERVER_HOST:$REMOTE_DIR/api_server/"

echo -e "${GREEN}✅ 파일 업로드 완료${NC}"
echo ""

# 3. 서비스 재시작
echo -e "${YELLOW}[3/4] API 서버 재시작...${NC}"
ssh -i "$SSH_KEY" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" << 'EOF'
    systemctl restart ansible-api-server
    sleep 3
    
    # 상태 확인
    systemctl status ansible-api-server --no-pager | head -10
EOF
echo ""

# 4. 최종 확인
echo -e "${YELLOW}[4/4] 배포 확인...${NC}"
sleep 2
if curl -s --connect-timeout 5 http://115.85.181.103:8000/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 배포 완료!${NC}"
    echo ""
    echo "서버 정보:"
    echo "  - 브랜치: $CURRENT_BRANCH"
    echo "  - API 서버: http://115.85.181.103:8000"
    echo "  - 리포트: http://115.85.181.103:8000/api/report"
else
    echo -e "${RED}⚠️  서버 응답 확인 실패 (서버가 시작 중일 수 있음)${NC}"
fi
echo ""
