#!/bin/bash
#################################################################
#  🍪 Biscuit Theme Manager
#  Protec By @biscuitMD
#################################################################

TAG="Protec By @biscuitMD"
THEMES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PANEL_DIR="/opt/biscuit-panel"
GOLD='\033[0;33m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

show_banner() {
    echo -e "${GOLD}"
    cat << "EOF"
╔══════════════════════════════════════════════════════╗
║          🍪  Biscuit Theme Manager                   ║
║          Protec By @biscuitMD                        ║
╚══════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

list_themes() {
    echo "📋 Theme tersedia:"
    echo ""
    for theme in "$THEMES_DIR"/*/; do
        [ ! -d "$theme" ] && continue
        NAME=$(basename "$theme")
        [ "$NAME" = "theme-manager.sh" ] && continue
        echo "  • $NAME"
    done
}

apply_theme() {
    local THEME_NAME="$1"
    local THEME_PATH="$THEMES_DIR/$THEME_NAME"

    [ ! -d "$THEME_PATH" ] && { echo -e "${RED}❌ Theme '$THEME_NAME' nggak ada${NC}"; exit 1; }

    echo -e "${GREEN}[*] Apply theme: $THEME_NAME${NC}"

    # Copy CSS ke panel
    if [ -f "$THEME_PATH/style.css" ]; then
        mkdir -p "$PANEL_DIR/assets"
        cp "$THEME_PATH/style.css" "$PANEL_DIR/assets/style.css"
        echo "  ✅ CSS applied"
    fi

    # Copy JS
    if [ -f "$THEME_PATH/theme.js" ]; then
        cp "$THEME_PATH/theme.js" "$PANEL_DIR/assets/theme.js"
        echo "  ✅ JS applied"
    fi

    # Save active theme
    mkdir -p "$PANEL_DIR/config"
    echo "$THEME_NAME" > "$PANEL_DIR/config/active-theme.txt"
    echo "  ✅ Active theme: $THEME_NAME"

    # Inject ke semua panel HTML
    find "$PANEL_DIR" -name "*.php" -o -name "*.html" 2>/dev/null | while read f; do
        # Cek udah ada theme.js
        grep -q "theme.js" "$f" 2>/dev/null && continue

        # Inject sebelum </body>
        if grep -q "</body>" "$f"; then
            sed -i 's|</body>|<script src="/assets/theme.js"></script>\n</body>|i' "$f"
        fi
    done
    echo "  ✅ Injected ke semua panel"

    echo ""
    echo -e "${GREEN}✅ Theme '$THEME_NAME' aktif!${NC}"
    echo "🍪 $TAG"
}

case "$1" in
    list)
        show_banner
        list_themes
        ;;
    apply)
        show_banner
        [ -z "$2" ] && { list_themes; echo ""; echo "Usage: $0 apply <theme-name>"; exit 1; }
        apply_theme "$2"
        ;;
    current)
        show_banner
        if [ -f "$PANEL_DIR/config/active-theme.txt" ]; then
            echo "🎨 Theme aktif: $(cat $PANEL_DIR/config/active-theme.txt)"
        else
            echo "⚠️ Belum ada theme aktif"
        fi
        ;;
    *)
        show_banner
        echo "Usage: $0 {list|apply <theme>|current}"
        echo ""
        echo "  list           → Lihat semua theme"
        echo "  apply <theme>  → Ganti theme"
        echo "  current        → Cek theme aktif"
        echo ""
        list_themes
        ;;
esac