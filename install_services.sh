#!/bin/bash
# MariaDB, CUBRID, Tomcat 설치 스크립트

set -e

echo "🚀 서비스 설치 시작..."
echo ""

# MariaDB 설치
echo "=========================================="
echo "1. MariaDB 설치 중..."
echo "=========================================="
if command -v mysql >/dev/null 2>&1; then
    echo "✅ MariaDB가 이미 설치되어 있습니다."
    mysql --version
else
    echo "MariaDB 설치 중..."
    sudo apt update
    sudo apt install -y mariadb-server mariadb-client
    sudo systemctl start mariadb
    sudo systemctl enable mariadb
    echo "✅ MariaDB 설치 완료!"
    mysql --version
fi
echo ""

# Java 설치 (Tomcat에 필요)
echo "=========================================="
echo "2. Java 설치 중..."
echo "=========================================="
if command -v java >/dev/null 2>&1; then
    echo "✅ Java가 이미 설치되어 있습니다."
    java -version 2>&1 | head -1
else
    echo "Java 설치 중..."
    sudo apt install -y default-jdk
    echo "✅ Java 설치 완료!"
    java -version 2>&1 | head -1
fi
echo ""

# Tomcat 설치
echo "=========================================="
echo "3. Tomcat 설치 중..."
echo "=========================================="
TOMCAT_VERSION="10.1.20"
TOMCAT_DIR="/opt/tomcat"
TOMCAT_USER="tomcat"

if [ -d "$TOMCAT_DIR" ] && [ -f "$TOMCAT_DIR/bin/catalina.sh" ]; then
    echo "✅ Tomcat이 이미 설치되어 있습니다: $TOMCAT_DIR"
    $TOMCAT_DIR/bin/catalina.sh version | head -1
else
    echo "Tomcat 설치 중..."
    
    # Tomcat 사용자 생성
    if ! id "$TOMCAT_USER" &>/dev/null; then
        sudo useradd -r -s /bin/false $TOMCAT_USER
    fi
    
    # Tomcat 다운로드
    cd /tmp
    if [ ! -f "apache-tomcat-${TOMCAT_VERSION}.tar.gz" ]; then
        echo "Tomcat ${TOMCAT_VERSION} 다운로드 중..."
        wget -q "https://archive.apache.org/dist/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"
    fi
    
    # Tomcat 압축 해제 및 설치
    sudo mkdir -p /opt
    sudo tar xzf apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /opt
    sudo mv /opt/apache-tomcat-${TOMCAT_VERSION} $TOMCAT_DIR
    sudo chown -R $TOMCAT_USER:$TOMCAT_USER $TOMCAT_DIR
    sudo chmod +x $TOMCAT_DIR/bin/*.sh
    
    # CATALINA_HOME 환경변수 설정
    if ! grep -q "CATALINA_HOME" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "export CATALINA_HOME=$TOMCAT_DIR" >> ~/.bashrc
        echo "export PATH=\$PATH:\$CATALINA_HOME/bin" >> ~/.bashrc
    fi
    
    export CATALINA_HOME=$TOMCAT_DIR
    export PATH=$PATH:$CATALINA_HOME/bin
    
    echo "✅ Tomcat 설치 완료: $TOMCAT_DIR"
    $TOMCAT_DIR/bin/catalina.sh version | head -1
    
    # Tomcat 서비스 파일 생성 (선택사항)
    echo "Tomcat 서비스 설정 중..."
    sudo tee /etc/systemd/system/tomcat.service > /dev/null <<EOF
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking
Environment=JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
Environment=CATALINA_PID=$TOMCAT_DIR/tomcat.pid
Environment=CATALINA_HOME=$TOMCAT_DIR
Environment=CATALINA_BASE=$TOMCAT_DIR
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=$TOMCAT_DIR/bin/startup.sh
ExecStop=$TOMCAT_DIR/bin/shutdown.sh

User=$TOMCAT_USER
Group=$TOMCAT_USER
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable tomcat
    echo "✅ Tomcat 서비스 설정 완료 (수동 시작 필요)"
fi
echo ""

# CUBRID 설치 (선택사항 - 시간이 오래 걸릴 수 있음)
echo "=========================================="
echo "4. CUBRID 설치 확인 중..."
echo "=========================================="
if command -v cubrid >/dev/null 2>&1; then
    echo "✅ CUBRID가 이미 설치되어 있습니다."
    cubrid version
else
    echo "⚠️  CUBRID는 수동 설치가 필요합니다."
    echo "   CUBRID 공식 사이트에서 다운로드 필요:"
    echo "   https://www.cubrid.org/download"
    echo "   또는 플레이북에서 CUBRID_HOME 경로 지정 필요"
fi
echo ""

echo "=========================================="
echo "✅ 설치 완료!"
echo "=========================================="
echo ""
echo "설치된 서비스:"
echo "  - MariaDB: $(command -v mysql && mysql --version 2>&1 | head -1 || echo '없음')"
echo "  - Java: $(command -v java && java -version 2>&1 | head -1 || echo '없음')"
echo "  - Tomcat: $([ -d "$TOMCAT_DIR" ] && echo "$TOMCAT_DIR" || echo '없음')"
echo "  - CUBRID: $(command -v cubrid && cubrid version 2>&1 | head -1 || echo '설치 안됨 (선택사항)')"
echo ""
echo "다음 단계:"
echo "  1. Tomcat 시작: sudo systemctl start tomcat"
echo "  2. 점검 실행: ansible-playbook -i inventory/dongguk_servers.ini [점검플레이북]"
echo ""

