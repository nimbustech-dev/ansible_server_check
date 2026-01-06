# Ansible 기반 서버 점검 자동화 시스템

Ansible을 활용한 인프라 모니터링 및 점검 자동화 시스템입니다. OS, WAS, DB 점검을 자동화하고, FastAPI와 PostgreSQL을 활용한 실시간 모니터링 대시보드를 제공합니다.

## 📋 목차

- [주요 기능](#주요-기능)
- [기술 스택](#기술-스택)
- [프로젝트 구조](#프로젝트-구조)
- [시작하기](#시작하기)
- [사용 방법](#사용-방법)
- [API 문서](#api-문서)
- [팀원 협업 가이드](#팀원-협업-가이드)

## ✨ 주요 기능

- ✅ **자동화된 서버 점검**: Ansible을 통한 OS, WAS, DB 점검 자동화
- ✅ **실시간 모니터링**: 웹 대시보드를 통한 점검 결과 실시간 확인
- ✅ **중앙 집중식 관리**: 모든 점검 결과를 PostgreSQL에 저장
- ✅ **담당자별 리포트**: OS 담당자, WAS 담당자별 맞춤 리포트 제공
- ✅ **통계 및 차트**: 점검 결과 통계, 일별 추이 차트 제공
- ✅ **필터링 및 검색**: 점검 유형, 호스트명, 담당자별 필터링

## 🛠 기술 스택

- **자동화**: Ansible
- **API 서버**: FastAPI (Python)
- **데이터베이스**: PostgreSQL
- **프론트엔드**: HTML, CSS, JavaScript (Chart.js)
- **실시간 통신**: WebSocket

## 📁 프로젝트 구조

```
ansible/
├── api_server/              # FastAPI 기반 API 서버
│   ├── main.py              # FastAPI 애플리케이션 메인 파일
│   ├── database.py          # 데이터베이스 연결 및 CRUD 작업
│   ├── models.py            # SQLAlchemy ORM 모델
│   ├── config.py            # 설정 파일
│   ├── report_template.html # DB 점검 결과 리포트 페이지
│   ├── os_report_template.html   # OS 점검 결과 리포트 페이지
│   ├── was_report_template.html  # WAS 점검 결과 리포트 페이지
│   ├── requirements.txt     # Python 의존성 패키지
│   └── .env                 # 환경 변수 설정
│
├── nimbus_check/            # Nimbus 서버 점검 플레이북
│   ├── os_check.yml         # OS 점검 플레이북
│   ├── was_check.yml        # WAS 점검 플레이북
│   ├── db_check.yml         # DB 점검 플레이북
│   └── system_check_v2.yml  # 시스템 종합 점검
│
├── mariadb_check/           # MariaDB 점검 플레이북
│   ├── mariadb_check.yml
│   └── roles/
│       └── mariadb_check/
│           ├── tasks/main.yml
│           └── templates/report.j2
│
├── postgresql_check/        # PostgreSQL 점검 플레이북
│   ├── postgresql_check.yml
│   └── roles/
│       └── postgresql_check/
│           ├── tasks/main.yml
│           └── templates/report.j2
│
├── cubrid_check/            # CUBRID 점검 플레이북
│   ├── cubrid_check.yml
│   └── roles/
│       └── cubrid_check/
│           ├── tasks/main.yml
│           └── templates/report.j2
│
├── common/                  # 공통 Ansible 역할
│   └── roles/
│       └── api_sender/      # API 서버로 결과 전송 역할
│           ├── tasks/main.yml
│           └── defaults/main.yml
│
├── config/                  # 설정 파일
│   └── api_config.yml        # API 서버 주소 및 설정
│
├── start_api_server.sh      # API 서버 시작 스크립트
├── stop_api_server.sh       # API 서버 종료 스크립트
├── setup_network_access.sh  # 네트워크 접근 설정 스크립트
└── setup_postgresql_remote_access.sh  # PostgreSQL 원격 접근 설정
│
└── 문서/
    ├── AI_CODING_REFERENCE.md          # AI 코딩 참고 정보
    ├── TEAM_MEMBER_API_GUIDE.md       # 팀원 API 사용 가이드
    ├── TEAM_NETWORK_SETUP.md          # 네트워크 설정 가이드
    └── NAVER_CLOUD_PIPELINE_SETUP.md  # 네이버 클라우드 연동 가이드
```

## 🚀 시작하기

### 사전 요구사항

- Python 3.8 이상
- Ansible 2.9 이상
- PostgreSQL 12 이상 (또는 SQLite)
- Git

### 1. 저장소 클론

```bash
git clone https://github.com/sth0824/ansible_server_check.git
cd ansible_server_check
git checkout develop
```

### 2. API 서버 설정

```bash
cd api_server

# 가상환경 생성 및 활성화
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# 또는
venv\Scripts\activate  # Windows

# 의존성 설치
pip install -r requirements.txt
```

### 3. 데이터베이스 설정

#### PostgreSQL 사용 (권장)

1. PostgreSQL 설치 및 데이터베이스 생성:
```sql
CREATE DATABASE ansible_checks;
CREATE USER ansible_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE ansible_checks TO ansible_user;
```

2. 환경 변수 설정 (`api_server/.env`):
```env
DATABASE_URL=postgresql://ansible_user:your_password@localhost:5432/ansible_checks
```

#### SQLite 사용 (개발용)

기본적으로 SQLite를 사용합니다. 별도 설정 불필요.

### 4. API 서버 실행

```bash
# 방법 1: 스크립트 사용 (권장)
cd ..
chmod +x start_api_server.sh
./start_api_server.sh

# 방법 2: 직접 실행
cd api_server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### 5. 서버 접속 확인

- API 서버: http://localhost:8000
- API 문서 (Swagger): http://localhost:8000/docs
- DB 점검 리포트: http://localhost:8000/api/db-checks/report
- OS 점검 리포트: http://localhost:8000/api/os-checks/report
- WAS 점검 리포트: http://localhost:8000/api/was-checks/report

## 📖 사용 방법

### Ansible 플레이북 실행

#### OS 점검

```bash
ansible-playbook -i inventory nimbus_check/os_check.yml
```

#### WAS 점검

```bash
ansible-playbook -i inventory nimbus_check/was_check.yml
```

#### MariaDB 점검

```bash
ansible-playbook -i inventory mariadb_check/mariadb_check.yml
```

#### PostgreSQL 점검

```bash
ansible-playbook -i inventory postgresql_check/postgresql_check.yml
```

### API 서버 설정

`config/api_config.yml` 파일에서 API 서버 주소를 설정:

```yaml
api_server:
  url: "http://localhost:8000/api/checks"
  timeout: 60
  retry_count: 5

default_checker: "담당자이름"
```

### Inventory 파일 설정

점검할 서버 정보를 `inventory` 파일에 추가:

```ini
[servers]
server1 ansible_host=192.168.1.100 ansible_user=root
server2 ansible_host=192.168.1.101 ansible_user=root
```

## 📡 API 문서

### 주요 엔드포인트

#### 1. 점검 결과 저장 (POST)

```http
POST /api/checks
Content-Type: application/json
```

**요청 본문:**
```json
{
  "check_type": "os",
  "hostname": "server01",
  "check_time": "2024-01-01T12:00:00",
  "checker": "홍길동",
  "status": "success",
  "results": {
    "cpu": "Intel Core i7",
    "memory": "8GB",
    "disk_usage": 75
  }
}
```

#### 2. 점검 결과 조회 (GET)

```http
GET /api/checks?check_type=os&limit=10
```

**쿼리 파라미터:**
- `check_type`: 점검 유형 필터 (os, was, mariadb, postgresql, cubrid)
- `hostname`: 호스트명 필터
- `checker`: 담당자 필터
- `limit`: 최대 조회 개수 (기본값: 100)

#### 3. 서버 상태 확인 (GET)

```http
GET /api/health
```

### 상세 API 문서

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## 👥 팀원 협업 가이드

### 새로운 팀원 온보딩

1. **저장소 클론 및 브랜치 확인**
   ```bash
   git clone https://github.com/sth0824/ansible_server_check.git
   cd ansible_server_check
   git checkout develop
   ```

2. **필수 문서 읽기**
   - `TEAM_MEMBER_API_GUIDE.md`: API 사용 가이드
   - `AI_CODING_REFERENCE.md`: AI 코딩 참고 정보
   - `TEAM_NETWORK_SETUP.md`: 네트워크 설정 가이드

3. **API 서버 설정**
   - `config/api_config.yml`에서 API 서버 주소 확인
   - 본인 PC에서 API 서버 접근 가능한지 확인

4. **점검 플레이북 실행**
   - 담당 점검 유형에 맞는 플레이북 실행
   - 결과가 API 서버로 전송되는지 확인

### 브랜치 전략

- `main`: 프로덕션/안정 버전
- `develop`: 개발 중인 코드 (기본 작업 브랜치)

### 커밋 규칙

- 커밋 메시지는 명확하게 작성
- 관련 이슈 번호가 있으면 포함

## 🔧 유지보수

### API 서버 재시작

```bash
./stop_api_server.sh
./start_api_server.sh
```

### 로그 확인

```bash
tail -f api_server.log
```

### 데이터베이스 백업

```bash
# PostgreSQL
pg_dump -U ansible_user ansible_checks > backup.sql

# SQLite
cp check_results.db backup.db
```

## 📚 추가 문서

- [AI 코딩 참고 정보](AI_CODING_REFERENCE.md)
- [팀원 API 사용 가이드](TEAM_MEMBER_API_GUIDE.md)
- [네트워크 설정 가이드](TEAM_NETWORK_SETUP.md)
- [네이버 클라우드 연동 가이드](NAVER_CLOUD_PIPELINE_SETUP.md)

## 🤝 기여하기

1. `develop` 브랜치에서 작업
2. 변경사항 커밋 및 푸시
3. Pull Request 생성 (필요시)

## 📝 라이선스

이 프로젝트는 회사 내부 사용을 위한 프로젝트입니다.

## 👤 작성자

- **성태환** - 초기 작업 및 유지보수

## 📞 문의

프로젝트 관련 문의사항이 있으시면 이슈를 생성해 주세요.

---

**마지막 업데이트**: 2026년 1월 6일

