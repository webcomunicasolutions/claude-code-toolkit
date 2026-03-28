#!/usr/bin/env python3
"""
Screenshot Compare - Captura screenshots de webs para comparar.
Parte del skill screenshot-compare de Claude Code.

Uso: xvfb-run --auto-servernum python3 capture.py --url URL [opciones]
"""
import argparse
import asyncio
import json
import os
import sys
from datetime import datetime
from urllib.parse import urlparse

try:
    import nodriver as uc
except ImportError:
    print("ERROR: nodriver no instalado. Ejecutar: pip3 install --user nodriver")
    sys.exit(1)


def find_credentials(data, keys_user=('username', 'user', 'email', 'usuario'),
                     keys_pass=('password', 'pass', 'contrasena', 'passwd')):
    """Busca recursivamente username/password en un dict JSON."""
    if not isinstance(data, dict):
        return None, None

    user = None
    passwd = None
    login_url = data.get('login_url', None)

    for k, v in data.items():
        kl = k.lower()
        if kl in keys_user and isinstance(v, str):
            user = v
        elif kl in keys_pass and isinstance(v, str):
            passwd = v

    if user and passwd:
        return {'username': user, 'password': passwd, 'login_url': login_url}, None

    # Search nested dicts
    for k, v in data.items():
        if isinstance(v, dict):
            result, _ = find_credentials(v, keys_user, keys_pass)
            if result:
                if not result.get('login_url') and v.get('login_url'):
                    result['login_url'] = v['login_url']
                return result, None

    return None, "No se encontraron credenciales en el JSON"


async def wait_for_page(tab, timeout=30):
    """Espera a que la página cargue completamente."""
    for _ in range(timeout):
        await asyncio.sleep(1)
        ready = await tab.evaluate("document.readyState")
        state = str(ready.get('value', ready)) if isinstance(ready, dict) else str(ready)
        if state == 'complete':
            return True
    return False


async def do_login(tab, base_url, login_url, username, password):
    """Intenta login genérico: Vue.js primero, luego HTML forms."""
    print(f"  Navegando a login: {login_url}")
    tab = await tab.browser.get(login_url)

    # Wait for Cloudflare / page load
    for _ in range(60):
        await asyncio.sleep(1)
        title = await tab.evaluate("document.title")
        t = str(title.get('value', title)) if isinstance(title, dict) else str(title)
        if 'moment' not in t.lower() and 'just' not in t.lower() and 'checking' not in t.lower():
            break

    await asyncio.sleep(2)

    # Try Vue.js login first
    vue_result = await tab.evaluate(f"""
        (function() {{
            try {{
                var app = document.getElementById('appVue');
                if (app && app.__vue__) {{
                    app.__vue__.$data.usuario = '{username}';
                    app.__vue__.$data.contrasena = '{password}';
                    return 'vue_ok';
                }}
            }} catch(e) {{}}
            return 'no_vue';
        }})()
    """)
    vue_status = str(vue_result.get('value', vue_result)) if isinstance(vue_result, dict) else str(vue_result)
    print(f"  Vue.js: {vue_status}")

    # Fill form fields (works for both Vue and regular HTML)
    await tab.evaluate(f"""
        (function() {{
            var inputs = document.querySelectorAll('input');
            var userField = null, passField = null;
            for (var i = 0; i < inputs.length; i++) {{
                var inp = inputs[i];
                var t = (inp.type || '').toLowerCase();
                var n = (inp.name || inp.id || '').toLowerCase();
                if (t === 'password' || n.includes('pass') || n.includes('contra')) {{
                    passField = inp;
                }} else if (t === 'email' || t === 'text' || n.includes('user') || n.includes('email') || n.includes('login')) {{
                    userField = inp;
                }}
            }}
            if (userField) {{
                userField.value = '{username}';
                userField.dispatchEvent(new Event('input', {{bubbles: true}}));
                userField.dispatchEvent(new Event('change', {{bubbles: true}}));
            }}
            if (passField) {{
                passField.value = '{password}';
                passField.dispatchEvent(new Event('input', {{bubbles: true}}));
                passField.dispatchEvent(new Event('change', {{bubbles: true}}));
            }}
            setTimeout(function() {{
                var btn = document.querySelector('button[type="submit"], input[type="submit"], button.login, .btn-login');
                if (btn) btn.click();
            }}, 500);
        }})()
    """)

    # Wait for login to complete
    initial_title = await tab.evaluate("document.title")
    initial_t = str(initial_title.get('value', initial_title)) if isinstance(initial_title, dict) else str(initial_title)

    for i in range(30):
        await asyncio.sleep(1)
        title = await tab.evaluate("document.title")
        t = str(title.get('value', title)) if isinstance(title, dict) else str(title)
        url = await tab.evaluate("window.location.href")
        u = str(url.get('value', url)) if isinstance(url, dict) else str(url)

        if t != initial_t and 'login' not in t.lower() and 'acceso' not in t.lower():
            print(f"  Login OK: {t}")
            return tab, True
        if base_url in u and 'login' not in u.lower():
            print(f"  Login OK (redirect)")
            return tab, True

    print(f"  Login posiblemente fallido (titulo: {t})")
    return tab, False


