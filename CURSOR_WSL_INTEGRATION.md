# Cursor IDE와 Ubuntu WSL 연동 가이드

## ✅ 연동 확인

Cursor IDE는 VS Code 기반이므로 WSL과 완벽하게 연동됩니다.

### 현재 상태 확인

이미지에서 확인된 내용:
- ✅ PowerShell 터미널: `PS C:\ansible_server_check>`
- ✅ Ubuntu 터미널: `soomin@PC:~ $`

**결론: Cursor와 Ubuntu WSL이 정상적으로 연동되어 있습니다!**

## 🚀 Cursor에서 Ubuntu 터미널 사용 방법

### 방법 1: 새 터미널에서 WSL 선택

1. **터미널 열기**: `Ctrl + `` (백틱) 또는 `Ctrl + Shift + `` 
2. **터미널 드롭다운 클릭** (터미널 상단 오른쪽의 `+` 옆 화살표)
3. **"WSL" 또는 "Ubuntu" 선택**

### 방법 2: 기본 터미널 프로필 설정

1. `Ctrl + Shift + P` (명령 팔레트 열기)
2. `Terminal: Select Default Profile` 입력
3. **"WSL" 또는 "Ubuntu" 선택**

이제 새 터미널을 열면 자동으로 Ubuntu가 열립니다.

### 방법 3: 직접 명령어 실행

PowerShell 터미널에서:
```powershell
wsl
```

## 📁 파일 시스템 접근

### Windows에서 Ubuntu 파일 접근

Cursor의 파일 탐색기에서:
- `\\wsl$\Ubuntu\home\soomin` 경로로 접근 가능
- 또는 Windows 탐색기 주소창에 입력

### Ubuntu에서 Windows 파일 접근

Ubuntu 터미널에서:
```bash
# 현재 프로젝트 디렉토리
cd /mnt/c/ansible_server_check

# 파일 목록 확인
ls -la
```

## 🔧 Cursor 설정 파일

### settings.json에 WSL 설정 추가

`Ctrl + Shift + P` → `Preferences: Open User Settings (JSON)`:

```json
{
  "terminal.integrated.defaultProfile.windows": "Ubuntu",
  "terminal.integrated.profiles.windows": {
    "Ubuntu": {
      "path": "wsl.exe",
      "args": ["-d", "Ubuntu"]
    },
    "PowerShell": {
      "source": "PowerShell",
      "icon": "terminal-powershell"
    }
  }
}
```

## 🎯 실전 사용 팁

### 1. 여러 터미널 탭 사용

- **PowerShell 탭**: Windows 명령어 실행
- **Ubuntu 탭**: Linux/Ansible 명령어 실행

### 2. 터미널 분할

- `Ctrl + Shift + 5`: 터미널 분할
- 각각 다른 프로필 선택 가능 (PowerShell + Ubuntu 동시 사용)

### 3. 통합 터미널에서 Ansible 실행

Ubuntu 터미널에서:
```bash
cd /mnt/c/ansible_server_check
ansible-playbook -i inventory nimbus_check/os_check.yml
```

### 4. 파일 편집 후 바로 실행

1. Cursor에서 파일 편집 (Windows 파일 시스템)
2. Ubuntu 터미널에서 바로 실행 (같은 파일 시스템 접근)

## 🔍 연동 상태 확인

### 현재 터미널 환경 확인

**PowerShell에서:**
```powershell
$env:OS
# Windows_NT 출력
```

**Ubuntu에서:**
```bash
uname -a
# Linux ... WSL2 ... 출력
```

### 파일 시스템 접근 테스트

Ubuntu 터미널에서:
```bash
# Windows 파일 읽기
cat /mnt/c/ansible_server_check/README.md | head -5

# Windows 파일 편집 (Cursor에서)
# Ubuntu에서 바로 확인 가능
ls -la /mnt/c/ansible_server_check/
```

## 📝 권장 워크플로우

### Ansible 프로젝트 작업 시

1. **Cursor에서 파일 편집**
   - Windows 파일 시스템에서 직접 편집
   - `C:\ansible_server_check\` 경로

2. **Ubuntu 터미널에서 실행**
   ```bash
   cd /mnt/c/ansible_server_check
   ansible-playbook ...
   ```

3. **결과 확인**
   - Cursor에서 로그 파일 확인
   - Ubuntu 터미널에서 실시간 출력 확인

## 🐛 문제 해결

### Ubuntu 터미널이 보이지 않을 때

1. `Ctrl + Shift + P`
2. `Terminal: Select Default Profile`
3. "Ubuntu" 또는 "WSL" 확인

### 터미널이 느릴 때

```powershell
# WSL 재시작
wsl --shutdown
wsl -d Ubuntu
```

### 파일 권한 문제

Ubuntu에서 Windows 파일을 실행할 때:
```bash
# 실행 권한 부여
chmod +x /mnt/c/ansible_server_check/start_api_server.sh
```

## ✅ 체크리스트

- [x] Ubuntu WSL 설치됨
- [x] Cursor에서 Ubuntu 터미널 열기 가능
- [x] Windows ↔ Ubuntu 파일 시스템 접근 가능
- [x] Ansible 설치됨
- [x] 프로젝트 디렉토리 접근 가능 (`/mnt/c/ansible_server_check`)

---

**결론**: Cursor IDE와 Ubuntu WSL이 완벽하게 연동되어 있습니다! 🎉

