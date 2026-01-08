# 192.168.0.18 서버 업데이트 가이드

## 문제
`http://192.168.0.18:8000/api/was-checks/report`에서 WAS 리포트가 제대로 표시되지 않습니다.

## 원인
`192.168.0.18` 서버의 API 서버 코드가 최신 버전이 아닙니다.

## 해결 방법

### 방법 1: 192.168.0.18 서버에서 직접 업데이트

1. **192.168.0.18 서버에 접속**
   ```bash
   ssh user@192.168.0.18
   ```

2. **API 서버 디렉토리로 이동**
   ```bash
   cd /path/to/ansible_server_check/api_server
   ```

3. **최신 코드 가져오기 (Git 사용 시)**
   ```bash
   git pull
   # 또는
   # 수동으로 파일 복사
   ```

4. **API 서버 재시작**
   ```bash
   # 실행 중인 서버 종료
   pkill -f 'python.*main.py'
   
   # 새로 시작
   cd /path/to/ansible_server_check/api_server
   source venv/bin/activate
   python3 main.py
   ```

### 방법 2: 로컬에서 파일 전송 후 재시작

1. **파일 전송 (SCP 사용)**
   ```bash
   # Windows PowerShell에서
   scp api_server/main.py user@192.168.0.18:/path/to/ansible_server_check/api_server/
   scp api_server/was_report_template.html user@192.168.0.18:/path/to/ansible_server_check/api_server/
   ```

2. **서버 재시작**
   ```bash
   ssh user@192.168.0.18
   cd /path/to/ansible_server_check/api_server
   pkill -f 'python.*main.py'
   source venv/bin/activate
   python3 main.py
   ```

### 방법 3: 로컬에서 테스트

만약 `192.168.0.18` 서버를 바로 업데이트할 수 없다면:

1. **로컬에서 API 서버 실행**
   ```bash
   # WSL에서
   cd /mnt/c/ansible_server_check/api_server
   source venv/bin/activate
   python3 main.py
   ```

2. **포트 포워딩 또는 localhost에서 테스트**
   - `http://localhost:8000/api/was-checks/report` 접속

## 확인 방법

업데이트 후 확인:
```bash
# 1. 엔드포인트 확인
curl http://192.168.0.18:8000/api/was-checks/data?limit=1

# 2. 리포트 HTML 확인
curl http://192.168.0.18:8000/api/was-checks/report | grep -i 'was-checks/data'
```

브라우저에서:
- `http://192.168.0.18:8000/api/was-checks/report` 접속
- **Ctrl + Shift + R**로 강력 새로고침
- 개발자 도구 > Network 탭에서 `/api/was-checks/data` 요청 확인

