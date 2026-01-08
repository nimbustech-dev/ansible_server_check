#!/bin/sh
# Docker Desktop 환경에서 Ansible 설치

echo "🐳 Docker Desktop 환경에서 Ansible 설치 중..."
echo ""

# 1. 패키지 매니저 확인
echo "1️⃣ 패키지 매니저 확인:"
if command -v apk &> /dev/null; then
    echo "   ✅ apk 발견 (Alpine Linux)"
    PKG_MGR="apk"
elif command -v apt &> /dev/null; then
    echo "   ✅ apt 발견"
    PKG_MGR="apt"
else
    echo "   ❌ 패키지 매니저를 찾을 수 없습니다."
    exit 1
fi

# 2. 패키지 업데이트
echo ""
echo "2️⃣ 패키지 목록 업데이트 중..."
if [ "$PKG_MGR" = "apk" ]; then
    apk update
elif [ "$PKG_MGR" = "apt" ]; then
    apt update
fi

# 3. Python3 설치
echo ""
echo "3️⃣ Python3 설치 중..."
if [ "$PKG_MGR" = "apk" ]; then
    apk add python3 py3-pip
elif [ "$PKG_MGR" = "apt" ]; then
    apt install -y python3 python3-pip
fi

# 4. 설치 확인
echo ""
echo "4️⃣ 설치 확인:"
if command -v python3 &> /dev/null; then
    echo "   ✅ Python3: $(python3 --version)"
else
    echo "   ❌ Python3 설치 실패"
    exit 1
fi

if command -v pip3 &> /dev/null || python3 -m pip --version &> /dev/null; then
    echo "   ✅ pip3 사용 가능"
else
    echo "   ❌ pip3 설치 실패"
    exit 1
fi

# 5. Ansible 설치
echo ""
echo "5️⃣ Ansible 설치 중..."
python3 -m pip install --user ansible

# 6. PATH 설정
echo ""
echo "6️⃣ PATH 설정 중..."
export PATH=$PATH:$HOME/.local/bin

# 7. 설치 확인
echo ""
echo "7️⃣ 최종 확인:"
if [ -f "$HOME/.local/bin/ansible" ]; then
    echo "   ✅ Ansible 설치 완료!"
    $HOME/.local/bin/ansible --version
    echo ""
    echo "   📝 PATH 설정 (현재 세션):"
    echo "   export PATH=\$PATH:\$HOME/.local/bin"
    echo ""
    echo "   영구 설정 (~/.profile 또는 ~/.bashrc에 추가):"
    echo "   echo 'export PATH=\$PATH:\$HOME/.local/bin' >> ~/.profile"
    echo "   source ~/.profile"
else
    echo "   ❌ Ansible 설치 실패"
    exit 1
fi

echo ""
echo "✅ 모든 설치 완료!"


