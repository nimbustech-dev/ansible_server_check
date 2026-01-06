# Ubuntu WSL 설치 스크립트
# PowerShell 관리자 권한으로 실행 필요

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Ubuntu WSL 설치 스크립트" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 관리자 권한 확인
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "오류: 이 스크립트는 관리자 권한으로 실행해야 합니다." -ForegroundColor Red
    Write-Host "PowerShell을 관리자 권한으로 실행한 후 다시 시도하세요." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "방법: 시작 메뉴에서 PowerShell을 찾아 '관리자 권한으로 실행'을 선택하세요." -ForegroundColor Yellow
    exit 1
}

Write-Host "[1/5] WSL 기능 활성화 중..." -ForegroundColor Green
try {
    # WSL 기능 활성화
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    Write-Host "✓ WSL 기능 활성화 완료" -ForegroundColor Green
} catch {
    Write-Host "✗ WSL 기능 활성화 실패: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/5] Virtual Machine Platform 기능 활성화 중..." -ForegroundColor Green
try {
    # Virtual Machine Platform 활성화 (WSL2에 필요)
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    Write-Host "✓ Virtual Machine Platform 활성화 완료" -ForegroundColor Green
} catch {
    Write-Host "✗ Virtual Machine Platform 활성화 실패: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[3/5] 시스템 재시작이 필요합니다." -ForegroundColor Yellow
Write-Host "재시작 후 이 스크립트를 다시 실행하면 Ubuntu 설치가 계속됩니다." -ForegroundColor Yellow
Write-Host ""
$restart = Read-Host "지금 재시작하시겠습니까? (Y/N)"
if ($restart -eq "Y" -or $restart -eq "y") {
    Write-Host "시스템을 재시작합니다..." -ForegroundColor Yellow
    Restart-Computer
} else {
    Write-Host ""
    Write-Host "수동으로 재시작한 후 다음 명령어를 실행하세요:" -ForegroundColor Yellow
    Write-Host "  wsl --install -d Ubuntu" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "또는 Microsoft Store에서 'Ubuntu'를 검색하여 설치할 수 있습니다." -ForegroundColor Yellow
    exit 0
}

