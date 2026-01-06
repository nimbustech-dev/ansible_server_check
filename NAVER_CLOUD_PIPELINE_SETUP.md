# 네이버 클라우드 서버 점검 파이프라인 연결 가이드

## 📋 필요한 정보 체크리스트

### 1️⃣ 네이버 클라우드 서버 접속 정보

#### 필수 정보
- [ ] **서버 IP 주소** (공인 IP 또는 사설 IP)
  - 예: `123.456.789.0`
  - 네이버 클라우드 콘솔에서 확인 가능

- [ ] **SSH 포트** (기본: 22)
  - 예: `22` 또는 `2222` (커스텀 포트인 경우)

- [ ] **SSH 사용자명**
  - 예: `root`, `ubuntu`, `centos`, `admin` 등
  - 서버 OS에 따라 다름

- [ ] **인증 방법**
  - [ ] **방법 A: SSH 키 사용 (권장)**
    - SSH 개인키 파일 경로
    - 예: `~/.ssh/naver_cloud_key` 또는 `~/.ssh/id_rsa`
    - 공개키가 서버에 등록되어 있어야 함
  
  - [ ] **방법 B: 비밀번호 사용**
    - SSH 비밀번호
    - ⚠️ 보안상 권장하지 않음

#### 선택 정보
- [ ] **서버 호스트명** (선택사항)
  - 예: `web-server-01`, `db-server-01`
  - inventory에서 식별용으로 사용

- [ ] **서버 역할/용도** (선택사항)
  - 예: `web`, `db`, `app` 등
  - 그룹핑에 사용

---

### 2️⃣ 네트워크 및 보안 설정 정보

#### 네이버 클라우드 플랫폼 설정
- [ ] **보안 그룹 설정**
  - 인바운드 규칙: SSH 포트(22) 허용
  - 출발지: 본인 PC의 공인 IP 주소
  - 또는 특정 IP 대역

- [ ] **ACL 설정** (있는 경우)
  - 네트워크 ACL에서 SSH 포트 허용 확인

#### 로컬 네트워크 정보
- [ ] **본인 PC의 공인 IP 주소**
  - 네이버 클라우드 보안 그룹에 등록할 IP
  - 확인 방법: `curl ifconfig.me` 또는 `curl ipinfo.io/ip`

- [ ] **네이버 클라우드 서버에서 접근 가능한 API 서버 주소**
  - 현재 API 서버 IP: `172.26.145.21` (또는 공인 IP)
  - 포트: `8000`
  - 네이버 클라우드 서버에서 이 주소로 접근 가능해야 함

---

### 3️⃣ API 서버 접근 정보

#### API 서버 연결 정보
- [ ] **API 서버 주소**
  - 현재: `http://172.26.145.21:8000/api/checks`
  - 또는 공인 IP가 필요할 수 있음

- [ ] **API 서버 접근 가능 여부**
  - 네이버 클라우드 서버에서 API 서버로 접근 가능한지 확인 필요
  - 테스트: `curl http://172.26.145.21:8000/api/health`

#### 네트워크 접근 문제 해결
- [ ] **공인 IP 필요 여부**
  - 네이버 클라우드 서버가 사설 IP만 있다면:
    - API 서버를 공인 IP로 노출 필요
    - 또는 VPN/터널링 설정 필요

- [ ] **방화벽 설정**
  - API 서버 방화벽에서 포트 8000 허용 확인
  - 네이버 클라우드 보안 그룹에서 아웃바운드 규칙 확인

---

### 4️⃣ Ansible 설정 정보

#### Inventory 파일 구성
```ini
[naver_cloud]
# 형식: 서버명 ansible_host=IP주소 ansible_user=사용자명 ansible_port=포트 ansible_ssh_private_key_file=키경로

# 예시 1: SSH 키 사용
server1 ansible_host=123.456.789.0 ansible_user=root ansible_port=22 ansible_ssh_private_key_file=~/.ssh/naver_cloud_key

# 예시 2: 비밀번호 사용 (비권장)
# server2 ansible_host=123.456.789.1 ansible_user=ubuntu ansible_port=22 ansible_ssh_pass=비밀번호
```

#### 필요한 Ansible 설정
- [ ] **Ansible 설치 확인**
  - `ansible --version` 명령어로 확인

- [ ] **SSH 키 설정** (키 사용 시)
  - SSH 키 생성: `ssh-keygen -t rsa -b 4096 -f ~/.ssh/naver_cloud_key`
  - 공개키를 네이버 클라우드 서버에 복사
  - `ssh-copy-id -i ~/.ssh/naver_cloud_key.pub 사용자명@서버IP`

- [ ] **연결 테스트**
  - `ansible -i inventory naver_cloud -m ping`

---

### 5️⃣ 점검 플레이북 설정 정보

#### 점검 유형 선택
- [ ] **OS 점검**
  - 플레이북: `nimbus_check/os_check.yml`
  - 또는 `naver_cloud_os_check.yml` (만든 경우)

- [ ] **WAS 점검**
  - 플레이북: `nimbus_check/was_check.yml`

