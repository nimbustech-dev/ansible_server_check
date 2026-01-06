# WSL and Ubuntu Connection Status Check Script

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "WSL and Ubuntu Connection Status Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. List WSL distributions
Write-Host "[1] Installed WSL Distributions:" -ForegroundColor Yellow
wsl --list --verbose
Write-Host ""

# 2. Ubuntu connection test
Write-Host "[2] Ubuntu Connection Test:" -ForegroundColor Yellow
$ubuntuUser = wsl -d Ubuntu -- whoami 2>&1
$ubuntuHost = wsl -d Ubuntu -- hostname 2>&1
$ubuntuPath = wsl -d Ubuntu -- pwd 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Ubuntu is accessible" -ForegroundColor Green
    Write-Host "   User: $ubuntuUser" -ForegroundColor White
    Write-Host "   Host: $ubuntuHost" -ForegroundColor White
    Write-Host "   Path: $ubuntuPath" -ForegroundColor White
} else {
    Write-Host "[FAIL] Ubuntu connection failed" -ForegroundColor Red
}
Write-Host ""

# 3. Ubuntu OS information
Write-Host "[3] Ubuntu OS Information:" -ForegroundColor Yellow
$osInfo = wsl -d Ubuntu -- uname -a 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host $osInfo -ForegroundColor White
}
Write-Host ""

# 4. Ansible installation check
Write-Host "[4] Ansible Installation Check:" -ForegroundColor Yellow
$ansibleCheck = wsl -d Ubuntu -- which ansible 2>&1
if ($LASTEXITCODE -eq 0 -and $ansibleCheck -match "ansible") {
    $ansibleVersion = wsl -d Ubuntu -- ansible --version 2>&1 | Select-Object -First 1
    Write-Host "[OK] Ansible is installed" -ForegroundColor Green
    Write-Host "   Version: $ansibleVersion" -ForegroundColor White
} else {
    Write-Host "[FAIL] Ansible is not installed" -ForegroundColor Red
    Write-Host "   Install command: wsl -d Ubuntu -- sudo apt install -y ansible" -ForegroundColor Yellow
}
Write-Host ""

# 5. Current terminal environment
Write-Host "[5] Current Terminal Environment:" -ForegroundColor Yellow
Write-Host "   Environment: PowerShell (Windows)" -ForegroundColor White
Write-Host "   Path: $(Get-Location)" -ForegroundColor White
Write-Host "   User: $env:USERNAME" -ForegroundColor White
Write-Host ""
Write-Host "To access Ubuntu: wsl or wsl -d Ubuntu" -ForegroundColor Cyan
Write-Host ""

