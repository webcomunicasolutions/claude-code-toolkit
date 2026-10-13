#!/usr/bin/env python3
"""Capturas de una web en tamaño móvil, entrando con el usuario del rol del manual.

Uso:  python3 capturar.py config.json [salida/]

SOLO MIRA: navega y hace capturas. No pulsa nada que guarde (en producción de cliente
un fichaje o un parte no se pueden borrar). Vuelca también el texto de cada pantalla,
de donde salen los nombres exactos de los botones para el manual.
"""
import json, os, re, sys
from playwright.sync_api import sync_playwright

UA_ANDROID = ("Mozilla/5.0 (Linux; Android 14; Pixel 9) AppleWebKit/537.36 "
              "(KHTML, like Gecko) Chrome/128 Mobile Safari/537.36")
UA_IPHONE = ("Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 "
             "(KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1")


def credencial(cfg, usuario):
    """Lee la contraseña del vault: nunca se escribe en el config ni en el repo."""
    vault = json.load(open(os.path.expanduser(cfg["vault"]["fichero"])))
    nodo = vault
    for parte in cfg["vault"]["ruta_usuarios"].split("."):
        nodo = nodo[parte]
    return nodo[usuario][cfg["vault"].get("campo_password", "password")]


def entrar(ctx, cfg, usuario, password):
    pg = ctx.new_page()
    pg.goto(cfg["url"], wait_until="networkidle")
    f = cfg.get("login", {})
    pg.fill(f.get("campo_usuario", "input[name=usuario]"), usuario)
    pg.fill(f.get("campo_password", "input[name=contrasena]"), password)
    with pg.expect_navigation(timeout=15000):
        pg.click(f.get("boton", "button[type=submit]"))
    pg.wait_for_timeout(1500)
    if pg.url.rstrip("/") == cfg["url"].rstrip("/"):
        raise SystemExit(f"ERROR: no se pudo entrar con {usuario} (¿contraseña o bloqueo por intentos?)")
    return pg


def main():
    cfg = json.load(open(sys.argv[1]))
    salida = sys.argv[2] if len(sys.argv) > 2 else "capturas"
    os.makedirs(salida, exist_ok=True)
    usuario = cfg["usuario_para_capturas"]
    pw = credencial(cfg, usuario)
    ua = UA_IPHONE if cfg.get("simular") == "iphone" else UA_ANDROID
    with sync_playwright() as p:
        b = p.chromium.launch()
        ctx = b.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=3,
                            is_mobile=True, has_touch=True, locale="es-ES", user_agent=ua)
        pg = entrar(ctx, cfg, usuario, pw)
        for c in cfg["capturas"]:
            pg.goto(cfg["url"].rstrip("/") + c["ruta"], wait_until="networkidle")
            pg.wait_for_timeout(c.get("espera_ms", 1500))
            for clic in c.get("clics_seguros", []):     # solo abrir menús/modales, nunca guardar
                try:
                    pg.click(clic); pg.wait_for_timeout(800)
                except Exception as e:
                    print(f"  aviso: no se pudo pulsar {clic}: {e}")
            pg.screenshot(path=os.path.join(salida, c["nombre"] + ".png"),
                          full_page=c.get("pagina_completa", False))
            texto = pg.inner_text("main") if pg.query_selector("main") else pg.inner_text("body")
            open(os.path.join(salida, c["nombre"] + ".txt"), "w", encoding="utf-8").write(
                re.sub(r"\n\s*\n+", "\n", texto))
            print("capturada:", c["nombre"], "->", pg.url)
        pg.goto(cfg["url"].rstrip("/") + cfg.get("logout", "/logout.php"))
        b.close()
    print(f"\n{len(cfg['capturas'])} capturas en {salida}/ (imagen + texto de cada pantalla)")


if __name__ == "__main__":
    main()
