#!/bin/bash
# WSL에서 Ansible 설치 스크립트

echo "🔧 WSL에서 Ansible 설치 중..."

# 현재 경로 확인
CURRENT_DIR=$(pwd)
echo "현재 경로: $CURRENT_DIR"

# Python3 확인
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3가 설치되어 있지 않습니다."
    echo "설치 중..."
    apt update
    apt install -y python3 python3-pip
fi

# pip3로 Ansible 설치
echo "📦 Ansible 설치 중..."
python3 -m pip install --user ansible

# 설치 확인
if [ -f "$HOME/.local/bin/ansible-playbook" ]; then
    echo "✅ Ansible 설치 완료!"
    echo ""
    echo "PATH에 추가하려면 다음 명령어를 실행하세요:"
    echo "export PATH=\$PATH:\$HOME/.local/bin"
    echo ""
    echo "또는 ~/.bashrc에 추가:"
    echo "echo 'export PATH=\$PATH:\$HOME/.local/bin' >> ~/.bashrc"
    echo "source ~/.bashrc"
else
    echo "❌ Ansible 설치 실패"
    exit 1
fi

# 설치된 Ansible 버전 확인
$HOME/.local/bin/ansible --version

echo ""
echo "✅ 설정 완료! 이제 플레이북을 실행할 수 있습니다."