- [ ] **DB 점검** (MariaDB/PostgreSQL/CUBRID)
  - 플레이북: `mariadb_check/mariadb_check.yml`
  - 또는 `postgresql_check/postgresql_check.yml`

#### API 전송 설정
- [ ] **config/api_config.yml 파일 설정**
  ```yaml
  api_server:
    url: "http://172.26.145.21:8000/api/checks"  # API 서버 주소
    timeout: 60
    retry_count: 5
  
  default_checker: "성태환"  # 담당자 이름
  ```

- [ ] **플레이북에 API 전송 기능 포함 확인**
  - `post_tasks`에 `api_sender` role 포함되어 있는지 확인

---

### 6️⃣ 데이터베이스 접근 정보 (선택사항)

네이버 클라우드 서버에서 직접 DB에 접속하려는 경우:

- [ ] **PostgreSQL 접속 정보**
  - 호스트: `172.26.145.21`
  - 포트: `5432`
  - 데이터베이스: `ansible_checks`
  - 사용자: `ansible_user`
  - 비밀번호: (설정된 비밀번호)

- [ ] **DB 접속 가능 여부**
  - 네이버 클라우드 서버에서 접속 테스트 필요
  - `psql -h 172.26.145.21 -p 5432 -U ansible_user -d ansible_checks`

---

## 🔧 설정 단계별 체크리스트

### Step 1: 네이버 클라우드 서버 정보 수집
- [ ] 서버 IP 주소 확인
- [ ] SSH 포트 확인
- [ ] 사용자명 확인
- [ ] 인증 방법 결정 (키/비밀번호)

### Step 2: SSH 접속 설정
- [ ] SSH 키 생성 (키 사용 시)
- [ ] 공개키를 서버에 등록
- [ ] 직접 SSH 접속 테스트
- [ ] `ssh 사용자명@서버IP` 명령어로 접속 확인

### Step 3: 네이버 클라우드 보안 그룹 설정
- [ ] 네이버 클라우드 콘솔 접속
- [ ] 서버 선택 → 보안 그룹
- [ ] 인바운드 규칙: SSH 포트(22) 허용
- [ ] 출발지: 본인 PC 공인 IP 입력

### Step 4: Ansible Inventory 생성
- [ ] `naver_cloud_inventory` 파일 생성
- [ ] 서버 정보 입력
- [ ] `ansible -i naver_cloud_inventory naver_cloud -m ping` 테스트

### Step 5: API 서버 접근 확인
- [ ] 네이버 클라우드 서버에서 API 서버 접근 테스트
- [ ] `curl http://172.26.145.21:8000/api/health` 실행
- [ ] 접근 불가 시 공인 IP 또는 VPN 설정 필요

### Step 6: 점검 플레이북 실행
- [ ] `config/api_config.yml` 설정 확인
- [ ] 점검 플레이북 실행
- [ ] 결과 확인: 웹 대시보드에서 확인

---

## 📝 정보 수집 템플릿

아래 템플릿을 채워서 사용하세요:

```
=== 네이버 클라우드 서버 정보 ===
서버명: _______________
IP 주소: _______________
SSH 포트: _______________
사용자명: _______________
인증 방법: [ ] SSH 키  [ ] 비밀번호
키 경로: _______________ (키 사용 시)

=== 네트워크 정보 ===
본인 PC 공인 IP: _______________
API 서버 주소: http://172.26.145.21:8000/api/checks
API 서버 접근 가능: [ ] 예  [ ] 아니오

=== 점검 설정 ===
점검 유형: [ ] OS  [ ] WAS  [ ] DB
담당자명: _______________
```

---

## 🚨 주의사항

### 보안
1. **SSH 키 사용 권장**: 비밀번호보다 안전
2. **IP 제한**: 보안 그룹에서 특정 IP만 허용
3. **API 서버 보안**: 프로덕션에서는 인증 추가 권장

### 네트워크
1. **공인 IP 필요**: 네이버 클라우드 서버가 사설 IP만 있다면 API 서버 접근 불가
2. **방화벽**: 양방향 방화벽 설정 확인
3. **포트**: SSH(22), API(8000) 포트 허용 확인

### 테스트
1. **단계별 테스트**: 각 단계마다 테스트 후 다음 단계 진행
2. **연결 테스트**: SSH → Ansible → API 순서로 테스트
3. **로그 확인**: 문제 발생 시 로그 파일 확인

---

## 📞 문제 해결

### SSH 연결 실패
- 보안 그룹에서 SSH 포트 허용 확인
- SSH 키 권한 확인: `chmod 600 ~/.ssh/naver_cloud_key`
- 서버 방화벽 확인

### Ansible 연결 실패
- `ansible -i inventory naver_cloud -m ping -vvv` (상세 모드)
- SSH 직접 접속 테스트
- Inventory 파일 문법 확인

### API 전송 실패
- 네이버 클라우드 서버에서 API 서버 접근 가능한지 확인
- `curl http://172.26.145.21:8000/api/health` 테스트
- 공인 IP 필요 여부 확인

---

**마지막 업데이트**: 2026-01-05

