# 대시보드 접근 가이드

## 배포된 서버 접속 정보

- **서버 주소**: `http://115.85.181.103:8000`
- **공인 IP**: 115.85.181.103
- **내부 IP**: 27.96.129.114

## 대시보드 접근 경로

### 메인 대시보드
- **URL**: `http://115.85.181.103:8000/api/dashboard`
- **설명**: DB, OS, WAS 점검 결과를 탭으로 통합하여 보여주는 대시보드
- **특징**: 
  - 실시간 업데이트 (WebSocket)
  - 필터링, 검색, 정렬 기능
  - 차트 및 통계 제공
  - 상세 모달 (원본 JSON 포함)

### 루트 경로
- **URL**: `http://115.85.181.103:8000/`
- **동작**: 자동으로 `/api/dashboard`로 리다이렉트

### 개별 리포트
- **DB 점검 리포트**: `http://115.85.181.103:8000/api/db-checks/report`
- **OS 점검 리포트**: `http://115.85.181.103:8000/api/os-checks/report`
- **WAS 점검 리포트**: `http://115.85.181.103:8000/api/was-checks/report`
- **통합 리포트**: `http://115.85.181.103:8000/api/report`

### 기타
- **JSON 뷰어**: `http://115.85.181.103:8000/api/json-viewer`
- **API 문서 (Swagger)**: `http://115.85.181.103:8000/docs`
- **서버 상태 확인**: `http://115.85.181.103:8000/api/health`

## 자동 점검 설정

### 실행 주기
- **매일 오전 7시** 자동 실행
- 네이버 클라우드 서버에서 자기 자신을 점검
- 점검 결과는 자동으로 대시보드에 표시됨

### 점검 항목
1. OS (Redhat) 점검
2. MariaDB 점검
3. PostgreSQL 점검
4. Tomcat (WAS) 점검

### 로그 확인
- **서버 로그 경로**: `/opt/ansible-monitoring/logs/navercloud_check_YYYYMMDD.log`
- **Cron 로그**: `/opt/ansible-monitoring/logs/navercloud_cron.log`

## 수동 점검 실행

서버에서 직접 실행:
```bash
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114
cd /opt/ansible-monitoring
./auto_check_navercloud.sh
```

## 문제 해결

### 대시보드에 데이터가 표시되지 않는 경우
1. API 서버 상태 확인: `http://115.85.181.103:8000/api/health`
2. 점검 실행 확인: 서버 로그 확인
3. 데이터베이스 연결 확인: PostgreSQL 서비스 상태 확인

### 자동 점검이 실행되지 않는 경우
1. Crontab 확인: `crontab -l` (서버에서)
2. 스크립트 실행 권한 확인: `ls -la /opt/ansible-monitoring/auto_check_navercloud.sh`
3. Ansible 설치 확인: `ansible-playbook --version` (서버에서)
