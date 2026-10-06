#!/bin/bash
#################################################################
#  🍪 Biscuit Cream Theme Installer - Pterodactyl
#  Protec By @biscuitMD
#################################################################

set -e
TAG="Protec By @biscuitMD"
GOLD='\033[0;33m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

[[ $EUID -ne 0 ]] && { echo -e "${RED}Root only!${NC}"; exit 1; }

echo -e "${GOLD}"
cat << "EOF"
╔══════════════════════════════════════════════════════╗
║          🍪  Biscuit Cream Theme Installer           ║
║          Protec By @biscuitMD                        ║
╚══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Auto-detect panel Pterodactyl
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

[ -z "$PANEL_PATH" ] && { echo -e "${RED}❌ Panel Pterodactyl nggak ketemu${NC}"; exit 1; }

echo -e "${GREEN}[*] Panel ditemukan: $PANEL_PATH${NC}"

# Copy theme
echo -e "${GREEN}[*] Copy theme...${NC}"
mkdir -p "$PANEL_PATH/public/themes"
cp "$(dirname "$0")/biscuit-cream.css" "$PANEL_PATH/public/themes/"
cp "$(dirname "$0")/biscuit-cream.js" "$PANEL_PATH/public/themes/"
echo "  ✅ Theme copied"

# Inject ke layout utama Pterodactyl
echo -e "${GREEN}[*] Inject ke layout...${NC}"
LAYOUT="$PANEL_PATH/resources/views/templates/wrapper.blade.php"

if [ -f "$LAYOUT" ]; then
    # Backup
    cp "$LAYOUT" "$LAYOUT.bak.$(date +%s)"

    # Cek udah di-inject
    if ! grep -q "biscuit-cream" "$LAYOUT"; then
        sed -i 's|</head>|<link rel="stylesheet" href="/themes/biscuit-cream.css">\n</head>|i' "$LAYOUT"
        sed -i 's|</body>|<script src="/themes/biscuit-cream.js"></script>\n</body>|i' "$LAYOUT"
        echo "  ✅ Layout di-inject"
    else
        echo "  ℹ️  Theme udah di-inject sebelumnya"
    fi
else
    echo -e "${RED}  ⚠️  Layout nggak ketemu: $LAYOUT${NC}"
    echo "  Manual: tambahin ke header.blade.php"
fi

# Clear cache
echo -e "${GREEN}[*] Clear cache...${NC}"
cd "$PANEL_PATH"
php artisan view:clear 2>/dev/null || true
php artisan cache:clear 2>/dev/null || true
echo "  ✅ Cache cleared"

# Set permission
chown -R www-data:www-data "$PANEL_PATH/public/themes" 2>/dev/null || \
    chown -R nginx:nginx "$PANEL_PATH/public/themes" 2>/dev/null || true
chmod 644 "$PANEL_PATH/public/themes"/* 2>/dev/null || true

echo ""
echo -e "${GREEN}✅ THEME INSTALLED!${NC}"
echo ""
echo "🍪 $TAG"
echo ""
echo "🎨 Theme: Biscuit Cream"
echo "📁 Path : $PANEL_PATH/public/themes/"
echo ""
echo "🔄 Refresh panel lo (Ctrl+F5)"
echo ""