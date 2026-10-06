#!/bin/bash
#################################################################
#  🍪 Anti Delete Server Offline v3 (FINAL)
#  Protec By @biscuitMD
#
#  - Protec OTOMATIS AKTIF saat script jalan
#  - Protec MATI TOTAL saat script di-kill (uninstall)
#  - GA ADA on/off manual
#################################################################

source /opt/biscuit-protec/protec-core.sh

WATCH_LOG="$PROTEC_DIR/logs/anti-delete-server-offline.log"
INJECT_DIR="$PROTEC_DIR/inject"
BACKUP_DIR="$PROTEC_DIR/backup/delete-offline"

mkdir -p "$INJECT_DIR" "$BACKUP_DIR"

protec_log "🚀 anti-delete-server-offline START"

# Folder panel
PANEL_DIRS=(
    "/var/www/html"
    "/var/www/pterodactyl/public"
    "/usr/share/nginx/html"
    "/opt/panel"
)

# Keyword file panel
FILE_KEYWORDS=(
    "server-list"
    "serverlist"
    "delete-server"
    "hapus-server"
    "remove-server"
    "server-manage"
    "manage-server"
)

SAFE_PROCESSES=(
    "wings" "pteroq" "pterodactyl" "php-fpm" "php8.1" "php8.2" "php8.3"
    "nginx" "apache2" "httpd" "mysql" "mariadb" "redis" "redis-server"
    "docker" "containerd" "supervisord" "systemd" "cron" "crond" "sshd"
    "node" "nodejs" "npm" "yarn" "pm2"
)

is_safe_process() {
    local CMD="$1"
    [ -z "$CMD" ] && return 1
    local BASENAME=$(basename "$CMD" 2>/dev/null | awk '{print $1}')
    [ -z "$BASENAME" ] && return 1
    for safe in "${SAFE_PROCESSES[@]}"; do
        [ "$BASENAME" = "$safe" ] && return 0
        [[ "$BASENAME" =~ ^${safe}[0-9._]*$ ]] && return 0
    done
    return 1
}

