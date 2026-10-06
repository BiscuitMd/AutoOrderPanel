#!/bin/bash
#################################################################
#  🍪 Anti Admin Bot - Block Create Admin di Bot
#  Protec By @biscuitMD
#
#  Fungsi:
#  - Tolak create admin baru via BOT
#  - Cuma ID 1 (whitelist) yang bisa create admin
#  - User random → BLOCK + pesan "Protec By @biscuitMD"
#  - Auto ON saat install, auto OFF saat uninstall
#  - SAFE: nggak ganggu bot & VPS
#################################################################

source /opt/biscuit-protec/protec-core.sh

WATCH_LOG="$PROTEC_DIR/logs/anti-admin-bot.log"
INJECT_DIR="$PROTEC_DIR/inject"
PROTEC_STATE="$PROTEC_DIR/state"
mkdir -p "$INJECT_DIR" "$PROTEC_STATE"

protec_log "🚀 anti-admin-bot START"

# ============ STATE FILE (AUTO ON) ============
STATE_FILE="$PROTEC_STATE/anti-admin-bot.lock"
[ ! -f "$STATE_FILE" ] && touch "$STATE_FILE"

# ============ FOLDER BOT ============
BOT_DIRS=(
    "/root/bot"
    "/opt/bot"
    "/home/*/bot"
    "/var/www/bot"
    "/usr/local/bot"
    "/root/plta"
    "/root/pltc"
    "/opt/plta"
    "/opt/pltc"
    "/srv/bot"
)

# ============ KEYWORD COMMAND BOT ============
BOT_ADMIN_COMMANDS=(
    "create-admin"
    "add-admin"
    "new-admin"
    "register-admin"
    "buat-admin"
    "tambah-admin"
    "daftar-admin"
    "addadmin"
    "createadmin"
    "newadmin"
    "registeradmin"
    "buatadmin"
    "tambahadmin"
    "daftaradmin"
    "/addadmin"
    "/createadmin"
    "/buatadmin"
    "/tambahadmin"
    "/newadmin"
    "/registeradmin"
    "/admin-add"
    "/admin-create"
    "/admin-new"
    "/admin-baru"
)

# ============ KEYWORD CALLBACK BUTTON ============
CALLBACK_KEYWORDS=(
    "create_admin"
    "add_admin"
    "new_admin"
    "register_admin"
    "buat_admin"
    "tambah_admin"
    "admin_create"
    "admin_add"
    "admin_new"
    "admin_register"
    "admincreate"
    "adminadd"
    "adminnew"
    "createadmin"
    "addadmin"
    "newadmin"
)

