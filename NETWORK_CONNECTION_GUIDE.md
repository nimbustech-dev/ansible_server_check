# 동국대 서버 네트워크 연결 해결 가이드

## 현재 상황 분석

### 네트워크 정보
- **네이버 클라우드 서버**:
  - 사설 IP: `10.41.153.183/23`
  - 공인 IP: `115.85.181.103`
  - 네트워크: `10.41.152.0/23`
  
- **동국대 서버**:
  - IP: `192.168.0.23`
  - 포트: `2222`
  - 네트워크: `192.168.0.0/24` (추정)

### 문제 원인
1. **서로 다른 네트워크**: 네이버 클라우드(10.41.x.x)와 동국대(192.168.x.x)는 서로 다른 사설 네트워크
2. **라우팅 없음**: 네이버 클라우드 서버의 라우팅 테이블에 192.168.0.0/24 네트워크 경로가 없음
3. **직접 통신 불가**: 두 서버 간 직접 통신이 불가능한 상태

---

## 해결 방법

### 방법 1: VPN 연결 (권장)

네이버 클라우드 서버에서 동국대 네트워크로 접근할 수 있도록 VPN을 설정합니다.

#### 1-1. OpenVPN 클라이언트 설치 및 설정

```bash
# 네이버 클라우드 서버에서 실행
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114

# OpenVPN 설치
yum install -y openvpn

# VPN 설정 파일 업로드 (동국대에서 제공하는 .ovpn 파일)
# scp를 통해 업로드하거나 직접 생성
```

#### 1-2. VPN 연결

```bash
# VPN 연결
openvpn --config /path/to/dongguk.ovpn --daemon

# 연결 확인
ip addr show | grep tun0
ping 192.168.0.23
```

#### 1-3. 자동 연결 설정

```bash
# systemd 서비스로 등록
cat > /etc/systemd/system/dongguk-vpn.service << EOF
[Unit]
Description=Dongguk VPN Connection
After=network.target

[Service]
Type=forking
ExecStart=/usr/sbin/openvpn --config /etc/openvpn/dongguk.ovpn --daemon
ExecStop=/bin/killall openvpn
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable dongguk-vpn
systemctl start dongguk-vpn
```

---

### 방법 2: SSH 터널링 (중간 서버 사용)

동국대 네트워크에 접근 가능한 중간 서버를 통해 터널링합니다.

#### 2-1. 중간 서버 설정

동국대 네트워크에 접근 가능한 서버(예: 로컬 PC 또는 다른 서버)를 사용합니다.

#### 2-2. SSH 터널 생성

```bash
# 로컬 PC에서 실행 (동국대 서버에 접근 가능한 곳)
ssh -L 2222:192.168.0.23:2222 root@동국대_게이트웨이

# 또는 네이버 클라우드 서버에서 직접 터널 생성
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "ssh -L 2222:192.168.0.23:2222 root@중간서버"
```

#### 2-3. hosts.ini.server 수정

```ini
dongguk_server1 ansible_host=127.0.0.1 ansible_connection=ssh ansible_port=2222 ansible_user=root ansible_ssh_pass=0124 ansible_hostname_display=dongguk-server
```

**주의**: 이 방법은 SSH 터널이 유지되는 동안만 작동합니다.

---

### 방법 3: 동국대 서버에 공인 IP 할당

동국대 서버에 공인 IP를 할당하고 포트 포워딩을 설정합니다.

#### 3-1. 공인 IP 할당
- 동국대 네트워크 관리자에게 공인 IP 할당 요청
- 또는 동국대 서버를 DMZ에 배치

#### 3-2. 포트 포워딩 설정
- 라우터/방화벽에서 공인 IP:포트 → 192.168.0.23:2222 포워딩

#### 3-3. hosts.ini.server 수정

```ini
dongguk_server1 ansible_host=공인IP ansible_connection=ssh ansible_port=2222 ansible_user=root ansible_ssh_pass=0124 ansible_hostname_display=dongguk-server
```

---

### 방법 4: 네이버 클라우드 Site-to-Site VPN

네이버 클라우드의 Site-to-Site VPN 기능을 사용합니다.

