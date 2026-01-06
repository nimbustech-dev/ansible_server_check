# Ubuntu WSL 설치 가이드

Windows에서 Ansible 프로젝트를 실행하기 위한 Ubuntu WSL 설치 가이드입니다.

## 📋 사전 요구사항

- Windows 10 버전 2004 이상 또는 Windows 11
- 관리자 권한
- 인터넷 연결

## 🚀 설치 방법

### 방법 1: 자동 설치 스크립트 사용 (권장)

#### 1단계: WSL 기능 활성화

1. PowerShell을 **관리자 권한으로 실행**
2. 프로젝트 디렉토리로 이동:
   ```powershell
   cd C:\ansible_server_check
   ```
3. 첫 번째 스크립트 실행:
   ```powershell
   .\install_ubuntu_wsl.ps1
   ```
4. 시스템 재시작 (스크립트에서 제안)

#### 2단계: Ubuntu 설치 (재시작 후)

1. PowerShell을 **관리자 권한으로 실행**
2. 두 번째 스크립트 실행:
   ```powershell
   .\install_ubuntu_wsl_step2.ps1
   ```

### 방법 2: 수동 설치

#### 1. WSL 기능 활성화

PowerShell을 **관리자 권한으로 실행**하고 다음 명령어 실행:

```powershell
# WSL 기능 활성화
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Virtual Machine Platform 활성화 (WSL2에 필요)
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

시스템 재시작

#### 2. WSL2를 기본 버전으로 설정

재시작 후 PowerShell을 **관리자 권한으로 실행**:

```powershell
wsl --set-default-version 2
```

#### 3. Ubuntu 설치

**옵션 A: 명령어로 설치**
```powershell
wsl --install -d Ubuntu
```

**옵션 B: Microsoft Store에서 설치**
1. Microsoft Store 열기
2. "Ubuntu" 검색
3. "Ubuntu" 또는 "Ubuntu 22.04 LTS" 설치
4. 설치 후 시작 메뉴에서 Ubuntu 실행

## ✅ 설치 확인

PowerShell에서 다음 명령어로 확인:

```powershell
wsl --list --verbose
```

다음과 같은 출력이 보이면 성공:
```
  NAME      STATE           VERSION
* Ubuntu    Running         2
```

## 🔧 Ubuntu 초기 설정

### 1. Ubuntu 첫 실행

PowerShell에서:
```powershell
wsl
```

또는 시작 메뉴에서 "Ubuntu" 실행

처음 실행 시:
- 사용자명 입력
- 비밀번호 입력 (2회)
- 비밀번호는 화면에 표시되지 않습니다 (정상)

### 2. 시스템 업데이트

```bash
sudo apt update
sudo apt upgrade -y
```

### 3. Ansible 및 필수 패키지 설치

```bash
# Ansible 설치
sudo apt install -y ansible

# Python 패키지 관리자 설치
sudo apt install -y python3-pip python3-venv

# Git 설치 (이미 있을 수 있음)
sudo apt install -y git

# 설치 확인
ansible --version
python3 --version
```

### 4. 프로젝트 클론 (WSL에서)

```bash
# Windows 파일 시스템 접근
cd /mnt/c/ansible_server_check

# 또는 WSL 홈 디렉토리에서 클론
cd ~
git clone https://github.com/sth0824/ansible_server_check.git
cd ansible_server_check
git checkout develop
```

## 📁 Windows와 WSL 파일 시스템 접근

### Windows에서 WSL 파일 접근

Windows 탐색기 주소창에 입력:
```
\\wsl$\Ubuntu\home\사용자명
```

### WSL에서 Windows 파일 접근

```bash
# C 드라이브 접근
cd /mnt/c

# 프로젝트 디렉토리 접근
cd /mnt/c/ansible_server_check
```

## 🐛 문제 해결

### WSL2 커널 업데이트 필요

오류 메시지: "WSL 2 requires an update to its kernel component"

해결:
1. https://aka.ms/wsl2kernel 에서 WSL2 커널 업데이트 패키지 다운로드
2. 설치 후 재시작

### Ubuntu가 시작되지 않음

```powershell
# WSL 재시작
wsl --shutdown
wsl -d Ubuntu
```

### 기본 배포판 변경

```powershell
wsl --set-default Ubuntu
```

### Ubuntu 제거 후 재설치

```powershell
# Ubuntu 제거
wsl --unregister Ubuntu

# 재설치
wsl --install -d Ubuntu
```

## 🎯 다음 단계

Ubuntu 설치가 완료되면:

1. **API 서버 설정**: `api_server/README.md` 참고
2. **Ansible 플레이북 실행**: `README.md`의 "사용 방법" 섹션 참고
3. **네트워크 설정**: `TEAM_NETWORK_SETUP.md` 참고

## 📚 참고 자료

- [Microsoft WSL 공식 문서](https://docs.microsoft.com/ko-kr/windows/wsl/)
- [Ansible 공식 문서](https://docs.ansible.com/)

---

**마지막 업데이트**: 2026년 1월 6일

