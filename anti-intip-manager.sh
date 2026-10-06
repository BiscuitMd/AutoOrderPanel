#!/bin/bash
#################################################################
#  🍪 Anti Intip Manager - Block File Manager Menu
#  Protec By @biscuitMD
#
#  Fungsi:
#  - Block akses menu "File Manager" di admin panel
#  - User random gak bisa lihat isi file
#  - Cuma ID 1 yang bisa akses
#  - SAFE: nggak ganggu panel & VPS
#################################################################

source /opt/biscuit-protec/protec-core.sh

WATCH_LOG="$PROTEC_DIR/logs/anti-intip-manager.log"
INJECT_DIR="$PROTEC_DIR/inject"
PROTEC_STATE="$PROTEC_DIR/state"
mkdir -p "$INJECT_DIR" "$PROTEC_STATE"

protec_log "🚀 anti-intip-manager START"

STATE_FILE="$PROTEC_STATE/anti-intip-manager.lock"
[ ! -f "$STATE_FILE" ] && touch "$STATE_FILE"

PANEL_DIRS=(
    "/var/www/html" "/var/www" "/usr/share/nginx/html"
    "/opt/panel" "/opt/admin" "/opt/plta" "/opt/pltc"
    "/root/panel" "/root/plta" "/root/pltc"
    "/home/*/panel" "/home/*/plta" "/home/*/pltc"
)

SAFE_PROCESSES=(
    "wings" "pteroq" "pterodactyl" "php-fpm" "nginx" "apache2"
    "mysql" "mariadb" "redis" "docker" "containerd" "supervisord"
    "systemd" "cron" "sshd" "node" "php" "plta" "pltc"
)

is_safe_process() {
    local CMD="$1"
    for safe in "${SAFE_PROCESSES[@]}"; do
        if echo "$CMD" | grep -qiE "(^|/| )${safe}( |$|\.)"; then
            return 0
        fi
    done
    return 1
}

find_manager_panels() {
    for dir in "${PANEL_DIRS[@]}"; do
        for d in $dir; do
            [ ! -d "$d" ] && continue
            find "$d" -maxdepth 5 \
                \( -iname "*manager*.php" -o -iname "*manager*.html" \
                -o -iname "*filemanager*" -o -iname "*file-manager*" \
                -o -iname "*file_manager*" -o -iname "*files*.php" \
                -o -iname "*manager*.blade.php" \) 2>/dev/null
        done
    done
}

