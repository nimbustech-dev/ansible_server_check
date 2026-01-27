#!/bin/bash
# 네이버 클라우드 서버 자동 점검 스크립트
# 매일 오전 7시에 모든 점검을 실행

# 환경 변수 설정 (크론잡 실행 시 필요)
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export HOME=/home/sth0824

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 로그 디렉토리 생성
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"

# 날짜별 로그 파일
LOG_DATE=$(date '+%Y%m%d')
LOG_FILE="$LOG_DIR/navercloud_check_${LOG_DATE}.log"
CRON_LOG_FILE="$LOG_DIR/navercloud_cron.log"

# 색상 출력
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 로그 함수
log() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo -e "$message" | tee -a "$LOG_FILE"
    # Cron에서 실행된 경우 cron 로그에도 기록
    if [ -n "$CRON_MODE" ]; then
        echo "$message" >> "$CRON_LOG_FILE"
    fi
}

# 색상 로그 함수
log_info() {
    log "${CYAN}ℹ️  $1${NC}"
}

log_success() {
    log "${GREEN}✅ $1${NC}"
}

log_warning() {
    log "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    log "${RED}❌ $1${NC}"
}

# Cron job 설정 함수
setup_cron() {
    local script_path="$SCRIPT_DIR/auto_check_navercloud.sh"
    local cron_entry="0 7 * * * $script_path --cron >> $CRON_LOG_FILE 2>&1"
    
    # 기존 cron job 확인
    if crontab -l 2>/dev/null | grep -q "auto_check_navercloud.sh"; then
        log_warning "이미 cron job이 등록되어 있습니다."
        echo ""
        echo "현재 cron job:"
        crontab -l 2>/dev/null | grep "auto_check_navercloud.sh"
        echo ""
        read -p "기존 항목을 삭제하고 새로 등록하시겠습니까? (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            # 기존 항목 삭제
            crontab -l 2>/dev/null | grep -v "auto_check_navercloud.sh" | crontab -
            log_info "기존 cron job 삭제 완료"
        else
            log_info "Cron job 설정을 취소했습니다."
            return 1
        fi
    fi
    
    # 새 cron job 추가
    (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
    
    if [ $? -eq 0 ]; then
        log_success "Cron job이 등록되었습니다!"
        echo ""
        echo "등록된 cron job:"
        crontab -l 2>/dev/null | grep "auto_check_navercloud.sh"
        echo ""
        echo "매일 오전 7시에 자동으로 점검이 실행됩니다."
        return 0
    else
        log_error "Cron job 등록에 실패했습니다."
        return 1
    fi
}

# 점검 실행 함수
run_check() {
    local check_name="$1"
    local playbook="$2"
    local hosts_group="$3"
    
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "$check_name 점검 시작"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local start_time=$(date +%s)
    
    # Ansible 플레이북 실행
    if [ -n "$hosts_group" ]; then
        ansible-playbook -i hosts.ini "$playbook" --limit "$hosts_group" >> "$LOG_FILE" 2>&1
    else
        ansible-playbook -i hosts.ini "$playbook" >> "$LOG_FILE" 2>&1
    fi
    
    local exit_code=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ $exit_code -eq 0 ]; then
        log_success "$check_name 점검 완료 (소요 시간: ${duration}초)"
        return 0
    else
        log_error "$check_name 점검 실패 (종료 코드: $exit_code, 소요 시간: ${duration}초)"
        return 1
    fi
}