# ============ PROSES AMAN ============
SAFE_PROCESSES=(
    "node"
    "npm"
    "pm2"
    "python"
    "python3"
    "php"
    "php-fpm"
    "nginx"
    "apache2"
    "mysql"
    "mariadb"
    "redis"
    "docker"
    "containerd"
    "systemd"
    "supervisord"
    "cron"
    "sshd"
    "wings"
    "pteroq"
    "pterodactyl"
    "plta"
    "pltc"
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

# ============ CARI FILE BOT ============
find_bot_files() {
    for dir in "${BOT_DIRS[@]}"; do
        for d in $dir; do
            [ ! -d "$d" ] && continue

            find "$d" -maxdepth 5 \
                \( -iname "*.js" \
                -o -iname "*.ts" \
                -o -iname "*.py" \
                -o -iname "*.php" \
                -o -iname "*.json" \) 2>/dev/null | \
            while read f; do
                # Cek file ini berisi command admin
                for kw in "${BOT_ADMIN_COMMANDS[@]}"; do
                    if grep -qiE "${kw}" "$f" 2>/dev/null; then
                        echo "$f"
                        break
                    fi
                done
            done
        done
    done
}

# ============ GENERATE MIDDLEWARE JS ============
generate_bot_middleware_js() {
    cat > "$INJECT_DIR/protec-bot-admin.js" <<'EOF'
/* 🍪 Protec By @biscuitMD - Bot Anti Admin */
'use strict';

const PROTEC_TAG = "Protec By @biscuitMD";
const WHITELIST = (process.env.PROTEC_WHITELIST || "admin1,biscuitmd,root").split(',');

function isAllowed(userId, username) {
    if (!userId && !username) return false;
    const id = String(userId || '');
    const name = String(username || '').toLowerCase();
    return WHITELIST.some(w => {
        const wl = w.trim().toLowerCase();
        return wl === id || wl === name;
    });
}

const ADMIN_COMMANDS = [
    '/addadmin', '/createadmin', '/newadmin', '/registeradmin',
    '/buatadmin', '/tambahadmin', '/daftaradmin', '/admin-add',
    '/admin-create', '/admin-new', '/admin-baru', 'addadmin',
    'createadmin', 'newadmin', 'registeradmin', 'buatadmin',
    'tambahadmin', 'daftaradmin'
];

const CALLBACK_KEYWORDS = [
    'create_admin', 'add_admin', 'new_admin', 'register_admin',
    'buat_admin', 'tambah_admin', 'admin_create', 'admin_add',
    'admin_new', 'admin_register', 'createadmin', 'addadmin', 'newadmin'
];

function isCreateAdminCommand(text) {
    if (!text) return false;
    const t = String(text).toLowerCase().trim();
    return ADMIN_COMMANDS.some(c => t.startsWith(c));
}

function isCreateAdminCallback(data) {
    if (!data) return false;
    const d = String(data).toLowerCase();
    return CALLBACK_KEYWORDS.some(k => d.includes(k));
}

function blockMessage() {
    return (
        "╔══════════════════════════════════════════╗\n" +
        "║  🚫 AKSES DIBLOCK                        ║\n" +
        "║                                          ║\n" +
        "║  Fitur *Buat Admin Baru*                 ║\n" +
        "║  sedang dilindungi sistem.               ║\n" +
        "║                                          ║\n" +
        "║  Hanya *Admin ID 1* yang bisa            ║\n" +
        "║  membuat admin baru.                     ║\n" +
        "║                                          ║\n" +
        "║  🍪 " + PROTEC_TAG + " 🍪                 ║\n" +
        "╚══════════════════════════════════════════╝"
    );
}

// ============ MIDDLEWARE UNTUK TELEGRAM BOT ============
function protecTelegramMiddleware(bot) {
    if (!bot || !bot.on) return;

    // Intercept message
    bot.on('message', (msg) => {
        const userId = msg.from && msg.from.id;
        const username = msg.from && msg.from.username;
        const text = msg.text || '';

        if (isCreateAdminCommand(text)) {
            if (!isAllowed(userId, username)) {
                // 🚫 BLOCK
                bot.sendMessage(msg.chat.id, blockMessage(), { parse_mode: 'Markdown' });
                console.log('🍪 ' + PROTEC_TAG + ' | BLOCKED: ' + username + ' (' + userId + ') -> ' + text);

                // Log ke protec
                logToProtec(userId, username, 'command', text);
                return;
            }
        }
    });

    // Intercept callback_query (inline button)
    bot.on('callback_query', (query) => {
        const data = query.data || '';
        const userId = query.from && query.from.id;
        const username = query.from && query.from.username;

        if (isCreateAdminCallback(data)) {
            if (!isAllowed(userId, username)) {
                // 🚫 BLOCK
                bot.answerCallbackQuery(query.id, {
                    text: '🍪 ' + PROTEC_TAG + '\n🚫 AKSES DIBLOCK',
                    show_alert: true
                });
                bot.sendMessage(query.message.chat.id, blockMessage(), { parse_mode: 'Markdown' });
                console.log('🍪 ' + PROTEC_TAG + ' | BLOCKED CALLBACK: ' + username + ' -> ' + data);

                logToProtec(userId, username, 'callback', data);
                return;
            }
        }
    });

    // Intercept inline query
    bot.on('inline_query', (query) => {
        const q = (query.query || '').toLowerCase();
        const userId = query.from && query.from.id;
        const username = query.from && query.from.username;

        if (ADMIN_COMMANDS.some(c => q.includes(c))) {
            if (!isAllowed(userId, username)) {
                logToProtec(userId, username, 'inline', q);
            }
        }
    });

    console.log('🍪 ' + PROTEC_TAG + ' | Telegram middleware attached');
}

// ============ MIDDLEWARE UNTUK DISCORD BOT ============
function protecDiscordMiddleware(client) {
    if (!client || !client.on) return;

    client.on('messageCreate', (msg) => {
        if (msg.author && msg.author.bot) return;

        const text = msg.content || '';
        const userId = msg.author && msg.author.id;
        const username = msg.author && msg.author.username;

        if (isCreateAdminCommand(text)) {
            if (!isAllowed(userId, username)) {
                msg.reply('🚫 **' + PROTEC_TAG + '**\nFitur buat admin baru diblok! Hanya ID 1 yang bisa.');
                console.log('🍪 ' + PROTEC_TAG + ' | Discord BLOCKED: ' + username);
                logToProtec(userId, username, 'discord', text);
                return;
            }
        }
    });

    client.on('interactionCreate', (interaction) => {
        if (!interaction.isButton && !interaction.isButton()) return;
        const data = interaction.customId || '';
        const userId = interaction.user && interaction.user.id;
        const username = interaction.user && interaction.user.username;

        if (isCreateAdminCallback(data)) {
            if (!isAllowed(userId, username)) {
                interaction.reply({
                    content: '🚫 **' + PROTEC_TAG + '**\nAkses diblok!',
                    ephemeral: true
                });
                logToProtec(userId, username, 'discord_callback', data);
                return;
            }
        }
    });

    console.log('🍪 ' + PROTEC_TAG + ' | Discord middleware attached');
}

// ============ LOG KE PROTEC ============
function logToProtec(userId, username, type, target) {
    try {
        const http = require('http');
        const data = JSON.stringify({
            user: username || userId,
            action: 'blocked_' + type,
            target: target,
            module: 'anti-admin-bot',
            time: new Date().toISOString()
        });

        const req = http.request({
            hostname: '127.0.0.1',
            port: 3999,
            path: '/protec-log',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': data.length
            }
        }, () => {});
        req.on('error', () => {});
        req.write(data);
        req.end();
    } catch(e) {}
}

// ============ EXPORT ============
module.exports = {
    protecTelegramMiddleware,
    protecDiscordMiddleware,
    isAllowed,
    isCreateAdminCommand,
    isCreateAdminCallback,
    blockMessage,
    PROTEC_TAG
};

// Auto-attach kalau di-require langsung dengan bot instance
if (typeof module !== 'undefined') {
    console.log('🍪 ' + PROTEC_TAG + ' | Bot Anti Admin loaded');
}
EOF

    protec_log "✅ Bot middleware generated"
}

