# SSH 접속 정보 확인 가이드

## 🔍 SSH 접속 정보를 알아내는 방법

동국대 서버(`192.168.0.23`)의 SSH 접속 정보를 확인하는 여러 방법을 안내합니다.

---

## 방법 1: 기존 접속 기록 확인 (가장 빠름)

### 1-1. PuTTY 설정 확인

**Windows에서:**
1. PuTTY 실행
2. 왼쪽 "Saved Sessions"에서 동국대 서버 관련 세션 확인
3. 세션 선택 후 "Load" 클릭
4. "Connection" → "Data"에서 사용자명 확인
5. "Connection" → "SSH" → "Auth"에서 SSH 키 파일 경로 확인

**또는 설정 파일 직접 확인:**
```
C:\Users\[사용자명]\AppData\Roaming\PuTTY\sessions\
```

### 1-2. MobaXterm 설정 확인

**Windows에서:**
1. MobaXterm 실행
2. 왼쪽 "Sessions" 탭에서 동국대 서버 세션 확인
3. 세션 우클릭 → "Edit session"
4. "Advanced SSH settings"에서 사용자명, SSH 키 확인

**또는 설정 파일 직접 확인:**
```
C:\Users\[사용자명]\AppData\Roaming\MobaXterm\Sessions\
```

### 1-3. SSH 키 파일 확인

**Windows:**
```powershell
# SSH 키 파일 검색
Get-ChildItem -Path C:\Users\$env:USERNAME\.ssh -Recurse -Include *.pem,*.key,*.ppk,id_rsa,id_ed25519
```

**WSL:**
```bash
# SSH 키 파일 확인
ls -la ~/.ssh/
ls -la /mnt/c/Users/$USER/.ssh/
```

### 1-4. SSH config 파일 확인

**Windows:**
```
C:\Users\[사용자명]\.ssh\config
```

**WSL:**
```bash
cat ~/.ssh/config
cat /mnt/c/Users/$USER/.ssh/config
```

---

## 방법 2: 서버 관리자에게 문의

### 2-1. 박지빈님에게 요청

**필요한 정보:**
```
1. SSH 사용자명: ?
2. 비밀번호: ? (또는 SSH 키 파일)
3. SSH 포트: ? (기본 22)
4. SSH 키 파일이 있다면 파일 위치: ?
```

### 2-2. 동국대 서버 관리자에게 요청

서버 관리자에게 다음 정보를 요청:
- SSH 접속 계정 정보
- 비밀번호 또는 SSH 키 파일
- 접속 권한 부여

---

## 방법 3: 동국대 서버에 직접 접근

### 3-1. 물리적 접근

동국대 서버에 직접 접근할 수 있다면:

```bash
# 현재 사용자 확인
whoami

# 사용 가능한 사용자 목록 확인
cat /etc/passwd | grep -E "/bin/(bash|sh)$"

# sudo 권한 확인
sudo -v

# SSH 서버 설정 확인
sudo cat /etc/ssh/sshd_config | grep -E "Port|PermitRootLogin|PasswordAuthentication"
```

### 3-2. 원격 데스크톱 접속

Windows 원격 데스크톱(RDP)으로 접속 가능하다면:
1. 원격 데스크톱으로 접속
2. PowerShell 또는 CMD에서 위 명령어 실행

---

## 방법 4: 자동 검색 스크립트 실행

프로젝트에 포함된 스크립트를 실행:

```bash
# WSL에서 실행
wsl bash -c "cd /mnt/c/ansible_server_check && chmod +x find_ssh_credentials.sh && ./find_ssh_credentials.sh"
```

이 스크립트가 자동으로:
- PuTTY 설정 파일 검색
- SSH 키 파일 검색
- SSH config 파일 확인
- MobaXterm 설정 확인

---

## 방법 5: 일반적인 사용자명 시도

동국대 서버에서 일반적으로 사용되는 사용자명:

- `root` (관리자 계정)
- `admin` (관리자 계정)
- `dongguk` (동국대 관련 계정)
- `ubuntu` (Ubuntu 기본 계정)
- `centos` (CentOS 기본 계정)
- `user` (일반 사용자 계정)
- 서버 관리자 이름

**주의**: 비밀번호를 무작위로 시도하는 것은 보안상 위험하므로 권장하지 않습니다.

---

## 방법 6: SSH 키 생성 및 등록

서버 관리자와 협의하여 새로운 SSH 키를 생성하고 등록:

### 6-1. SSH 키 생성

```bash
# WSL에서 실행
ssh-keygen -t rsa -b 4096 -f ~/.ssh/dongguk_server_key
```

### 6-2. 공개키를 서버 관리자에게 전달

```bash
cat ~/.ssh/dongguk_server_key.pub
```

서버 관리자가 이 공개키를 서버에 등록하면, 비밀번호 없이 접속 가능합니다.

---

## 📋 체크리스트

SSH 접속 정보 확인을 위한 체크리스트:

- [ ] PuTTY 설정 확인
- [ ] MobaXterm 설정 확인
- [ ] SSH 키 파일 검색
- [ ] SSH config 파일 확인
- [ ] 서버 관리자에게 문의
- [ ] 동국대 서버에 직접 접근하여 확인
- [ ] 자동 검색 스크립트 실행

---

## 🎯 다음 단계

SSH 접속 정보를 확인했다면:

1. **Inventory 파일에 정보 추가**
   ```ini
   dongguk_server1 ansible_host=192.168.0.23 ansible_user=확인한사용자명 ansible_ssh_pass=비밀번호
   ```

2. **SSH 접속 테스트**
   ```bash
   ssh 확인한사용자명@192.168.0.23
   ```

3. **Ansible 연결 테스트**
   ```bash
   ansible -i inventory/dongguk_remote_servers.ini dongguk_servers -m ping
   ```

4. **점검 실행**
   ```bash
   ansible-playbook -i inventory/dongguk_remote_servers.ini redhat_check/redhat_check.yml
   ```

---

## ⚠️ 보안 주의사항

1. **비밀번호를 파일에 직접 작성하지 마세요**
   - 가능하면 SSH 키 사용
   - Ansible Vault 사용 권장

2. **SSH 키 파일 권한 설정**
   ```bash
   chmod 600 ~/.ssh/id_rsa
   ```

3. **Inventory 파일을 Git에 커밋하지 마세요**
   - `.gitignore`에 추가되어 있는지 확인

---

**참고**: 이 가이드는 동국대 서버 접속 정보를 안전하게 확인하는 방법을 안내합니다. 보안을 위해 접속 정보는 안전하게 관리하세요.

