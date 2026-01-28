# 동국대 서버 자동 점검 설정 완료

## 설정 완료 사항

### 1. hosts.ini.server 파일 업데이트
- 동국대 서버(`dongguk_server1`)를 모든 점검 그룹에 추가
  - `[webservers]`: OS 점검용
  - `[mariadb]`: MariaDB 점검용
  - `[postgresql]`: PostgreSQL 점검용
- 비밀번호 인증 설정: `ansible_ssh_pass=0124`
- 호스트명 표시: `dongguk-server`

### 2. auto_check_navercloud.sh 수정
- 두 서버 모두 점검하도록 `LIMIT_TARGET` 변경
- `nimbus-server,dongguk_server1`로 설정

### 3. sshpass 설치
- 비밀번호 인증을 위한 `sshpass` 패키지 설치 완료

## 현재 상태

### ✅ 완료된 작업
- [x] hosts.ini.server에 동국대 서버 추가
- [x] auto_check_navercloud.sh 수정
- [x] 파일 배포 완료
- [x] sshpass 설치 완료

### ⚠️ 네트워크 연결 문제

현재 네이버 클라우드 서버에서 동국대 서버(192.168.0.23:2222)로 연결이 되지 않습니다.

**오류 메시지:**
```
ssh: connect to host 192.168.0.23 port 2222: Connection timed out
```

## 해결 방법

### 1. 네트워크 경로 확인

동국대 서버(192.168.0.23)는 사설 IP 주소이므로, 네이버 클라우드 서버에서 직접 접근이 불가능할 수 있습니다.

**확인 사항:**
- 동국대 서버가 VPN을 통해 접근 가능한지 확인
- 네이버 클라우드 서버에서 동국대 네트워크로 라우팅이 설정되어 있는지 확인
- 방화벽에서 네이버 클라우드 서버 IP 허용 여부 확인

### 2. 대안 방법

#### 방법 1: VPN 설정
네이버 클라우드 서버에서 동국대 네트워크로 접근할 수 있도록 VPN 연결 설정

#### 방법 2: SSH 터널링
중간 서버를 통한 SSH 터널링 설정

#### 방법 3: 공인 IP 사용
동국대 서버에 공인 IP를 할당하고 방화벽 설정

### 3. 연결 테스트

네트워크 연결이 해결되면 다음 명령어로 테스트:

```bash
# 서버에서 직접 테스트
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "cd /opt/ansible-monitoring && \
     export LC_ALL=en_US.UTF-8 && \
     export LANG=en_US.UTF-8 && \
     ansible dongguk_server1 -i hosts.ini.server -m ping"
```

성공 시:
```
dongguk_server1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

## 자동 점검 스케줄

현재 설정:
- **실행 시간**: 매일 오전 7시
- **점검 대상**: 
  - `nimbus-server` (네이버 클라우드 서버)
  - `dongguk_server1` (동국대 서버) - 네트워크 연결 해결 후 작동

## 점검 항목

동국대 서버는 다음 항목을 점검합니다:
- ✅ OS 점검 (Redhat)
- ✅ MariaDB 점검
- ✅ PostgreSQL 점검
- ✅ Tomcat 점검

## 보안 고려사항

⚠️ **비밀번호 평문 저장**
- 현재 `hosts.ini.server`에 비밀번호가 평문으로 저장되어 있습니다
- 향후 보안 강화를 위해 다음 방법 고려:
  1. SSH 키 인증으로 전환
  2. Ansible Vault 사용
  3. 환경 변수 사용

## 문제 해결

### sshpass 오류
이미 해결됨: `yum install -y sshpass`로 설치 완료

### 네트워크 연결 타임아웃
- 네트워크 경로 확인 필요
- VPN 또는 라우팅 설정 필요

### 점검 실패 시
로그 확인:
```bash
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "tail -100 /opt/ansible-monitoring/logs/navercloud_check_$(date +%Y%m%d).log"
```

## 업데이트 이력

- **2026-01-28**: 동국대 서버 자동 점검 설정 완료
  - hosts.ini.server에 동국대 서버 추가
  - auto_check_navercloud.sh 수정
  - sshpass 설치
  - 네트워크 연결 문제 확인 (해결 필요)
