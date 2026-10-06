#!/bin/bash
#################################################################
#  🍪 Biscuit Protec - Full Installer
#  Protec By @biscuitMD
#################################################################

set -e
TAG="Protec By @biscuitMD"
PROTEC_DIR="/opt/biscuit-protec"
GOLD='\033[0;33m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

[[ $EUID -ne 0 ]] && { echo -e "${RED}Root only!${NC}"; exit 1; }

echo -e "${GOLD}"
cat << "EOF"
╔══════════════════════════════════════════════════════╗
║                                                      ║
║          🍪  Protec By @biscuitMD  🍪                ║
║                                                      ║
║          Biscuit Protec Installer v1.0               ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${GREEN}[*] Install dependencies...${NC}"
if command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq
    apt-get install -y inotify-tools curl jq 2>/dev/null || true
elif command -v yum >/dev/null 2>&1; then
    yum install -y inotify-tools curl jq 2>/dev/null || true
fi

echo -e "${GREEN}[*] Setup directories...${NC}"
mkdir -p "$PROTEC_DIR"/{logs,config,state,inject,backup,locks}
chmod -R 700 "$PROTEC_DIR"

echo -e "${GREEN}[*] Copy files...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/protec-core.sh" "$PROTEC_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR/anti-"*.sh "$PROTEC_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR/protec-toggle.sh" "$PROTEC_DIR/" 2>/dev/null || true
chmod +x "$PROTEC_DIR"/*.sh 2>/dev/null || true

echo -e "${GREEN}[*] Setup whitelist...${NC}"
if [ ! -s "$PROTEC_DIR/config/whitelist.txt" ]; then
    cat > "$PROTEC_DIR/config/whitelist.txt" <<EOF
root
biscuitmd
admin1
EOF
fi

echo -e "${GREEN}[*] AUTO ON all protec...${NC}"
touch "$PROTEC_DIR/state/anti-maling-plta.lock"
touch "$PROTEC_DIR/state/anti-intip-server.lock"
touch "$PROTEC_DIR/state/anti-delete-server-offline.lock"
touch "$PROTEC_DIR/state/anti-admin-panel.lock"
touch "$PROTEC_DIR/state/anti-admin-bot.lock"
touch "$PROTEC_DIR/state/anti-maling-pw-vps.lock"
touch "$PROTEC_DIR/state/anti-maling-username.lock"
touch "$PROTEC_DIR/state/anti-intip-node.lock"
touch "$PROTEC_DIR/state/anti-intip-all-admin.lock"
touch "$PROTEC_DIR/state/anti-intip-manager.lock"
touch "$PROTEC_DIR/state/anti-maling-pltc.lock"

echo -e "${GREEN}[*] Start protec...${NC}"
for s in "$PROTEC_DIR"/anti-*.sh; do
    [ ! -f "$s" ] && continue
    pgrep -f "$s" >/dev/null && continue
    nohup bash "$s" >/dev/null 2>&1 &
    echo "  ✅ $(basename $s)"
done

echo ""
echo -e "${GREEN}✅ Install selesai - Semua protec ON${NC}"
echo ""
echo "🍪 $TAG"
echo ""
echo "Config whitelist: $PROTEC_DIR/config/whitelist.txt"
echo "Log: $PROTEC_DIR/logs/"