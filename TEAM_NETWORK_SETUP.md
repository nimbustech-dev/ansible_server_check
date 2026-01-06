# 팀원 네트워크 접근 설정 가이드

## 현재 상황

✅ **API 서버**: 이미 네트워크 접근 가능 (`0.0.0.0`으로 설정됨)
⚠️ **PostgreSQL**: 네트워크 접근 설정 필요
⚠️ **방화벽**: 포트 열기 필요

## 설정 방법

### 1단계: 네트워크 접근 설정 (이 컴퓨터에서 실행)

```bash
cd /home/sth0824/ansible
chmod +x setup_network_access.sh
./setup_network_access.sh
```

이 스크립트가 자동으로:
- PostgreSQL 네트워크 접근 허용
- 방화벽 포트 8000 열기
- 현재 IP 주소 확인

### 2단계: 현재 컴퓨터 IP 주소 확인

```bash
hostname -I
```

또는:
```bash
ip addr show | grep "inet " | grep -v 127.0.0.1
```

예: `192.168.1.100` 같은 IP 주소가 나옵니다.

### 3단계: 다른 팀원들이 설정할 내용

각 팀원의 `config/api_config.yml` 파일에서:

```yaml
api_server:
  url: "http://192.168.1.100:8000/api/checks"  # 이 컴퓨터의 IP 주소로 변경
  timeout: 30
  retry_count: 3
```

**중요**: `192.168.1.100`을 실제 이 컴퓨터의 IP 주소로 변경하세요!

## 확인 방법

### 이 컴퓨터에서:
```bash
# API 서버가 네트워크에서 접근 가능한지 확인
curl http://localhost:8000/api/health

# 또는 다른 컴퓨터에서
curl http://192.168.1.100:8000/api/health
```

### 다른 팀원 컴퓨터에서:
```bash
# API 서버 연결 테스트
curl http://192.168.1.100:8000/api/health

# 점검 실행
cd /home/sth0824/ansible/mariadb_check
ansible-playbook -i inventory mariadb_check.yml
```

## 보안 주의사항

⚠️ **현재 설정은 같은 네트워크의 모든 컴퓨터에서 접근 가능합니다.**

프로덕션 환경에서는:
1. 방화벽에서 특정 IP만 허용
2. API 인증 추가 (토큰 등)
3. HTTPS 사용

## 문제 해결

### 연결이 안 될 때

1. **방화벽 확인**
   ```bash
   sudo ufw status
   sudo ufw allow 8000/tcp
   ```

2. **IP 주소 확인**
   ```bash
   hostname -I
   ```

3. **API 서버 재시작**
   ```bash
   ./stop_api_server.sh
   ./start_api_server.sh
   ```

4. **PostgreSQL 접근 확인**
   ```bash
   sudo systemctl status postgresql
   ```