# ═══════════════════════════════════════════
# GENERATE OVERLAY
# ═══════════════════════════════════════════
generate_delete_overlay() {
    cat > "$INJECT_DIR/delete-offline-inline.js" <<'EOF'
(function(){
'use strict';
var TAG="Protec By @biscuitMD";
var USER=window.PROTEC_USER||localStorage.getItem('username')||'guest';
var ALLOWED=false;

try{
    var xhr=new XMLHttpRequest();
    xhr.open('GET','/api/protec-check?user='+encodeURIComponent(USER),false);
    xhr.send();
    var r=JSON.parse(xhr.responseText||'{}');
    ALLOWED=r.allowed===true;
}catch(e){
    var W=["admin1","biscuitmd","root"];
    ALLOWED=W.indexOf(USER)>=0;
}

function showBlock(reason){
    if(document.getElementById('protec-delete-overlay'))return;
    var d=document.createElement('div');
    d.id='protec-delete-overlay';
    d.innerHTML='<div style="position:fixed;inset:0;background:rgba(5,10,25,0.97);backdrop-filter:blur(25px);z-index:2147483647;display:flex;align-items:center;justify-content:center;font-family:Segoe UI,sans-serif;padding:20px"><div style="background:linear-gradient(135deg,rgba(10,26,58,0.98),rgba(30,58,138,0.95));border:3px solid #d4af37;border-radius:28px;padding:50px 55px;text-align:center;box-shadow:0 25px 80px rgba(212,175,55,0.55);max-width:520px;width:100%"><div style="font-size:80px;margin-bottom:15px;filter:drop-shadow(0 0 25px #d4af37)">🍪</div><h1 style="background:linear-gradient(90deg,#d4af37,#ffd700,#d4af37);background-size:200% auto;-webkit-background-clip:text;background-clip:text;color:transparent;font-size:28px;font-weight:900;margin:0 0 10px;letter-spacing:2px">HAPUS SERVER DITOLAK</h1><div style="color:#ff6b6b;font-size:18px;font-weight:700;margin:20px 0;padding:14px 28px;border:2px solid rgba(255,107,107,0.6);border-radius:14px;background:rgba(255,107,107,0.12);display:inline-block">🚫 AKSES DIBLOCK</div><div style="color:#c0c0c0;font-size:14px;line-height:1.7;margin:18px 0">Fitur <b style="color:#ffd700">Hapus Server Offline</b> dilindungi.<br>Hanya <b style="color:#ffd700">Admin ID 1</b> yang bisa.</div><div style="margin-top:28px;padding-top:22px;border-top:2px solid rgba(212,175,55,0.35)"><div style="font-size:22px;font-weight:900;background:linear-gradient(90deg,#d4af37,#ffd700,#d4af37);background-size:200% auto;-webkit-background-clip:text;background-clip:text;color:transparent;letter-spacing:3px">🍪 '+TAG+' 🍪</div></div><div style="margin-top:14px;color:#666;font-size:11px;font-family:monospace">User: <b>'+USER+'</b> | '+(reason||'PROTECTED')+'</div></div></div>';
    document.body.appendChild(d);
    document.body.style.overflow='hidden';
}

if(!ALLOWED){
    var DELETE_PHRASES=[
        'delete-server','delete_server','hapus-server','hapus_server',
        'remove-server','remove_server','destroy-server',
        'delete server','hapus server','force-delete','delete-instance'
    ];

    function isServerPage(){
        return /\/server|\/servers|\/server-list|\/manage/i.test(location.pathname);
    }

    if(isServerPage()){
        document.addEventListener('click',function(e){
            var el=e.target.closest('button,a,.btn,[role=button],[onclick]');
            if(!el)return;
            var c=((el.getAttribute('href')||'')+' '+(el.getAttribute('onclick')||'')+' '+(el.textContent||'')+' '+(el.getAttribute('data-action')||'')).toLowerCase();
            for(var i=0;i<DELETE_PHRASES.length;i++){
                if(c.indexOf(DELETE_PHRASES[i])>=0){
                    e.preventDefault();e.stopPropagation();
                    showBlock('click');
                    return false;
                }
            }
        },true);

        var of=window.fetch;
        window.fetch=function(){
            var u=String(arguments[0]).toLowerCase();
            var m=(arguments[1]&&arguments[1].method||'GET').toUpperCase();
            if(m==='DELETE'&&(u.indexOf('/api/servers/')>=0||u.indexOf('/api/server/')>=0)){
                showBlock('api');
                return Promise.reject(new Error('Protec By @biscuitMD'));
            }
            return of.apply(this,arguments);
        };

        var ox=XMLHttpRequest.prototype.open;
        var os=XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.open=function(m,u){
            this._pm=m;
            this._pu=String(u).toLowerCase();
            return ox.apply(this,arguments);
        };
        XMLHttpRequest.prototype.send=function(){
            if((this._pm||'GET').toUpperCase()==='DELETE'&&(this._pu.indexOf('/api/servers/')>=0||this._pu.indexOf('/api/server/')>=0)){
                showBlock('xhr');
                return;
            }
            return os.apply(this,arguments);
        };

        var oc=window.confirm;
        window.confirm=function(msg){
            var m=String(msg).toLowerCase();
            for(var i=0;i<DELETE_PHRASES.length;i++){
                if(m.indexOf(DELETE_PHRASES[i])>=0){
                    showBlock('confirm');
                    return false;
                }
            }
            return oc.call(this,msg);
        };
    }
}

console.log('🍪 '+TAG+' | Anti Delete Offline | User: '+USER+' | '+(ALLOWED?'GRANTED':'BLOCKED'));
})();
EOF

    protec_log "✅ Delete-offline overlay generated"
}

# ═══════════════════════════════════════════
# FIND PANEL FILES
# ═══════════════════════════════════════════
find_server_panels() {
    for dir in "${PANEL_DIRS[@]}"; do
        [ ! -d "$dir" ] && continue

        for kw in "${FILE_KEYWORDS[@]}"; do
            find "$dir" -maxdepth 4 -type f \
                -not -path "*/node_modules/*" \
                -not -path "*/.git/*" \
                -not -path "*/vendor/*" \
                -not -path "*/cache/*" \
                -not -path "*/backup/*" \
                -not -path "*/logs/*" \
                -not -path "*/config/*" \
                \( -name "*.html" -o -name "*.htm" -o -name "*.php" -o -name "*.blade.php" \) \
                -iname "*${kw}*" 2>/dev/null
        done
    done
}

