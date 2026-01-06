# nimso2026.pem 키 사용 가이드

## ✅ 현재 상태

- 인증키 변경 완료: `nimso2026.pem` 발급 완료
- 파일 위치: `~/.ssh/nimso2026.pem`
- 권한 설정: `600` (완료)
- Inventory 파일: 설정 완료

## 🔧 다음 단계

### 1단계: 관리자 비밀번호 확인

네이버 클라우드 콘솔에서:

1. **Server → Server → nimbus-server 선택**
2. **"서버 관리 및 설정 변경" 클릭**
3. **"관리자 비밀번호 확인" 클릭**
4. **`nimso2026.pem` 파일 업로드**
   - Windows: `C:\Users\nimbu\Downloads\nimso2026.pem`
   - 또는 WSL2: `/mnt/c/Users/nimbu/Downloads/nimso2026.pem`
5. **비밀번호 확인**

### 2단계: 서버 상태 확인

- 서버 상태가 **"운영중"**인지 확인
- "부팅중"이면 완료될 때까지 대기

### 3단계: SSH 접속 테스트

서버가 "운영중" 상태가 되면:

```bash
# 방법 1: 공인 IP로 접속
ssh -i ~/.ssh/nimso2026.pem root@115.85.181.103

# 방법 2: 포트 포워딩 사용 (위 방법이 안 되면)
ssh -i ~/.ssh/nimso2026.pem -p 1025 root@27.96.129.114
```

### 4단계: Ansible 점검 실행

SSH 접속이 성공하면:

```bash
# OS 점검
ansible-playbook -i naver_cloud_inventory nimbus_check/os_check.yml

# WAS 점검
ansible-playbook -i naver_cloud_inventory nimbus_check/was_check.yml
```

---

## 📝 체크리스트

- [ ] 관리자 비밀번호 확인 (nimso2026.pem 파일 업로드)
- [ ] 서버 상태 확인 (운영중)
- [ ] SSH 접속 테스트
- [ ] Ansible 점검 실행

---

## ⚠️ 주의사항

- 기존 `nimsou2021` 키는 더 이상 사용 불가능
- `nimsou` 프로그램이 기존 키를 사용 중이라면 재설정 필요
- 새 키(`nimso2026.pem`)만 사용 가능

---

**작성일**: 2026년 1월 6일

