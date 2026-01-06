# 🤖 AI 코딩 참고 정보

팀원들이 AI에게 부탁해서 코딩할 때 필요한 핵심 정보만 정리했습니다.

---

## 📡 API 서버 정보

### 기본 주소
```
http://192.168.0.18:8000
```

### 주요 엔드포인트

#### 1. 점검 결과 저장 (POST)
```
POST http://192.168.0.18:8000/api/checks
Content-Type: application/json
```

**요청 본문 형식:**
```json
{
  "check_type": "os",           // 필수: "os", "was", "mariadb", "postgresql", "cubrid" 등
  "hostname": "server01",       // 필수: 호스트명
  "check_time": "2024-01-01T12:00:00",  // 필수: ISO8601 형식
  "checker": "홍길동",          // 필수: 담당자 이름
  "status": "success",          // 필수: "success", "warning", "error"
  "results": {                  // 필수: 점검 결과 (자유 형식)
    "cpu": "Intel Core i7",
    "memory": "8GB",
    "disk_usage": 75
  }
}
```

**성공 응답:**
```json
{
  "success": true,
  "message": "점검 결과가 성공적으로 저장되었습니다",
  "id": 123,
  "check_type": "os",
  "hostname": "server01",
  "check_time": "2024-01-01T12:00:00"
}
```

#### 2. 서버 상태 확인 (GET)
```
GET http://192.168.0.18:8000/api/health
```

#### 3. 점검 결과 조회 (GET)
```
GET http://192.168.0.18:8000/api/checks?check_type=os&limit=10
```

---

## 🗄️ 데이터베이스 정보

### PostgreSQL 연결 정보
```
호스트: localhost (또는 127.0.0.1)
포트: 5432
데이터베이스명: ansible_check_db
사용자: ansible_checker
비밀번호: ansible1234
```

### 테이블 구조

#### `check_results` 테이블
```sql
CREATE TABLE check_results (
    id SERIAL PRIMARY KEY,
    check_type VARCHAR(50) NOT NULL,      -- 점검 유형: "os", "was", "mariadb" 등
    hostname VARCHAR(255) NOT NULL,       -- 호스트명
    check_time TIMESTAMP NOT NULL,        -- 점검 시간
    checker VARCHAR(100),                  -- 담당자 이름
    status VARCHAR(20),                   -- 상태: "success", "warning", "error"
    results JSONB,                        -- 점검 결과 (JSON 형식)
    created_at TIMESTAMP DEFAULT NOW()    -- 생성 시간
);
```

### 인덱스
```sql
CREATE INDEX idx_check_type ON check_results(check_type);
CREATE INDEX idx_hostname ON check_results(hostname);
CREATE INDEX idx_checker ON check_results(checker);
CREATE INDEX idx_check_time ON check_results(check_time);
```

---

## 🔧 Ansible 플레이북에서 사용하는 방법

### 기본 구조

```yaml
---
- name: 점검 이름
  hosts: all
  tasks:
    # 점검 작업들...
    - name: 점검 작업
      shell: ...
      register: result
  
  post_tasks:
    # API로 결과 전송
    - name: Send results to API
      include_tasks: "{{ playbook_dir }}/../common/roles/api_sender/tasks/main.yml"
      vars:
        check_type: "os"                    # 필수
        checker_name: "담당자이름"           # 필수
        check_results:                       # 필수: 딕셔너리 형식
          cpu: "{{ result.stdout }}"
          memory: "8GB"
```

### Config 파일 (선택사항)

`config/api_config.yml`:
```yaml
api_server:
  url: "http://192.168.0.18:8000/api/checks"
  timeout: 30
  retry_count: 3

default_checker: "담당자이름"
```

---

## 📋 점검 유형 (check_type) 예시

- `os`: OS 점검
- `was`: WAS 점검 (Tomcat 등)
- `mariadb`: MariaDB 점검
- `postgresql`: PostgreSQL 점검
- `cubrid`: CUBRID 점검
- 기타 자유롭게 정의 가능

---

## 🔑 핵심 포인트

1. **API 주소**: `http://192.168.0.18:8000/api/checks`
2. **요청 형식**: POST, JSON, Content-Type: application/json
3. **필수 필드**: `check_type`, `hostname`, `check_time`, `checker`, `status`, `results`
4. **results 필드**: 자유 형식의 JSON 객체 (딕셔너리)
5. **Ansible 사용 시**: `common/roles/api_sender/tasks/main.yml` include 사용

---

## 💡 AI에게 요청할 때 예시

```
"Ansible 플레이북을 만들어줘. OS 점검을 하고 결과를 
http://192.168.0.18:8000/api/checks 로 POST 요청해서 저장해줘.

요청 형식:
- check_type: "os"
- hostname: inventory_hostname
- check_time: 현재 시간 (ISO8601)
- checker: "홍길동"
- status: "success"
- results: 점검 결과 딕셔너리

common/roles/api_sender/tasks/main.yml을 include해서 사용해줘."
```

---

**마지막 업데이트**: 2024-01-01

