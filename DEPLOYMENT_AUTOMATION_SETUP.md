# 배포 자동화 설정 가이드

## 옵션 1: GitHub Actions 설정 (추천)

### 1단계: GitHub Secrets 등록

GitHub 저장소 → Settings → Secrets and variables → Actions → New repository secret

다음 Secrets를 등록하세요:

```
SERVER_HOST=27.96.129.114
SERVER_PORT=4433
SERVER_USER=root
SSH_PRIVATE_KEY=(~/.ssh/nimso2026.pem 파일 내용 전체)
SSH_KEY_PATH=/home/sth0824/.ssh/nimso2026.pem
```

**SSH_PRIVATE_KEY 등록 방법:**
```bash
cat ~/.ssh/nimso2026.pem | pbcopy  # Mac
cat ~/.ssh/nimso2026.pem | xclip   # Linux
# 또는 파일 내용을 직접 복사
```

### 2단계: Workflow 파일 확인

`.github/workflows/deploy.yml` 파일이 생성되었는지 확인

### 3단계: 테스트

```bash
# develop 브랜치에 변경사항 commit & push
git add .
git commit -m "자동 배포 테스트"
git push origin develop
```

GitHub Actions 탭에서 배포 진행 상황 확인

---

## 옵션 2: Git Hooks 설정

### 1단계: Hook 파일 생성

```bash
chmod +x .git/hooks/pre-push
```

### 2단계: 테스트

```bash
git push origin develop
# 자동으로 배포 스크립트 실행됨
```

**주의**: 배포 실패해도 push는 계속 진행됩니다 (exit 0).

배포 실패 시 push를 중단하려면 `.git/hooks/pre-push`에서 `exit 0`을 `exit $DEPLOY_EXIT_CODE`로 변경하세요.

---

## 옵션 3: 서버 Webhook 설정

### 1단계: 서버에 Webhook 리스너 설치

```bash
# 서버에서 실행
chmod +x /opt/ansible-monitoring/scripts/webhook_listener.sh
nohup /opt/ansible-monitoring/scripts/webhook_listener.sh > /dev/null 2>&1 &
```

### 2단계: systemd 서비스로 등록 (선택)

`/etc/systemd/system/webhook-listener.service`:

```ini
[Unit]
Description=GitHub Webhook Listener
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ansible-monitoring
ExecStart=/opt/ansible-monitoring/scripts/webhook_listener.sh
Restart=always
Environment="WEBHOOK_SECRET=your-secret-key"

[Install]
WantedBy=multi-user.target
```

```bash
systemctl enable webhook-listener
systemctl start webhook-listener
```

### 3단계: GitHub Webhook 설정

GitHub 저장소 → Settings → Webhooks → Add webhook

- **Payload URL**: `http://27.96.129.114:9000/webhook` (또는 서버 IP)
- **Content type**: `application/json`
- **Secret**: `your-secret-key` (webhook_listener.sh와 동일)
- **Events**: `Just the push event` 또는 `Let me select individual events` → `Pushes`

### 4단계: 방화벽/ACG 설정

네이버 클라우드 콘솔에서 포트 9000 인바운드 허용

---

## 옵션 4: 스케줄링된 자동 배포

### 1단계: Cron Job 등록

```bash
# 서버에서 실행
crontab -e

# 매시간마다 체크 (또는 원하는 주기로)
0 * * * * /opt/ansible-monitoring/scripts/auto_deploy_cron.sh >> /opt/ansible-monitoring/logs/auto_deploy.log 2>&1

# 또는 매일 오전 8시에 체크
0 8 * * * /opt/ansible-monitoring/scripts/auto_deploy_cron.sh >> /opt/ansible-monitoring/logs/auto_deploy.log 2>&1
```

### 2단계: 스크립트 권한 부여

```bash
chmod +x /opt/ansible-monitoring/scripts/auto_deploy_cron.sh
```

---

## 비교표

| 옵션 | 실시간성 | 설정 복잡도 | 추천도 |
|------|---------|------------|--------|
| GitHub Actions | ⭐⭐⭐ 즉시 | ⭐⭐ 중간 | ⭐⭐⭐ 추천 |
| Git Hooks | ⭐⭐⭐ 즉시 | ⭐ 쉬움 | ⭐⭐ |
| 서버 Webhook | ⭐⭐⭐ 즉시 | ⭐⭐⭐ 복잡 | ⭐⭐ |
| 스케줄링 | ⭐ 지연 | ⭐ 쉬움 | ⭐ |

---

## 하이브리드 방식 (추천)

**GitHub Actions + Git Hooks** 조합:

1. **GitHub Actions**: develop 브랜치 push 시 자동 배포 (표준)
2. **Git Hooks**: 로컬에서 빠른 배포 (개발 편의)

두 가지 모두 활성화해도 충돌 없이 작동합니다.

---

## 문제 해결

### GitHub Actions 실패 시
- Secrets 확인 (특히 SSH_PRIVATE_KEY)
- 서버 SSH 접속 가능 여부 확인
- Actions 로그 확인

### Git Hooks 작동 안 함
- 파일 권한 확인: `chmod +x .git/hooks/pre-push`
- Git 버전 확인 (2.9+)

### Webhook 작동 안 함
- 서버에서 리스너 실행 확인: `ps aux | grep webhook`
- 방화벽/ACG 포트 확인
- GitHub Webhook 설정 확인 (Secret 일치)

### Cron 배포 실패
- Cron 로그 확인: `tail -f /opt/ansible-monitoring/logs/auto_deploy.log`
- Git 저장소 접근 권한 확인
