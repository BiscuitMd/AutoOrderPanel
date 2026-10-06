#!/bin/bash
#################################################################
#  🍪 Biscuit Panel Installer - PLTA & PLTC
#  Protec By @biscuitMD
#################################################################

set -e
TAG="Protec By @biscuitMD"
PANEL_DIR="/opt/biscuit-panel"
PLTA_DIR="$PANEL_DIR/plta"
PLTC_DIR="$PANEL_DIR/pltc"
GOLD='\033[0;33m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

[[ $EUID -ne 0 ]] && { echo -e "${RED}Root only!${NC}"; exit 1; }

echo -e "${GOLD}"
cat << "EOF"
╔══════════════════════════════════════════════════════╗
║                                                      ║
║          🍪  Protec By @biscuitMD  🍪                ║
║                                                      ║
║          Biscuit Panel Installer v1.0                ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# ============ KONFIGURASI ============
read -p "Masukkan domain panel (contoh: panel.domain.com): " PANEL_DOMAIN
read -p "Masukkan port panel (contoh: 8080): " PANEL_PORT
read -p "Masukkan username admin ID 1: " ADMIN_USER
read -s -p "Masukkan password admin ID 1: " ADMIN_PASS
echo ""
read -p "Masukkan email admin: " ADMIN_EMAIL

# Default
PANEL_DOMAIN="${PANEL_DOMAIN:-panel.local}"
PANEL_PORT="${PANEL_PORT:-8080}"
ADMIN_USER="${ADMIN_USER:-biscuitmd}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@panel.local}"

echo -e "${GREEN}[*] Install dependencies...${NC}"
if command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq
    apt-get install -y nginx php php-fpm php-mysql php-curl php-json php-mbstring \
        mysql-server curl wget unzip git 2>/dev/null || true
elif command -v yum >/dev/null 2>&1; then
    yum install -y nginx php php-fpm php-mysql php-curl php-json php-mbstring \
        mariadb-server curl wget unzip git 2>/dev/null || true
fi

echo -e "${GREEN}[*] Setup directories...${NC}"
mkdir -p "$PANEL_DIR"/{logs,backup,config,uploads}
mkdir -p "$PLTA_DIR" "$PLTC_DIR"
mkdir -p "$PLTA_DIR"/{api,admin,user,assets,uploads}
mkdir -p "$PLTC_DIR"/{api,admin,user,assets,uploads}
chmod -R 755 "$PANEL_DIR"

echo -e "${GREEN}[*] Setup database...${NC}"
DB_NAME="biscuit_panel"
DB_USER="biscuit_user"
DB_PASS=$(openssl rand -hex 16)

mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;" 2>/dev/null || true
mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';" 2>/dev/null || true
mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';" 2>/dev/null || true
mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true

# Simpan config DB
cat > "$PANEL_DIR/config/database.php" <<EOF
<?php
// 🍪 $TAG
return [
    'host' => 'localhost',
    'name' => '$DB_NAME',
    'user' => '$DB_USER',
    'pass' => '$DB_PASS',
];
EOF
chmod 600 "$PANEL_DIR/config/database.php"

echo -e "${GREEN}[*] Setup PLTA panel...${NC}"
cat > "$PLTA_DIR/index.php" <<'PHPEOF'
<?php
// 🍪 Protec By @biscuitMD - PLTA Panel
session_start();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>PLTA Panel - Biscuit</title>
    <link rel="stylesheet" href="/assets/style.css">
</head>
<body>
    <div id="landing" class="screen">
        <div class="box">
            <div class="logo">🍪</div>
            <h1 class="gold">PLTA Panel</h1>
            <p>Protec By @biscuitMD</p>
            <button onclick="location.href='admin/'">MASUK ADMIN</button>
        </div>
    </div>
    <script>
        window.PROTEC_WHITELIST = <?php echo json_encode(['admin1','biscuitmd','root']); ?>;
        window.PROTEC_USER = "<?php echo $_SESSION['username'] ?? 'guest'; ?>";
    </script>
    <script src="/anti-admin-panel.js"></script>
    <script src="/anti-intip-all-admin.js"></script>
    <script src="/anti-intip-manager.js"></script>
