#!/bin/bash
#################################################################
#  🍪 Biscuit Protec Core Library
#  Protec By @biscuitMD
#################################################################

TAG="Protec By @biscuitMD"
PROTEC_DIR="/opt/biscuit-protec"
REGISTRY="$PROTEC_DIR/registry.txt"
WHITELIST="$PROTEC_DIR/config/whitelist.txt"
LOG="$PROTEC_DIR/logs/protec.log"
LOCK_DIR="$PROTEC_DIR/locks"

mkdir -p "$PROTEC_DIR" "$PROTEC_DIR/logs" "$PROTEC_DIR/config" "$PROTEC_DIR/state" "$PROTEC_DIR/inject" "$PROTEC_DIR/backup" "$LOCK_DIR"
touch "$REGISTRY" "$WHITELIST" "$LOG"

# ============ LOG ============
protec_log() {
    echo "[$(date '+%F %T')] $1 | $TAG" >> "$LOG"
}

# ============ CEK USER WHITELIST ============
protec_is_allowed() {
    local USER="$1"
    [ -z "$USER" ] && return 1
    grep -qE "^${USER}$" "$WHITELIST" 2>/dev/null && return 0
    return 1
}

# ============ CEK PROTEC ON/OFF ============
protec_is_on() {
    local MODULE="$1"
    [ -f "$PROTEC_DIR/state/${MODULE}.lock" ] && return 0
    return 1
}

# ============ TAMPILKAN BANNER BLOCK ============
protec_show_block() {
    local USER="$1"
    local FEATURE="$2"
    local MODULE="${3:-unknown}"

    echo ""
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║                                                      ║"
    echo "║  🚫  AKSES DIBLOCK                                   ║"
    echo "║                                                      ║"
    echo "║  User   : $USER"
    echo "║  Fitur  : $FEATURE"
    echo "║  Modul  : $MODULE"
    echo "║  Status : PROTECTED                                  ║"
    echo "║                                                      ║"
    echo "║  Fitur ini sedang dalam perlindungan sistem.         ║"
    echo "║                                                      ║"
    echo "║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━     ║"
    echo "║                                                      ║"
    echo "║              🍪  Protec By @biscuitMD  🍪            ║"
    echo "║                                                      ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo ""
}

# ============ BLOCK USER ============
protec_block() {
    local USER="$1"
    local FEATURE="$2"
    local MODULE="${3:-unknown}"

    protec_show_block "$USER" "$FEATURE" "$MODULE"
    protec_log "🚫 BLOCKED | user=$USER | feature=$FEATURE | module=$MODULE"

    # Tendang session user (kecuali system)
    if [[ ! "$USER" =~ ^(root|systemd|www-data|mysql|nginx|pterodactyl|unknown)$ ]]; then
        for pid in $(pgrep -u "$USER" 2>/dev/null); do
            local PROC=$(ps -p "$pid" -o comm= 2>/dev/null)
            [[ "$PROC" =~ ^(systemd|init|dbus|sshd|bash|sh)$ ]] && continue
            kill -9 "$pid" 2>/dev/null
        done
    fi

    exit 403
}

# ============ KIRIM NOTIF KE MONITOR ============
protec_notify() {
    local MODULE="$1"
    local USER="$2"
    local TARGET="$3"
    local IP="${4:-—}"
    local SEVERITY="${5:-medium}"
    local TITLE="${6:-Pelanggaran terdeteksi}"

    # Load config monitor URL
    source "$PROTEC_DIR/config/monitor.conf" 2>/dev/null
    local MONITOR_URL="${MONITOR_URL:-}"
    [ -z "$MONITOR_URL" ] && return 0

    local API_ENDPOINT="$MONITOR_URL/api/notifications"

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

    protec_log "📤 NOTIFY SENT | $MODULE | $USER → $TARGET"
}

# ============ LOCK FITUR ============
protec_lock_feature() {
    local TARGET="$1"
    local LOCK_FILE="$LOCK_DIR/$(echo "$TARGET" | md5sum | awk '{print $1}').lock"

    [ ! -e "$TARGET" ] && return 1
    [ -f "$LOCK_FILE" ] && return 0

    local ORIG_OWNER=$(stat -c '%U' "$TARGET")
    local ORIG_GROUP=$(stat -c '%G' "$TARGET")
    local ORIG_PERM=$(stat -c '%a' "$TARGET")

    cat > "${LOCK_FILE}.info" <<EOF
TARGET=$TARGET
OWNER=$ORIG_OWNER
GROUP=$ORIG_GROUP
PERM=$ORIG_PERM
LOCKED_AT=$(date '+%F %T')
EOF

    chattr +i "$TARGET" 2>/dev/null
    chmod 000 "$TARGET" 2>/dev/null

    if [ -d "$TARGET" ]; then
        find "$TARGET" -type f -exec chattr +i {} \; 2>/dev/null
        find "$TARGET" -type f -exec chmod 000 {} \; 2>/dev/null
    fi

    touch "$LOCK_FILE"
    protec_log "🔒 LOCKED | $TARGET"
}

# ============ UNLOCK FITUR ============
protec_unlock_feature() {
    local TARGET="$1"
    local LOCK_FILE="$LOCK_DIR/$(echo "$TARGET" | md5sum | awk '{print $1}').lock"
    local INFO_FILE="${LOCK_FILE}.info"

    [ ! -f "$INFO_FILE" ] && return 1
    source "$INFO_FILE"

    chattr -i "$TARGET" 2>/dev/null
    if [ -d "$TARGET" ]; then
        find "$TARGET" -type f -exec chattr -i {} \; 2>/dev/null
    fi

    chmod "$PERM" "$TARGET" 2>/dev/null
    chown "$OWNER:$GROUP" "$TARGET" 2>/dev/null

    rm -f "$LOCK_FILE" "$INFO_FILE"
    protec_log "🔓 UNLOCKED | $TARGET"
}

# ============ SAFE PROCESS CHECK ============
protec_is_safe_process() {
    local CMD="$1"
    local SAFE_LIST="wings pteroq pterodactyl php-fpm nginx apache2 mysql mariadb redis docker containerd supervisord systemd cron sshd node php plta pltc"

    for safe in $SAFE_LIST; do
        if echo "$CMD" | grep -qiE "(^|/| )${safe}( |$|\.)"; then
            return 0
        fi
    done
    return 1
}