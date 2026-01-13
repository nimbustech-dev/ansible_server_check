# API 서버 재시작 스크립트 (Windows PowerShell)

Write-Host "🔄 API 서버 재시작 중..." -ForegroundColor Yellow

# API 서버 디렉토리로 이동
$apiDir = Join-Path $PSScriptRoot "api_server"
Set-Location $apiDir

# 포트 8000을 사용하는 프로세스 찾기
Write-Host "`n📋 포트 8000 사용 중인 프로세스 확인..." -ForegroundColor Cyan
$processes = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique

if ($processes) {
    foreach ($pid in $processes) {
        $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "   발견: PID $pid - $($proc.ProcessName)" -ForegroundColor Yellow
            Write-Host "   종료 중..." -ForegroundColor Yellow
            Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
        }
    }
    Start-Sleep -Seconds 2
    Write-Host "✅ 기존 프로세스 종료 완료" -ForegroundColor Green
} else {
    Write-Host "   실행 중인 프로세스 없음" -ForegroundColor Gray
}

# Python 프로세스도 확인 (main.py 실행 중인 경우)
Write-Host "`n📋 Python 프로세스 확인..." -ForegroundColor Cyan
$pythonProcs = Get-Process python* -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*main.py*" -or $_.Path -like "*api_server*"
}

if ($pythonProcs) {
    foreach ($proc in $pythonProcs) {
        Write-Host "   발견: PID $($proc.Id) - $($proc.ProcessName)" -ForegroundColor Yellow
        Write-Host "   종료 중..." -ForegroundColor Yellow
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 2
    Write-Host "✅ Python 프로세스 종료 완료" -ForegroundColor Green
}

# API 서버 재시작
Write-Host "`n🚀 API 서버 시작 중..." -ForegroundColor Cyan

# 가상환경 확인
$venvPath = Join-Path $apiDir "venv"
if (Test-Path $venvPath) {
    $pythonPath = Join-Path $venvPath "Scripts\python.exe"
    if (Test-Path $pythonPath) {
        Write-Host "   가상환경 사용: $pythonPath" -ForegroundColor Gray
        & $pythonPath main.py
    } else {
        Write-Host "   가상환경 Python 없음, 시스템 Python 사용" -ForegroundColor Yellow
        python main.py
    }
} else {
    Write-Host "   가상환경 없음, 시스템 Python 사용" -ForegroundColor Yellow
    python main.py
}

Write-Host "`n✅ API 서버가 시작되었습니다!" -ForegroundColor Green
Write-Host "   주소: http://192.168.0.18:8000" -ForegroundColor Cyan
Write-Host "   WAS 데이터: http://192.168.0.18:8000/api/was-checks/data" -ForegroundColor Cyan
Write-Host "   WAS 대시보드: http://192.168.0.18:8000/api/was-checks/report" -ForegroundColor Cyan
Write-Host "`n종료하려면 Ctrl+C를 누르세요." -ForegroundColor Yellow


