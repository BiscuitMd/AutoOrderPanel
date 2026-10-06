/* 🍪 Biscuit Gold Theme - Protec By @biscuitMD */
(function() {
    'use strict';

    const THEME = {
        name: 'Biscuit Gold',
        version: '1.0',
        author: 'biscuitMD',
        colors: {
            gold: '#d4af37',
            goldBright: '#ffd700',
            blue: '#1e3a8a',
            blueDark: '#0a1a3a',
            white: '#ffffff'
        }
    };

    // Inject theme meta
    function injectMeta() {
        if (document.querySelector('meta[name="theme"]')) return;
        const meta = document.createElement('meta');
        meta.name = 'theme';
        meta.content = THEME.name;
        document.head.appendChild(meta);
    }

    // Add theme class ke body
    function applyThemeClass() {
        document.body.classList.add('theme-biscuit-gold');
    }

    // Add favicon
    function injectFavicon() {
        const link = document.createElement('link');
        link.rel = 'icon';
        link.href = 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><text y=".9em" font-size="90">🍪</text></svg>';
        document.head.appendChild(link);
    }

    // Loading overlay
    function showLoading() {
        const loader = document.createElement('div');
        loader.id = 'theme-loader';
        loader.innerHTML = `
            <div style="
                position: fixed; inset: 0;
                background: linear-gradient(135deg, #0a1a3a, #1e3a8a);
                display: flex; align-items: center; justify-content: center;
                z-index: 999999;
                transition: opacity 0.5s;
            ">
                <div style="text-align:center;">
                    <div style="font-size: 80px; animation: bounce 1s ease-in-out infinite;">🍪</div>
                    <div style="
                        margin-top: 20px;
                        font-family: 'Fredoka One', cursive;
                        font-size: 24px;
                        background: linear-gradient(90deg, #d4af37, #ffd700, #d4af37);
                        background-size: 200% auto;
                        -webkit-background-clip: text;
                        background-clip: text;
                        color: transparent;
                        letter-spacing: 3px;
                        animation: shine 2s linear infinite;
                    ">Protec By @biscuitMD</div>
                </div>
            </div>
        `;
        document.body.appendChild(loader);

        setTimeout(() => {
            loader.style.opacity = '0';
            setTimeout(() => loader.remove(), 500);
        }, 800);
    }

    // Particle effect
    function createParticles() {
        const container = document.createElement('div');
        container.id = 'theme-particles';
        container.style.cssText = 'position:fixed;inset:0;pointer-events:none;z-index:1;overflow:hidden;';

        for (let i = 0; i < 15; i++) {
            const p = document.createElement('div');
            const size = Math.random() * 6 + 3;
            p.style.cssText = `
                position: absolute;
                width: ${size}px; height: ${size}px;
                background: ${Math.random() > 0.5 ? '#d4af37' : '#3b82f6'};
                border-radius: 50%;
                top: ${Math.random() * 100}%;
                left: ${Math.random() * 100}%;
                opacity: ${Math.random() * 0.5 + 0.2};
                animation: float ${Math.random() * 10 + 8}s ease-in-out infinite;
                box-shadow: 0 0 ${size * 2}px currentColor;
            `;
            container.appendChild(p);
        }
        document.body.appendChild(container);
    }

    // Style tag untuk animasi
    function injectStyles() {
        const style = document.createElement('style');
        style.textContent = `
            @keyframes bounce {
                0%, 100% { transform: translateY(0); }
                50% { transform: translateY(-15px); }
            }
            @keyframes shine {
                to { background-position: 200% center; }
            }
            @keyframes float {
                0%, 100% { transform: translate(0, 0); }
                25% { transform: translate(30px, -30px); }
                50% { transform: translate(-20px, 20px); }
                75% { transform: translate(20px, 30px); }
            }
        `;
        document.head.appendChild(style);
    }

    // Init
    function init() {
        injectStyles();
        injectMeta();
        injectFavicon();
        applyThemeClass();

        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => {
                createParticles();
            });
        } else {
            createParticles();
        }

        console.log('%c🍪 Biscuit Gold Theme loaded | Protec By @biscuitMD', 'color:#d4af37;font-weight:bold;font-size:14px;');
    }

    // Expose API
    window.BiscuitTheme = {
        name: THEME.name,
        version: THEME.version,
        colors: THEME.colors,
        showLoading: showLoading,
        reload: init
    };

    init();
})();