generate_overlay() {
    cat > "$INJECT_DIR/anti-intip-manager.js" <<'EOF'
/* 🍪 Protec By @biscuitMD - Anti Intip Manager */
(function() {
    'use strict';

    const PROTEC_TAG = "Protec By @biscuitMD";
    const WHITELIST = window.PROTEC_WHITELIST || ["admin1", "biscuitmd", "root"];
    const CURRENT_USER = window.PROTEC_USER ||
                         localStorage.getItem('username') ||
                         document.cookie.match(/username=([^;]+)/)?.[1] ||
                         'guest';

    function isAllowed() {
        return WHITELIST.includes(CURRENT_USER);
    }

    function createOverlay(reason) {
        const old = document.getElementById('protec-manager-overlay');
        if (old) old.remove();

        const overlay = document.createElement('div');
        overlay.id = 'protec-manager-overlay';
        overlay.innerHTML = `
            <div style="position:fixed;inset:0;background:rgba(5,10,25,0.96);backdrop-filter:blur(25px);-webkit-backdrop-filter:blur(25px);z-index:2147483647;display:flex;align-items:center;justify-content:center;font-family:'Segoe UI',system-ui,sans-serif;animation:protecFadeIn 0.3s ease;padding:20px;">
                <div style="background:linear-gradient(135deg,rgba(10,26,58,0.98),rgba(30,58,138,0.95));border:3px solid #d4af37;border-radius:28px;padding:50px 55px;text-align:center;box-shadow:0 25px 80px rgba(212,175,55,0.55),inset 0 0 40px rgba(212,175,55,0.08);max-width:520px;width:100%;animation:protecPop 0.45s cubic-bezier(0.68,-0.55,0.265,1.55);position:relative;overflow:hidden;">
                    <div style="position:absolute;top:-50%;left:-50%;width:200%;height:200%;background:radial-gradient(circle,rgba(212,175,55,0.15) 0%,transparent 70%);animation:protecRotate 8s linear infinite;pointer-events:none;"></div>
                    <div style="position:relative;z-index:2;">
                        <div style="font-size:80px;margin-bottom:15px;filter:drop-shadow(0 0 25px #d4af37);animation:protecBounce 2s ease-in-out infinite;">🍪</div>
                        <h1 style="background:linear-gradient(90deg,#d4af37,#ffd700,#d4af37);background-size:200% auto;-webkit-background-clip:text;background-clip:text;color:transparent;font-size:26px;font-weight:900;margin:0 0 10px 0;letter-spacing:2px;animation:protecShine 3s linear infinite;">FILE MANAGER DIBLOCK</h1>
                        <div style="color:#ff6b6b;font-size:18px;font-weight:700;margin:20px 0;padding:14px 28px;border:2px solid rgba(255,107,107,0.6);border-radius:14px;background:rgba(255,107,107,0.12);display:inline-block;">🚫 AKSES DIBLOCK</div>
                        <div style="color:#c0c0c0;font-size:14px;line-height:1.7;margin:18px 0;">
                            Menu <b style="color:#ffd700">File Manager</b><br>
                            sedang dilindungi sistem.<br>
                            Hanya <b style="color:#ffd700">Admin ID 1</b> yang bisa akses.
                        </div>
                        <div style="margin-top:28px;padding-top:22px;border-top:2px solid rgba(212,175,55,0.35);">
                            <div style="font-size:22px;font-weight:900;background:linear-gradient(90deg,#d4af37,#ffd700,#d4af37);background-size:200% auto;-webkit-background-clip:text;background-clip:text;color:transparent;letter-spacing:3px;animation:protecShine 3s linear infinite;">🍪 ${PROTEC_TAG} 🍪</div>
                        </div>
                        <div style="margin-top:14px;color:#666;font-size:11px;font-family:monospace;">
                            User: <b>${CURRENT_USER}</b> | ${reason || 'PROTECTED'} | ${new Date().toLocaleString()}
                        </div>
                    </div>
                </div>
            </div>
            <style>
                @keyframes protecFadeIn{from{opacity:0}to{opacity:1}}
                @keyframes protecPop{0%{transform:scale(0.5) rotate(-5deg);opacity:0}100%{transform:scale(1) rotate(0);opacity:1}}
                @keyframes protecShine{to{background-position:200% center}}
                @keyframes protecBounce{0%,100%{transform:translateY(0)}50%{transform:translateY(-12px)}}
                @keyframes protecRotate{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
                body{overflow:hidden !important;}
            </style>
        `;
        return overlay;
    }

    function showBlock(reason) {
        if (!document.getElementById('protec-manager-overlay')) {
            document.body.appendChild(createOverlay(reason));
        }
        protecLog('blocked', reason);
    }

    function isManagerMenu(el) {
        const href = (el.getAttribute('href') || '').toLowerCase();
        const onclick = (el.getAttribute('onclick') || '').toLowerCase();
        const text = (el.textContent || '').trim().toLowerCase();
        const title = (el.getAttribute('title') || '').toLowerCase();
        const dataUrl = (el.getAttribute('data-url') || '').toLowerCase();
        const combined = [href, onclick, text, title, dataUrl].join(' ');

        const managerKw = [
            'manager', 'file-manager', 'filemanager', 'file_manager',
            'files', 'kelola-file', 'manage-file', 'explorer',
            'file-explorer', 'browser', 'directory', 'folder'
        ];

        for (const kw of managerKw) {
            if (combined.includes(kw)) return true;
        }
        return false;
    }

    function interceptClick(e) {
        if (isAllowed()) return;
        const target = e.target.closest('a, button, .btn, [role="button"], [onclick]');
        if (!target) return;
        if (!isManagerMenu(target)) return;
        e.preventDefault();
        e.stopPropagation();
        e.stopImmediatePropagation();
        showBlock('Manager Menu BLOCKED');
        return false;
    }

    const originalFetch = window.fetch;
    window.fetch = function(...args) {
        if (isAllowed()) return originalFetch.apply(this, args);
        const url = String(args[0]).toLowerCase();
        const managerApis = [
            '/api/files', '/api/file', '/api/manager', '/api/filemanager',
            '/filemanager', '/file-manager', '/api/directory', '/api/folder'
        ];
        for (const api of managerApis) {
            if (url.includes(api)) {
                showBlock('API BLOCKED: ' + api);
                return Promise.reject(new Error('🍪 Protec By @biscuitMD - BLOCKED'));
            }
        }
        return originalFetch.apply(this, args);
    };

    const originalOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function(method, url, ...rest) {
        if (!isAllowed()) {
            const u = String(url).toLowerCase();
            const managerApis = ['/api/files', '/api/manager', '/filemanager', '/file-manager', '/api/directory'];
            for (const api of managerApis) {
                if (u.includes(api)) {
                    showBlock('XHR BLOCKED: ' + api);
                    throw new Error('🍪 Protec By @biscuitMD');
                }
            }
        }
        return originalOpen.apply(this, [method, url, ...rest]);
    };

    function autoBlockPage() {
        if (isAllowed()) return;
        const url = location.href.toLowerCase();
        const managerPages = ['/filemanager', '/file-manager', '/manager', '/files', '/explorer'];
        for (const p of managerPages) {
            if (url.includes(p)) {
                document.addEventListener('DOMContentLoaded', () => showBlock('Page BLOCKED: ' + p));
                return;
            }
        }
    }

    function protecLog(action, target) {
        try {
            fetch('/protec-log', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    user: CURRENT_USER,
                    action: action,
                    target: String(target),
                    module: 'anti-intip-manager',
                    time: new Date().toISOString()
                })
            }).catch(() => {});
        } catch(e) {}
    }

    document.addEventListener('click', interceptClick, true);
    autoBlockPage();

    console.log('%c🍪 ' + PROTEC_TAG + ' | Anti Intip Manager | User: ' + CURRENT_USER, 'color:#d4af37;font-weight:bold;');
})();
EOF
    protec_log "✅ anti-intip-manager overlay generated"
}

