#!/bin/bash
#################################################################
#  🍪 Anti Intip Node v2 (FIXED)
#  Protec By @biscuitMD
#################################################################

source /opt/biscuit-protec/protec-core.sh

WATCH_LOG="$PROTEC_DIR/logs/anti-intip-node.log"
INJECT_DIR="$PROTEC_DIR/inject"
BACKUP_DIR="$PROTEC_DIR/backup/node-panels"

mkdir -p "$INJECT_DIR" "$BACKUP_DIR"

protec_log "🚀 anti-intip-node START"

# Folder — buang /usr/local, /srv
NODE_PANEL_DIRS=(
    "/var/www/html"
    "/var/www/pterodactyl/public"
    "/usr/share/nginx/html"
    "/opt/panel"
    "/opt/admin"
)

# Keyword SPESIFIK — buang "node", "nodes", "daemon", "allocation"
NODE_KEYWORDS=(
    "node-manager"
    "node-list"
    "nodes-list"
    "manage-node"
    "add-node"
    "edit-node"
    "delete-node"
    "node-status"
    "node-info"
    "wings-manager"
    "wings-list"
    "daemon-manager"
    "daemon-list"
)

SAFE_PROCESSES=(
    "wings" "pteroq" "pterodactyl" "php-fpm" "php8.1" "php8.2" "php8.3"
    "nginx" "apache2" "httpd" "mysql" "mariadb" "redis" "redis-server"
    "docker" "containerd" "supervisord" "systemd" "cron" "crond" "sshd"
    "node" "nodejs" "npm" "yarn" "pm2"
)

# ═══════════════════════════════════════════
# CARI FITUR NODE — FILTER SPESIFIK
# ═══════════════════════════════════════════
find_node_features() {
    for dir in "${NODE_PANEL_DIRS[@]}"; do
        [ ! -d "$dir" ] && continue

        for kw in "${NODE_KEYWORDS[@]}"; do
            find "$dir" -maxdepth 4 -type f \
                -not -path "*/node_modules/*" \
                -not -path "*/.git/*" \
                -not -path "*/vendor/*" \
                -not -path "*/cache/*" \
                -not -path "*/backup/*" \
                -not -path "*/logs/*" \
                \( -name "*.html" -o -name "*.htm" -o -name "*.php" \) \
                -iname "*${kw}*" 2>/dev/null
        done
    done
}

# ═══════════════════════════════════════════
# CEK PROSES AMAN — EXACT MATCH
# ═══════════════════════════════════════════
is_safe_process() {
    local CMD="$1"
    [ -z "$CMD" ] && return 1

    local BASENAME=$(basename "$CMD" 2>/dev/null | awk '{print $1}')
    [ -z "$BASENAME" ] && return 1

    for safe in "${SAFE_PROCESSES[@]}"; do
        [ "$BASENAME" = "$safe" ] && return 0
        # Match versi (php8.1, node18, dll)
        [[ "$BASENAME" =~ ^${safe}[0-9._]*$ ]] && return 0
    done
    return 1
}

