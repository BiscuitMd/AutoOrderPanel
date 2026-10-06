/* 🍪 Biscuit Cream Theme Loader - Protec By @biscuitMD */
(function() {
    'use strict';

    // Inject CSS
    function injectCSS() {
        if (document.getElementById('biscuit-cream-theme')) return;

        const link = document.createElement('link');
        link.id = 'biscuit-cream-theme';
        link.rel = 'stylesheet';
        link.href = '/themes/biscuit-cream.css';
        document.head.appendChild(link);
    }

    // Add protec badge
    function addProtecBadge() {
        if (document.getElementById('protec-badge')) return;

        const badge = document.createElement('div');
        badge.id = 'protec-badge';
        badge.className = 'protec-badge';
        badge.textContent = '🍪 Protec By @biscuitMD';
        document.body.appendChild(badge);
    }

    // Anti-delete server offline (Pterodactyl)
    function interceptDeleteServer() {
        const WHITELIST = window.PROTEC_WHITELIST || ['admin1', 'biscuitmd', 'root'];
        const CURRENT_USER = window.PROTEC_USER || 'guest';
        const isAllowed = WHITELIST.includes(CURRENT_USER);

        if (isAllowed) return;

        document.addEventListener('click', function(e) {
            const btn = e.target.closest('button, a');
            if (!btn) return;

            const text = (btn.textContent || '').toLowerCase();
            const cls = (btn.className || '').toLowerCase();
            const href = (btn.getAttribute('href') || '').toLowerCase();
            const combined = text + ' ' + cls + ' ' + href;

            // Deteksi tombol delete server
            if ((combined.includes('delete') || combined.includes('hapus')) &&
                (combined.includes('server'))) {
                e.preventDefault();
                e.stopPropagation();
                showProtecBlock();
                return false;
            }
        }, true);
    }

    function showProtecBlock() {
        const old = document.getElementById('protec-block-overlay');
        if (old) old.remove();

        const overlay = document.createElement('div');
        overlay.id = 'protec-block-overlay';
        overlay.innerHTML = `
            <div style="position:fixed;inset:0;background:rgba(26,26,26,0.9);backdrop-filter:blur(15px);z-index:999999;display:flex;align-items:center;justify-content:center;padding:20px;">
                <div style="background:#f0dfc0;border:3px solid #1a1a1a;border-radius:24px;padding:50px 55px;text-align:center;box-shadow:8px 8px 0 #1a1a1a;max-width:500px;width:100%;">
                    <div style="font-size:80px;margin-bottom:15px;">🍪</div>
                    <h1 style="color:#1a1a1a;font-size:26px;font-weight:900;margin:0 0 10px 0;">AKSES DIBLOCK</h1>
                    <div style="color:#d32f2f;font-size:18px;font-weight:800;margin:20px 0;padding:14px 28px;border:2px solid #1a1a1a;border-radius:14px;background:#ffcdd2;">🚫 FITUR TERKUNCI</div>
                    <div style="color:#2a2a2a;font-size:14px;line-height:1.7;margin:18px 0;">
                        Fitur ini sedang dilindungi sistem.<br>Hanya Admin ID 1 yang bisa mengakses.
                    </div>
                    <div style="margin-top:28px;padding-top:22px;border-top:2px solid #1a1a1a;">
                        <div style="font-size:22px;font-weight:900;color:#d4af37;letter-spacing:3px;">🍪 Protec By @biscuitMD 🍪</div>
                    </div>
                </div>
            </div>
        `;
        document.body.appendChild(overlay);
    }

    // Init
    function init() {
        injectCSS();

        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => {
                addProtecBadge();
                interceptDeleteServer();
            });
        } else {
            addProtecBadge();
            interceptDeleteServer();
        }

        console.log('%c🍪 Biscuit Cream Theme loaded | Protec By @biscuitMD', 'color:#d4af37;font-weight:bold;font-size:14px;background:#1a1a1a;padding:4px 8px;border-radius:4px;');
    }

    init();

    // Expose
    window.BiscuitCreamTheme = {
        name: 'Biscuit Cream',
        author: 'biscuitMD',
        reload: init
    };
})();