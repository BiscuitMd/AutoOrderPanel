#!/bin/bash
#################################################################
#  🍪 Anti Maling PLTA - Protect API Key Feature
#  Protec By @biscuitMD
#
#  Fungsi:
#  - Lock semua fitur yang nama-nya match "plta*"
#  - User random buka → FITUR KEKUNCI + tendang
#  - User whitelist buka → BOLEH
#  - Muncul pesan "Protec By @biscuitMD"
#################################################################

source /opt/biscuit-protec/protec-core.sh

WATCH_LOG="$PROTEC_DIR/logs/anti-maling-plta.log"

protec_log "🚀 anti-maling-plta START"

# ============ FOLDER YANG DI-SCAN ============
SEARCH_DIRS=(
    "/root"
    "/home"
    "/opt"
    "/var/www"
    "/usr/local"
    "/srv"
)

# ============ CARI SEMUA FITUR PLTA ============
find_plta_features() {
    for dir in "${SEARCH_DIRS[@]}"; do
        [ ! -d "$dir" ] && continue
        find "$dir" -maxdepth 5 -iname "*plta*" 2>/dev/null
    done
}

# ============ LOCK SEMUA FITUR PLTA ============
lock_all_plta() {
    local FEATURES=$(find_plta_features)
    local COUNT=0

    for f in $FEATURES; do
        [ -z "$f" ] && continue
        protec_lock_feature "$f"
        COUNT=$((COUNT+1))
    done

    protec_log "🔒 Locked $COUNT plta features"
    echo "🔒 Total fitur plta dikunci: $COUNT"
}

# ============ DETEKSI AKSES KE FITUR PLTA ============
detect_access() {
    while true; do
        # Scan semua fitur plta
        for feature in $(find_plta_features); do
            [ ! -e "$feature" ] && continue

            # Cek proses yang akses file ini
            local PIDS=$(lsof "$feature" 2>/dev/null | awk 'NR>1 {print $2}' | sort -u)

            for pid in $PIDS; do
                [ -z "$pid" ] && continue

                local USER=$(ps -p "$pid" -o user= 2>/dev/null | tr -d ' ')
                [ -z "$USER" ] && continue

                # Skip proses system
                local CMD=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)
                [[ "$CMD" =~ ^(/usr/lib/systemd|/sbin/init|kernel) ]] && continue

                # 👑 WHITELIST - BOLEH
                if protec_is_allowed "$USER"; then
                    protec_log "👑 ALLOWED | user=$USER | feature=$feature"
                    continue
                fi

                # 🚫 BUKAN WHITELIST - BLOCK
                kill -9 "$pid" 2>/dev/null
                protec_log "🚫 BLOCKED ACCESS | user=$USER | pid=$pid | feature=$feature"
                echo "[$(date '+%F %T')] 🚫 $TAG | Blocked: $USER -> $feature" >> "$WATCH_LOG"

                # Tampilkan pesan
                protec_show_block "$USER" "$feature"

                # Tendang session
                for spid in $(pgrep -u "$USER" 2>/dev/null); do
                    PROC=$(ps -p "$spid" -o comm= 2>/dev/null)
                    [[ "$PROC" =~ ^(systemd|init|dbus|sshd) ]] && continue
                    kill -9 "$spid" 2>/dev/null
                done
            done
        done
        sleep 3
    done
}

# ============ MONITOR FILE BARU ============
watch_new_plta() {
    for dir in "${SEARCH_DIRS[@]}"; do
        [ ! -d "$dir" ] && continue

        inotifywait -m -r -e create,moved_to "$dir" 2>/dev/null | \
        while read path file; do
            FULL="${path}${file}"

            # Match pattern plta
            if echo "$FULL" | grep -qiE "plta"; then
                protec_log "🆕 NEW PLTA | $FULL"

                # Lock
                protec_lock_feature "$FULL"

                echo "[$(date '+%F %T')] 🆕 $TAG | New plta locked: $FULL" >> "$WATCH_LOG"
            fi
        done &
    done
    wait
}

# ============ MAIN ============
echo ""
echo "🍪 $TAG"
echo "🔒 Locking fitur plta..."
echo ""

lock_all_plta

echo ""
echo "🚀 Mulai monitoring..."
echo ""

# Jalanin paralel
detect_access &
watch_new_plta &

wait