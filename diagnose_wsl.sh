#!/bin/bash
# WSL 환경 진단 스크립트

echo "🔍 WSL 환경 진단 중..."
echo ""

# 1. OS 정보
echo "1️⃣ 운영체제 정보:"
if [ -f /etc/os-release ]; then
    cat /etc/os-release
else
    echo "   /etc/os-release 파일이 없습니다."
fi
echo ""

# 2. 사용자 정보
echo "2️⃣ 사용자 정보:"
echo "   사용자: $(whoami)"
echo "   UID: $(id -u)"
echo "   GID: $(id -g)"
echo ""

# 3. 쉘 정보
echo "3️⃣ 쉘 정보:"
echo "   쉘: $SHELL"
echo "   쉘 경로: $(which sh)"
echo ""

# 4. 패키지 매니저 확인
echo "4️⃣ 패키지 매니저 확인:"
PACKAGE_MANAGERS=("apt" "yum" "dnf" "apk" "pacman" "zypper")
FOUND_MGR=""

for mgr in "${PACKAGE_MANAGERS[@]}"; do
    if command -v $mgr &> /dev/null; then
        echo "   ✅ $mgr 발견: $(which $mgr)"
        FOUND_MGR=$mgr
    else
        echo "   ❌ $mgr 없음"
    fi
done
echo ""

# 5. Python 확인
echo "5️⃣ Python 확인:"
PYTHON_VERSIONS=("python3" "python" "python2")
FOUND_PYTHON=""

for py in "${PYTHON_VERSIONS[@]}"; do
    if command -v $py &> /dev/null; then
        echo "   ✅ $py 발견: $($py --version 2>&1)"
        FOUND_PYTHON=$py
    else
        echo "   ❌ $py 없음"
    fi
done
echo ""

# 6. 권한 확인
echo "6️⃣ 권한 확인:"
if [ "$(id -u)" -eq 0 ]; then
    echo "   ✅ root 권한"
    SUDO_NEEDED=false
else
    echo "   ⚠️  일반 사용자 권한"
    if command -v sudo &> /dev/null; then
        echo "   ✅ sudo 사용 가능"
        SUDO_NEEDED=true
    else
        echo "   ❌ sudo 없음"
        SUDO_NEEDED=false
    fi
fi
echo ""

# 7. 권장 사항
echo "7️⃣ 권장 사항:"
if [ -z "$FOUND_MGR" ]; then
    echo "   ❌ 패키지 매니저를 찾을 수 없습니다."
    echo "   💡 WSL 재설정을 고려하세요."
elif [ -z "$FOUND_PYTHON" ]; then
    echo "   📦 $FOUND_MGR를 사용하여 Python 설치:"
    case $FOUND_MGR in
        apt)
            if [ "$SUDO_NEEDED" = true ]; then
                echo "      sudo apt update && sudo apt install -y python3 python3-pip"
            else
                echo "      apt update && apt install -y python3 python3-pip"
            fi
            ;;
        yum)
            if [ "$SUDO_NEEDED" = true ]; then
                echo "      sudo yum install -y python3 python3-pip"
            else
                echo "      yum install -y python3 python3-pip"
            fi
            ;;
        apk)
            if [ "$SUDO_NEEDED" = true ]; then
                echo "      sudo apk add python3 py3-pip"
            else
                echo "      apk add python3 py3-pip"
            fi
            ;;
        pacman)
            if [ "$SUDO_NEEDED" = true ]; then
                echo "      sudo pacman -S python python-pip"
            else
                echo "      pacman -S python python-pip"
            fi
            ;;
    esac
else
    echo "   ✅ Python이 설치되어 있습니다: $FOUND_PYTHON"
    echo "   📦 Ansible 설치:"
    echo "      $FOUND_PYTHON -m pip install --user ansible"
fi


