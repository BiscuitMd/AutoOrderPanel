#!/bin/bash
#################################################################
#  🍪 Anti Intip Server - Real Protection
#  Protec By @biscuitMD
#
#  Fungsi:
#  - Deteksi admin panel intip server baru
#  - Inject overlay "Protec By @biscuitMD" ke panel
#  - Block user random saat klik server
#  - ID 1 bisa akses bebas
#################################################################

source /opt/biscuit-protec/protec-core.sh

WATCH_LOG="$PROTEC_DIR/logs/anti-intip-server.log"
INJECT_DIR="$PROTEC_DIR/inject"
mkdir -p "$INJECT_DIR"

protec_log "🚀 anti-intip-server START"

# ============ FOLDER PANEL YANG DI-SCAN ============
PANEL_DIRS=(
    "/var/www/html"
    "/var/www"
    "/usr/share/nginx/html"
    "/opt/panel"
    "/opt/admin"
    "/root/panel"
    "/home/*/panel"
    "/home/*/admin"
    "/srv/www"
)

# ============ KEYWORD PANEL INTIP SERVER ============
PANEL_KEYWORDS=(
    "intip"
    "intip-server"
    "lihat-server"
    "cek-server"
    "monitor-server"
    "status-server"
    "server-status"
    "server-online"
    "online-offline"
    "check-server"
    "view-server"
    "spy-server"
    "server-list"
    "list-server"
)

# ============ CARI PANEL INTIP SERVER ============
find_intip_panels() {
    for dir in "${PANEL_DIRS[@]}"; do
        for d in $dir; do
            [ ! -d "$d" ] && continue

            for kw in "${PANEL_KEYWORDS[@]}"; do
                find "$d" -maxdepth 5 -iname "*${kw}*" 2>/dev/null
            done
        done
    done
}

