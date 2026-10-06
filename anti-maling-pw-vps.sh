#!/bin/bash
#################################################################
#  🍪 Anti Maling PW VPS - Real Protection
#  Protec By @biscuitMD
#
#  Deteksi & block script/proses yang coba curi password VPS
#  Keyword: pwvps, pw vps, cek pw vps, ipvps, passwd vps, dll
#################################################################

source /opt/biscuit-protec/protec-core.sh

WATCH_LOG="$PROTEC_DIR/logs/anti-maling-pw.log"
SUSPEND_LOG="$PROTEC_DIR/logs/suspended.log"
SUSPEND_DIR="$PROTEC_DIR/suspended"

mkdir -p "$SUSPEND_DIR"

protec_log "🚀 anti-maling-pw-vps START"

# ============ KEYWORD MENcurigakan ============
SUSPECT_KEYWORDS=(
    "pwvps"
    "pw_vps"
    "pw-vps"
    "pw vps"
    "passwdvps"
    "passwd_vps"
    "passwordvps"
    "password_vps"
    "ipvps"
    "ip_vps"
    "ip-vps"
    "cek pw"
    "cekpw"
    "cek_pw"
    "cek password"
    "getpw"
    "get_pw"
    "dump pw"
    "dumppw"
    "steal pw"
    "stealpw"
    "curi pw"
    "curipw"
    "ambil pw"
    "ambipw"
    "list pw"
    "listpw"
    "showpw"
    "show pw"
    "extract pw"
    "extractpw"
    "grab pw"
    "grabpw"
)

# ============ FILE/FOLDER MENcurigakan ============
SUSPECT_PATHS=(
    "/tmp/pwvps"
    "/tmp/pw_vps"
    "/tmp/ipvps"
    "/tmp/pw"
    "/tmp/passwd"
    "/root/pwvps"
    "/root/pw_vps"
    "/root/ipvps"
    "/home/*/pwvps"
    "/home/*/ipvps"
    "/var/tmp/pwvps"
    "/dev/shm/pwvps"
    "/dev/shm/pw"
)

# ============ CEK APAKAH USER DIIZINKAN ============
is_user_allowed() {
    local USER="$1"
    protec_is_allowed "$USER" "anti-maling-pw"
}

# ============ SUSPEND PROSES ============
suspend_process() {
    local PID="$1"
    local USER="$2"
    local CMD="$3"
    local REASON="$4"

    # 👑 Skip whitelist
    if is_user_allowed "$USER"; then
        protec_log "👑 ALLOWED | user=$USER | cmd=$CMD"
        return 0
    fi

    # 🚫 SUSPEND (SIGSTOP - proses dibekukan)
    kill -STOP "$PID" 2>/dev/null

    # Simpan info proses yang di-suspend
    local SUSP_FILE="$SUSPEND_DIR/${PID}.info"
    cat > "$SUSP_FILE" <<EOF
PID=$PID
USER=$USER
CMD=$CMD
REASON=$REASON
TIME=$(date '+%F %T')
EOF

    # Log
    protec_log "🚫 SUSPENDED | pid=$PID | user=$USER | cmd=$CMD | reason=$REASON"
    echo "[$(date '+%F %T')] 🚫 $TAG | SUSPEND: PID=$PID user=$USER cmd=$CMD" >> "$SUSPEND_LOG"

    # Tampilkan banner
    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║  🚫 PROSES DI-SUSPEND!                        ║"
    echo "║                                              ║"
    echo "║  PID    : $PID"
    echo "║  User   : $USER"
    echo "║  Cmd    : $CMD"
    echo "║  Alasan : $REASON"
    echo "║                                              ║"
    echo "║  🍪 $TAG"
    echo "╚══════════════════════════════════════════════╝"
    echo ""
}

# ============ BLOCK PERMANEN ============
block_permanent() {
    local PID="$1"
    local USER="$2"
    local CMD="$3"
    local REASON="$4"

    # 👑 Skip whitelist
    if is_user_allowed "$USER"; then
        return 0
    fi

    # 🚫 KILL -9 (matikan total)
    kill -9 "$PID" 2>/dev/null

    # Lock user session (kalau bukan system user)
    if [[ ! "$USER" =~ ^(root|systemd|www-data|mysql|nginx|pterodactyl)$ ]]; then
        # Tendang semua session user
        pkill -9 -u "$USER" 2>/dev/null
    fi

    protec_log "🚫 BLOCKED PERMANENT | pid=$PID | user=$USER | cmd=$CMD | reason=$REASON"
    echo "[$(date '+%F %T')] 🚫 $TAG | BLOCKED: PID=$PID user=$USER cmd=$CMD" >> "$SUSPEND_LOG"

    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║  🚫 AKSES DIBLOCK TOTAL!                      ║"
    echo "║                                              ║"
    echo "║  PID    : $PID"
    echo "║  User   : $USER"
    echo "║  Cmd    : $CMD"
    echo "║  Alasan : $REASON"
    echo "║                                              ║"
    echo "║  🍪 $TAG"
    echo "╚══════════════════════════════════════════════╝"
    echo ""
}

