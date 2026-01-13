# 공통 API 전송 모듈 사용 가이드

## 개요
이 모듈은 모든 팀원이 자신의 Ansible 점검 결과를 중앙 API 서버로 전송할 수 있게 해줍니다.

## 설정 방법

### 1. API 서버 주소 설정
`config/api_config.yml` 파일을 열어서 실제 API 서버 주소를 입력하세요:

```yaml
api_server:
  url: "http://실제서버주소:8000/api/checks"  # 여기를 수정
```

### 2. 각 팀원의 플레이북에서 사용하기

#### 예시 1: OS 체크 (redhat_check/redhat_check.yml)
```yaml
---
- name: "[OS] 서버 기초 체력 정밀 점검"
  hosts: all
  gather_facts: yes
  vars_files:
    - ../config/api_config.yml  # 설정 파일 로드
  
  tasks:
    # ... 기존 OS 점검 tasks ...
    - name: "1. CPU 모델명 확인"
      shell: "lscpu | grep 'Model name'"
      register: cpu_info
    
    # ... 다른 점검 tasks ...
    
    # 마지막에 API 전송 추가
    - name: Send OS check result to API
      include_role:
        name: ../common/roles/api_sender
      vars:
        check_type: "os"
        checker_name: "홍길동"  # 자신의 이름
        check_results:
          cpu_info: "{{ cpu_info.stdout }}"
          mem_check: "{{ mem_check.stdout }}"
          disk_usage: "{{ disk_usage.stdout }}"
          ping_result: "{{ ping_result.stdout }}"
          ntp_check: "{{ ntp_check.stdout }}"
```

#### 예시 2: WAS 체크 (tomcat_check/tomcat_check.yml)
```yaml
---
- name: "[WAS] Apache Tomcat 정밀 점검"
  hosts: all
  gather_facts: yes
  vars_files:
    - ../config/api_config.yml
  
  tasks:
    # ... 기존 WAS 점검 tasks ...
    
    # 마지막에 API 전송 추가
    - name: Send WAS check result to API
      include_role:
        name: ../common/roles/api_sender
      vars:
        check_type: "was"
        checker_name: "김철수"
        check_results:
          tomcat_proc: "{{ tomcat_proc.stdout }}"
          error_count: "{{ error_count.stdout }}"
          script_date: "{{ script_date.stdout }}"
```

#### 예시 3: DB 체크 (mariadb_check, postgresql_check 등)
```yaml
---
- name: MariaDB 통합 자동 점검
  hosts: mariadb
  gather_facts: yes
  vars_files:
    - ../config/api_config.yml
  
  roles:
    - mariadb_check
  
  # role 실행 후 API 전송
  post_tasks:
    - name: Send MariaDB check result to API
      include_role:
        name: ../common/roles/api_sender
      vars:
        check_type: "mariadb"
        checker_name: "이영희"
        check_results:
          service_status:
            active: "{{ mariadb_service.status.ActiveState }}"
            substate: "{{ mariadb_service.status.SubState }}"
          listener: "{{ mariadb_listener.stdout }}"
          os_resources:
            memory: "{{ mem_usage.stdout }}"
            cpu: "{{ cpu_usage.stdout }}"
          db_internal:
            innodb_buffer_pool: "{{ innodb_bp.stdout }}"
            log_bin: "{{ log_bin.stdout }}"
            tablespace: "{{ tablespace.stdout }}"
```

## 변수 설명

### 필수 변수
- `check_type`: 점검 유형 ("os", "was", "mariadb", "postgresql", "cubrid" 등)
- `check_results`: 점검 결과 데이터 (딕셔너리 형태)

### 선택 변수
- `checker_name`: 담당자 이름 (기본값: "unknown")
- `api_server_url`: API 서버 URL (기본값: config 파일에서 읽음)

## 동작 방식

1. 각 팀원이 자신의 플레이북 실행
2. 점검 수행 후 결과를 `check_results` 변수에 담음
3. `api_sender` role이 자동으로:
   - JSON 형식으로 변환
   - 로컬 파일로 백업 저장 (`/tmp/{check_type}_check_result_{timestamp}.json`)
   - API 서버로 HTTP POST 전송
4. 전송 실패 시에도 로컬 파일은 저장되므로 나중에 재전송 가능

## 주의사항

- API 서버가 다운되어도 점검 자체는 실패하지 않음
- 전송 실패 시 로컬 파일이 저장되므로 수동으로 재전송 가능
- 모든 팀원이 같은 `config/api_config.yml` 파일을 사용해야 함

