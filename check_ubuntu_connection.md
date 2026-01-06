# Ubuntu WSL 접속 확인 방법

## 🔍 접속 상태 확인 방법

### 1. PowerShell에서 WSL 상태 확인

```powershell
# 설치된 WSL 배포판 목록 및 상태 확인
wsl --list --verbose
```

**출력 예시:**
```
  NAME                   STATE           VERSION
* Ubuntu                 Running         2
  docker-desktop         Stopped         2
```

- `Running`: 현재 실행 중 (접속 가능)
- `Stopped`: 중지됨 (접속하려면 시작 필요)

### 2. 현재 터미널이 Ubuntu인지 확인

#### 방법 A: 호스트명 확인
```bash
hostname
```
- Windows PowerShell: `PC` 또는 컴퓨터 이름
- Ubuntu: `PC` 또는 `ubuntu` 등 (보통 같지만 환경 변수로 구분 가능)

#### 방법 B: OS 정보 확인
```bash
uname -a
```
- Windows PowerShell: 오류 또는 Windows 정보
- Ubuntu: `Linux ... WSL2 ...` 출력

#### 방법 C: 현재 셸 확인
```bash
echo $SHELL
```
- Windows PowerShell: PowerShell 경로
- Ubuntu: `/bin/bash` 또는 `/bin/zsh`

#### 방법 D: 사용자 확인
```bash
whoami
```
- Windows PowerShell: Windows 사용자명
- Ubuntu: Ubuntu 사용자명 (예: `soomin`)

#### 방법 E: 경로 확인
```bash
pwd
```
- Windows PowerShell: `C:\...` 형식
- Ubuntu: `/mnt/c/...` 또는 `/home/...` 형식

### 3. 간단한 확인 스크립트

PowerShell에서:
```powershell
# Ubuntu가 실행 중인지 확인
wsl -d Ubuntu -- echo "Ubuntu 접속 가능"
```

Ubuntu에서:
```bash
# 현재 환경 확인
if [ -f /etc/os-release ]; then
    echo "✅ Ubuntu 환경입니다"
    cat /etc/os-release | grep PRETTY_NAME
else
    echo "❌ Ubuntu가 아닙니다"
fi
```

## 🚀 빠른 확인 명령어

### PowerShell에서 한 번에 확인
```powershell
# Ubuntu 상태 확인
wsl --list --verbose | Select-String "Ubuntu"

# Ubuntu에서 명령 실행 테스트
wsl -d Ubuntu -- uname -a
```

### Ubuntu에서 확인
```bash
# OS 정보
cat /etc/os-release

# WSL 버전 확인
cat /proc/version
```

## 📝 실용적인 확인 스크립트

### PowerShell 스크립트 (check_wsl.ps1)
```powershell
Write-Host "WSL 상태 확인 중..." -ForegroundColor Cyan
wsl --list --verbose

Write-Host "`nUbuntu 접속 테스트..." -ForegroundColor Cyan
$result = wsl -d Ubuntu -- uname -a 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Ubuntu 접속 가능" -ForegroundColor Green
    Write-Host $result
} else {
    Write-Host "❌ Ubuntu 접속 불가" -ForegroundColor Red
}
```

### Bash 스크립트 (check_env.sh)
```bash
#!/bin/bash
echo "현재 환경 확인:"
echo "OS: $(uname -s)"
echo "호스트명: $(hostname)"
echo "사용자: $(whoami)"
echo "경로: $(pwd)"
echo "셸: $SHELL"

if [ -f /proc/version ] && grep -q "microsoft" /proc/version; then
    echo "✅ WSL 환경입니다"
else
    echo "❌ WSL 환경이 아닙니다"
fi
```

## 💡 팁

1. **PowerShell 프롬프트**: `PS C:\...>`
2. **Ubuntu 프롬프트**: `soomin@PC:/mnt/c/...$` 또는 `$`

3. **빠른 전환**:
   - PowerShell → Ubuntu: `wsl`
   - Ubuntu → PowerShell: `exit`

4. **상태 확인**:
   ```powershell
   # WSL이 실행 중인지 확인
   Get-Process | Where-Object {$_.ProcessName -like "*wsl*"}
   ```

