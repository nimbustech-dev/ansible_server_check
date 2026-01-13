# Ansible 점검 결과 수집 API 서버

FastAPI 기반으로 Ansible 점검 결과를 수집하고 데이터베이스에 저장하는 서버입니다.

## 기능

- ✅ 점검 결과 수신 및 저장 (POST /api/checks)
- ✅ 점검 결과 조회 (GET /api/checks)
- ✅ 필터링 지원 (점검 유형, 호스트명, 담당자별)
- ✅ 자동 API 문서 생성 (Swagger UI)

## 설치 및 실행

### 1. 의존성 설치

```bash
cd api_server
pip install -r requirements.txt
```

### 2. 서버 실행

```bash
# 방법 1: 스크립트 사용
chmod +x run_server.sh
./run_server.sh

# 방법 2: 직접 실행
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

# 방법 3: Python으로 실행
python main.py
```

### 3. 접속

- API 서버: http://localhost:8000
- API 문서 (Swagger): http://localhost:8000/docs
- API 문서 (ReDoc): http://localhost:8000/redoc

## 데이터베이스 설정

### 기본값: SQLite (개발용)

기본적으로 SQLite를 사용합니다. `check_results.db` 파일이 자동 생성됩니다.

### PostgreSQL 사용

1. PostgreSQL 설치 및 데이터베이스 생성
2. `requirements.txt`에 `psycopg2-binary` 추가
3. 환경변수 설정:
   ```bash
   export DATABASE_URL="postgresql://user:password@localhost:5432/dbname"
   ```

### MariaDB 사용

1. MariaDB 설치 및 데이터베이스 생성
2. `requirements.txt`에 `pymysql` 추가
3. 환경변수 설정:
   ```bash
   export DATABASE_URL="mysql+pymysql://user:password@localhost:3306/dbname"
   ```

## API 엔드포인트

### POST /api/checks
점검 결과 저장

**요청 예시:**
```json
{
  "check_type": "mariadb",
  "hostname": "db01",
  "check_time": "2024-01-15T10:30:00Z",
  "checker": "홍길동",
  "status": "success",
  "results": {
    "service_status": {
      "active": "active",
      "substate": "running"
    },
    "listener": "3306 LISTENING"
  }
}
```

### GET /api/checks
점검 결과 조회

**쿼리 파라미터:**
- `check_type`: 점검 유형 필터 (선택)
- `hostname`: 호스트명 필터 (선택)
- `checker`: 담당자 필터 (선택)
- `limit`: 최대 조회 개수 (기본값: 100)

**예시:**
```
GET /api/checks?check_type=mariadb&limit=10
```

## Ansible 플레이북과 연동

`config/api_config.yml` 파일에서 API 서버 주소를 설정:

```yaml
api_server:
  url: "http://localhost:8000/api/checks"
```

## 데이터베이스 스키마

```sql
CREATE TABLE check_results (
    id INTEGER PRIMARY KEY,
    check_type VARCHAR(50) NOT NULL,
    hostname VARCHAR(255) NOT NULL,
    check_time VARCHAR(50) NOT NULL,
    checker VARCHAR(100),
    status VARCHAR(20),
    results JSON NOT NULL,
    created_at DATETIME NOT NULL
);
```

## 개발 모드

`--reload` 옵션으로 코드 변경 시 자동 재시작:

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

