# Ansible 기반 서버 점검 자동화 시스템

Ansible로 **OS / WAS(Tomcat) / DB(MariaDB, PostgreSQL, CUBRID)** 점검을 수행하고, 결과를 **FastAPI 기반 API 서버**로 수집하여 **DB에 적재**한 뒤 **웹 리포트(테이블/차트/상세보기)** 형태로 조회할 수 있는 점검 자동화 시스템입니다.

---

## 주요 기능

- **점검 자동화**: Ansible 플레이북으로 OS/WAS/DB 점검 수행
- **결과 수집/중앙 저장**: 공통 역할이 JSON 결과를 API 서버로 전송 → DB 저장
- **리포트 제공**: 필터/검색/통계/일별 추이/상세 모달(원본 JSON 포함)

---

## 기술 스택

- **Automation**: Ansible
- **Backend**: FastAPI (Python)
- **DB**: SQLite(기본) / PostgreSQL(권장)
- **Frontend**: HTML/CSS/JavaScript + Chart.js
- **Realtime**: WebSocket(새 결과 반영 트리거)

---

## 동작 흐름(파이프라인)

1) `ansible-playbook` 실행  
2) 대상 서버에서 점검 수행 및 결과 수집  
3) `common/roles/api_sender`가 결과를 JSON으로 구성해 API 서버로 전송  
4) FastAPI가 결과를 DB에 저장  
5) 리포트 페이지가 API에서 데이터를 조회해 테이블/차트를 렌더링 (행 클릭 시 상세 모달)

---

## 빠른 시작(최소 실행)

### 0) 요구사항

- Python 3.8+
- Ansible 2.9+

### 1) API 서버 준비 및 실행

API 서버는 기본값으로 **SQLite(`api_server/check_results.db`)** 를 사용합니다.  
운영 환경에서는 `api_server/.env`의 `DATABASE_URL`로 PostgreSQL을 권장합니다.

```bash
cd api_server
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

실행(스크립트 권장):

```bash
chmod +x start_api_server.sh
./start_api_server.sh
```

### 2) 점검 실행(Ansible)

```bash
# OS
ansible-playbook -i inventory redhat_check/redhat_check.yml

# WAS(Tomcat)
ansible-playbook -i inventory tomcat_check/tomcat_check.yml

# DB
ansible-playbook -i inventory mariadb_check/mariadb_check.yml
ansible-playbook -i inventory postgresql_check/postgresql_check.yml
ansible-playbook -i inventory cubrid_check/cubrid_check.yml
```

### 3) 결과 확인(리포트/문서 경로)

아래는 **API 서버 기준 경로**입니다(실행 중인 API 서버 호스트/포트에 접속):

- **루트 경로**: `/` → 대시보드로 자동 리다이렉트
- **대시보드**: `/api/dashboard` (메인 대시보드 - DB/OS/WAS 통합)
- **통합 리포트**: `/api/report`
- **DB 리포트**: `/api/db-checks/report`
- **OS 리포트**: `/api/os-checks/report`
- **WAS 리포트**: `/api/was-checks/report`
- **JSON 뷰어**: `/api/json-viewer`
- **Swagger(API 문서)**: `/docs`

**배포된 서버 접속 예시:**
- 대시보드: `http://115.85.181.103:8000/api/dashboard`
- 루트 접속: `http://115.85.181.103:8000/` (자동으로 대시보드로 이동)

---

## 설정 파일(중요)

### `config/api_config.yml` (Ansible → API 전송 설정)

- `api_server.url`: 점검 결과를 수신할 API 엔드포인트(반드시 `/api/checks` 포함)
- `default_checker`: 기본 담당자(팀원별 변경 가능)

현재 파일 예시(실제 파일을 수정해서 사용):

```yaml
api_server:
  url: "<API_SERVER_URL>/api/checks"
  timeout: 60
  retry_count: 5

default_checker: "성태환"
```

### `inventory`, `hosts.ini` (점검 대상 정의)

- `inventory`: 로컬/개발용 그룹 예시가 포함된 Ansible 인벤토리 파일
- `hosts.ini`: 특정 원격 서버 SSH 접속 정보 예시(필요 시 별도 인벤토리로 분리 권장)

원격 점검 시 예:

```bash
ansible-playbook -i hosts.ini redhat_check/redhat_check.yml
```

---

## 디렉터리 구조(현재 프로젝트 기준)

```text
ansible/
  api_server/                    FastAPI 서버 + 리포트 템플릿
  common/roles/api_sender/        점검 결과 JSON 구성 + API 전송 공통 역할
  redhat_check/                   OS 점검
  tomcat_check/                   WAS(Tomcat) 점검
  mariadb_check/                  MariaDB 점검
  postgresql_check/               PostgreSQL 점검
  cubrid_check/                   CUBRID 점검

  config/api_config.yml           API 전송 대상/타임아웃/재시도/기본 담당자
  inventory                        Ansible 인벤토리(로컬/개발 예시 포함)
  hosts.ini                        원격 서버 인벤토리 예시
```

---

## Ansible 플레이북 설명

이 프로젝트의 점검은 **플레이북(실행 진입점) + 역할(Role, 실제 점검 로직)** 구조로 구성되어 있습니다.

### 플레이북(Entry Point)