# ═══════════════════════════════════════════
# GENERATE OVERLAY (INLINE, SERVER-SIDE CHECK)
# ═══════════════════════════════════════════
generate_node_overlay() {
    cat > "$INJECT_DIR/node-overlay-inline.js" <<'EOF'
(function(){
'use strict';
var TAG="Protec By @biscuitMD";
var USER=window.PROTEC_USER||localStorage.getItem('username')||'guest';
var ALLOWED=false;

// Server-side check
try{
    var xhr=new XMLHttpRequest();
    xhr.open('GET','/api/protec-check?user='+encodeURIComponent(USER),false);
    xhr.send();
    var r=JSON.parse(xhr.responseText||'{}');
    ALLOWED=r.allowed===true;
}catch(e){}

function showOverlay(reason){
    if(document.getElementById('protec-node-overlay'))return;
    var d=document.createElement('div');
    d.id='protec-node-overlay';
    d.innerHTML='<div style="position:fixed;inset:0;background:rgba(5,10,25,0.97);backdrop-filter:blur(25px);z-index:2147483647;display:flex;align-items:center;justify-content:center;font-family:Segoe UI,sans-serif;padding:20px"><div style="background:linear-gradient(135deg,rgba(10,26,58,0.98),rgba(30,58,138,0.95));border:3px solid #d4af37;border-radius:28px;padding:50px 55px;text-align:center;box-shadow:0 25px 80px rgba(212,175,55,0.55);max-width:500px;width:100%"><div style="font-size:80px;margin-bottom:15px;filter:drop-shadow(0 0 25px #d4af37)">🍪</div><h1 style="background:linear-gradient(90deg,#d4af37,#ffd700,#d4af37);background-size:200% auto;-webkit-background-clip:text;background-clip:text;color:transparent;font-size:32px;font-weight:900;margin:0 0 10px;letter-spacing:2px">FITUR NODE TERKUNCI</h1><div style="color:#ff6b6b;font-size:18px;font-weight:700;margin:20px 0;padding:14px 28px;border:2px solid rgba(255,107,107,0.6);border-radius:14px;background:rgba(255,107,107,0.12);display:inline-block">🚫 AKSES DIBLOCK</div><div style="color:#c0c0c0;font-size:14px;line-height:1.6;margin:18px 0">Fitur <b style="color:#ffd700">Node/Wings</b> dilindungi.<br>Hanya <b style="color:#ffd700">Admin ID 1</b> yang bisa akses.</div><div style="margin-top:28px;padding-top:22px;border-top:2px solid rgba(212,175,55,0.35)"><div style="font-size:22px;font-weight:900;background:linear-gradient(90deg,#d4af37,#ffd700,#d4af37);background-size:200% auto;-webkit-background-clip:text;background-clip:text;color:transparent;letter-spacing:3px">🍪 '+TAG+' 🍪</div></div><div style="margin-top:14px;color:#666;font-size:11px;font-family:monospace">User: <b>'+USER+'</b> | '+(reason||'PROTECTED')+'</div></div></div>';
    document.body.appendChild(d);
    document.body.style.overflow='hidden';
}

if(!ALLOWED){
    // Block page load
    if(/\/node|\/wings|\/daemon|\/allocation/i.test(location.pathname+location.search)){
        document.addEventListener('DOMContentLoaded',function(){showOverlay('page');});
    }

    // Block click
    document.addEventListener('click',function(e){
        var el=e.target.closest('a,button,[role=button]');
        if(!el)return;
        var c=((el.getAttribute('href')||'')+' '+(el.getAttribute('onclick')||'')+' '+(el.textContent||'')+' '+(el.getAttribute('data-url')||'')).toLowerCase();
        if(/node-manager|node-list|manage-node|add-node|edit-node|delete-node|wings-manager|daemon-manager/.test(c)){
            e.preventDefault();e.stopPropagation();
            showOverlay('click');
            return false;
        }
    },true);

    // Block fetch
    var of=window.fetch;
    window.fetch=function(){
        var u=String(arguments[0]).toLowerCase();
        if(/\/(api\/(nodes|node|wings|daemon|allocation)|\/node\/|\/nodes\/|\/wings\/)/i.test(u)){
            showOverlay('api');
            return Promise.reject(new Error('Protec By @biscuitMD'));
        }
        return of.apply(this,arguments);
    };

    // Block XHR
    var ox=XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open=function(m,u){
        var l=String(u).toLowerCase();
        if(/\/(api\/(nodes|node|wings|daemon|allocation)|\/node\/|\/nodes\/|\/wings\/)/i.test(l)){
            showOverlay('xhr');
            throw new Error('Protec By @biscuitMD');
        }
        return ox.apply(this,arguments);
    };
}

console.log('🍪 '+TAG+' | User: '+USER+' | '+(ALLOWED?'GRANTED':'BLOCKED'));
})();
EOF

    protec_log "✅ Node overlay inline generated"
}

