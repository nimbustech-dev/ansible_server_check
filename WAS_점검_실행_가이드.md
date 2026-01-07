# WAS 점검 실행 가이드

## 📊 대시보드 링크

### WAS 점검 대시보드
- **메인 대시보드**: http://192.168.0.18:8000/api/was-checks/report
- **API 데이터 (JSON)**: http://192.168.0.18:8000/api/was-checks/data?limit=1000

### 기타 대시보드
- **DB 점검 대시보드**: http://192.168.0.18:8000/api/db-checks/report
- **OS 점검 대시보드**: http://192.168.0.18:8000/api/os-checks/report

### API 확인 방법

#### 브라우저에서 확인
브라우저 주소창에 아래 링크를 입력:
```
http://192.168.0.18:8000/api/was-checks/data?limit=10
```

#### 터미널에서 확인 (curl 사용)
```bash
# WAS 데이터 확인
curl http://192.168.0.18:8000/api/was-checks/data?limit=10

# 예쁘게 보기 (jq 설치 필요)
curl http://192.168.0.18:8000/api/was-checks/data?limit=10 | jq

# 또는 python으로 확인
python3 -c "import requests, json; print(json.dumps(requests.get('http://192.168.0.18:8000/api/was-checks/data?limit=10').json(), indent=2, ensure_ascii=False))"
```

---

## 🚀 빠른 실행 명령어

### WSL 우분투에서 실행

```bash
cd /mnt/c/ansible_server_check
ansible-playbook -i localhost, tomcat_check/tomcat_check.yml --connection=local --ask-become-pass
```

## 📋 전체 프로세스

### 1단계: WSL 우분투 접속
```bash
# Windows PowerShell에서
wsl

# 또는 특정 우분투 배포판
wsl -d Ubuntu-22.04
```

### 2단계: 프로젝트 디렉토리로 이동
```bash
cd /mnt/c/ansible_server_check
```

### 3단계: WAS 점검 플레이북 실행
```bash
ansible-playbook -i localhost, tomcat_check/tomcat_check.yml --connection=local --ask-become-pass
```

**설명:**
- `-i localhost,`: localhost를 대상으로 실행
- `--connection=local`: SSH 없이 로컬에서 실행
- `--ask-become-pass`: sudo 비밀번호 입력 요청

### 4단계: 실행 결과 확인

플레이북 실행 후:
1. ✅ **점검 실행**: Tomcat 설치, 서비스 상태, 포트, 리소스 등 11개 카테고리 점검
2. ✅ **API 전송**: 점검 결과가 자동으로 API 서버로 전송
   - API 서버: `http://192.168.0.18:8000/api/checks`
   - 점검 유형: `was`
   - 담당자: `이수민`
3. ✅ **DB 저장**: PostgreSQL에 자동 저장
4. ✅ **대시보드 표시**: 웹 대시보드에서 확인 가능

### 5단계: 대시보드에서 확인

브라우저에서 다음 URL 열기:
```
http://192.168.0.18:8000/api/was-checks/report
```

## 📊 점검 항목 (11개 카테고리)

1. **설치 확인**: Tomcat 설치 여부, 경로
2. **디렉토리 구조**: CATALINA_HOME 구조
3. **파일시스템**: 각 디렉토리 사용률
4. **서비스 상태**: systemd 서비스 상태
5. **리스너 포트**: 8080, 8005, 8009
6. **OS 리소스**: CPU, 메모리, 프로세스
7. **애플리케이션**: 배포된 앱 목록 및 개수
8. **설정**: server.xml, JAVA_OPTS, 힙 메모리
9. **로그**: catalina.out, 에러 로그, 접속 로그
10. **프로세스**: 실행 상태 및 상세 정보
11. **스크립트**: startup.sh 수정일자

## 🔧 사전 준비사항

### 1. Ansible 설치 확인
```bash
ansible --version
```

없다면:
```bash
sudo apt update
sudo apt install -y python3 python3-pip
python3 -m pip install --user ansible
export PATH=$PATH:$HOME/.local/bin
```

### 2. API 서버 실행 확인
```bash
# API 서버가 실행 중인지 확인
curl http://192.168.0.18:8000/api/health
```

### 3. 네트워크 연결 확인
```bash
# API 서버 접근 가능한지 확인
ping 192.168.0.18
```

## 📝 실행 예시

```bash
# WSL 우분투 접속
wsl

# 프로젝트 디렉토리로 이동
cd /mnt/c/ansible_server_check

# 플레이북 실행
ansible-playbook -i localhost, tomcat_check/tomcat_check.yml --connection=local --ask-become-pass

# 실행 중 sudo 비밀번호 입력 요청 시 입력
# [sudo] password for user: (비밀번호 입력)

# 실행 완료 후 대시보드 확인
# 브라우저: http://192.168.0.18:8000/api/was-checks/report
```

## 🎯 한 줄 명령어 (복사해서 사용)

```bash
cd /mnt/c/ansible_server_check && ansible-playbook -i localhost, tomcat_check/tomcat_check.yml --connection=local --ask-become-pass
```

## ⚠️ 문제 해결

### Ansible이 없는 경우
```bash
sudo apt update && sudo apt install -y python3 python3-pip && python3 -m pip install --user ansible && export PATH=$PATH:$HOME/.local/bin
```

### API 서버 연결 실패
- API 서버가 실행 중인지 확인: `http://192.168.0.18:8000/api/health`
- 네트워크 연결 확인: `ping 192.168.0.18`
- 방화벽 설정 확인

### 대시보드에 데이터가 안 보이는 경우
1. 플레이북 실행이 성공했는지 확인
2. API 전송 성공 메시지 확인
3. 대시보드 새로고침 (F5 또는 Ctrl+F5)
4. 날짜 필터에서 "오늘" 선택
5. 브라우저 콘솔(F12)에서 에러 확인

## 📌 체크리스트

실행 전 확인:
- [ ] WSL 우분투 접속됨
- [ ] Ansible 설치됨 (`ansible --version`)
- [ ] 프로젝트 디렉토리에 있음 (`pwd` 확인)
- [ ] API 서버 실행 중 (`http://192.168.0.18:8000/api/health`)

실행 후 확인:
- [ ] 플레이북 실행 성공
- [ ] "API 전송 결과" 메시지 확인
- [ ] 대시보드에서 데이터 확인
- [ ] 오늘 날짜 필터로 확인

