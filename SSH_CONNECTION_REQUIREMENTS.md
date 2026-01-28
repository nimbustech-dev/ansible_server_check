# 원격 컴퓨터 SSH 연결에 필요한 정보

## 필수 정보

### 1. 네트워크 정보

#### 공인 IP 주소 (외부에서 접속하는 경우)
- 원격 컴퓨터의 공인 IP 주소
- 확인 방법:
  ```bash
  # 원격 컴퓨터에서 실행
  curl ifconfig.me
  # 또는
  curl ipinfo.io/ip
  ```

#### 사설 IP 주소 (같은 네트워크 내에서 접속하는 경우)
- 예: `192.168.0.23`
- 확인 방법:
  ```bash
  # Windows: ipconfig
  # Linux/Mac: ip addr show 또는 ifconfig
  ```

#### 포트 번호
- 기본 SSH 포트: `22`
- 다른 포트 사용 시: `2222`, `22222` 등
- 확인 방법:
  ```bash
  # 원격 컴퓨터에서 실행
  netstat -tlnp | grep ssh
  # 또는
  ss -tlnp | grep ssh
  ```

### 2. 인증 정보

#### 사용자명
- 예: `root`, `admin`, `user` 등
- 확인 방법:
  ```bash
  # 원격 컴퓨터에서 실행
  whoami
  ```

#### 인증 방법

**방법 A: 비밀번호 인증**
- 사용자 비밀번호
- 예: `0124` (현재 설정)

**방법 B: SSH 키 인증 (권장)**
- SSH 개인 키 파일 (예: `~/.ssh/id_rsa`)
- 또는 공개 키가 원격 컴퓨터에 등록되어 있어야 함

### 3. 네트워크 접근 설정

#### 방화벽 설정
- 원격 컴퓨터의 방화벽에서 SSH 포트 허용
- Windows: 방화벽 규칙 추가
- Linux: `firewalld` 또는 `iptables` 설정

#### 라우터 포트 포워딩 (사설 IP인 경우)
- 라우터에서 외부 포트 → 원격 컴퓨터 IP:SSH 포트 포워딩
- 예: 외부 포트 2222 → 192.168.0.23:22

#### 공유기/라우터 설정
- DMZ 설정 또는 포트 포워딩 규칙 추가

---

## 현재 설정 정보

`hosts.ini` 파일에 있는 정보:
```ini
dongguk_server1 ansible_host=192.168.0.23 ansible_connection=ssh ansible_port=2222 ansible_user=root ansible_ssh_pass=0124
```

**의미:**
- `ansible_host=192.168.0.23`: 원격 컴퓨터의 IP 주소
- `ansible_port=2222`: SSH 포트 번호
- `ansible_user=root`: 사용자명
- `ansible_ssh_pass=0124`: 비밀번호

---

## 연결 테스트 방법

### 1. 로컬에서 직접 테스트

```bash
# 비밀번호로 접속
ssh -p 2222 root@192.168.0.23

# 또는 비밀번호를 직접 입력
sshpass -p '0124' ssh -p 2222 root@192.168.0.23 'echo 연결성공'
```

### 2. 네이버 클라우드 서버에서 테스트

```bash
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "sshpass -p '0124' ssh -o StrictHostKeyChecking=no -p 2222 root@192.168.0.23 'echo 연결성공'"
```

### 3. Ansible로 테스트

```bash
# 로컬에서
ansible dongguk_server1 -i hosts.ini -m ping

# 네이버 클라우드 서버에서
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "cd /opt/ansible-monitoring && \
     export LC_ALL=en_US.UTF-8 && \
     export LANG=en_US.UTF-8 && \
     ansible dongguk_server1 -i hosts.ini.server -m ping"
```

---

## 네트워크 연결 문제 해결

### 문제 1: Connection timed out

**원인:**
- 원격 컴퓨터가 다른 네트워크에 있음
- 방화벽이 차단
- 포트 포워딩이 안 됨

