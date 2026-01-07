# WAS 점검 실행 스크립트 (PowerShell)

Write-Host "🚀 WAS 점검 시작..." -ForegroundColor Cyan
Write-Host ""

# WSL을 통해 실행
$playbookPath = "tomcat_check/tomcat_check.yml"

Write-Host "WSL에서 Ansible 플레이북 실행 중..." -ForegroundColor Yellow
wsl bash -c "cd /mnt/host/c/ansible_server_check && ansible-playbook -i localhost, $playbookPath --connection=local --ask-become-pass"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ WAS 점검 완료!" -ForegroundColor Green
    Write-Host "대시보드에서 확인: http://192.168.0.18:8000/api/was-checks/report" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "❌ WAS 점검 실패 (종료 코드: $LASTEXITCODE)" -ForegroundColor Red
    Write-Host "WSL에서 Ansible이 설치되어 있는지 확인하세요." -ForegroundColor Yellow
}

