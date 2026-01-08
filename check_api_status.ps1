# API 서버 상태 확인 스크립트

Write-Host "🔍 API 서버 상태 확인 중..." -ForegroundColor Cyan

# 1. 포트 8000 사용 중인 프로세스 확인
Write-Host "`n📋 포트 8000 사용 중인 프로세스:" -ForegroundColor Yellow
$connections = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue
if ($connections) {
    foreach ($conn in $connections) {
        $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "   PID: $($proc.Id) - $($proc.ProcessName) - $($proc.Path)" -ForegroundColor Green
        }
    }
} else {
    Write-Host "   ❌ 포트 8000을 사용하는 프로세스가 없습니다." -ForegroundColor Red
}

# 2. API 엔드포인트 확인
Write-Host "`n📡 API 엔드포인트 확인:" -ForegroundColor Yellow

$endpoints = @(
    "http://192.168.0.18:8000/api/was-checks/data?limit=1",
    "http://192.168.0.18:8000/api/was-checks/report",
    "http://192.168.0.18:8000/docs"
)

foreach ($url in $endpoints) {
    try {
        $response = Invoke-WebRequest -Uri $url -Method Get -TimeoutSec 3 -ErrorAction Stop
        Write-Host "   ✅ $url - 상태: $($response.StatusCode)" -ForegroundColor Green
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode) {
            Write-Host "   ⚠️  $url - 상태: $statusCode" -ForegroundColor Yellow
        } else {
            Write-Host "   ❌ $url - 연결 실패: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`n💡 해결 방법:" -ForegroundColor Cyan
Write-Host "   1. API 서버가 실행 중이 아니면 재시작하세요" -ForegroundColor White
Write-Host "   2. 브라우저에서 Ctrl+Shift+R로 강력 새로고침" -ForegroundColor White
Write-Host "   3. 개발자 도구(F12) → Network 탭에서 요청 확인" -ForegroundColor White


