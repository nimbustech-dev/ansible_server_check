# 원격 컴퓨터 정보 확인 가이드

동국대 컴퓨터에 직접 접속해서 다음 정보를 확인하세요.

---

## 필수 확인 정보

### 1. IP 주소 확인

#### 공인 IP (외부에서 접속할 때 필요)
```bash
# Linux/Mac
curl ifconfig.me
# 또는
curl ipinfo.io/ip

# Windows (PowerShell)
(Invoke-WebRequest -Uri "https://ifconfig.me").Content
```

#### 사설 IP (로컬 네트워크 IP)
```bash
# Linux/Mac
ip addr show
# 또는
ifconfig
# 또는 간단히
hostname -I

# Windows (CMD)
ipconfig
# 또는 (PowerShell)
Get-NetIPAddress | Where-Object {$_.AddressFamily -eq 'IPv4'} | Select-Object IPAddress
```

**필요한 정보**: `192.168.x.x` 또는 `10.x.x.x` 형태의 IP 주소

---

### 2. SSH 포트 번호 확인

```bash
# Linux/Mac
sudo netstat -tlnp | grep ssh
# 또는
sudo ss -tlnp | grep ssh
# 또는 SSH 설정 파일 확인
sudo grep "^Port" /etc/ssh/sshd_config

# Windows (PowerShell - 관리자 권한)
Get-NetTCPConnection | Where-Object {$_.State -eq "Listen" -and $_.LocalPort -eq 22}
# 또는 OpenSSH 설정 확인
Get-Content C:\ProgramData\ssh\sshd_config | Select-String "Port"
```

**필요한 정보**: 포트 번호 (기본값: 22, 다른 포트 사용 시 해당 번호)

---

### 3. 사용자명 확인

```bash
# Linux/Mac/Windows
whoami
```

**필요한 정보**: 현재 사용자명 (예: `root`, `admin`, `user`)

---

### 4. SSH 서비스 실행 여부 확인

```bash
# Linux (systemd)
systemctl status sshd
# 또는
systemctl is-active sshd

# Linux (service)
service ssh status

# Windows (PowerShell - 관리자 권한)
Get-Service sshd
# 또는
Get-Service | Where-Object {$_.Name -like "*ssh*"}
```

**필요한 정보**: SSH 서비스가 실행 중인지 (`active` 또는 `Running`)

---

### 5. 방화벽 설정 확인

```bash
# Linux (firewalld)
sudo firewall-cmd --list-all
sudo firewall-cmd --list-ports

# Linux (ufw - Ubuntu)
sudo ufw status
sudo ufw status numbered

# Linux (iptables)
sudo iptables -L -n | grep 22

# Windows (PowerShell - 관리자 권한)
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*SSH*" -or $_.DisplayName -like "*OpenSSH*"}
# 또는
netsh advfirewall firewall show rule name=all | findstr SSH
```

**필요한 정보**: SSH 포트(22 또는 다른 포트)가 허용되어 있는지

---

### 6. 네트워크 정보 (추가 확인)

```bash
# 게이트웨이 확인
# Linux/Mac
ip route | grep default
# 또는
route -n | grep "^0.0.0.0"

# Windows
ipconfig | findstr "Gateway"

# DNS 서버 확인
# Linux/Mac
cat /etc/resolv.conf

# Windows
ipconfig /all | findstr "DNS"
```

---

## 한 번에 확인하는 스크립트

### Linux/Mac용

동국대 컴퓨터에서 다음 스크립트를 실행하세요:

```bash
#!/bin/bash
echo "=========================================="
echo "원격 컴퓨터 SSH 연결 정보 확인"
echo "=========================================="
echo ""

echo "1. 공인 IP 주소:"
curl -s ifconfig.me
echo ""
echo ""

echo "2. 사설 IP 주소:"
hostname -I | awk '{print $1}'
echo ""

echo "3. SSH 포트:"
sudo grep "^Port" /etc/ssh/sshd_config 2>/dev/null || echo "기본값: 22"
echo ""

echo "4. 사용자명:"
whoami
echo ""

echo "5. SSH 서비스 상태:"
systemctl is-active sshd 2>/dev/null || service ssh status 2>/dev/null | head -1
echo ""

echo "6. 방화벽 상태 (firewalld):"
sudo firewall-cmd --list-ports 2>/dev/null || echo "firewalld 없음"
echo ""

echo "7. 네트워크 인터페이스:"
ip addr show | grep -E "inet |inet6 " | grep -v "127.0.0.1"
echo ""

echo "=========================================="
```

