# 트러블슈팅 가이드

이 문서는 Ansible 모니터링 시스템 배포 및 운영 중 발생할 수 있는 문제와 해결 방법을 정리합니다.

## 목차

1. [대시보드 접속 불가 문제](#대시보드-접속-불가-문제)
2. [API 서버 시작 실패](#api-서버-시작-실패)
3. [PostgreSQL 인증 실패](#postgresql-인증-실패)
4. [자동 점검 스크립트 실행 실패](#자동-점검-스크립트-실행-실패)
5. [Ansible 로케일 경고](#ansible-로케일-경고)

---

## 대시보드 접속 불가 문제

### 증상

브라우저에서 `http://115.85.181.103:8000/api/dashboard`에 접속 시 다음 오류 발생:
- `ERR_CONNECTION_REFUSED`
- "사이트에 연결할 수 없음"
- "115.85.181.103에서 연결을 거부했습니다."

### 원인 진단

1. **API 서버 상태 확인**
   ```bash
   ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 "systemctl status ansible-api-server"
   ```

2. **포트 리스닝 확인**
   ```bash
   ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 "ss -tlnp | grep 8000"
   ```

3. **서버 로그 확인**
   ```bash
   ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 "journalctl -u ansible-api-server -n 50"
   ```

### 해결 방법

대부분의 경우 API 서버가 시작되지 않아 발생합니다. 아래 "API 서버 시작 실패" 섹션을 참고하여 해결하세요.

---

## API 서버 시작 실패

### 증상

- `systemctl status ansible-api-server`에서 서비스가 `active (running)`이지만 포트가 열리지 않음
- 로그에 `Application startup failed. Exiting.` 메시지
- 포트 8000이 리스닝되지 않음

### 원인

주로 데이터베이스 연결 실패로 인해 발생합니다.

### 해결 방법

#### 1단계: 로그 확인

```bash
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 "journalctl -u ansible-api-server -n 100 | grep -i error"
```

#### 2단계: 데이터베이스 연결 확인

PostgreSQL 연결 실패인 경우 아래 "PostgreSQL 인증 실패" 섹션을 참고하세요.

#### 3단계: 서버 재시작

```bash
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 "systemctl restart ansible-api-server"
sleep 3
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 "systemctl status ansible-api-server"
```

---

## PostgreSQL 인증 실패

### 증상

API 서버 로그에 다음 오류 메시지:
```
sqlalchemy.exc.OperationalError: (psycopg2.OperationalError) 
connection to server at "localhost" (127.0.0.1), port 5432 failed: 
FATAL: password authentication failed for user "ansible_user"
```

### 원인

1. PostgreSQL 사용자 비밀번호가 변경됨
2. `.env` 파일의 비밀번호와 실제 비밀번호가 불일치
3. PostgreSQL 인증 설정 문제

### 해결 방법

#### 1단계: PostgreSQL 사용자 및 데이터베이스 확인

```bash
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 "sudo -u postgres psql -c \"SELECT usename FROM pg_user WHERE usename='ansible_user';\""
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 "sudo -u postgres psql -c \"SELECT datname FROM pg_database WHERE datname='ansible_checks';\""
```

#### 2단계: 비밀번호 재설정

```bash
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 "sudo -u postgres psql -c \"ALTER USER ansible_user WITH PASSWORD 'nimbus1234';\""
```

**주의:** 비밀번호는 `.env` 파일의 `DATABASE_URL`과 일치해야 합니다.

#### 3단계: 연결 테스트

```bash
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 "PGPASSWORD=nimbus1234 psql -h 127.0.0.1 -U ansible_user -d ansible_checks -c 'SELECT COUNT(*) FROM check_results;'"
```

#### 4단계: `.env` 파일 확인

```bash
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 "cat /opt/ansible-monitoring/api_server/.env"
```

`.env` 파일 내용 예시:
```
DATABASE_URL=postgresql://ansible_user:nimbus1234@localhost:5432/ansible_checks
```

#### 5단계: API 서버 재시작

```bash
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 "systemctl restart ansible-api-server"
sleep 3
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 "systemctl status ansible-api-server"
```

#### 6단계: 최종 확인

```bash
# 포트 리스닝 확인
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 "ss -tlnp | grep 8000"

# 로컬에서 연결 테스트
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 "curl -s http://127.0.0.1:8000/api/health"
```

### 예방 방법

1. PostgreSQL 비밀번호 변경 시 `.env` 파일도 함께 업데이트
2. 정기적으로 데이터베이스 연결 상태 모니터링
3. 비밀번호는 안전하게 관리 (환경 변수 또는 비밀번호 관리 도구 사용)

---

## 자동 점검 스크립트 실행 실패

### 증상

- Crontab에 등록되어 있지만 점검이 실행되지 않음
- 수동 실행 시 모든 점검이 실패 (종료 코드: 1)
- 로그에 `ERROR: Ansible could not initialize the preferred locale` 메시지

### 원인

1. Ansible 로케일 설정 문제
2. 스크립트 실행 권한 없음
3. SSH 키 권한 문제

### 해결 방법

#### 1단계: 로케일 설정 추가

`auto_check_navercloud.sh` 파일 상단에 다음 내용 추가:

```bash
#!/bin/bash
# 로케일 설정 (Ansible 경고 방지)
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
```

#### 2단계: 스크립트 업데이트 및 배포

```bash
# 로컬에서 수정 후
cd /home/sth0824/ansible
sed -i 's/\r$//' auto_check_navercloud.sh  # CRLF 제거 (Windows에서 편집한 경우)
rsync -avz -e "ssh -i ~/.ssh/nimso2026.pem -p 4433" \
    ./auto_check_navercloud.sh root@27.96.129.114:/opt/ansible-monitoring/
```

#### 3단계: 실행 권한 확인

```bash
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "chmod +x /opt/ansible-monitoring/auto_check_navercloud.sh"
```

#### 4단계: SSH 키 권한 확인

```bash
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "ls -la /opt/ansible-monitoring/.ssh/nimso2026.pem"
# 권한이 600이어야 함
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "chmod 600 /opt/ansible-monitoring/.ssh/nimso2026.pem"
```

#### 5단계: 수동 테스트

```bash
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "cd /opt/ansible-monitoring && timeout 180 ./auto_check_navercloud.sh 2>&1 | tail -30"
```

#### 6단계: Crontab 확인

```bash
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 "crontab -l | grep auto_check"
```

예상 출력:
```
0 7 * * * cd /opt/ansible-monitoring && /opt/ansible-monitoring/auto_check_navercloud.sh >> /opt/ansible-monitoring/logs/navercloud_cron.log 2>&1
```

---

## Ansible 로케일 경고

### 증상

Ansible 실행 시 다음 경고 메시지:
```
ERROR: Ansible could not initialize the preferred locale: unsupported locale setting
```

### 원인

시스템 로케일이 설정되지 않았거나 UTF-8 로케일이 설치되지 않음

### 해결 방법

#### 방법 1: 스크립트에서 환경 변수 설정 (권장)

점검 스크립트 상단에 다음 추가:
```bash
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
```

#### 방법 2: 시스템 로케일 설정

```bash
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 << 'EOF'
# 로케일 생성 (필요한 경우)
localedef -i en_US -f UTF-8 en_US.UTF-8

# 시스템 로케일 설정
echo 'export LC_ALL=en_US.UTF-8' >> /etc/profile
echo 'export LANG=en_US.UTF-8' >> /etc/profile
EOF
```

**주의:** 방법 1이 더 안전하고 간단합니다. 스크립트 레벨에서만 적용되므로 시스템 설정에 영향을 주지 않습니다.

---

## Cron에서 자동 점검 실패 (exit code 127)

### 증상
- Crontab에는 매일 오전 7시 실행으로 설정되어 있음
- `navercloud_cron.log`에 07:00:01 실행 기록은 있으나, 모든 점검이 **종료 코드 127**로 실패
- OS / MariaDB / PostgreSQL / Tomcat 모두 "점검 실패 (종료 코드: 127, 소요 시간: 0초)"

### 원인
Cron은 **제한된 환경**에서 실행됩니다. `PATH`에 `/usr/local/bin`이 없어 `ansible-playbook`을 찾지 못함 (127 = command not found).

### 해결
`auto_check_navercloud.sh` **맨 위**(set -e 다음)에 PATH 추가:

```bash
# Cron 환경에서 PATH 제한됨 → ansible-playbook 등 명령어를 찾을 수 있도록 설정
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH"
```

수정 후 서버에 스크립트 다시 배포:

```bash
rsync -avz -e "ssh -i ~/.ssh/nimso2026.pem -p 4433" ./auto_check_navercloud.sh root@27.96.129.114:/opt/ansible-monitoring/
```

### 확인
- 다음날 오전 7시 이후 `navercloud_cron.log` 또는 `navercloud_check_YYYYMMDD.log`에서 성공 메시지 확인
- 대시보드에서 해당 날짜/시간대 점검 결과 노출 여부 확인

---

## Cron에서 자동 점검 실패 (exit code 4)

### 증상
- 스크립트는 실행되나 OS / MariaDB / PostgreSQL / Tomcat 모두 **종료 코드 4**로 실패
- 각 점검에 60~100초 정도 소요 후 실패

### 원인
Ansible **exit code 4** = "one or more hosts were unreachable".  
`hosts.ini.server`에 **dongguk_server1**(192.168.0.23)이 포함되어 있는데, 네이버 클라우드 서버에서 해당 IP로 연결이 안 되면 전체 playbook이 실패합니다.

### 해결
`auto_check_navercloud.sh`에서 **동국대 서버 연결 가능 여부를 먼저 확인**하고, 연결 불가 시 **nimbus-server만** 점검하도록 변경:

- `ansible dongguk_server1 -m ping`으로 연결 테스트 (타임아웃 10초)
- 성공 시: `LIMIT_TARGET="nimbus-server,dongguk_server1"`
- 실패 시: `LIMIT_TARGET="nimbus-server"` (네이버 클라우드만 점검)

이렇게 하면 동국대 네트워크가 준비되기 전에도 **nimbus-server 자동 점검은 매일 오전 7시에 정상 수행**됩니다.

---

## PostgreSQL 점검만 실패 (exit code 2, task timeout)

### 증상
- OS / MariaDB / Tomcat은 성공, **PostgreSQL만** "점검 실패 (종료 코드: 2)"
- 서버에서 수동 실행 시: `The shell action failed to execute in the expected time frame (10) and was terminated`

### 원인
1. **Ansible task 타임아웃**: PostgreSQL role의 일부 shell 태스크에 `timeout: 10`(초)이 걸려 있음.
2. **"Get PostgreSQL log directory"** 등에서 `psql`을 여러 번 실행(먼저 `postgres` 사용자, 실패 시 `ansible_user` 재시도)하는데, SSH로 자기 자신(127.0.0.1)을 점검할 때 연결이 느려 10초 안에 끝나지 않음.
3. 타임아웃으로 태스크가 중단되면 playbook이 실패하고 **exit code 2** 반환.

### 해결 (적용된 수정)
1. **`postgresql_check.yml`**: `postgresql_task_timeout`을 **10 → 60초**로 증가.
2. **`roles/postgresql_check/tasks/main.yml`**  
   - "Get PostgreSQL log directory" / "Check system log filesystem usage"에서 **`ansible_user`를 먼저** 사용하고, 실패 시에만 `postgres` 사용자 시도.  
   - 각 `psql` 호출에 `timeout 8` 초를 걸어 한 호출이 무한히 걸리지 않도록 함.

이후 서버에 `postgresql_check` 디렉터리를 다시 배포하고, 자동 점검 스크립트 또는 `ansible-playbook ... postgresql_check.yml`으로 재실행해 보면 됨.

---

## 기타 문제

### 문제: CRLF 줄바꿈 문제

#### 증상
스크립트 실행 시:
```
: command not found
: invalid option
```

#### 해결
```bash
# 로컬에서
sed -i 's/\r$//' 스크립트파일.sh

# 또는 서버에서
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "sed -i 's/\r$//' /opt/ansible-monitoring/auto_check_navercloud.sh"
```

### 문제: 점검 결과 요약 로직 오류

#### 증상
점검은 성공했지만 요약에서 실패로 표시됨

#### 해결
`auto_check_navercloud.sh`의 결과 추적 로직을 개별 점검별로 수정:
- 각 점검의 성공/실패를 개별 변수에 저장
- 요약 시 각 변수를 개별적으로 확인

---

## 유용한 명령어 모음

### 서버 상태 확인

```bash
# API 서버 상태
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "systemctl status ansible-api-server"

# 포트 리스닝 확인
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "ss -tlnp | grep 8000"

# PostgreSQL 상태
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "systemctl status postgresql"

# 최근 점검 로그
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "tail -50 /opt/ansible-monitoring/logs/navercloud_check_$(date +%Y%m%d).log"
```

### 데이터베이스 확인

```bash
# 데이터 개수 확인
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "PGPASSWORD=nimbus1234 psql -h 127.0.0.1 -U ansible_user -d ansible_checks -c 'SELECT COUNT(*) FROM check_results;'"

# 최근 점검 결과 확인
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "PGPASSWORD=nimbus1234 psql -h 127.0.0.1 -U ansible_user -d ansible_checks -c \"SELECT check_type, hostname, status, check_time FROM check_results ORDER BY created_at DESC LIMIT 10;\""
```

### 서비스 재시작

```bash
# API 서버 재시작
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "systemctl restart ansible-api-server"

# PostgreSQL 재시작 (필요한 경우)
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "systemctl restart postgresql"
```

---

## 문제 보고

문제가 지속되거나 위의 해결 방법으로 해결되지 않는 경우:

1. 관련 로그 수집
   ```bash
   # API 서버 로그
   ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
       "journalctl -u ansible-api-server -n 100" > api_server.log
   
   # 점검 스크립트 로그
   ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
       "tail -100 /opt/ansible-monitoring/logs/navercloud_check_$(date +%Y%m%d).log" > check.log
   ```

2. 시스템 정보 수집
   ```bash
   ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
       "uname -a; python3 --version; ansible-playbook --version" > system_info.txt
   ```

3. 문제 상황과 함께 로그 파일 제공

---

## 업데이트 이력

- **2026-01-28**: 초기 문서 작성
  - 대시보드 접속 불가 문제
  - API 서버 시작 실패
  - PostgreSQL 인증 실패
  - 자동 점검 스크립트 실행 실패
  - Ansible 로케일 경고
