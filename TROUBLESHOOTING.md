# 트러블슈팅

## 연결 거부 (사이트에 연결할 수 없음)

**증상**: "사이트에 연결할 수 없음", "115.85.181.103에서 연결을 거부했습니다" — 브라우저에서 접속 주소로 들어가면 연결 자체가 되지 않습니다.

아래 순서로 확인하세요.

### 1. 배포 대상과 접속 주소가 같은 서버인지 확인

- **배포 대상(SSH)**: `deploy_current_branch.sh`의 `SERVER_HOST` (예: 27.96.129.114) — 여기로 배포·재시작이 수행됩니다.
- **접속 주소**: `ACCESS_HOST` (예: 115.85.181.103) — 사용자가 브라우저로 접속하는 주소.

두 IP가 **같은 서버**(예: 하나는 공인 IP, 하나는 사설/내부 IP)인지, **서로 다른 서버**인지 먼저 구분하세요.

### 2. 같은 서버인 경우

1. **방화벽 / 네이버 클라우드 ACG(Access Control Group)**  
   - 8000 포트 **인바운드** 허용이 없으면 외부에서 연결할 수 없습니다.  
   - 조치: 네이버 클라우드 콘솔에서 해당 서버의 ACG(또는 방화벽)에 **TCP 8000 인바운드 허용**을 추가하세요.

2. **API 서버 기동 여부**  
   - 배포 대상 서버(27.96.129.114 등)에 SSH 접속한 뒤:
     - `systemctl status ansible-api-server` → `active (running)` 인지 확인.
     - `curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/health` → `200` 이 나오는지 확인.
   - 서비스가 없거나 실패하면 상단 "배포 후 확인" 절차와 `scripts/ansible-api-server.service` 설치 여부를 확인하세요.

3. **바인딩 주소**  
   - `scripts/ansible-api-server.service`는 `--host 0.0.0.0 --port 8000`으로 설정되어 있어, 같은 호스트라면 공인 IP로도 접속 가능해야 합니다.  
   - 예전에 `127.0.0.1`로만 띄운 유닛을 쓰고 있다면, 지금 사용하는 유닛이 `0.0.0.0`인지 확인하세요.

### 3. 다른 서버인 경우

API는 배포 대상(27.96.129.114)에서만 동작하고, 115.85.181.103에는 8000 포트를 열어둔 서비스가 없으면 **연결 거부**가 납니다.

- **접속 주소를 배포 서버로 사용**: 브라우저에서 `http://27.96.129.114:8000/api/dashboard` 로 접속. (27.96.129.114에서도 8000 인바운드 허용 필요.)
- **115.85.181.103 서버에 API 배포**: 접속 주소를 115.85.181.103으로 쓰려면 그 서버에 배포해야 합니다. `deploy_current_branch.sh`의 `SERVER_HOST`를 `115.85.181.103`으로 바꾸고, 해당 서버에 SSH 접속 가능한지 확인한 뒤 배포하세요.
- **포워딩**: 115.85.181.103에서 27.96.129.114:8000으로 포워딩(로드밸런서/리버스 프록시)하도록 네트워크·인프라를 설정하는 방법도 있습니다.

---

## 배포 후 확인 (페이지가 안 뜰 때)

배포 후 `http://115.85.181.103:8000/api/dashboard` 등 접속 주소로 페이지가 안 뜨면, 아래 순서로 확인하세요. **연결 거부/타임아웃**인지, **401/500 응답**인지 구분하면 원인 파악이 빠릅니다.

### 1. API 서버 프로세스 확인

배포한 서버(SSH로 접속하는 호스트)에서:

```bash
systemctl status ansible-api-server
```

- `active (running)` 이어야 합니다. 비활성이라면 `journalctl -u ansible-api-server -n 50` 로 로그를 확인하세요.

### 2. 서버 내부에서 헬스체크

같은 서버에서:

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/health
```

- `200`이 나오면 API 서버는 동작 중입니다.
- 연결 거부면 서비스가 안 떠 있거나 포트가 다릅니다.

### 3. 루트·대시보드 응답 확인

```bash
# 루트(리다이렉트)
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/