#### 4-1. 네이버 클라우드 콘솔 설정
1. 네이버 클라우드 콘솔 접속
2. **VPC** → **Site-to-Site VPN** 메뉴
3. VPN 게이트웨이 생성
4. 동국대 네트워크와 연결 설정

#### 4-2. 라우팅 설정
- 네이버 클라우드 VPC 라우팅 테이블에 192.168.0.0/24 추가
- 동국대 네트워크에도 10.41.152.0/23 추가

---

### 방법 5: 동국대 서버에서 네이버 클라우드로 접속 (역방향)

동국대 서버에서 네이버 클라우드 서버로 접속하여 점검 결과를 전송하는 방식입니다.

#### 5-1. 동국대 서버에 Ansible 설치

```bash
# 동국대 서버에서
yum install -y python3 python3-pip
pip3 install ansible
```

#### 5-2. 점검 스크립트 수정

동국대 서버에서 직접 점검을 실행하고 결과를 API 서버로 전송:

```bash
# 동국대 서버에서 실행
ansible-playbook -i localhost, redhat_check/redhat_check.yml
```

#### 5-3. Crontab 설정

동국대 서버의 crontab에 점검 스크립트 등록

**단점**: 동국대 서버에 Ansible과 스크립트를 설치해야 함

---

## 추천 방법

### 즉시 적용 가능 (단기)
**방법 2: SSH 터널링** (테스트용)
- 빠르게 테스트 가능
- 영구적이지 않음

### 장기적 해결 (권장)
**방법 1: VPN 연결** 또는 **방법 4: Site-to-Site VPN**
- 안정적이고 영구적
- 여러 서버 점검 시 확장 가능

---

## 연결 테스트

네트워크 연결이 해결되면 다음 명령어로 테스트:

```bash
# 1. Ping 테스트
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "ping -c 3 192.168.0.23"

# 2. SSH 연결 테스트
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "ssh -o StrictHostKeyChecking=no -p 2222 root@192.168.0.23 'echo 연결성공'"

# 3. Ansible Ping 테스트
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "cd /opt/ansible-monitoring && \
     export LC_ALL=en_US.UTF-8 && \
     export LANG=en_US.UTF-8 && \
     ansible dongguk_server1 -i hosts.ini.server -m ping"

# 4. 실제 점검 테스트
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 \
    "cd /opt/ansible-monitoring && \
     export LC_ALL=en_US.UTF-8 && \
     export LANG=en_US.UTF-8 && \
     ansible-playbook -i hosts.ini.server redhat_check/redhat_check.yml --limit dongguk_server1"
```

---

## 현재 상태 확인

### 네트워크 정보 확인

```bash
# 네이버 클라우드 서버에서
ssh -i ~/.ssh/nimso2026.pem -p 4433 root@27.96.129.114 << 'EOF'
echo "=== 네트워크 인터페이스 ==="
ip addr show

echo -e "\n=== 라우팅 테이블 ==="
route -n

echo -e "\n=== 동국대 서버 연결 테스트 ==="
ping -c 2 192.168.0.23 || echo "연결 실패"
EOF
```

---

## 다음 단계

1. **방법 선택**: 위의 방법 중 하나를 선택
2. **설정 적용**: 선택한 방법에 따라 설정 진행
3. **연결 테스트**: 위의 테스트 명령어 실행
4. **자동 점검 확인**: 네트워크 연결 후 자동 점검 스크립트 실행

---

## 문제 해결

### VPN 연결이 안 될 때
- VPN 서버 상태 확인
- 방화벽 규칙 확인
- VPN 로그 확인: `journalctl -u dongguk-vpn -n 50`

### SSH 터널이 끊어질 때
- 터널을 systemd 서비스로 등록
- autossh 사용 고려

### 여전히 연결이 안 될 때
- 동국대 네트워크 관리자에게 문의
- 방화벽/라우터 설정 확인 필요

---

## 업데이트 이력

- **2026-01-28**: 네트워크 연결 해결 가이드 작성
  - VPN 연결 방법
  - SSH 터널링 방법
  - 공인 IP 할당 방법
  - Site-to-Site VPN 방법
  - 역방향 접속 방법
