# 📘 팀원용 API 점검 결과 저장 가이드

## 🎯 목적

이 가이드는 **팀원들이 Ansible로 점검한 결과를 API를 통해 중앙 PostgreSQL 데이터베이스에 저장**하는 방법을 설명합니다.

### 현재 상황
- ✅ 각자 Ansible로 점검하고 결과를 뽑아내는 것까지는 성공
- ✅ 같은 와이파이 네트워크 사용 중
- ⚠️ **이제 점검 결과를 API를 통해 중앙 DB에 저장해야 함**

**참고:** 같은 네트워크를 사용하더라도 각 컴퓨터는 고유한 IP 주소를 가집니다. API 서버는 DB 담당자 PC에서만 실행되므로, 모든 팀원이 DB 담당자 PC의 IP 주소를 사용해야 합니다.

### 목표
- 모든 팀원의 점검 결과가 **같은 PostgreSQL 데이터베이스**에 저장됨
- API 서버 주소: `http://192.168.0.18:8000/api/checks` (DB 담당자 PC에서 실행 중)

### ⚠️ 중요: 네트워크 IP 주소 안내

**같은 와이파이 네트워크를 사용하더라도, 각 컴퓨터는 고유한 IP 주소를 가집니다!**

- ✅ **DB 담당자 PC**: `192.168.0.18` (API 서버가 실행되는 컴퓨터)
- ⚠️ **강하나 PC**: 다른 IP 주소 (예: `192.168.0.19`)
- ⚠️ **이수민 PC**: 다른 IP 주소 (예: `192.168.0.20`)

**중요:** 
- 각 팀원은 **자신의 IP 주소가 아니라, DB 담당자 PC의 IP 주소(`192.168.0.18`)**를 사용해야 합니다!
- API 서버는 DB 담당자 PC에서만 실행되므로, 모든 팀원이 `192.168.0.18`을 사용합니다.
- 만약 DB 담당자 PC의 IP 주소가 변경되었다면, DB 담당자에게 새 IP 주소를 확인하세요.

### 🤖 AI 코딩 도구 활용 안내

**중요:** 이 가이드에 없는 내용이나 부족한 부분이 있다면, **AI 코딩 도구를 활용해서 직접 해결하세요!**

- ✅ AI에게 이 가이드를 참고해서 코드 작성 요청
- ✅ AI에게 예제 코드를 자신의 환경에 맞게 수정 요청
- ✅ AI에게 에러 메시지를 보여주고 해결 방법 요청
- ✅ AI에게 추가 기능이나 개선 사항 구현 요청

**DB 담당자에게 굳이 문의할 필요 없이, AI를 활용해서 자유롭게 작업하세요!**

---

## 📋 담당자별 가이드