async def capture_section(tab, base_url, section, output_dir, index, wait_secs=3, width=1920, height=1080):
    """Captura screenshot de una sección."""
    url = f"{base_url.rstrip('/')}/{section.lstrip('/')}" if section else base_url
    print(f"  [{index:02d}] Capturando: {section or 'home'} -> {url}")

    try:
        await tab.evaluate(f"window.location.href = '{url}'")
        await asyncio.sleep(wait_secs)
        await wait_for_page(tab, timeout=15)
        await asyncio.sleep(1)  # Extra wait for JS rendering

        # Take screenshot
        safe_name = section.replace('/', '_').replace('?', '_').replace('&', '_') or 'home'
        filename = f"{index:02d}_{safe_name}.png"
        filepath = os.path.join(output_dir, filename)

        await tab.save_screenshot(filepath)

        # Get page title
        title = await tab.evaluate("document.title")
        t = str(title.get('value', title)) if isinstance(title, dict) else str(title)

        print(f"       OK: {filepath} ({t})")
        return {"section": section, "file": filename, "url": url, "title": t, "ok": True}
    except Exception as e:
        print(f"       ERROR: {e}")
        return {"section": section, "url": url, "error": str(e), "ok": False}


async def main():
    parser = argparse.ArgumentParser(description='Screenshot Compare - Captura webs para comparar')
    parser.add_argument('--url', required=True, help='URL base de la web')
    parser.add_argument('--login-url', help='URL de login (si requiere auth)')
    parser.add_argument('--credentials', help='Path al JSON con credenciales')
    parser.add_argument('--sections', default='', help='Secciones a capturar (separadas por coma)')
    parser.add_argument('--output', default='./capturas', help='Carpeta de salida')
    parser.add_argument('--wait', type=int, default=3, help='Segundos de espera por página')
    parser.add_argument('--width', type=int, default=1920, help='Ancho viewport')
    parser.add_argument('--height', type=int, default=1080, help='Alto viewport')

    args = parser.parse_args()

    # Parse sections
    sections = [s.strip() for s in args.sections.split(',') if s.strip()] if args.sections else ['']

    # Create output directory
    domain = urlparse(args.url).netloc.replace('.', '_').replace(':', '_')
    timestamp = datetime.now().strftime('%Y-%m-%d_%H%M')
    output_dir = os.path.join(args.output, f"{timestamp}_{domain}")
    os.makedirs(output_dir, exist_ok=True)

    print(f"{'='*60}")
    print(f"SCREENSHOT COMPARE")
    print(f"{'='*60}")
    print(f"  URL: {args.url}")
    print(f"  Secciones: {len(sections)}")
    print(f"  Output: {output_dir}")

    # Load credentials if provided
    creds = None
    if args.credentials and os.path.exists(args.credentials):
        with open(args.credentials) as f:
            raw = json.load(f)
        creds, err = find_credentials(raw)
        if err:
            print(f"  Credenciales: {err}")
        else:
            print(f"  Credenciales: OK ({creds['username']})")
            if not args.login_url and creds.get('login_url'):
                args.login_url = creds['login_url']

    # Start browser
    browser = await uc.start(
        headless=False,
        browser_args=[
            '--no-sandbox', '--disable-dev-shm-usage',
            f'--window-size={args.width},{args.height}'
        ]
    )

    tab = await browser.get(args.url)
    await asyncio.sleep(2)

    # Login if needed
    if args.login_url and creds:
        tab, login_ok = await do_login(
            tab, args.url, args.login_url,
            creds['username'], creds['password']
        )
        if not login_ok:
            print("  WARNING: Login posiblemente fallido, continuando...")
        await asyncio.sleep(2)

    # Capture sections
    print(f"\nCapturando {len(sections)} secciones...")
    results = []
    for idx, section in enumerate(sections, 1):
        result = await capture_section(
            tab, args.url, section, output_dir, idx,
            wait_secs=args.wait, width=args.width, height=args.height
        )
        results.append(result)

    browser.stop()

    # Save metadata
    metadata = {
        "url": args.url,
        "timestamp": datetime.now().isoformat(),
        "sections": results,
        "viewport": {"width": args.width, "height": args.height},
        "total": len(results),
        "ok": sum(1 for r in results if r.get('ok')),
        "errors": sum(1 for r in results if not r.get('ok')),
    }
    meta_path = os.path.join(output_dir, '_metadata.json')
    with open(meta_path, 'w', encoding='utf-8') as f:
        json.dump(metadata, f, indent=2, ensure_ascii=False)

    print(f"\n{'='*60}")
    print(f"COMPLETADO: {metadata['ok']}/{metadata['total']} capturas OK")
    print(f"Output: {output_dir}")
    print(f"{'='*60}")


if __name__ == '__main__':
    asyncio.run(main())
