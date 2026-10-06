#!/bin/bash
#################################################################
#  🍪 Protec Notify - Kirim Pelanggaran ke Monitor
#  Protec By @biscuitMD
#################################################################

MONITOR_URL="${MONITOR_URL:-https://domaingw.com}"
API_ENDPOINT="$MONITOR_URL/api/notifications"

# Fungsi kirim notif
# Usage: protec_notify "module" "user" "target" "ip" "severity" "title"
protec_notify() {
    local MODULE="$1"
    local USER="$2"
    local TARGET="$3"
    local IP="${4:-—}"
    local SEVERITY="${5:-medium}"
    local TITLE="${6:-Pelanggaran terdeteksi}"

    local PAYLOAD=$(cat <<JSON
{
    "module": "$MODULE",
    "user": "$USER",
    "target": "$TARGET",
    "ip": "$IP",
    "severity": "$SEVERITY",
    "title": "$TITLE",
    "action": "BLOCKED",
    "time": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
}
JSON
)

    curl -s -X POST "$API_ENDPOINT" \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD" \
        -m 5 >/dev/null 2>&1 &

    echo "[$(date '+%F %T')] 🍪 Notif sent: $USER → $TARGET ($MODULE)"
}

# Kalau dipanggil langsung
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    protec_notify "$@"
fi