# ============ GENERATE OVERLAY JS ============
generate_overlay_js() {
    cat > "$INJECT_DIR/protec-overlay.js" <<'EOF'
/* 🍪 Protec By @biscuitMD - Overlay Blocker */
(function() {
    'use strict';

    const PROTEC_TAG = "Protec By @biscuitMD";
    const WHITELIST_USERS = window.PROTEC_WHITELIST || ["admin1", "biscuitmd", "root"];
    const CURRENT_USER = window.PROTEC_USER || localStorage.getItem('username') || 'guest';

    // Cek whitelist
    function isAllowed() {
        return WHITELIST_USERS.includes(CURRENT_USER);
    }

    // Bikin overlay
    function createOverlay() {
        const overlay = document.createElement('div');
        overlay.id = 'protec-overlay';
        overlay.innerHTML = `
            <div style="
                position: fixed;
                top: 0; left: 0;
                width: 100vw; height: 100vh;
                background: rgba(10, 15, 30, 0.95);
                backdrop-filter: blur(20px);
                z-index: 999999;
                display: flex;
                align-items: center;
                justify-content: center;
                font-family: 'Segoe UI', sans-serif;
                animation: protecFade 0.3s ease;
            ">
                <div style="
                    background: linear-gradient(135deg, rgba(10,26,58,0.98), rgba(30,58,138,0.98));
                    border: 3px solid #d4af37;
                    border-radius: 30px;
                    padding: 50px 60px;
                    text-align: center;
                    box-shadow: 0 20px 60px rgba(212,175,55,0.5), inset 0 0 30px rgba(212,175,55,0.1);
                    max-width: 90vw;
                    animation: protecPop 0.4s cubic-bezier(0.68, -0.55, 0.265, 1.55);
                ">
                    <div style="font-size: 80px; margin-bottom: 20px; filter: drop-shadow(0 0 20px #d4af37);">🍪</div>
                    <h1 style="
                        background: linear-gradient(90deg, #d4af37, #ffd700, #d4af37);
                        -webkit-background-clip: text;
                        background-clip: text;
                        color: transparent;
                        font-size: 38px;
                        font-weight: 900;
                        margin: 0 0 15px 0;
                        letter-spacing: 2px;
                        text-shadow: 0 0 30px rgba(212,175,55,0.5);
                    ">FITUR TERKUNCI</h1>
                    <div style="
                        color: #ff6b6b;
                        font-size: 20px;
                        font-weight: 700;
                        margin: 20px 0;
                        padding: 15px 30px;
                        border: 2px solid rgba(255,107,107,0.5);
                        border-radius: 15px;
                        background: rgba(255,107,107,0.1);
                    ">
                        🚫 AKSES DIBLOCK
                    </div>
                    <div style="
                        color: #c0c0c0;
                        font-size: 15px;
                        margin: 20px 0;
                    ">
                        Fitur intip server ini sedang dilindungi sistem.<br>
                        Hanya user terdaftar yang bisa mengakses.
                    </div>
                    <div style="
                        margin-top: 30px;
                        padding-top: 25px;
                        border-top: 2px solid rgba(212,175,55,0.3);
                    ">
                        <div style="
                            font-size: 24px;
                            font-weight: 900;
                            background: linear-gradient(90deg, #d4af37, #ffd700, #d4af37);
                            -webkit-background-clip: text;
                            background-clip: text;
                            color: transparent;
                            letter-spacing: 3px;
                            text-shadow: 0 0 20px rgba(212,175,55,0.6);
                        ">🍪 ${PROTEC_TAG} 🍪</div>
                    </div>
                    <div style="
                        margin-top: 15px;
                        color: #888;
                        font-size: 12px;
                    ">
                        User: ${CURRENT_USER} | Status: PROTECTED
                    </div>
                </div>
            </div>
            <style>
                @keyframes protecFade {
                    from { opacity: 0; }
                    to { opacity: 1; }
                }
                @keyframes protecPop {
                    0% { transform: scale(0.5); opacity: 0; }
                    100% { transform: scale(1); opacity: 1; }
                }
                body { overflow: hidden !important; }
            </style>
        `;
        return overlay;
    }

    // Block klik server
    function blockServerClick(e) {
        const target = e.target.closest('[data-server], .server-item, .server-card, .server-list tr, .server-btn, .intip-server, .view-server, .check-server');

        if (!target) return;

        // Cek whitelist
        if (isAllowed()) {
            console.log('🍪 Protec: User ' + CURRENT_USER + ' allowed');
            return;
        }

        // BLOCK!
        e.preventDefault();
        e.stopPropagation();
        e.stopImmediatePropagation();

        // Tampilkan overlay
        if (!document.getElementById('protec-overlay')) {
            document.body.appendChild(createOverlay());
        }

        // Log ke server (opsional)
        fetch('/protec-log', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                user: CURRENT_USER,
                action: 'blocked_intip',
                target: target.className,
                time: new Date().toISOString()
            })
        }).catch(() => {});

        return false;
    }

    // Auto block saat load halaman intip
    function autoBlockPage() {
        const url = window.location.href.toLowerCase();
        const isIntipPage = url.includes('intip') ||
                            url.includes('server-status') ||
                            url.includes('server-online') ||
                            url.includes('monitor-server');

        if (isIntipPage && !isAllowed()) {
            document.addEventListener('DOMContentLoaded', () => {
                document.body.appendChild(createOverlay());
            });
        }
    }

    // Intercept fetch/XHR ke API server
    const originalFetch = window.fetch;
    window.fetch = function(...args) {
        const url = String(args[0]).toLowerCase();
        const isServerAPI = url.includes('/api/server') ||
                            url.includes('/server/status') ||
                            url.includes('/intip') ||
                            url.includes('/monitor');

        if (isServerAPI && !isAllowed()) {
            protecLog('fetch_blocked', url);
            if (!document.getElementById('protec-overlay')) {
                document.body.appendChild(createOverlay());
            }
            return Promise.reject(new Error('🍪 Protec By @biscuitMD - BLOCKED'));
        }
        return originalFetch.apply(this, args);
    };

    // Intercept XHR
    const originalXHROpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function(method, url, ...rest) {
        const u = String(url).toLowerCase();
        if ((u.includes('/api/server') || u.includes('/intip')) && !isAllowed()) {
            if (!document.getElementById('protec-overlay')) {
                document.body.appendChild(createOverlay());
            }
            throw new Error('🍪 Protec By @biscuitMD - BLOCKED');
        }
        return originalXHROpen.apply(this, [method, url, ...rest]);
    };

    function protecLog(action, target) {
        try {
            fetch('/protec-log', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    user: CURRENT_USER,
                    action: action,
                    target: target,
                    time: new Date().toISOString()
                })
            }).catch(() => {});
        } catch(e) {}
    }

    // Init
    document.addEventListener('click', blockServerClick, true);
    autoBlockPage();

    console.log('🍪 Protec By @biscuitMD - Active | User: ' + CURRENT_USER);
})();
EOF

    protec_log "✅ Overlay JS generated"
}

