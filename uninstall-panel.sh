#!/bin/bash
#################################################################
#  🍪 Biscuit Panel Uninstaller
#  Protec By @biscuitMD
#################################################################

TAG="Protec By @biscuitMD"
PANEL_DIR="/opt/biscuit-panel"
GREEN='\033[0;32m'; GOLD='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'

[[ $EUID -ne 0 ]] && { echo -e "${RED}Root only!${NC}"; exit 1; }

echo -e "${GOLD}"
cat << "EOF"
╔══════════════════════════════════════════════════════╗
║          🍪  Biscuit Panel Uninstaller               ║
║          Protec By @biscuitMD                        ║
╚══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

read -p "⚠️  Yakin mau uninstall panel? Backup dulu? (y/N): " CONFIRM
[[ ! "$CONFIRM" =~ ^[Yy]$ ]] && { echo "❌ Dibatalkan"; exit 0; }

# Backup dulu
BACKUP_FILE="/root/biscuit-panel-backup-$(date +%s).tar.gz"
if [ -d "$PANEL_DIR" ]; then
    echo -e "${GREEN}[*] Backup panel...${NC}"
    tar -czf "$BACKUP_FILE" "$PANEL_DIR" 2>/dev/null
    echo "  ✅ Backup: $BACKUP_FILE"
fi

# Stop protec dulu
echo -e "${GREEN}[*] Stop protec...${NC}"
pkill -f "/opt/biscuit-protec/anti-" 2>/dev/null
rm -f /opt/biscuit-protec/state/*.lock
echo "  ✅ Protec di-stop"

# Stop & hapus service
echo -e "${GREEN}[*] Remove service...${NC}"
systemctl stop biscuit-panel.service 2>/dev/null
systemctl disable biscuit-panel.service 2>/dev/null
rm -f /etc/systemd/system/biscuit-panel.service
systemctl daemon-reload
echo "  ✅ Service dihapus"

# Hapus nginx config
echo -e "${GREEN}[*] Remove nginx config...${NC}"
rm -f /etc/nginx/sites-available/biscuit-panel
rm -f /etc/nginx/sites-enabled/biscuit-panel
nginx -t 2>/dev/null && systemctl reload nginx 2>/dev/null || true
echo "  ✅ Nginx config dihapus"

# Hapus database
echo -e "${GREEN}[*] Remove database...${NC}"
mysql -e "DROP DATABASE IF EXISTS biscuit_panel;" 2>/dev/null || true
mysql -e "DROP USER IF EXISTS 'biscuit_user'@'localhost';" 2>/dev/null || true
mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true
echo "  ✅ Database dihapus"

# Unlock semua file yang di-chattr +i
echo -e "${GREEN}[*] Unlock files...${NC}"
for f in $(find "$PANEL_DIR" -type f 2>/dev/null); do
    chattr -i "$f" 2>/dev/null || true
done
echo "  ✅ Files di-unlock"

# Hapus folder panel
echo -e "${GREEN}[*] Remove panel folder...${NC}"
rm -rf "$PANEL_DIR"
echo "  ✅ Panel dihapus"

# Hapus inject overlay
echo -e "${GREEN}[*] Remove overlay...${NC}"
rm -f /var/www/html/*.js 2>/dev/null
rm -f /usr/share/nginx/html/*.js 2>/dev/null
rm -rf /opt/biscuit-protec/inject 2>/dev/null
echo "  ✅ Overlay dihapus"

# Info
echo ""
echo -e "${GREEN}✅ PANEL UNINSTALL SELESAI${NC}"
echo ""
echo "🍪 $TAG"
echo ""
echo "📋 Yang udah dihapus:"
echo "   ✅ Service biscuit-panel"
echo "   ✅ Nginx config"
echo "   ✅ Database biscuit_panel"
echo "   ✅ Folder /opt/biscuit-panel"
echo "   ✅ Overlay JS"
echo ""
echo "📦 Backup disimpan di: $BACKUP_FILE"
echo ""
echo "💡 Kalau mau restore:"
echo "   tar -xzf $BACKUP_FILE -C /"
echo ""