# 메인 실행 함수
main() {
    # Cron 모드 확인
    if [ "$1" = "--cron" ]; then
        CRON_MODE=1
    fi
    
    log_info "=========================================="
    log_info "네이버 클라우드 서버 자동 점검 시작"
    log_info "=========================================="
    log_info "점검 대상: nimbus-server (네이버 클라우드)"
    log_info "점검 일시: $(date '+%Y-%m-%d %H:%M:%S')"
    log_info "로그 파일: $LOG_FILE"
    log_info ""
    
    # 전체 시작 시간
    total_start_time=$(date +%s)
    
    # 점검 결과 추적
    local results=()
    local total_checks=0
    local success_checks=0
    local failed_checks=0
    
    # 1. OS 점검 (Redhat)
    total_checks=$((total_checks + 1))
    if run_check "OS (Redhat)" "redhat_check/redhat_check.yml" ""; then
        success_checks=$((success_checks + 1))
        results+=("OS 점검: ✅ 성공")
    else
        failed_checks=$((failed_checks + 1))
        results+=("OS 점검: ❌ 실패")
    fi
    
    log_info ""
    
    # 2. MariaDB 점검
    total_checks=$((total_checks + 1))
    if run_check "MariaDB" "mariadb_check/mariadb_check.yml" "mariadb"; then
        success_checks=$((success_checks + 1))
        results+=("MariaDB 점검: ✅ 성공")
    else
        failed_checks=$((failed_checks + 1))
        results+=("MariaDB 점검: ❌ 실패")
    fi
    
    log_info ""
    
    # 3. PostgreSQL 점검
    total_checks=$((total_checks + 1))
    if run_check "PostgreSQL" "postgresql_check/postgresql_check.yml" "postgresql"; then
        success_checks=$((success_checks + 1))
        results+=("PostgreSQL 점검: ✅ 성공")
    else
        failed_checks=$((failed_checks + 1))
        results+=("PostgreSQL 점검: ❌ 실패")
    fi
    
    log_info ""
    
    # 4. Tomcat 점검
    total_checks=$((total_checks + 1))
    if run_check "Tomcat" "tomcat_check/tomcat_check.yml" ""; then
        success_checks=$((success_checks + 1))
        results+=("Tomcat 점검: ✅ 성공")
    else
        failed_checks=$((failed_checks + 1))
        results+=("Tomcat 점검: ❌ 실패")
    fi
    
    # 전체 종료 시간
    total_end_time=$(date +%s)
    total_duration=$((total_end_time - total_start_time))
    
    # 결과 요약
    log_info ""
    log_info "=========================================="
    log_info "점검 결과 요약"
    log_info "=========================================="
    
    for result in "${results[@]}"; do
        log_info "$result"
    done
    
    log_info ""
    log_info "총 점검 수: $total_checks"
    log_info "성공: $success_checks"
    log_info "실패: $failed_checks"
    log_info "총 소요 시간: ${total_duration}초"
    
    if [ $failed_checks -eq 0 ]; then
        log_success "모든 점검이 성공적으로 완료되었습니다!"
        log_info "리포트 확인: http://192.168.0.18:8000/api/report"
    else
        log_warning "일부 점검이 실패했습니다. 로그를 확인하세요."
        log_info "로그 파일: $LOG_FILE"
    fi
    
    log_info "=========================================="
    
    # 실패한 점검이 있으면 종료 코드 1 반환
    if [ $failed_checks -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# 인자 처리
if [ "$1" = "--setup-cron" ]; then
    setup_cron
    exit $?
elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "네이버 클라우드 서버 자동 점검 스크립트"
    echo ""
    echo "사용법:"
    echo "  $0                 - 점검 실행"
    echo "  $0 --cron          - Cron 모드로 실행 (로그만 기록)"
    echo "  $0 --setup-cron    - Cron job 등록 (매일 오전 7시)"
    echo "  $0 --help          - 도움말 표시"
    echo ""
    echo "점검 항목:"
    echo "  - OS (Redhat) 점검"
    echo "  - MariaDB 점검"
    echo "  - PostgreSQL 점검"
    echo "  - Tomcat 점검"
    echo ""
    echo "로그 파일:"
    echo "  - $LOG_DIR/navercloud_check_YYYYMMDD.log"
    exit 0
else
    main "$@"
fi