</body>
</html>
PHPEOF

cat > "$PLTC_DIR/index.php" <<'PHPEOF'
<?php
// 🍪 Protec By @biscuitMD - PLTC Panel
session_start();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>PLTC Panel - Biscuit</title>
    <link rel="stylesheet" href="/assets/style.css">
</head>
<body>
    <div id="landing" class="screen">
        <div class="box">
            <div class="logo">🍪</div>
            <h1 class="gold">PLTC Panel</h1>
            <p>Protec By @biscuitMD</p>
            <button onclick="location.href='admin/'">MASUK ADMIN</button>
        </div>
    </div>
    <script>
        window.PROTEC_WHITELIST = <?php echo json_encode(['admin1','biscuitmd','root']); ?>;
        window.PROTEC_USER = "<?php echo $_SESSION['username'] ?? 'guest'; ?>";
    </script>
    <script src="/anti-maling-pltc.js"></script>
    <script src="/anti-intip-manager.js"></script>
</body>
</html>
PHPEOF

echo -e "${GREEN}[*] Setup admin panel...${NC}"
mkdir -p "$PLTA_DIR/admin" "$PLTC_DIR/admin"

cat > "$PLTA_DIR/admin/index.php" <<'PHPEOF'
<?php
// 🍪 Protec By @biscuitMD - PLTA Admin
session_start();

$WHITELIST = ['admin1', 'biscuitmd', 'root'];
$CURRENT_USER = $_SESSION['username'] ?? 'guest';

$isAllowed = in_array($CURRENT_USER, $WHITELIST);
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Admin PLTA - Biscuit</title>
    <link rel="stylesheet" href="/assets/style.css">
</head>
<body>
    <div class="admin-panel">
        <h1 class="gold">🍪 Admin PLTA</h1>
        <p>Protec By @biscuitMD</p>
        <?php if (!$isAllowed): ?>
            <div class="alert">🚫 AKSES DIBLOCK - Login sebagai ID 1</div>
        <?php else: ?>
            <div class="menu">
                <a href="users.php">👥 Users</a>
                <a href="nodes.php">🖥️ Nodes</a>
                <a href="filemanager.php">📁 File Manager</a>
                <a href="pltc.php">⚙️ PLTC</a>
                <a href="settings.php">🔧 Settings</a>
            </div>
        <?php endif; ?>
    </div>
    <script>
        window.PROTEC_WHITELIST = <?php echo json_encode($WHITELIST); ?>;
        window.PROTEC_USER = "<?php echo $CURRENT_USER; ?>";
    </script>
    <script src="/anti-admin-panel.js"></script>
    <script src="/anti-intip-all-admin.js"></script>
    <script src="/anti-intip-manager.js"></script>
    <script src="/anti-intip-node.js"></script>
    <script src="/anti-maling-pltc.js"></script>
</body>
</html>
PHPEOF

# Copy sama buat PLTC
cp "$PLTA_DIR/admin/index.php" "$PLTC_DIR/admin/index.php"