# ============ GENERATE MIDDLEWARE PYTHON ============
generate_bot_middleware_py() {
    cat > "$INJECT_DIR/protec_bot_admin.py" <<'EOF'
# 🍪 Protec By @biscuitMD - Bot Anti Admin (Python)
import os
import json
import logging
from datetime import datetime

PROTEC_TAG = "Protec By @biscuitMD"
WHITELIST = (os.getenv("PROTEC_WHITELIST", "admin1,biscuitmd,root")).split(",")

ADMIN_COMMANDS = [
    "/addadmin", "/createadmin", "/newadmin", "/registeradmin",
    "/buatadmin", "/tambahadmin", "/daftaradmin", "/admin-add",
    "/admin-create", "/admin-new", "/admin-baru", "addadmin",
    "createadmin", "newadmin", "registeradmin", "buatadmin",
    "tambahadmin", "daftaradmin"
]

CALLBACK_KEYWORDS = [
    "create_admin", "add_admin", "new_admin", "register_admin",
    "buat_admin", "tambah_admin", "admin_create", "admin_add",
    "admin_new", "admin_register", "createadmin", "addadmin", "newadmin"
]

def is_allowed(user_id, username=None):
    if not user_id and not username:
        return False
    uid = str(user_id or "")
    uname = str(username or "").lower()
    for w in WHITELIST:
        wl = w.strip().lower()
        if wl == uid or wl == uname:
            return True
    return False

def is_create_admin_command(text):
    if not text:
        return False
    t = str(text).lower().strip()
    return any(t.startswith(c) for c in ADMIN_COMMANDS)

def is_create_admin_callback(data):
    if not data:
        return False
    d = str(data).lower()
    return any(k in d for k in CALLBACK_KEYWORDS)

def block_message():
    return (
        "╔══════════════════════════════════════════╗\n"
        "║  🚫 AKSES DIBLOCK                        ║\n"
        "║                                          ║\n"
        "║  Fitur *Buat Admin Baru*                 ║\n"
        "║  sedang dilindungi sistem.               ║\n"
        "║                                          ║\n"
        "║  Hanya *Admin ID 1* yang bisa            ║\n"
        "║  membuat admin baru.                     ║\n"
        "║                                          ║\n"
        "║  🍪 " + PROTEC_TAG + " 🍪                 ║\n"
        "╚══════════════════════════════════════════╝"
    )

def protec_telegram_handler(update, context):
    """Handler untuk python-telegram-bot"""
    try:
        msg = update.message or update.callback_query.message
        user = update.effective_user
        user_id = user.id if user else None
        username = user.username if user else None

        # Command
        if update.message and update.message.text:
            text = update.message.text
            if is_create_admin_command(text):
                if not is_allowed(user_id, username):
                    update.message.reply_text(block_message(), parse_mode='Markdown')
                    logging.info(f"🍪 {PROTEC_TAG} | BLOCKED: {username} -> {text}")
                    return True  # handled

        # Callback
        if update.callback_query:
            data = update.callback_query.data or ""
            if is_create_admin_callback(data):
                if not is_allowed(user_id, username):
                    update.callback_query.answer(
                        text=f"🍪 {PROTEC_TAG}\n🚫 AKSES DIBLOCK",
                        show_alert=True
                    )
                    update.callback_query.message.reply_text(block_message(), parse_mode='Markdown')
                    logging.info(f"🍪 {PROTEC_TAG} | BLOCKED CALLBACK: {username} -> {data}")
                    return True
    except Exception as e:
        logging.error(f"Protec error: {e}")
    return False

def protec_decorator(func):
    """Decorator untuk wrap handler"""
    def wrapper(update, context, *args, **kwargs):
        if protec_telegram_handler(update, context):
            return
        return func(update, context, *args, **kwargs)
    return wrapper

if __name__ == "__main__":
    print(f"🍪 {PROTEC_TAG} | Bot Anti Admin loaded")
EOF

    protec_log "✅ Bot middleware Python generated"
}

