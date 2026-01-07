@echo off
REM WAS 점검 실행 스크립트 (배치 파일)

echo WAS 점검 시작...
echo.

REM WSL을 통해 실행
wsl bash -c "cd /mnt/host/c/ansible_server_check && ansible-playbook -i localhost, tomcat_check/tomcat_check.yml --connection=local --ask-become-pass"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo WAS 점검 완료!
    echo 대시보드에서 확인: http://192.168.0.18:8000/api/was-checks/report
) else (
    echo.
    echo WAS 점검 실패
    echo WSL에서 Ansible이 설치되어 있는지 확인하세요.
)

pause