### 👤 강하나 (OS/Redhat 점검 담당자)
[강하나 담당자용 가이드](#강하나-osredhat-점검-담당자-가이드)

### 👤 이수민 (WAS/ApacheTomcat 점검 담당자)
[이수민 담당자용 가이드](#이수민-wasapachetomcat-점검-담당자-가이드)

---

## 🔧 공통 사전 준비 (모든 담당자)

### 1단계: API 서버 연결 확인

터미널에서 다음 명령어로 API 서버가 정상 작동하는지 확인하세요:

```bash
curl http://192.168.0.18:8000/api/health
```

**⚠️ 중요:** 
- `192.168.0.18`은 **DB 담당자 PC의 IP 주소**입니다.
- 각 팀원은 자신의 IP 주소가 아니라, **DB 담당자 PC의 IP 주소**를 사용해야 합니다!
- 만약 연결이 안 되면, DB 담당자에게 현재 IP 주소를 확인하세요.

**성공 응답 예시:**
```json
{"status":"healthy","timestamp":"2025-12-30T10:00:00"}
```

**실패 시 (Connection refused 등):**
1. **IP 주소 확인:** DB 담당자에게 현재 IP 주소 확인 요청
2. **AI에게 요청:** "API 서버 연결 오류 해결 방법" 요청
3. **네트워크 연결 확인:**
   ```bash
   ping 192.168.0.18  # DB 담당자 PC IP 주소
   ```
4. 필요시 DB 담당자에게 API 서버 실행 요청

### 2단계: 프로젝트 구조 확인

현재 Ansible 프로젝트에서 다음 구조가 있는지 확인:

```
프로젝트루트/
├── common/
│   └── roles/
│       └── api_sender/          # ← 이 디렉토리가 있어야 함
│           └── tasks/
│               └── main.yml
└── config/
    └── api_config.yml           # ← 이 파일 생성 필요
```

**없다면:** 
- AI에게 "Ansible common roles api_sender 구조 생성" 요청
- 또는 DB 담당자에게 `common/roles/api_sender/` 디렉토리 복사 요청

---

## ⚙️ 공통 설정 (모든 담당자)

### Config 파일 생성

프로젝트 루트에 `config/api_config.yml` 파일을 생성하세요:

```yaml
# config/api_config.yml
api_server:
  url: "http://192.168.0.18:8000/api/checks"  # API 서버 주소 (DB 담당자 PC IP)
  timeout: 30                                  # 타임아웃 (초)
  retry_count: 3                               # 재시도 횟수

# 기본 담당자 정보 (각자 자신의 이름으로 수정)
default_checker: "강하나"  # 또는 "이수민"
```

**⚠️ 중요:** 
- `url`의 `192.168.0.18`은 **DB 담당자 PC의 IP 주소**입니다.
- 각 팀원은 자신의 IP 주소가 아니라, **DB 담당자 PC의 IP 주소**를 사용해야 합니다!
- 만약 DB 담당자 PC의 IP 주소가 변경되었다면, 새 IP 주소로 수정하세요.
- `default_checker` 값을 자신의 이름으로 변경하세요!

---

## 📝 API 전송 기능 추가 방법 (핵심)

### 기본 원리

현재 플레이북 구조:
```yaml
- name: 점검 이름
  hosts: all
  tasks:
    # 점검 작업들...
    - name: 점검 작업
      shell: ...
      register: result
```

**변경 후 구조:**
```yaml
- name: 점검 이름
  hosts: all
  
  # 1. API 설정 로드 추가
  pre_tasks:
    - name: Load API config if exists
      include_vars:
        file: config/api_config.yml
      failed_when: false
      ignore_errors: yes
  
  # 2. API 기본값 설정 추가
  vars:
    api_server:
      url: "{{ api_server.url | default('http://192.168.0.18:8000/api/checks') }}"
      timeout: "{{ api_server.timeout | default(30) }}"
      retry_count: "{{ api_server.retry_count | default(3) }}"
  
  tasks:
    # 점검 작업들... (기존과 동일)
    - name: 점검 작업
      shell: ...
      register: result
  
  # 3. API 전송 추가 (가장 중요!)
  post_tasks:
    - name: Send check results to API
      include_tasks: "{{ playbook_dir }}/common/roles/api_sender/tasks/main.yml"
      vars:
        check_type: "os"  # 또는 "was"
        checker_name: "{{ default_checker | default('담당자이름') }}"
        check_results:
          # 여기에 점검 결과를 딕셔너리 형식으로 넣기
          cpu: "{{ cpu_info.stdout | default('N/A') }}"
          memory: "{{ mem_info.stdout | default('N/A') }}"
```

### 핵심 포인트

1. **pre_tasks**: API 설정 파일 로드 (없어도 기본값 사용)
2. **vars**: API 서버 주소 및 기본값 설정
3. **post_tasks**: 점검 완료 후 API로 결과 전송
4. **check_results**: 모든 점검 결과를 딕셔너리 형식으로 구조화

---

## 👤 강하나 (OS/Redhat 점검 담당자) 가이드

### 현재 상황 가정
- Redhat OS 점검 플레이북이 이미 있음
- 점검 결과를 수집하는 것까지는 성공
- 이제 API로 전송해야 함

### 예제: OS 점검 플레이북에 API 전송 추가

#### Step 1: 기존 플레이북 확인

현재 플레이북이 다음과 같다고 가정:

```yaml
---
- name: Redhat OS 점검
  hosts: all
  become: yes
  gather_facts: yes
  
  tasks:
    - name: Get CPU model
      shell: lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs
      register: cpu_info
      changed_when: false
    
    - name: Get memory info
      shell: free -h
      register: mem_info
      changed_when: false
    
    - name: Get disk usage
      shell: df -h / | awk 'NR==2 {print $5}' | tr -d '%'
      register: disk_usage
      changed_when: false
```

#### Step 2: API 전송 기능 추가

위 플레이북을 다음과 같이 수정:

```yaml
---
- name: Redhat OS 점검
  hosts: all
  become: yes
  gather_facts: yes
  
  # ============================================
  # API 설정 로드 (추가)
  # ============================================
  pre_tasks:
    - name: Load API config if exists
      include_vars:
        file: config/api_config.yml
      failed_when: false
      ignore_errors: yes
  
  # ============================================
  # API 기본값 설정 (추가)
  # ============================================
  vars:
    api_server:
      url: "{{ api_server.url | default('http://192.168.0.18:8000/api/checks') }}"
      timeout: "{{ api_server.timeout | default(30) }}"
      retry_count: "{{ api_server.retry_count | default(3) }}"
  
  # ============================================
  # 기존 점검 작업들 (변경 없음)
  # ============================================
  tasks:
    - name: Get CPU model
      shell: lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs
      register: cpu_info
      changed_when: false
    
    - name: Get memory info
      shell: free -h
      register: mem_info
      changed_when: false
    
    - name: Get disk usage
      shell: df -h / | awk 'NR==2 {print $5}' | tr -d '%'
      register: disk_usage
      changed_when: false
    
    # ... 기타 점검 작업들 ...
  
  # ============================================
  # API 전송 (추가 - 가장 중요!)
  # ============================================
  post_tasks:
    - name: Send OS check results to API
      include_tasks: "{{ playbook_dir }}/common/roles/api_sender/tasks/main.yml"
      vars:
        check_type: "os"  # OS 점검임을 명시
        checker_name: "{{ default_checker | default('강하나') }}"
        check_results:
          # 모든 점검 결과를 딕셔너리로 구조화
          cpu:
            model: "{{ cpu_info.stdout | default('N/A') }}"
          memory:
            info: "{{ mem_info.stdout | default('N/A') }}"
          disk:
            root_usage_percent: "{{ disk_usage.stdout | default('N/A') }}"
          # ... 기타 점검 결과들 ...
```

### 완전한 OS 점검 예제

```yaml
---
- name: Redhat OS 점검 및 API 전송
  hosts: all
  become: yes
  gather_facts: yes
  
  pre_tasks:
    - name: Load API config if exists
      include_vars:
        file: config/api_config.yml
      failed_when: false
      ignore_errors: yes
  
  vars:
    api_server:
      url: "{{ api_server.url | default('http://192.168.0.18:8000/api/checks') }}"
      timeout: "{{ api_server.timeout | default(30) }}"
      retry_count: "{{ api_server.retry_count | default(3) }}"
  
  tasks:
    # 1. CPU 정보
    - name: Get CPU model name
      shell: lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs
      register: cpu_info
      changed_when: false
      failed_when: false
    
    - name: Get CPU cores
      shell: nproc
      register: cpu_cores
      changed_when: false
      failed_when: false
    
    # 2. 메모리 정보
    - name: Get memory info
      shell: free -h
      register: mem_info
      changed_when: false
      failed_when: false
    
    # 3. 디스크 사용률
    - name: Get disk usage for root
      shell: df -h / | awk 'NR==2 {print $5}' | tr -d '%'
      register: disk_usage_root
      changed_when: false
      failed_when: false
    
    - name: Get all disk usage
      shell: df -h
      register: disk_all
      changed_when: false
      failed_when: false
    
    # 4. 네트워크 연결 확인
    - name: Test network connectivity
      shell: ping -c 2 8.8.8.8
      register: network_test
      failed_when: false
      changed_when: false
    
    # 5. 시스템 부하
    - name: Get system load average
      shell: uptime | awk -F'load average:' '{print $2}' | xargs
      register: load_avg
      changed_when: false
      failed_when: false
    
    # 6. 실행 중인 프로세스 수
    - name: Get process count
      shell: ps aux | wc -l
      register: process_count
      changed_when: false
      failed_when: false
    
    # 7. 시간 동기화 상태 (Redhat의 경우 chrony)
    - name: Check NTP sync status
      shell: chronyc sources -v 2>/dev/null || echo "NTP not configured"
      register: ntp_check
      failed_when: false
      changed_when: false
    
    # 8. 시스템 업타임
    - name: Get system uptime
      shell: uptime -p
      register: uptime
      failed_when: false
      changed_when: false
    
    # 9. Redhat 특화: SELinux 상태
    - name: Check SELinux status
      shell: getenforce
      register: selinux_status
      failed_when: false
      changed_when: false
    
    # 10. Redhat 특화: 방화벽 상태
    - name: Check firewall status
      shell: firewall-cmd --state 2>/dev/null || echo "firewalld not running"
      register: firewall_status
      failed_when: false
      changed_when: false
  
  # API로 결과 전송
  post_tasks:
    - name: Send OS check results to API
      include_tasks: "{{ playbook_dir }}/common/roles/api_sender/tasks/main.yml"
      vars:
        check_type: "os"
        checker_name: "{{ default_checker | default('강하나') }}"
        check_results:
          cpu:
            model: "{{ cpu_info.stdout | default('N/A') }}"
            cores: "{{ cpu_cores.stdout | default('N/A') }}"
          memory:
            info: "{{ mem_info.stdout | default('N/A') }}"
          disk:
            root_usage_percent: "{{ disk_usage_root.stdout | default('N/A') }}"
            all_usage: "{{ disk_all.stdout | default('N/A') }}"
          network:
            connectivity: "{{ 'OK' if network_test.rc == 0 else 'FAILED' }}"
            ping_result: "{{ network_test.stdout | default('N/A') }}"
          system:
            load_average: "{{ load_avg.stdout | default('N/A') }}"
            process_count: "{{ process_count.stdout | default('N/A') }}"
            uptime: "{{ uptime.stdout | default('N/A') }}"
          ntp:
            status: "{{ ntp_check.stdout | default('N/A') }}"
          redhat_specific:
            selinux_status: "{{ selinux_status.stdout | default('N/A') }}"
            firewall_status: "{{ firewall_status.stdout | default('N/A') }}"
```

### 강하나 담당자 체크리스트

- [ ] API 서버 연결 확인 (`curl http://192.168.0.18:8000/api/health`)
- [ ] `config/api_config.yml` 파일 생성 및 `default_checker: "강하나"` 설정
- [ ] `common/roles/api_sender/` 디렉토리 확인
- [ ] 기존 OS 점검 플레이북에 `pre_tasks`, `vars`, `post_tasks` 추가
- [ ] `check_type: "os"` 설정
- [ ] 모든 점검 결과를 `check_results` 딕셔너리로 구조화
- [ ] 플레이북 실행 및 API 전송 확인

---

## 👤 이수민 (WAS/ApacheTomcat 점검 담당자) 가이드

### 현재 상황 가정
- ApacheTomcat WAS 점검 플레이북이 이미 있음
- 점검 결과를 수집하는 것까지는 성공
- 이제 API로 전송해야 함

### 예제: WAS 점검 플레이북에 API 전송 추가

#### Step 1: 기존 플레이북 확인

현재 플레이북이 다음과 같다고 가정:

```yaml
---
- name: ApacheTomcat WAS 점검
  hosts: all
  become: yes
  gather_facts: yes
  
  vars:
    tomcat_home: "/usr/local/tomcat9"
    was_port: "8080"
  
  tasks:
    - name: Check Tomcat service status
      systemd:
        name: tomcat
      register: tomcat_service
      failed_when: false
    
    - name: Check Tomcat process
      shell: ps -ef | grep java | grep tomcat | grep -v grep
      register: tomcat_process
      failed_when: false
    
    - name: Check Tomcat port
      shell: ss -lntp | grep 8080 || echo "NOT LISTENING"
      register: tomcat_port
      failed_when: false
```

#### Step 2: API 전송 기능 추가

위 플레이북을 다음과 같이 수정:

```yaml
---
- name: ApacheTomcat WAS 점검
  hosts: all
  become: yes
  gather_facts: yes
  
  # ============================================
  # API 설정 로드 (추가)
  # ============================================
  pre_tasks:
    - name: Load API config if exists
      include_vars:
        file: config/api_config.yml
      failed_when: false
      ignore_errors: yes
  
  vars:
    tomcat_home: "/usr/local/tomcat9"
    was_port: "8080"
    
    # ============================================
    # API 기본값 설정 (추가)
    # ============================================
    api_server:
      url: "{{ api_server.url | default('http://192.168.0.18:8000/api/checks') }}"
      timeout: "{{ api_server.timeout | default(30) }}"
      retry_count: "{{ api_server.retry_count | default(3) }}"
  
  # ============================================
  # 기존 점검 작업들 (변경 없음)
  # ============================================
  tasks:
    - name: Check Tomcat service status
      systemd:
        name: tomcat
      register: tomcat_service
      failed_when: false
    
    - name: Check Tomcat process
      shell: ps -ef | grep java | grep tomcat | grep -v grep
      register: tomcat_process
      failed_when: false
    
    - name: Check Tomcat port
      shell: ss -lntp | grep 8080 || echo "NOT LISTENING"
      register: tomcat_port
      failed_when: false
    
    # ... 기타 점검 작업들 ...
  
  # ============================================
  # API 전송 (추가 - 가장 중요!)
  # ============================================
  post_tasks:
    - name: Send WAS check results to API
      include_tasks: "{{ playbook_dir }}/common/roles/api_sender/tasks/main.yml"
      vars:
        check_type: "was"  # WAS 점검임을 명시
        checker_name: "{{ default_checker | default('이수민') }}"
        check_results:
          # 모든 점검 결과를 딕셔너리로 구조화
          service:
            status: "{{ tomcat_service.status.ActiveState | default('N/A') }}"
            enabled: "{{ tomcat_service.status.UnitFileState | default('N/A') }}"
          process:
            running: "{{ 'YES' if tomcat_process.stdout != '' else 'NO' }}"
            details: "{{ tomcat_process.stdout | default('N/A') }}"
          port:
            listening: "{{ 'YES' if 'LISTEN' in tomcat_port.stdout else 'NO' }}"
            details: "{{ tomcat_port.stdout | default('N/A') }}"
          # ... 기타 점검 결과들 ...
```

### 완전한 WAS 점검 예제

```yaml
---
- name: ApacheTomcat WAS 점검 및 API 전송
  hosts: all
  become: yes
  gather_facts: yes
  
  pre_tasks:
    - name: Load API config if exists
      include_vars:
        file: config/api_config.yml
      failed_when: false
      ignore_errors: yes
  
  vars:
    # WAS 서비스 이름 (환경에 맞게 수정)
    was_service_name: "tomcat"  # 또는 "tomcat9", "apache2" 등
    
    # Tomcat 경로 (환경에 맞게 수정)
    tomcat_home: "/usr/local/tomcat9"  # 또는 "/opt/tomcat" 등
    
    # WAS 포트 (환경에 맞게 수정)
    was_port: "8080"
    
    # API 기본값 설정
    api_server:
      url: "{{ api_server.url | default('http://192.168.0.18:8000/api/checks') }}"
      timeout: "{{ api_server.timeout | default(30) }}"
      retry_count: "{{ api_server.retry_count | default(3) }}"
  
  tasks:
    # 1. WAS 서비스 상태 확인
    - name: Check WAS service status
      systemd:
        name: "{{ was_service_name }}"
      register: was_service
      failed_when: false
      changed_when: false
    
    # 2. WAS 프로세스 확인
    - name: Check WAS process
      shell: ps -ef | grep java | grep -i tomcat | grep -v grep
      register: was_process
      failed_when: false
      changed_when: false
    
    # 3. WAS 포트 리스닝 확인
    - name: Check WAS port listening
      shell: ss -lntp | grep "{{ was_port }}" || echo "PORT {{ was_port }} NOT LISTENING"
      register: was_port_check
      changed_when: false
      failed_when: false
    
    # 4. WAS 웹 응답 확인
    - name: Test WAS web response
      uri:
        url: "http://localhost:{{ was_port }}"
        method: GET
        status_code: [200, 302, 404]  # 404도 정상 (서버는 응답함)
        timeout: 5
      register: was_web_response
      failed_when: false
      changed_when: false
      ignore_errors: yes
    
    # 5. 에러 로그 확인 (catalina.out)
    - name: Count error logs in catalina.out
      shell: |
        if [ -f {{ tomcat_home }}/logs/catalina.out ]; then
          tail -n 1000 {{ tomcat_home }}/logs/catalina.out | grep -i error | wc -l
        else
          echo "0"
        fi
      register: error_log_count
      failed_when: false
      changed_when: false
    
    # 6. 최근 에러 로그 내용 (마지막 5줄)
    - name: Get recent error logs
      shell: |
        if [ -f {{ tomcat_home }}/logs/catalina.out ]; then
          tail -n 1000 {{ tomcat_home }}/logs/catalina.out | grep -i error | tail -n 5
        else
          echo "No error logs found"
        fi
      register: recent_errors
      failed_when: false
      changed_when: false
    
    # 7. 접속 로그 에러 카운트 (오늘)
    - name: Count access log errors (today)
      shell: |
        LOG_FILE="{{ tomcat_home }}/logs/localhost_access_log.$(date +%Y-%m-%d).txt"
        if [ -f "$LOG_FILE" ]; then
          grep -v " 200 " "$LOG_FILE" | wc -l
        else
          echo "0"
        fi
      register: access_log_errors
      failed_when: false
      changed_when: false
    
    # 8. WAS 버전 확인
    - name: Get WAS version
      shell: |
        if [ -f {{ tomcat_home }}/bin/version.sh ]; then
          {{ tomcat_home }}/bin/version.sh 2>/dev/null | head -n 1
        else
          echo "Version info not available"
        fi
      register: was_version
      failed_when: false
      changed_when: false
    
    # 9. JVM 메모리 사용량
    - name: Get JVM memory usage
      shell: |
        PID=$(ps aux | grep java | grep -i tomcat | grep -v grep | awk '{print $2}' | head -n 1)
        if [ -n "$PID" ]; then
          ps -p $PID -o rss= | awk '{printf "%.2f MB\n", $1/1024}'
        else
          echo "N/A"
        fi
      register: jvm_memory
      failed_when: false
      changed_when: false
    
    # 10. 기동 스크립트 수정일자
    - name: Get startup script modification date
      shell: |
        if [ -f {{ tomcat_home }}/bin/startup.sh ]; then
          stat -c %y {{ tomcat_home }}/bin/startup.sh
        else
          echo "N/A"
        fi
      register: script_date
      failed_when: false
      changed_when: false
  
  # API로 결과 전송
  post_tasks:
    - name: Send WAS check results to API
      include_tasks: "{{ playbook_dir }}/common/roles/api_sender/tasks/main.yml"
      vars:
        check_type: "was"
        checker_name: "{{ default_checker | default('이수민') }}"
        check_results:
          service:
            name: "{{ was_service_name }}"
            status: "{{ was_service.status.ActiveState | default('N/A') }}"
            enabled: "{{ was_service.status.UnitFileState | default('N/A') }}"
            loaded: "{{ was_service.status.LoadState | default('N/A') }}"
          process:
            running: "{{ 'YES' if was_process.stdout != '' else 'NO' }}"
            details: "{{ was_process.stdout | default('N/A') }}"
          port:
            number: "{{ was_port }}"
            listening: "{{ 'YES' if 'LISTEN' in was_port_check.stdout else 'NO' }}"
            details: "{{ was_port_check.stdout | default('N/A') }}"
          web:
            response_code: "{{ was_web_response.status | default('N/A') }}"
            accessible: "{{ 'YES' if was_web_response.status is defined else 'NO' }}"
          logs:
            error_count_catalina: "{{ error_log_count.stdout | default('0') }}"
            recent_errors: "{{ recent_errors.stdout | default('N/A') }}"
            access_log_errors_today: "{{ access_log_errors.stdout | default('0') }}"
          version:
            info: "{{ was_version.stdout | default('N/A') }}"
          memory:
            jvm_usage: "{{ jvm_memory.stdout | default('N/A') }}"
          files:
            startup_script_date: "{{ script_date.stdout | default('N/A') }}"
```

### 이수민 담당자 체크리스트

- [ ] API 서버 연결 확인 (`curl http://192.168.0.18:8000/api/health`)
- [ ] `config/api_config.yml` 파일 생성 및 `default_checker: "이수민"` 설정
- [ ] `common/roles/api_sender/` 디렉토리 확인
- [ ] 기존 WAS 점검 플레이북에 `pre_tasks`, `vars`, `post_tasks` 추가
- [ ] `check_type: "was"` 설정
- [ ] 모든 점검 결과를 `check_results` 딕셔너리로 구조화
- [ ] `tomcat_home`, `was_port` 등 환경 변수 확인
- [ ] 플레이북 실행 및 API 전송 확인

---

## 🧪 테스트 방법

### 1단계: 플레이북 실행

```bash
ansible-playbook -i inventory your_check_playbook.yml
```

### 2단계: API 전송 확인

플레이북 실행 후 다음 메시지가 나오면 성공:

```
TASK [Send check result to API server] ********************
ok: [localhost] => {
    "status": 200
}
```

### 3단계: 저장된 결과 확인

```bash
# 전체 점검 결과 조회
curl "http://192.168.0.18:8000/api/checks"

# OS 점검만 조회
curl "http://192.168.0.18:8000/api/checks?check_type=os"

# WAS 점검만 조회
curl "http://192.168.0.18:8000/api/checks?check_type=was"

# 특정 담당자 점검만 조회
curl "http://192.168.0.18:8000/api/checks?checker=강하나"
curl "http://192.168.0.18:8000/api/checks?checker=이수민"
```

**⚠️ 참고:** 위의 `192.168.0.18`은 DB 담당자 PC의 IP 주소입니다. 모든 팀원이 동일한 IP 주소를 사용합니다.

---

## 🐛 문제 해결

### 문제 해결 원칙

**⚠️ 중요:** 문제가 발생하면 다음 순서로 해결하세요:

1. **이 가이드의 문제 해결 섹션 확인** (아래 참고)
2. **AI 코딩 도구 활용** - 에러 메시지나 문제 상황을 AI에게 설명하고 해결 방법 요청
3. **로컬 백업 파일 확인** - API 전송 실패해도 로컬에 저장됨
4. **필요시 DB 담당자에게 문의** - API 서버 관련 문제만

**대부분의 문제는 AI 코딩 도구로 해결 가능합니다!**

---

### 문제 1: API 서버에 연결할 수 없음

**증상:**
```
Connection refused
Status code was -1
```

**해결 방법:**
1. **IP 주소 확인 (가장 중요!):**
   - `192.168.0.18`이 DB 담당자 PC의 현재 IP 주소인지 확인
   - DB 담당자에게 현재 IP 주소 확인 요청
   - IP 주소가 변경되었다면, config 파일과 플레이북의 IP 주소 수정
   
2. API 서버 상태 확인:
   ```bash
   curl http://192.168.0.18:8000/api/health
   ```
   (위의 IP 주소는 DB 담당자 PC의 IP 주소로 변경해야 함)
   
3. **AI에게 요청:** "Ansible에서 API 서버 연결 오류 해결 방법 알려줘"
   
4. 네트워크 연결 확인:
   ```bash
   ping 192.168.0.18  # DB 담당자 PC IP 주소
   ```
   
5. 필요시 DB 담당자에게 API 서버 실행 요청

### 문제 2: "common/roles/api_sender/tasks/main.yml" 파일을 찾을 수 없음

**증상:**
```
Could not find or access 'common/roles/api_sender/tasks/main.yml'
```

**해결 방법:**
1. 프로젝트 루트에서 실행하는지 확인
2. `common/roles/api_sender/` 디렉토리가 있는지 확인
3. **AI에게 요청:** "Ansible common roles api_sender 구조 생성해줘" 또는 "api_sender role 파일 내용 알려줘"
4. 없다면 DB 담당자에게 요청하여 복사

### 문제 3: 변수 경로 오류

**증상:**
```
'playbook_dir' is undefined
```

**해결 방법:**
- **AI에게 요청:** "Ansible playbook_dir 변수 오류 해결 방법" 또는 "상대 경로로 include_tasks 사용하는 방법"
- `{{ playbook_dir }}/common/...` 대신 상대 경로 사용:
  ```yaml
  include_tasks: "../common/roles/api_sender/tasks/main.yml"
  ```
- 또는 절대 경로 사용 (프로젝트 구조에 맞게)

### 문제 4: 점검 결과가 저장되지 않음

**확인 사항:**
1. API 전송 task가 실행되었는지 확인
2. `check_results` 변수가 올바른 딕셔너리 형식인지 확인
3. 로컬 백업 파일 확인:
   ```bash
   ls -la /tmp/*_check_result_*.json
   ```
4. **AI에게 요청:** "Ansible 점검 결과가 API로 전송되지 않는 문제 해결 방법"

### 문제 5: JSON 형식 오류

**증상:**
```
Invalid JSON format
```

**해결 방법:**
- **AI에게 요청:** "Ansible에서 JSON 형식 오류 해결 방법" 또는 "Ansible 변수에서 특수문자 처리 방법"
- `check_results`에 특수문자나 줄바꿈이 있는 경우 처리:
  ```yaml
  check_results:
    output: "{{ result.stdout | replace('\n', ' ') }}"
  ```

### 문제 6: 기타 문제

**해결 방법:**
- **AI에게 요청:** 에러 메시지 전체를 복사해서 AI에게 보여주고 해결 방법 요청
- 예시: "Ansible 플레이북 실행 중 이런 오류가 나는데 해결 방법 알려줘: [에러 메시지 붙여넣기]"
- 이 가이드의 예제 코드를 AI에게 보여주고 자신의 환경에 맞게 수정 요청

---

## 📚 AI 코딩 도구 활용 가이드

### 🤖 AI 활용 원칙

**이 가이드에 없는 내용이나 부족한 부분은 AI 코딩 도구를 적극 활용하세요!**

- ✅ 코드 작성, 수정, 개선
- ✅ 에러 해결
- ✅ 환경에 맞는 커스터마이징
- ✅ 추가 기능 구현

**DB 담당자에게 굳이 문의할 필요 없이, AI를 활용해서 자유롭게 작업하세요!**

---

### AI에게 요청할 때 사용할 수 있는 프롬프트 예시

#### 기본 요청 (강하나 담당자용)
```
내 Ansible OS 점검 플레이북에 API 전송 기능을 추가해줘.
- API 서버 주소: http://192.168.0.18:8000/api/checks (DB 담당자 PC IP 주소)
- check_type: "os"
- checker_name: "강하나"
- 모든 점검 결과를 check_results 딕셔너리로 구조화해서 전송
- common/roles/api_sender/tasks/main.yml을 사용해서 전송
- 이 가이드를 참고해서: [TEAM_MEMBER_API_GUIDE.md 내용 붙여넣기]
```

#### 기본 요청 (이수민 담당자용)
```
내 Ansible WAS 점검 플레이북에 API 전송 기능을 추가해줘.
- API 서버 주소: http://192.168.0.18:8000/api/checks (DB 담당자 PC IP 주소)
- check_type: "was"
- checker_name: "이수민"
- 모든 점검 결과를 check_results 딕셔너리로 구조화해서 전송
- common/roles/api_sender/tasks/main.yml을 사용해서 전송
- 이 가이드를 참고해서: [TEAM_MEMBER_API_GUIDE.md 내용 붙여넣기]
```

**⚠️ 참고:** `192.168.0.18`은 DB 담당자 PC의 IP 주소입니다. 각 팀원은 자신의 IP 주소가 아니라 DB 담당자 PC의 IP 주소를 사용해야 합니다. IP 주소가 변경되었다면 DB 담당자에게 확인하세요.

#### 에러 해결 요청
```
Ansible 플레이북 실행 중 이런 오류가 나는데 해결 방법 알려줘:
[에러 메시지 전체 복사해서 붙여넣기]

내 플레이북 구조:
[플레이북 내용 또는 구조 설명]
```

#### 코드 수정 요청
```
이 Ansible 플레이북을 내 환경에 맞게 수정해줘:
[기존 플레이북 내용]

내 환경:
- Tomcat 경로: /opt/tomcat
- 포트: 8080
- 서비스 이름: tomcat9
```

#### 추가 기능 요청
```
내 OS 점검 플레이북에 다음 항목도 추가해서 API로 전송하고 싶어:
- 디스크 I/O 상태
- 네트워크 인터페이스 정보
- 실행 중인 서비스 목록

기존 플레이북:
[플레이북 내용]
```

---

### AI가 이해해야 할 핵심 정보

AI에게 요청할 때 다음 정보를 함께 제공하면 더 정확한 답변을 받을 수 있습니다:

1. **API 전송 구조:**
   - `pre_tasks`: API 설정 로드
   - `vars`: API 서버 주소 설정
   - `post_tasks`: API 전송 (가장 중요)

2. **필수 변수:**
   - `check_type`: "os" 또는 "was"
   - `checker_name`: 담당자 이름
   - `check_results`: 점검 결과 딕셔너리

3. **파일 경로:**
   - `{{ playbook_dir }}/common/roles/api_sender/tasks/main.yml`
   - 또는 상대 경로: `../common/roles/api_sender/tasks/main.yml`

4. **API 서버 정보:**
   - 주소: `http://192.168.0.18:8000/api/checks` (DB 담당자 PC IP 주소)
   - 엔드포인트: `POST /api/checks`
   - Content-Type: `application/json`
   - **중요:** 각 팀원은 자신의 IP 주소가 아니라 DB 담당자 PC의 IP 주소를 사용해야 합니다!

---

### AI 활용 시나리오 예시

#### 시나리오 1: 기존 플레이북에 API 전송 추가
```
AI에게: "이 Ansible 플레이북에 API 전송 기능을 추가해줘. 
TEAM_MEMBER_API_GUIDE.md 가이드를 참고해서."

[기존 플레이북 내용 붙여넣기]
```

#### 시나리오 2: 에러 발생 시
```
AI에게: "Ansible에서 이런 에러가 나는데 해결 방법 알려줘:
'playbook_dir' is undefined

내 플레이북:
[플레이북 내용]"
```

#### 시나리오 3: 환경에 맞게 커스터마이징
```
AI에게: "이 예제 플레이북을 내 환경에 맞게 수정해줘:
- Tomcat 경로: /usr/local/tomcat9 → /opt/tomcat
- 포트: 8080 → 8443
- 서비스 이름: tomcat → tomcat9

[예제 플레이북 내용]"
```

#### 시나리오 4: 추가 점검 항목 추가
```
AI에게: "내 OS 점검 플레이북에 다음 항목도 추가해줘:
- 시스템 로그 확인
- 패키지 업데이트 상태
- 보안 패치 상태

기존 플레이북:
[플레이북 내용]"
```

---

## ✅ 최종 체크리스트

### 공통 체크리스트
- [ ] API 서버 연결 확인 완료
- [ ] `config/api_config.yml` 파일 생성 완료
- [ ] `common/roles/api_sender/` 디렉토리 확인 완료
- [ ] 플레이북에 API 전송 기능 추가 완료
- [ ] 테스트 실행 및 결과 확인 완료

### 강하나 담당자
- [ ] `check_type: "os"` 설정
- [ ] `checker_name: "강하나"` 설정
- [ ] OS 점검 결과가 모두 `check_results`에 포함됨

### 이수민 담당자
- [ ] `check_type: "was"` 설정
- [ ] `checker_name: "이수민"` 설정
- [ ] WAS 점검 결과가 모두 `check_results`에 포함됨

---

## 📞 지원 및 문제 해결

### 문제 해결 순서

**⚠️ 중요:** 문제가 발생하면 다음 순서로 해결하세요:

1. **이 가이드의 [문제 해결](#-문제-해결) 섹션 확인**
2. **AI 코딩 도구 활용** - 에러 메시지나 문제 상황을 AI에게 설명하고 해결 방법 요청
   - "이 가이드를 참고해서 문제 해결해줘" 라고 AI에게 요청
   - 에러 메시지 전체를 복사해서 AI에게 보여주기
3. **로컬 백업 파일 확인** - API 전송 실패해도 로컬에 저장됨:
   ```bash
   ls -la /tmp/*_check_result_*.json
   ```
4. **필요시 DB 담당자에게 문의** - API 서버 관련 문제만 (서버 실행, 네트워크 설정 등)

### AI 활용 우선 원칙

**대부분의 문제는 AI 코딩 도구로 해결 가능합니다!**

- ✅ 코드 오류 → AI에게 에러 메시지 보여주고 해결 방법 요청
- ✅ 기능 추가 → AI에게 요구사항 설명하고 코드 작성 요청
- ✅ 환경 맞춤 → AI에게 환경 정보 제공하고 코드 수정 요청
- ✅ 예제 수정 → AI에게 예제 코드 보여주고 자신의 환경에 맞게 수정 요청

**DB 담당자에게 굳이 문의할 필요 없이, AI를 활용해서 자유롭게 작업하세요!**

---

**마지막 업데이트**: 2025-12-30  
**작성자**: DB 담당자  
**대상**: 강하나 (OS 점검), 이수민 (WAS 점검)