# ═══════════════════════════════════════════
# INJECT — SKIP .JS, BACKUP, MARKER
# ═══════════════════════════════════════════
inject_to_panel() {
    local FILE="$1"
    [ ! -f "$FILE" ] && return 1

    # ⚠️ SKIP .js — BAHAYA
    [[ "$FILE" =~ \.js$ ]] && return 1

    # Skip kalau udah di-inject
    grep -q "Protec By @biscuitMD" "$FILE" 2>/dev/null && return 0

    # Cek file text (bukan binary)
    file "$FILE" | grep -qi "text" || return 1

    # Backup dengan struktur path
    local REL_PATH=$(echo "$FILE" | sed 's|/|_|g')
    local BACKUP_FILE="$BACKUP_DIR/${REL_PATH}.bak"
    cp "$FILE" "$BACKUP_FILE" 2>/dev/null
    echo "$FILE" > "${BACKUP_FILE}.path"

    # Inline overlay JS (escape untuk perl)
    local OVERLAY_JS=$(cat "$INJECT_DIR/node-overlay-inline.js" | tr '\n' ' ')

    # Inject pake perl (lebih reliable)
    if grep -q "</body>" "$FILE"; then
        perl -i -pe "s|</body>|<script>/*Protec By @biscuitMD*/$OVERLAY_JS</script></body>|i" "$FILE" 2>/dev/null && \
            protec_log "✅ Injected: $FILE" || \
            protec_log "❌ Failed: $FILE"
        return 0
    fi

    protec_log "⚠️ No </body>: $FILE"
    return 1
}

# ═══════════════════════════════════════════
# UNINSTALL
# ═══════════════════════════════════════════
uninstall_protec() {
    local COUNT=0
    for bak in "$BACKUP_DIR"/*.bak; do
        [ ! -f "$bak" ] && continue
        local path_file="${bak}.path"
        [ ! -f "$path_file" ] && continue
        local orig=$(cat "$path_file")
        [ ! -f "$orig" ] && continue
        cp "$bak" "$orig"
        COUNT=$((COUNT+1))
    done
    rm -rf "$BACKUP_DIR"/*
    protec_log "🗑 Uninstalled $COUNT panels"
    echo "✅ Uninstalled: $COUNT"
}

# ═══════════════════════════════════════════
# MONITOR VIA INOTIFYWAIT (BUKAN LOOP LSOF)
# ═══════════════════════════════════════════
monitor_panels() {
    [ ${#NODE_PANEL_DIRS[@]} -eq 0 ] && return

    protec_log "🔍 Monitor node panels start"

    inotifywait -m -r \
        --exclude '(\.log$|\.bak$|/logs/|/cache/|/tmp/|/backup/|/node_modules/|/vendor/|\.tar\.gz$|\.zip$)' \
        -e create,moved_to \
        "${NODE_PANEL_DIRS[@]}" 2>/dev/null | \
    while read path file; do
        FULL="${path}${file}"

        # Skip .js, backup, log
        [[ "$FULL" =~ \.js$ ]] && continue
        [[ "$FULL" =~ \.(bak|log|tmp|tar\.gz|zip)$ ]] && continue
        [[ "$FULL" =~ /node_modules/ ]] && continue
        [[ "$FULL" =~ /vendor/ ]] && continue

        # Cek keyword
        for kw in "${NODE_KEYWORDS[@]}"; do
            if echo "$FULL" | grep -qiE "$kw"; then
                protec_log "🆕 NEW NODE PANEL | $FULL"
                sleep 1
                inject_to_panel "$FULL"
                protec_alert "🆕 *NEW NODE PANEL*%0AFile: \`$FULL\`"
                break
            fi
        done
    done
}

# ═══════════════════════════════════════════
# MODE CLI
# ═══════════════════════════════════════════
case "$1" in
    uninstall)
        uninstall_protec
        exit 0
        ;;
    scan)
        echo "🔍 Scanning node panels..."
        find_node_features
        exit 0
        ;;
    status)
        echo "🍪 $TAG"
        echo ""
        echo "📋 Injected panels:"
        ls -la "$BACKUP_DIR"/*.bak 2>/dev/null | wc -l
        echo ""
        echo "📋 Registry:"
        cat "$PROTEC_DIR/registry.txt" 2>/dev/null || echo "  (kosong)"
        exit 0
        ;;
esac

# ═══════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════
echo ""
echo "🍪 $TAG"
echo "🔒 Anti Intip Node v2 - Starting..."
echo ""

generate_node_overlay

echo "🔍 Scanning & injecting..."
COUNT=0
for panel in $(find_node_features); do
    [ -z "$panel" ] && continue
    inject_to_panel "$panel" && COUNT=$((COUNT+1))
done
echo "✅ Injected: $COUNT panels"

echo ""
echo "🚀 Monitoring aktif..."
echo ""

monitor_panels &
wait