inject_to_panel() {
    local FILE="$1"
    [ ! -f "$FILE" ] && return 1
    grep -q "anti-intip-manager.js" "$FILE" 2>/dev/null && return 0
    cp "$FILE" "$PROTEC_DIR/backup/$(basename $FILE).bak" 2>/dev/null
    if echo "$FILE" | grep -qiE "\.html?$|\.php$|\.blade\.php$"; then
        grep -q "</body>" "$FILE" && \
            sed -i 's|</body>|<script src="/anti-intip-manager.js"></script>\n</body>|i' "$FILE" && \
            protec_log "✅ Injected: $FILE"
    fi
}

deploy_overlay() {
    for webroot in /var/www/html /usr/share/nginx/html /var/www /var/www/pterodactyl/public /var/www/plta/public /var/www/pltc/public; do
        [ ! -d "$webroot" ] && continue
        cp "$INJECT_DIR/anti-intip-manager.js" "$webroot/anti-intip-manager.js" 2>/dev/null
        chmod 644 "$webroot/anti-intip-manager.js" 2>/dev/null
    done
}

monitor_access() {
    while true; do
        [ ! -f "$STATE_FILE" ] && { sleep 10; continue; }
        for panel in $(find_manager_panels); do
            [ ! -e "$panel" ] && continue
            local PIDS=$(lsof "$panel" 2>/dev/null | awk 'NR>1 {print $2}' | sort -u)
            for pid in $PIDS; do
                [ -z "$pid" ] && continue
                local CMD=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)
                is_safe_process "$CMD" && continue
                local USER=$(ps -p "$pid" -o user= 2>/dev/null | tr -d ' ')
                [ -z "$USER" ] && continue
                [[ "$USER" =~ ^(root|systemd|www-data|nginx|mysql|pterodactyl)$ ]] && continue
                protec_is_allowed "$USER" && continue
                for spid in $(pgrep -u "$USER" 2>/dev/null); do
                    local SPROC=$(ps -p "$spid" -o comm= 2>/dev/null)
                    is_safe_process "$SPROC" && continue
                    [[ "$SPROC" =~ ^(systemd|init|dbus|sshd|bash|sh)$ ]] && continue
                    kill -9 "$spid" 2>/dev/null
                done
                protec_log "🚫 BLOCKED MANAGER MENU | user=$USER"
                echo "[$(date '+%F %T')] 🚫 $TAG | Blocked: $USER" >> "$WATCH_LOG"
            done
        done
        sleep 3
    done
}

watch_new_panels() {
    for dir in "${PANEL_DIRS[@]}"; do
        for d in $dir; do
            [ ! -d "$d" ] && continue
            inotifywait -m -r -e create,moved_to "$d" 2>/dev/null | \
            while read path file; do
                FULL="${path}${file}"
                if echo "$FULL" | grep -qiE "manager|file"; then
                    sleep 1
                    inject_to_panel "$FULL"
                fi
            done &
        done
    done
    wait
}

echo ""
echo "🍪 $TAG"
echo "🔒 Anti Intip Manager - Starting..."
generate_overlay
deploy_overlay
echo "🔍 Scanning manager panels..."
for panel in $(find_manager_panels); do
    inject_to_panel "$panel"
done
echo "🚀 Monitoring aktif..."
monitor_access &
watch_new_panels &
wait