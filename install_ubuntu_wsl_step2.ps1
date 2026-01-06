# Ubuntu WSL 설치 스크립트 - 2단계 (재시작 후 실행)
# PowerShell 관리자 권한으로 실행 필요

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Ubuntu WSL 설치 스크립트 - 2단계" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 관리자 권한 확인
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "오류: 이 스크립트는 관리자 권한으로 실행해야 합니다." -ForegroundColor Red
    exit 1
}

Write-Host "[1/3] WSL 기본 버전을 WSL2로 설정 중..." -ForegroundColor Green
try {
    wsl --set-default-version 2
    Write-Host "✓ WSL2 기본 버전 설정 완료" -ForegroundColor Green
} catch {
    Write-Host "⚠ WSL2 설정 실패 (이미 설정되어 있거나 WSL2 커널 업데이트 필요)" -ForegroundColor Yellow
    Write-Host "WSL2 커널 업데이트가 필요하면 다음 링크에서 다운로드하세요:" -ForegroundColor Yellow
    Write-Host "https://aka.ms/wsl2kernel" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "[2/3] Ubuntu 설치 중..." -ForegroundColor Green
try {
    wsl --install -d Ubuntu
    Write-Host "✓ Ubuntu 설치 완료" -ForegroundColor Green
} catch {
    Write-Host "✗ Ubuntu 설치 실패: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "대안: Microsoft Store에서 Ubuntu를 설치하세요:" -ForegroundColor Yellow
    Write-Host "1. Microsoft Store 열기" -ForegroundColor Yellow
    Write-Host "2. 'Ubuntu' 검색" -ForegroundColor Yellow
    Write-Host "3. 'Ubuntu' 또는 'Ubuntu 22.04 LTS' 설치" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "[3/3] 설치된 WSL 배포판 확인 중..." -ForegroundColor Green
wsl --list --verbose

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "설치 완료!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "다음 단계:" -ForegroundColor Yellow
Write-Host "1. 'wsl' 또는 'ubuntu' 명령어로 Ubuntu에 접속" -ForegroundColor White
Write-Host "2. 처음 실행 시 사용자명과 비밀번호 설정" -ForegroundColor White
Write-Host "3. Ubuntu에서 Ansible 설치:" -ForegroundColor White
Write-Host "   sudo apt update" -ForegroundColor Cyan
Write-Host "   sudo apt install -y ansible python3-pip" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ubuntu 접속: wsl" -ForegroundColor Cyan
Write-Host ""

