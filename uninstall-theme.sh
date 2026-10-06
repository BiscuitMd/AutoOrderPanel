#!/bin/bash
#################################################################
#  🍪 Biscuit Cream Theme Uninstaller
#  Protec By @biscuitMD
#################################################################

TAG="Protec By @biscuitMD"
GOLD='\033[0;33m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

[[ $EUID -ne 0 ]] && { echo -e "${RED}Root only!${NC}"; exit 1; }

echo -e "${GOLD}🍪 $TAG${NC}"
echo "🗑️ Uninstalling Biscuit Cream theme..."
echo ""

PANEL_PATHS=(
    "/var/www/pterodactyl"
    "/var/www/html/pterodactyl"
    "/opt/pterodactyl"
    "/usr/share/nginx/html/pterodactyl"
)

PANEL_PATH=""
for p in "${PANEL_PATHS[@]}"; do
    [ -d "$p" ] && { PANEL_PATH="$p"; break; }
done

[ -z "$PANEL_PATH" ] && { echo -e "${RED}❌ Panel nggak ketemu${NC}"; exit 1; }

# Hapus theme files
echo -e "${GREEN}[*] Remove theme files...${NC}"
rm -f "$PANEL_PATH/public/themes/biscuit-cream.css"
rm -f "$PANEL_PATH/public/themes/biscuit-cream.js"
echo "  ✅ Files dihapus"

# Remove inject dari layout
echo -e "${GREEN}[*] Remove inject...${NC}"
LAYOUT="$PANEL_PATH/resources/views/templates/wrapper.blade.php"

if [ -f "$LAYOUT" ]; then
    # Restore dari backup terbaru
    LATEST_BACKUP=$(ls -t "$LAYOUT".bak.* 2>/dev/null | head -1)
    if [ -n "$LATEST_BACKUP" ]; then
        cp "$LATEST_BACKUP" "$LAYOUT"
        echo "  ✅ Restored dari backup: $LATEST_BACKUP"
    else
        # Manual remove
        sed -i '/biscuit-cream/d' "$LAYOUT"
        echo "  ✅ Inject di-remove manual"
    fi
fi

# Clear cache
cd "$PANEL_PATH"
php artisan view:clear 2>/dev/null || true
php artisan cache:clear 2>/dev/null || true

echo ""
echo -e "${GREEN}✅ Uninstall selesai - Panel kembali normal${NC}"
echo "🍪 $TAG"
echo ""