- `redhat_check/redhat_check.yml`: **OS 점검** 실행 플레이북
- `tomcat_check/tomcat_check.yml`: **WAS(Tomcat) 점검** 실행 플레이북
- `mariadb_check/mariadb_check.yml`: **MariaDB 점검** 실행 플레이북
- `postgresql_check/postgresql_check.yml`: **PostgreSQL 점검** 실행 플레이북
- `cubrid_check/cubrid_check.yml`: **CUBRID 점검** 실행 플레이북

각 플레이북은 공통적으로 다음 흐름을 갖습니다.

- **대상 서버 선택**: `-i inventory` 또는 `-i hosts.ini`로 호스트/그룹 결정
- **점검 수행**: 각 점검 디렉터리의 `roles/<role>/tasks/main.yml`에서 실제 점검 실행
- **결과 전송**: `common/roles/api_sender`를 호출해 결과(JSON)를 API 서버로 전송

### Role(점검 로직) 구조

점검 항목을 수정/추가할 때는 보통 아래 파일을 수정합니다.

- `*/roles/*/tasks/main.yml`: 실제 점검 명령 실행, 출력 수집/가공
- `common/roles/api_sender/tasks/main.yml`: 결과 JSON 구성 및 API 전송(공통)

### 실행 예시

```bash
# 인벤토리(그룹) 기반 실행
ansible-playbook -i inventory redhat_check/redhat_check.yml

# 특정 인벤토리 파일 기반(원격 서버) 실행
ansible-playbook -i hosts.ini tomcat_check/tomcat_check.yml
```

---

## `api_server/` 내부 주요 파일

- `main.py`: API 엔드포인트, 리포트 서빙, 결과 포맷팅
- `database.py`: DB 연결/저장/조회
- `models.py`: 테이블 모델
- `config.py`: `DATABASE_URL` 기본값(SQLite) 등 설정
- `report_template.html`: DB 리포트 UI
- `os_report_template.html`: OS 리포트 UI
- `was_report_template.html`: WAS 리포트 UI
- `unified_report_template.html`: 통합 리포트 UI
- `migrate_to_postgresql.py`: DB 마이그레이션 보조 스크립트
- `query_db.py`: DB 조회 보조 스크립트

---

## 운영/편의 스크립트(현재 존재하는 파일 기준)

### API/DB 시작·종료

- `start_api_server.sh` / `stop_api_server.sh`
- `start_db_server.sh` / `stop_db_server.sh`
- `restart_db_server.sh`

### 자동 업데이트(운영 보조)

- `auto_update_smart.sh`
- `auto_update_and_restart.sh`

### Windows/PowerShell 보조

- `run_was_check.ps1`, `run_was_check.bat`
- `restart_api_server.ps1`
- `check_api_status.ps1`

### 로그/상태 파일

- `api_server.log`: API 서버 로그
- `api_auto_update.log`: 자동 업데이트 로그
- `api_server.pid`: API 서버 PID 파일

---

## 트러블슈팅(자주 막히는 포인트)

자세한 트러블슈팅 가이드는 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)를 참고하세요.

- **결과가 안 올라감**: `config/api_config.yml`의 `api_server.url`이 올바른지(특히 `/api/checks`) 확인
- **API 서버가 안 뜸**: `api_server.log` 확인
- **SSH 접속 실패**: 대상 서버 SSH 포트/방화벽/계정/키 권한 확인

---

## 사용된 라이브러리 및 오픈소스

이 프로젝트는 다음 오픈소스 라이브러리를 사용합니다:

### Backend (Python)

- **[FastAPI](https://fastapi.tiangolo.com/)** (v0.104.1) - MIT License
  - 고성능 웹 프레임워크
  - GitHub: https://github.com/tiangolo/fastapi

- **[Uvicorn](https://www.uvicorn.org/)** (v0.24.0) - BSD License
  - ASGI 서버
  - GitHub: https://github.com/encode/uvicorn

- **[Pydantic](https://docs.pydantic.dev/)** (v2.5.0) - MIT License
  - 데이터 검증 라이브러리
  - GitHub: https://github.com/pydantic/pydantic

- **[SQLAlchemy](https://www.sqlalchemy.org/)** (v2.0.23) - MIT License
  - ORM 및 데이터베이스 툴킷
  - GitHub: https://github.com/sqlalchemy/sqlalchemy

- **[python-multipart](https://github.com/andrew-d/python-multipart)** (v0.0.6) - Apache 2.0 License
  - 멀티파트 폼 데이터 파싱
  - GitHub: https://github.com/andrew-d/python-multipart

- **[requests](https://requests.readthedocs.io/)** (v2.31.0) - Apache 2.0 License
  - HTTP 라이브러리
  - GitHub: https://github.com/psf/requests

- **[psycopg2-binary](https://www.psycopg.org/)** (v2.9.9) - LGPL/PostgreSQL License
  - PostgreSQL 어댑터 (선택사항)
  - GitHub: https://github.com/psycopg/psycopg2

### Frontend (JavaScript)

- **[Chart.js](https://www.chartjs.org/)** (v4.4.0) - MIT License
  - 차트 및 그래프 라이브러리
  - CDN: https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js
  - GitHub: https://github.com/chartjs/Chart.js

### Automation

- **[Ansible](https://www.ansible.com/)** (v2.9+) - GPLv3 License
  - 인프라 자동화 도구
  - GitHub: https://github.com/ansible/ansible

---

**마지막 업데이트**: 2026년 1월 16일

## 👤 작성자

- **성태환**