# ============ CEK COMMAND LINE ============
check_cmdline() {
    local PID="$1"
    local CMDLINE=$(tr '\0' ' ' < "/proc/$PID/cmdline" 2>/dev/null)
    local USER=$(ps -p "$PID" -o user= 2>/dev/null | tr -d ' ')

    [ -z "$USER" ] && return
    [ -z "$CMDLINE" ] && return

    # Skip proses system penting
    [[ "$CMDLINE" =~ ^(/usr/lib/systemd|/sbin/init|kernel) ]] && return
    [[ "$CMDLINE" =~ ^/opt/biscuit-protec/ ]] && return
    [[ "$CMDLINE" =~ grep ]] && return

    # Cek keyword mencurigakan
    local CMD_LOWER=$(echo "$CMDLINE" | tr '[:upper:]' '[:lower:]')

    for kw in "${SUSPECT_KEYWORDS[@]}"; do
        if echo "$CMD_LOWER" | grep -qE "$kw"; then
            # 🚫 SUSPEND dulu
            suspend_process "$PID" "$USER" "$CMDLINE" "Keyword: $kw"

            # Tunggu 5 detik, kalau masih ada → block permanent
            sleep 5
            if kill -0 "$PID" 2>/dev/null; then
                block_permanent "$PID" "$USER" "$CMDLINE" "Masih running setelah suspend"
            fi
            return
        fi
    done
}

# ============ CEK FILE MENcurigakan ============
check_suspect_files() {
    for pattern in "${SUSPECT_PATHS[@]}"; do
        for f in $pattern; do
            [ ! -e "$f" ] && continue

            # Ambil user pemilik
            local OWNER=$(stat -c '%U' "$f" 2>/dev/null)

            # 👑 Skip whitelist
            if is_user_allowed "$OWNER"; then
                continue
            fi

            # 🚫 Hapus file mencurigakan
            chattr -i "$f" 2>/dev/null
            rm -f "$f" 2>/dev/null

            protec_log "🚫 DELETED SUSPECT FILE | $f | owner=$OWNER"
            echo "[$(date '+%F %T')] 🚫 $TAG | Deleted: $f (owner=$OWNER)" >> "$SUSPEND_LOG"
        done
    done
}

# ============ MONITOR PROCESS REAL-TIME ============
monitor_process() {
    protec_log "🔍 Monitor process mulai"

    while true; do
        # Loop semua PID
        for pid in /proc/[0-9]*; do
            pid_num=$(basename "$pid")
            [ ! -d "/proc/$pid_num" ] && continue

            check_cmdline "$pid_num"
        done

        # Cek file mencurigakan
        check_suspect_files

        sleep 3
    done
}

# ============ MONITOR FILE /etc/shadow ============
monitor_shadow() {
    protec_log "🔍 Monitor /etc/shadow mulai"

    # Bikin immutable
    chattr +i /etc/shadow /etc/passwd /etc/gshadow /etc/group 2>/dev/null

    inotifywait -m -e access,open,modify /etc/shadow /etc/passwd /etc/gshadow /etc/group 2>/dev/null | \
    while read path action file; do
        FULL="${path}${file}"

        USER=$(lsof "$FULL" 2>/dev/null | awk 'NR>1 {print $3}' | head -1)
        [ -z "$USER" ] && USER="unknown"
        PID=$(lsof "$FULL" 2>/dev/null | awk 'NR>1 {print $2}' | head -1)

        # 👑 Skip whitelist
        is_user_allowed "$USER" && continue

        # Skip proses internal (systemd, login, sshd)
        CMD=$(tr '\0' ' ' < "/proc/$PID/cmdline" 2>/dev/null)
        [[ "$CMD" =~ ^(/usr/sbin/sshd|/usr/bin/login|/usr/lib/systemd|/bin/login) ]] && continue

        # 🚫 BLOCK
        [ -n "$PID" ] && block_permanent "$PID" "$USER" "$CMD" "Akses /etc/shadow"
    done
}

# ============ START MONITOR ============
monitor_process &
monitor_shadow &

# Tunggu semua
wait