#!/bin/bash
#################################################################
#  🍪 Biscuit Protec - Uninstaller
#  Protec By @biscuitMD
#################################################################

TAG="Protec By @biscuitMD"
PROTEC_DIR="/opt/biscuit-protec"
GREEN='\033[0;32m'; GOLD='\033[0;33m'; NC='\033[0m'

[[ $EUID -ne 0 ]] && { echo "Root only!"; exit 1; }

echo -e "${GOLD}🍪 $TAG${NC}"
echo "🗑️ Uninstalling..."

# Stop semua protec
pkill -f "$PROTEC_DIR/anti-" 2>/dev/null
echo "  ⏹️  Semua protec di-stop"

# Hapus state (auto OFF)
rm -f "$PROTEC_DIR/state"/*.lock
echo "  🔓 State dihapus (auto OFF)"

# Restore backup panel & bot
if [ -d "$PROTEC_DIR/backup" ]; then
    COUNT=0
    for bak in "$PROTEC_DIR/backup"/*.bak; do
        [ ! -f "$bak" ] && continue
        ORIG=$(basename "$bak" .bak)
        find /var/www /opt /root /home /usr/share/nginx/html -name "$ORIG" -type f 2>/dev/null | while read f; do
            cp "$bak" "$f" 2>/dev/null
        done
        COUNT=$((COUNT+1))
    done
    echo "  ♻️  Restored: $COUNT files"
fi

# Unlock semua fitur yang dikunci
if [ -d "$PROTEC_DIR/locks" ]; then
    for info in "$PROTEC_DIR/locks"/*.info; do
        [ ! -f "$info" ] && continue
        source "$info"
        [ -z "$TARGET" ] && continue
        chattr -i "$TARGET" 2>/dev/null
        [ -d "$TARGET" ] && find "$TARGET" -type f -exec chattr -i {} \; 2>/dev/null
        chmod "$PERM" "$TARGET" 2>/dev/null
        chown "$OWNER:$GROUP" "$TARGET" 2>/dev/null
    done
    rm -f "$PROTEC_DIR/locks"/*.lock "$PROTEC_DIR/locks"/*.info
    echo "  🔓 Semua fitur di-unlock"
fi

echo ""
echo -e "${GREEN}✅ Uninstall selesai - Semua protec OFF${NC}"
echo "   Panel & bot kembali normal"
echo ""
echo "🍪 $TAG"