# 대시보드 (미인증 시 302 리다이렉트 → 로그인 페이지)
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/dashboard
```

- `/` → `302` (로그인 또는 대시보드로 리다이렉트)
- `/api/dashboard` → `302`(미인증, 로그인으로 이동) 또는 `200`(인증됨)

### 4. 접속 주소(공인 IP)에서 확인

로컬 PC나 다른 서버에서:

```bash
curl -s -o /dev/null -w "%{http_code}" http://115.85.181.103:8000/api/health
```

- `200`이면 방화벽/포트 포워딩이 정상입니다.
- 타임아웃/연결 거부면 방화벽, 포트 포워딩, 보안 그룹(네이버 클라우드 등)에서 8000 포트 허용 여부를 확인하세요.

### 5. DB 연결 확인 (PostgreSQL 사용 시)

API 서버가 PostgreSQL을 쓰는 경우, 같은 호스트에서:

```bash
# api_server/.env 의 DATABASE_URL 기준으로 접속 테스트
psql "postgresql://ansible_user:비밀번호@localhost:5432/ansible_checks" -c "SELECT 1"
```

- DB가 꺼져 있거나 연결 정보가 잘못되면 API 기동 시 실패하거나 요청 시 500이 날 수 있습니다.

---

## 관리자 페이지에서 500 (Internal Server Error)

**증상**: `/api/admin` 접속 시 페이지는 뜨지만 "Failed to load resource: 500" 또는 회원/서버 목록이 안 뜸.

**원인**: 배포 서버 DB 스키마가 최신이 아님 (회원 `role` 컬럼 없음, 또는 `servers` 테이블 없음).

**조치** (배포 서버에 SSH 접속 후):

1. **역할(role) 마이그레이션** (한 번만):
   ```bash
   cd /opt/ansible-monitoring/api_server
   ./venv/bin/python3 migrate_add_role.py
   ```
2. **API 서버 재시작** (새 테이블 반영 및 코드 적용):
   ```bash
   systemctl restart ansible-api-server
   ```
3. 브라우저에서 관리자 페이지 새로고침.

---

## ansible-api-server 서비스가 failed 상태일 때

**증상**: `systemctl status ansible-api-server` 에서 `Active: failed` 또는 `activating (auto-restart)` 이며, `code=exited, status=1/FAILURE` 가 보입니다.

1. **실제 오류 메시지 확인** (배포한 서버에 SSH 접속 후):
   ```bash
   journalctl -u ansible-api-server -n 80 --no-pager
   ```
   - Python 트레이스백이나 `ModuleNotFoundError`, `Connection refused`(DB) 등이 보이면 그에 맞게 조치하세요.

2. **PostgreSQL 사용 중인 경우**  
   - `api_server/.env` 의 `DATABASE_URL` 이 PostgreSQL을 가리키면, 해당 서버에서 PostgreSQL이 떠 있어야 합니다.
   - PostgreSQL 미기동 시: `systemctl start postgresql` (또는 해당 서비스명) 후 `systemctl restart ansible-api-server`.
   - DB/사용자/비밀번호가 맞는지 확인하고, 필요하면 `psql` 로 접속 테스트하세요.

3. **DB 초기화 실패해도 서비스는 기동하도록**  
   - 최신 코드는 DB 연결 실패 시에도 프로세스는 띄우고, `/api/health` 에서 `db: error` 로 알립니다.  
   - 한 번 다시 배포한 뒤 `systemctl restart ansible-api-server` 하고, 위 `journalctl` 로 남는 오류가 있는지 확인하세요.

---

## 자주 막히는 포인트

- **결과가 안 올라감**: `config/api_config.yml`의 `api_server.url` / `api_server.urls` 가 올바른지(특히 `/api/checks` 포함) 확인하세요.
- **API 서버가 안 뜸**: `api_server.log` 또는 `journalctl -u ansible-api-server` 로그를 확인하세요.
- **SSH 접속 실패**: 대상 서버 SSH 포트/방화벽/계정/키 권한을 확인하세요.
- **대시보드 주소로 들어가면 페이지가 안 뜸**: 미인증이면 로그인 페이지로 리다이렉트되도록 되어 있습니다. 여전히 빈 화면이면 위 1~4단계로 서버·네트워크를 확인하세요.