echo -e "${GREEN}[*] Setup assets...${NC}"
cat > "$PLTA_DIR/assets/style.css" <<'CSSEOF'
* { margin:0; padding:0; box-sizing:border-box; font-family:'Segoe UI',sans-serif; }
body {
    background: linear-gradient(135deg, #0a1a3a 0%, #1e3a8a 50%, #0a1a3a 100%);
    min-height: 100vh; color: #fff; padding: 20px;
}
.screen { display: flex; align-items: center; justify-content: center; min-height: 100vh; }
.box, .admin-panel {
    background: rgba(255,255,255,0.08);
    backdrop-filter: blur(20px);
    border: 2px solid #d4af37;
    border-radius: 24px;
    padding: 40px;
    max-width: 600px;
    width: 100%;
    text-align: center;
    box-shadow: 0 8px 32px rgba(212,175,55,0.3);
}
.logo { font-size: 80px; filter: drop-shadow(0 0 20px #d4af37); }
.gold {
    background: linear-gradient(90deg, #d4af37, #ffd700, #d4af37);
    -webkit-background-clip: text;
    background-clip: text;
    color: transparent;
    font-weight: 900;
    margin: 15px 0;
}
button, .menu a {
    display: inline-block;
    padding: 14px 28px;
    margin: 8px;
    border: none;
    border-radius: 12px;
    background: linear-gradient(90deg, #d4af37, #ffd700);
    color: #0a1a3a;
    font-weight: 800;
    text-decoration: none;
    cursor: pointer;
    box-shadow: 0 4px 15px rgba(212,175,55,0.5);
    transition: transform 0.2s;
}
button:hover, .menu a:hover { transform: translateY(-2px) scale(1.02); }
.alert {
    background: rgba(255,107,107,0.2);
    border: 2px solid #ff6b6b;
    color: #ff6b6b;
    padding: 15px;
    border-radius: 12px;
    margin: 20px 0;
    font-weight: 700;
}
.menu { margin-top: 30px; display: flex; flex-wrap: wrap; justify-content: center; }
CSSEOF

cp "$PLTA_DIR/assets/style.css" "$PLTC_DIR/assets/style.css"

echo -e "${GREEN}[*] Setup nginx...${NC}"
cat > /etc/nginx/sites-available/biscuit-panel <<EOF
server {
    listen $PANEL_PORT;
    server_name $PANEL_DOMAIN;
    root $PLTA_DIR;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf 2>/dev/null || fastcgi_params;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location /pltc {
        alias $PLTC_DIR;
        index index.php;
    }

    location /anti- {
        alias /opt/biscuit-protec/inject/;
        try_files \$uri \$uri/ =404;
    }

    access_log $PANEL_DIR/logs/access.log;
    error_log $PANEL_DIR/logs/error.log;
}
EOF

ln -sf /etc/nginx/sites-available/biscuit-panel /etc/nginx/sites-enabled/biscuit-panel 2>/dev/null
nginx -t 2>/dev/null && systemctl reload nginx 2>/dev/null || true

echo -e "${GREEN}[*] Setup admin user...${NC}"
cat > "$PANEL_DIR/config/admin.txt" <<EOF
username=$ADMIN_USER
password=$(echo -n "$ADMIN_PASS" | md5sum | awk '{print $1}')
email=$ADMIN_EMAIL
role=ID1
created=$(date '+%F %T')
EOF
chmod 600 "$PANEL_DIR/config/admin.txt"

echo -e "${GREEN}[*] Setup service...${NC}"
cat > /etc/systemd/system/biscuit-panel.service <<EOF
[Unit]
Description=🍪 Biscuit Panel - Protec By @biscuitMD
After=network.target mysql.service nginx.service

[Service]
Type=simple
ExecStart=/bin/bash -c 'while true; do sleep 3600; done'
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable biscuit-panel.service 2>/dev/null
systemctl start biscuit-panel.service 2>/dev/null

# Simpan info
cat > "$PANEL_DIR/panel.info" <<EOF
DOMAIN=$PANEL_DOMAIN
PORT=$PANEL_PORT
PLTA_PATH=$PLTA_DIR
PLTC_PATH=$PLTC_DIR
ADMIN_USER=$ADMIN_USER
INSTALLED=$(date '+%F %T')
EOF

echo ""
echo -e "${GREEN}✅ PANEL INSTALL SELESAI${NC}"
echo ""
echo "🍪 $TAG"
echo ""
echo "📋 Info Panel:"
echo "   Domain  : http://$PANEL_DOMAIN:$PANEL_PORT"
echo "   PLTA    : http://$PANEL_DOMAIN:$PANEL_PORT/"
echo "   PLTC    : http://$PANEL_DOMAIN:$PANEL_PORT/pltc"
echo "   Admin ID: $ADMIN_USER"
echo "   DB Pass : $DB_PASS"
echo ""
echo "   Config  : $PANEL_DIR/config/"
echo "   Logs    : $PANEL_DIR/logs/"
echo ""