**실행 방법:**
```bash
# 파일로 저장
cat > check_ssh_info.sh << 'EOF'
[위 스크립트 내용]
EOF

chmod +x check_ssh_info.sh
sudo ./check_ssh_info.sh
```

### Windows용 (PowerShell)

동국대 컴퓨터에서 PowerShell을 관리자 권한으로 실행:

```powershell
Write-Host "=========================================="
Write-Host "원격 컴퓨터 SSH 연결 정보 확인"
Write-Host "=========================================="
Write-Host ""

Write-Host "1. 공인 IP 주소:"
(Invoke-WebRequest -Uri "https://ifconfig.me").Content
Write-Host ""

Write-Host "2. 사설 IP 주소:"
Get-NetIPAddress | Where-Object {$_.AddressFamily -eq 'IPv4' -and $_.IPAddress -notlike "127.*"} | Select-Object IPAddress
Write-Host ""

Write-Host "3. SSH 포트:"
$sshConfig = Get-Content C:\ProgramData\ssh\sshd_config -ErrorAction SilentlyContinue
if ($sshConfig) {
    $portLine = $sshConfig | Select-String "^Port"
    if ($portLine) { $portLine } else { "기본값: 22" }
} else {
    "SSH 설정 파일 없음 (기본값: 22)"
}
Write-Host ""

Write-Host "4. 사용자명:"
$env:USERNAME
Write-Host ""

Write-Host "5. SSH 서비스 상태:"
Get-Service sshd -ErrorAction SilentlyContinue | Select-Object Name, Status
Write-Host ""

Write-Host "6. 방화벽 규칙 (SSH 관련):"
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*SSH*" -or $_.DisplayName -like "*OpenSSH*"} | Select-Object DisplayName, Enabled
Write-Host ""

Write-Host "=========================================="
```

---

## 확인 후 필요한 정보 정리

다음 정보를 확인해서 알려주세요:

1. **공인 IP**: `xxx.xxx.xxx.xxx` (외부에서 접속할 때 사용)
2. **사설 IP**: `192.168.x.x` 또는 `10.x.x.x` (같은 네트워크 내에서 사용)
3. **SSH 포트**: `22` 또는 다른 번호
4. **사용자명**: `root`, `admin` 등
5. **SSH 서비스**: 실행 중인지 여부
6. **방화벽**: SSH 포트가 허용되어 있는지

---

## 추가 확인 사항

### SSH 접속 테스트 (로컬에서)

동국대 컴퓨터에서 자기 자신에게 SSH 접속이 되는지 확인:

```bash
# Linux/Mac
ssh localhost
# 또는
ssh 127.0.0.1

# Windows
ssh localhost
```

### 외부에서 접속 가능한지 테스트

다른 컴퓨터(예: 로컬 PC)에서:

```bash
# 공인 IP로 접속 테스트
ssh -p [포트번호] [사용자명]@[공인IP]

# 예시
ssh -p 2222 root@xxx.xxx.xxx.xxx
```

---

## 정보 확인 후 다음 단계

확인한 정보를 알려주시면:
1. `hosts.ini.server` 파일 업데이트
2. 네이버 클라우드 서버에 배포
3. 연결 테스트 진행

---

## 빠른 확인 명령어 (Linux/Mac)

```bash
echo "=== 빠른 정보 확인 ===" && \
echo "공인 IP: $(curl -s ifconfig.me)" && \
echo "사설 IP: $(hostname -I | awk '{print $1}')" && \
echo "사용자: $(whoami)" && \
echo "SSH 포트: $(sudo grep '^Port' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo '22')" && \
echo "SSH 서비스: $(systemctl is-active sshd 2>/dev/null || echo '확인 필요')"
```