**해결:**
1. 원격 컴퓨터의 공인 IP 확인
2. 라우터에서 포트 포워딩 설정
3. 방화벽에서 SSH 포트 허용

### 문제 2: Connection refused

**원인:**
- SSH 서비스가 실행되지 않음
- 잘못된 포트 번호

**해결:**
1. 원격 컴퓨터에서 SSH 서비스 확인:
   ```bash
   # Linux
   systemctl status sshd
   # Windows (OpenSSH)
   Get-Service sshd
   ```
2. 포트 번호 확인

### 문제 3: Permission denied

**원인:**
- 잘못된 비밀번호
- SSH 키 인증 실패

**해결:**
1. 비밀번호 확인
2. SSH 키 권한 확인: `chmod 600 ~/.ssh/id_rsa`

---

## 원격 컴퓨터 설정 체크리스트

### Windows 컴퓨터

- [ ] OpenSSH 서버 설치 및 실행
  ```powershell
  # PowerShell (관리자 권한)
  Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
  Start-Service sshd
  Set-Service -Name sshd -StartupType 'Automatic'
  ```
- [ ] 방화벽에서 포트 22 허용
- [ ] 공인 IP 확인 또는 포트 포워딩 설정
- [ ] 사용자 비밀번호 확인

### Linux 컴퓨터

- [ ] SSH 서비스 설치 및 실행
  ```bash
  # Ubuntu/Debian
  sudo apt-get install openssh-server
  sudo systemctl start sshd
  sudo systemctl enable sshd
  
  # CentOS/RHEL
  sudo yum install openssh-server
  sudo systemctl start sshd
  sudo systemctl enable sshd
  ```
- [ ] 방화벽 설정
  ```bash
  # firewalld
  sudo firewall-cmd --permanent --add-service=ssh
  sudo firewall-cmd --reload
  
  # iptables
  sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
  ```
- [ ] 공인 IP 확인 또는 포트 포워딩 설정
- [ ] 사용자 비밀번호 확인

---

## 보안 권장사항

### 1. SSH 키 인증 사용 (비밀번호 대신)

```bash
# 로컬에서 SSH 키 생성
ssh-keygen -t rsa -b 4096

# 원격 컴퓨터에 공개 키 복사
ssh-copy-id -p 2222 root@192.168.0.23

# hosts.ini.server 수정
dongguk_server1 ansible_host=192.168.0.23 ansible_connection=ssh ansible_port=2222 ansible_user=root ansible_ssh_private_key_file=/opt/ansible-monitoring/.ssh/id_rsa
```

### 2. 비밀번호 인증 비활성화 (SSH 키 사용 시)

```bash
# /etc/ssh/sshd_config 수정
PasswordAuthentication no
PubkeyAuthentication yes

# SSH 서비스 재시작
systemctl restart sshd
```

### 3. 포트 변경 (기본 22 포트 변경)

```bash
# /etc/ssh/sshd_config 수정
Port 2222

# SSH 서비스 재시작
systemctl restart sshd
```

---

## 현재 상황에서 필요한 정보

원격 컴퓨터에 접속하려면 다음 정보를 확인해주세요:

1. **원격 컴퓨터의 공인 IP 주소** (외부에서 접속하는 경우)
   - 또는 사설 IP + 포트 포워딩 설정

2. **SSH 포트 번호**
   - 현재 설정: `2222`
   - 실제 포트 확인 필요

3. **사용자명과 비밀번호**
   - 현재 설정: `root` / `0124`
   - 확인 필요

4. **네트워크 접근 가능 여부**
   - 같은 네트워크 내에 있는지
   - 공인 IP로 접근 가능한지
   - VPN이 필요한지

---

## 다음 단계

1. 원격 컴퓨터에서 위의 정보 확인
2. 네트워크 연결 테스트
3. 연결 성공 시 `hosts.ini.server` 파일 업데이트
4. 자동 점검 테스트