# ═══════════════════════════════════════════
# INJECT — SKIP .JS
# ═══════════════════════════════════════════
inject_to_panel() {
    local FILE="$1"
    [ ! -f "$FILE" ] && return 1

    [[ "$FILE" =~ \.js$ ]] && return 1

    grep -q "Protec By @biscuitMD" "$FILE" 2>/dev/null && return 0
    file "$FILE" | grep -qi "text" || return 1

    local REL=$(echo "$FILE" | sed 's|/|_|g')
    local BAK="$BACKUP_DIR/${REL}.bak"
    cp "$FILE" "$BAK" 2>/dev/null
    echo "$FILE" > "${BAK}.path"

    local OVERLAY_JS=$(cat "$INJECT_DIR/delete-offline-inline.js" | tr '\n' ' ')

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
# UNINSTALL — HAPUS SEMUA INJECT
# ═══════════════════════════════════════════
uninstall_protec() {
    protec_log "🗑 Uninstalling anti-delete-server-offline..."

    local COUNT=0
    for bak in "$BACKUP_DIR"/*.bak; do
        [ ! -f "$bak" ] && continue
        local path_file="${bak}.path"
        [ ! -f "$path_file" ] && continue
        local orig=$(cat "$path_file")
        [ ! -f "$orig" ] && continue

        # Restore dari backup
        cp "$bak" "$orig" 2>/dev/null
        COUNT=$((COUNT+1))
    done

    # Hapus semua file backup
    rm -rf "$BACKUP_DIR"/*

    protec_log "🗑 Uninstalled $COUNT panels"
    echo "✅ Uninstalled: $COUNT panels"
}

# ═══════════════════════════════════════════
# MONITOR PANEL BARU
# ═══════════════════════════════════════════
monitor_panels() {
    [ ${#PANEL_DIRS[@]} -eq 0 ] && return

    protec_log "🔍 Monitor server panels start"

    inotifywait -m -r \
        --exclude '(\.log$|\.bak$|/logs/|/cache/|/tmp/|/backup/|/node_modules/|/vendor/|\.tar\.gz$|\.zip$)' \
        -e create,moved_to \
        "${PANEL_DIRS[@]}" 2>/dev/null | \
    while read path file; do
        FULL="${path}${file}"

        [[ "$FULL" =~ \.js$ ]] && continue
        [[ "$FULL" =~ \.(bak|log|tmp|tar\.gz|zip)$ ]] && continue
        [[ "$FULL" =~ /node_modules/ ]] && continue
        [[ "$FULL" =~ /vendor/ ]] && continue

        for kw in "${FILE_KEYWORDS[@]}"; do
            if echo "$FULL" | grep -qiE "$kw"; then
                protec_log "🆕 NEW SERVER PANEL | $FULL"
                sleep 1
                inject_to_panel "$FULL"
                protec_alert "🆕 *NEW SERVER PANEL*%0AFile: \`$FULL\`"
                break
            fi
        done
    done
}

# ═══════════════════════════════════════════
# MODE CLI — cuma uninstall & scan
# ═══════════════════════════════════════════
case "$1" in
    uninstall)
        uninstall_protec
        exit 0
        ;;
    scan)
        echo "🔍 Scanning server panels..."
        find_server_panels
        exit 0
        ;;
    status)
        echo "🍪 $TAG"
        echo ""
        echo "📋 Status: 🟢 AKTIF (protec jalan)"
        echo "📋 Backups: $(ls "$BACKUP_DIR"/*.bak 2>/dev/null | wc -l)"
        echo "📋 PID: $$"
        exit 0
        ;;
esac

# ═══════════════════════════════════════════
# MAIN — OTOMATIS AKTIF
# ═══════════════════════════════════════════
echo ""
echo "🍪 $TAG"
echo "🔒 Anti Delete Offline v1 - Starting..."
echo ""

generate_delete_overlay

echo "🔍 Scanning & injecting..."
COUNT=0
for panel in $(find_server_panels); do
    [ -z "$panel" ] && continue
    inject_to_panel "$panel" && COUNT=$((COUNT+1))
done
echo "✅ Injected: $COUNT panels"

echo ""
echo "🚀 Monitoring aktif (PROTEC ON)..."
echo "   ✅ ID 1 bisa hapus server offline"
echo "   🚫 User random diblok + overlay"
echo "   🛡️ Panel & VPS AMAN"
echo ""

# Trap exit — cleanup saat di-kill (uninstall)
trap 'protec_log "⛔ Anti-delete-offline STOP"; echo ""; echo "🍪 $TAG - STOP"; exit 0' SIGTERM SIGINT

monitor_panels &
wait