# ============ INJECT KE PANEL ============
inject_to_panel() {
    local PANEL_FILE="$1"

    [ ! -f "$PANEL_FILE" ] && return 1

    # Cek udah di-inject belum
    if grep -q "protec-overlay.js" "$PANEL_FILE" 2>/dev/null; then
        return 0
    fi

    # Tentukan tipe file
    if echo "$PANEL_FILE" | grep -qiE "\.html?$"; then
        # Inject sebelum </body>
        if grep -q "</body>" "$PANEL_FILE"; then
            sed -i 's|</body>|<script src="/protec-overlay.js"></script>\n</body>|i' "$PANEL_FILE"
            protec_log "✅ Injected HTML: $PANEL_FILE"
        fi
    elif echo "$PANEL_FILE" | grep -qiE "\.php$"; then
        # Inject via PHP
        if grep -q "</body>" "$PANEL_FILE"; then
            sed -i 's|</body>|<script src="/protec-overlay.js"></script>\n</body>|i' "$PANEL_FILE"
            protec_log "✅ Injected PHP: $PANEL_FILE"
        fi
    elif echo "$PANEL_FILE" | grep -qiE "\.js$"; then
        # Inject via JS
        echo "" >> "$PANEL_FILE"
        echo "// 🍪 Protec By @biscuitMD" >> "$PANEL_FILE"
        echo "document.addEventListener('DOMContentLoaded',()=>{" >> "$PANEL_FILE"
        echo "  const s=document.createElement('script');s.src='/protec-overlay.js';document.body.appendChild(s);" >> "$PANEL_FILE"
        echo "});" >> "$PANEL_FILE"
        protec_log "✅ Injected JS: $PANEL_FILE"
    fi
}

# ============ DEPLOY OVERLAY KE WEB ROOT ============
deploy_overlay() {
    # Copy overlay ke web root
    for webroot in /var/www/html /usr/share/nginx/html /var/www; do
        [ ! -d "$webroot" ] && continue
        cp "$INJECT_DIR/protec-overlay.js" "$webroot/protec-overlay.js" 2>/dev/null
        chmod 644 "$webroot/protec-overlay.js" 2>/dev/null
        protec_log "✅ Overlay deployed: $webroot"
    done
}

# ============ MONITOR AKSES ============
monitor_access() {
    while true; do
        for panel in $(find_intip_panels); do
            [ ! -e "$panel" ] && continue

            # Cek proses yang akses
            local PIDS=$(lsof "$panel" 2>/dev/null | awk 'NR>1 {print $2}' | sort -u)

            for pid in $PIDS; do
                [ -z "$pid" ] && continue
                local USER=$(ps -p "$pid" -o user= 2>/dev/null | tr -d ' ')
                [ -z "$USER" ] && continue

                # Skip system
                [[ "$USER" =~ ^(root|systemd|www-data|nginx|mysql)$ ]] && continue

                # 👑 Whitelist skip
                if protec_is_allowed "$USER"; then
                    protec_log "👑 ALLOWED | user=$USER | panel=$panel"
                    continue
                fi

                # 🚫 BLOCK
                kill -9 "$pid" 2>/dev/null
                protec_log "🚫 BLOCKED | user=$USER | panel=$panel | pid=$pid"

                echo ""
                echo "╔══════════════════════════════════════════════════════╗"
                echo "║                                                      ║"
                echo "║  🚫  FITUR INTIP SERVER TERKUNCI                     ║"
                echo "║                                                      ║"
                echo "║  User  : $USER"
                echo "║  Panel : $panel"
                echo "║                                                      ║"
                echo "║              🍪  Protec By @biscuitMD  🍪            ║"
                echo "║                                                      ║"
                echo "╚══════════════════════════════════════════════════════╝"
                echo ""
            done
        done
        sleep 3
    done
}

# ============ MONITOR PANEL BARU ============
watch_new_panels() {
    for dir in "${PANEL_DIRS[@]}"; do
        for d in $dir; do
            [ ! -d "$d" ] && continue

            inotifywait -m -r -e create,moved_to "$d" 2>/dev/null | \
            while read path file; do
                FULL="${path}${file}"

                # Match keyword intip
                if echo "$FULL" | grep -qiE "intip|lihat-server|server-status|server-online|monitor-server"; then
                    protec_log "🆕 NEW INTIP PANEL | $FULL"
                    echo "[$(date '+%F %T')] 🆕 $TAG | New panel: $FULL" >> "$WATCH_LOG"

                    # Inject protec
                    sleep 1
                    inject_to_panel "$FULL"
                fi
            done &
        done
    done
    wait
}

# ============ MAIN ============
echo ""
echo "🍪 $TAG"
echo "🔒 Anti Intip Server - Starting..."
echo ""

# Generate overlay
generate_overlay_js

# Deploy ke web root
deploy_overlay

# Scan & inject panel yang ada
echo "🔍 Scanning panels..."
COUNT=0
for panel in $(find_intip_panels); do
    [ -z "$panel" ] && continue
    inject_to_panel "$panel"
    COUNT=$((COUNT+1))
done
echo "✅ Injected: $COUNT panels"

echo ""
echo "🚀 Monitoring aktif..."
echo ""

# Jalanin paralel
monitor_access &
watch_new_panels &

wait