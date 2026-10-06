#!/bin/bash
#################################################################
#  🍪 Anti Intip Username - Block Lihat Username
#  Protec By @biscuitMD
#
#  Fungsi:
#  - Block akses menu "Username" / "User List" di admin panel
#  - User random gak bisa lihat daftar username
#  - Cuma ID 1 yang bisa akses
#  - SAFE: nggak ganggu panel & VPS
#################################################################

source /opt/biscuit-protec/protec-core.sh

WATCH_LOG="$PROTEC_DIR/logs/anti-intip-username.log"
INJECT_DIR="$PROTEC_DIR/inject"
PROTEC_STATE="$PROTEC_DIR/state"
mkdir -p "$INJECT_DIR" "$PROTEC_STATE"

protec_log "🚀 anti-intip-username START"

STATE_FILE="$PROTEC_STATE/anti-intip-username.lock"
[ ! -f "$STATE_FILE" ] && touch "$STATE_FILE"

PANEL_DIRS=(
    "/var/www/html" "/var/www" "/usr/share/nginx/html"
    "/opt/panel" "/opt/admin" "/opt/plta" "/opt/pltc"
    "/root/panel" "/root/plta" "/root/pltc"
    "/home/*/panel" "/home/*/plta" "/home/*/pltc"
    "/var/www/pterodactyl"
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

find_username_panels() {
    for dir in "${PANEL_DIRS[@]}"; do
        for d in $dir; do
            [ ! -d "$d" ] && continue
            find "$d" -maxdepth 5 \
                \( -iname "*username*.php" -o -iname "*username*.html" \
                -o -iname "*username*.blade.php" -o -iname "*username*.js" \
                -o -iname "*user-list*" -o -iname "*list-user*" \
                -o -iname "*daftar-user*" -o -iname "*kelola-user*" \
                -o -iname "*manage-user*" -o -iname "*users.php" \) 2>/dev/null
        done
    done
}

# ============ GENERATE OVERLAY ============
generate_overlay() {
    cat > "$INJECT_DIR/anti-intip-username.js" <<'EOF'
/* 🍪 Protec By @biscuitMD - Anti Intip Username */
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
        const old = document.getElementById('protec-username-overlay');
        if (old) old.remove();

        const overlay = document.createElement('div');
        overlay.id = 'protec-username-overlay';
        overlay.innerHTML = `
            <div style="position:fixed;inset:0;background:rgba(26,26,26,0.9);backdrop-filter:blur(20px);-webkit-backdrop-filter:blur(20px);z-index:2147483647;display:flex;align-items:center;justify-content:center;font-family:'Poppins',system-ui,sans-serif;animation:protecFadeIn 0.3s ease;padding:20px;">
                <div style="background:linear-gradient(135deg,#ffffff,#fff8e1);border:3px solid #1a1a1a;border-radius:28px;padding:50px 55px;text-align:center;box-shadow:12px 12px 0 #1a1a1a;max-width:520px;width:100%;animation:protecPop 0.45s cubic-bezier(0.68,-0.55,0.265,1.55);position:relative;overflow:hidden;">
                    <div style="position:absolute;top:-50%;left:-50%;width:200%;height:200%;background:radial-gradient(circle,rgba(255,193,7,0.25) 0%,transparent 70%);animation:protecRotate 8s linear infinite;pointer-events:none;"></div>
                    <div style="position:relative;z-index:2;">
                        <div style="font-size:80px;margin-bottom:15px;filter:drop-shadow(3px 3px 0 #1a1a1a);animation:protecBounce 2s ease-in-out infinite;">🍪</div>
                        <h1 style="font-family:'Fredoka',sans-serif;background:linear-gradient(90deg,#e53935,#ffc107,#e53935);background-size:200% auto;-webkit-background-clip:text;background-clip:text;color:transparent;font-size:26px;font-weight:900;margin:0 0 10px 0;letter-spacing:2px;animation:protecShine 3s linear infinite;">USERNAME DIBLOCK</h1>
                        <div style="color:#e53935;font-size:18px;font-weight:800;margin:20px 0;padding:14px 28px;border:3px solid #1a1a1a;border-radius:14px;background:#ffcdd2;display:inline-block;">🚫 AKSES DIBLOCK</div>
                        <div style="color:#1a1a1a;font-size:14px;line-height:1.7;margin:18px 0;font-weight:600;">
                            Fitur <b style="color:#e53935">Lihat Daftar Username</b><br>
                            sedang dilindungi sistem.<br>
                            Hanya <b style="color:#e53935">Admin ID 1</b> yang bisa akses.
                        </div>
                        <div style="margin-top:28px;padding-top:22px;border-top:3px solid #1a1a1a;">
                            <div style="font-family:'Fredoka',sans-serif;font-size:22px;font-weight:900;background:linear-gradient(90deg,#ffc107,#e53935,#ffc107);background-size:200% auto;-webkit-background-clip:text;background-clip:text;color:transparent;letter-spacing:3px;animation:protecShine 3s linear infinite;">🍪 ${PROTEC_TAG} 🍪</div>
                        </div>
                        <div style="margin-top:14px;color:#757575;font-size:11px;font-family:monospace;font-weight:600;">
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
        if (!document.getElementById('protec-username-overlay')) {
            document.body.appendChild(createOverlay(reason));
        }
        protecLog('blocked', reason);
    }

    function isUsernameMenu(el) {
        const href = (el.getAttribute('href') || '').toLowerCase();
        const onclick = (el.getAttribute('onclick') || '').toLowerCase();
        const text = (el.textContent || '').trim().toLowerCase();
        const title = (el.getAttribute('title') || '').toLowerCase();
        const dataUrl = (el.getAttribute('data-url') || '').toLowerCase();
        const combined = [href, onclick, text, title, dataUrl].join(' ');

        const usernameKw = [
            'username', 'user-list', 'list-user', 'daftar-user',
            'kelola-user', 'manage-user', 'users', 'pengguna',
            'member-list', 'userlist', 'user_list'
        ];

        for (const kw of usernameKw) {
            if (combined.includes(kw)) return true;
        }
        return false;
    }

    function interceptClick(e) {
        if (isAllowed()) return;
        const target = e.target.closest('a, button, .btn, [role="button"], [onclick]');
        if (!target) return;
        if (!isUsernameMenu(target)) return;
        e.preventDefault();
        e.stopPropagation();
        e.stopImmediatePropagation();
        showBlock('Username Menu BLOCKED');
        return false;
    }

    const originalFetch = window.fetch;
    window.fetch = function(...args) {
        if (isAllowed()) return originalFetch.apply(this, args);
        const url = String(args[0]).toLowerCase();
        const usernameApis = [
            '/api/users', '/api/user/', '/api/usernames', '/users',
            '/user/list', '/admin/users', '/user-list', '/api/user-list',
            '/api/username', '/username/list'
        ];
        for (const api of usernameApis) {
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
            const usernameApis = ['/api/users', '/api/user/', '/api/usernames', '/admin/users', '/user-list', '/api/username'];
            for (const api of usernameApis) {
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
        const usernamePages = [
            '/admin/users', '/admin/user', '/users', '/user-list',
            '/username', '/username-list', '/kelola-user', '/manage-user',
            '/daftar-user', '/list-user'
        ];
        for (const p of usernamePages) {
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
                    module: 'anti-intip-username',
                    time: new Date().toISOString()
                })
            }).catch(() => {});
        } catch(e) {}
    }

    document.addEventListener('click', interceptClick, true);
    autoBlockPage();

    console.log('%c🍪 ' + PROTEC_TAG + ' | Anti Intip Username | User: ' + CURRENT_USER, 'color:#ffc107;font-weight:bold;background:#1a1a1a;padding:4px 8px;border-radius:4px;');
})();
EOF
    protec_log "✅ anti-intip-username overlay generated"
}

inject_to_panel() {
    local FILE="$1"
    [ ! -f "$FILE" ] && return 1
    grep -q "anti-intip-username.js" "$FILE" 2>/dev/null && return 0
    cp "$FILE" "$PROTEC_DIR/backup/$(basename $FILE).bak" 2>/dev/null
    if echo "$FILE" | grep -qiE "\.html?$|\.php$|\.blade\.php$"; then
        grep -q "</body>" "$FILE" && \
            sed -i 's|</body>|<script src="/anti-intip-username.js"></script>\n</body>|i' "$FILE" && \
            protec_log "✅ Injected: $FILE"
    elif echo "$FILE" | grep -qiE "\.js$"; then
        cat >> "$FILE" <<'JSEOF'

// 🍪 Protec By @biscuitMD - Anti Intip Username
document.addEventListener('DOMContentLoaded', function() {
    var s = document.createElement('script');
    s.src = '/anti-intip-username.js';
    document.body.appendChild(s);
});
JSEOF
        protec_log "✅ Injected JS: $FILE"
    fi
}

deploy_overlay() {
    for webroot in /var/www/html /usr/share/nginx/html /var/www /var/www/pterodactyl/public /var/www/plta/public /var/www/pltc/public; do
        [ ! -d "$webroot" ] && continue
        cp "$INJECT_DIR/anti-intip-username.js" "$webroot/anti-intip-username.js" 2>/dev/null
        chmod 644 "$webroot/anti-intip-username.js" 2>/dev/null
        protec_log "✅ Deployed: $webroot/anti-intip-username.js"
    done
}

monitor_access() {
    while true; do
        [ ! -f "$STATE_FILE" ] && { sleep 10; continue; }
        for panel in $(find_username_panels); do
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

                protec_log "🚫 BLOCKED USERNAME | user=$USER | panel=$panel"
                echo "[$(date '+%F %T')] 🚫 $TAG | Blocked: $USER → $panel" >> "$WATCH_LOG"

                protec_notify "anti-intip-username" "$USER" "$panel" "—" "high" "Username Menu Diblok"
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
                if echo "$FULL" | grep -qiE "username|user-list|users"; then
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
echo "🔒 Anti Intip Username - Starting..."
echo ""

generate_overlay
deploy_overlay

echo "🔍 Scanning username panels..."
COUNT=0
for panel in $(find_username_panels); do
    [ -z "$panel" ] && continue
    inject_to_panel "$panel"
    COUNT=$((COUNT+1))
done
echo "✅ Injected: $COUNT panels"

echo ""
echo "🚀 Monitoring aktif (SAFE MODE)..."
echo "   ✅ ID 1 bisa lihat username"
echo "   🚫 User random diblok + overlay"
echo "   🛡️ Panel & VPS AMAN"
echo ""

monitor_access &
watch_new_panels &

wait