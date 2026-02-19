#!/bin/bash
# 관리자 콘솔에서 등록한 서버(API 동적 inventory)로 Ansible 점검 실행
# 환경변수: API_BASE_URL(기본 http://localhost:8000), INVENTORY_API_KEY(필수, .env 또는 export)
# 사용법: INVENTORY_API_KEY=your-key ./run_checks_from_api.sh
# 또는 api_server/.env에 INVENTORY_API_KEY 설정 후, 해당 디렉터리에서 로드하거나 export 후 실행

set -e

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# API 주소 (배포 서버에서 실행 시 localhost, 원격이면 URL 지정)
API_BASE_URL="${API_BASE_URL:-http://localhost:8000}"
INV_FILE="$SCRIPT_DIR/.inventory_from_api.json"

# INVENTORY_API_KEY가 없으면 api_server/.env에서 시도
if [ -z "$INVENTORY_API_KEY" ] && [ -f "$SCRIPT_DIR/api_server/.env" ]; then
  while IFS= read -r line; do
    [[ "$line" =~ ^INVENTORY_API_KEY=(.*)$ ]] && INVENTORY_API_KEY="${BASH_REMATCH[1]}" && break
  done < "$SCRIPT_DIR/api_server/.env"
  INVENTORY_API_KEY=$(echo "$INVENTORY_API_KEY" | sed 's/^["'\'']//;s/["'\'']$//')
fi

if [ -z "$INVENTORY_API_KEY" ]; then
  echo "INVENTORY_API_KEY가 필요합니다. api_server/.env에 넣거나 export 하세요."
  exit 1
fi

echo "동적 inventory 가져오는 중: $API_BASE_URL/api/inventory"
HTTP=$(curl -s -w "%{http_code}" -o "$INV_FILE" -H "X-API-Key: $INVENTORY_API_KEY" "$API_BASE_URL/api/inventory" 2>/dev/null || echo "000")

if [ "$HTTP" != "200" ]; then
  echo "inventory 조회 실패 (HTTP $HTTP). API 서버 및 INVENTORY_API_KEY 확인."
  exit 1
fi

if [ ! -s "$INV_FILE" ]; then
  echo "inventory가 비었습니다. 관리자에서 점검 대상 서버를 추가하세요."
  exit 1
fi

# 호스트 수 확인 (all.hosts 배열 길이)
HOSTS_COUNT=$(python3 -c "import json; d=json.load(open('$INV_FILE')); print(len(d.get('all',{}).get('hosts',[])))" 2>/dev/null || echo "0")
if [ "$HOSTS_COUNT" = "0" ]; then
  echo "점검 대상 서버가 없습니다. 관리자 콘솔에서 서버 추가 후 점검 대상을 활성화하세요."
  exit 1
fi

echo "점검 대상 $HOSTS_COUNT 대. playbook 실행 중..."

run() {
  local name="$1"
  local playbook="$2"
  if [ ! -f "$SCRIPT_DIR/$playbook" ]; then
    echo "건너뜀: $playbook 없음"
    return 0
  fi
  echo "--- $name ---"
  if ansible-playbook -i "$INV_FILE" "$SCRIPT_DIR/$playbook"; then
    echo "OK: $name"
  else
    echo "실패: $name"
    return 1
  fi
}

FAIL=0
run "OS (Redhat)" "redhat_check/redhat_check.yml" || FAIL=1
run "MariaDB" "mariadb_check/mariadb_check.yml" || FAIL=1
run "PostgreSQL" "postgresql_check/postgresql_check.yml" || FAIL=1
run "Tomcat" "tomcat_check/tomcat_check.yml" || FAIL=1

[ $FAIL -eq 0 ] && echo "모든 점검 완료." || echo "일부 점검 실패."
exit $FAIL