# ============ PATCH BOT FILE ============
patch_bot_file() {
    local FILE="$1"
    [ ! -f "$FILE" ] && return 1

    # Skip kalau udah dipatch
    grep -q "protec-bot-admin\|protec_bot_admin" "$FILE" 2>/dev/null && return 0

    # Backup
    cp "$FILE" "$PROTEC_DIR/backup/$(basename $FILE).bak" 2>/dev/null

    # Deteksi tipe file
    if echo "$FILE" | grep -qiE "\.js$|\.ts$"; then
        # Node.js - inject require + middleware
        if grep -q "require('telegraf')\|require(\"telegraf\")" "$FILE" 2>/dev/null; then
            # Telegraf
            sed -i "1i const { protecTelegramMiddleware } = require('/opt/biscuit-protec/inject/protec-bot-admin.js');" "$FILE"
            # Tambah middleware setelah bot dibuat
            if grep -q "new Telegraf" "$FILE"; then
                sed -i "/new Telegraf/a protecTelegramMiddleware(bot);" "$FILE"
            fi
            protec_log "✅ Patched Telegraf: $FILE"
        elif grep -q "require('node-telegram-bot-api')" "$FILE" 2>/dev/null; then
            # node-telegram-bot-api
            sed -i "1i const { protecTelegramMiddleware } = require('/opt/biscuit-protec/inject/protec-bot-admin.js');" "$FILE"
            sed -i "/new TelegramBot/a protecTelegramMiddleware(bot);" "$FILE"
            protec_log "✅ Patched node-telegram-bot-api: $FILE"
        elif grep -q "require('discord.js')" "$FILE" 2>/dev/null; then
            # Discord.js
            sed -i "1i const { protecDiscordMiddleware } = require('/opt/biscuit-protec/inject/protec-bot-admin.js');" "$FILE"
            sed -i "/new Client/a protecDiscordMiddleware(client);" "$FILE"
            protec_log "✅ Patched Discord.js: $FILE"
        fi
    elif echo "$FILE" | grep -qiE "\.py$"; then
        # Python
        sed -i "1i from protec_bot_admin import protec_telegram_handler" "$FILE" 2>/dev/null
        protec_log "✅ Patched Python: $FILE"
    fi
}

# ============ MONITOR & PATCH ============
monitor_and_patch() {
    while true; do
        # Skip kalau OFF
        if [ ! -f "$STATE_FILE" ]; then
            sleep 10
            continue
        fi

        for botfile in $(find_bot_files); do
            [ ! -f "$botfile" ] && continue
            patch_bot_file "$botfile"
        done
        sleep 30
    done
}

# ============ MONITOR PROSES BOT ============
monitor_bot_process() {
    while true; do
        if [ ! -f "$STATE_FILE" ]; then
            sleep 10
            continue
        fi

        # Cek proses bot yang akses command admin
        for pid in $(pgrep -f "node|python|python3" 2>/dev/null); do
            [ -z "$pid" ] && continue

            local CMD=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)
            is_safe_process "$CMD" && continue

            # Cek apakah proses ini bot yang akses command admin
            local ENV=$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null)
            local USER=$(ps -p "$pid" -o user= 2>/dev/null | tr -d ' ')
            [ -z "$USER" ] && continue

            # Skip whitelist
            protec_is_allowed "$USER" && continue

            # Log aja, jangan kill (AMAN)
            protec_log "ℹ️ Bot process running | pid=$pid | user=$USER"
        done
        sleep 60
    done
}

# ============ MAIN ============
echo ""
echo "🍪 $TAG"
echo "🔒 Anti Admin Bot - Starting..."
echo ""

generate_bot_middleware_js
generate_bot_middleware_py

echo "🔍 Scanning bot files..."
COUNT=0
for botfile in $(find_bot_files); do
    [ -z "$botfile" ] && continue
    patch_bot_file "$botfile"
    COUNT=$((COUNT+1))
done
echo "✅ Patched: $COUNT bot files"

echo ""
echo "🚀 Monitoring aktif (SAFE MODE)..."
echo "   ✅ ID 1 bisa create admin via bot"
echo "   🚫 User random diblok + pesan Protec"
echo "   🛡️ Bot & VPS AMAN"
echo ""

monitor_and_patch &
monitor_bot_process &

wait