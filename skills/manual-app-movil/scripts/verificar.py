#!/usr/bin/env python3
"""Verificación del manual y las fichas. Sin esto, el trabajo NO está hecho.

Uso: python3 verificar.py config.json manual.pdf fichas/ [marca_vieja]
Comprueba: login de cada usuario (N de N), contraseña impresa == vault, QR legible
y correcto, y que no quedan restos de la marca anterior.
"""
import json, os, subprocess, sys
import os, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from capturar import credencial, entrar
from playwright.sync_api import sync_playwright

cfg = json.load(open(sys.argv[1])); manual, fichas = sys.argv[2], sys.argv[3]
marca_vieja = sys.argv[4] if len(sys.argv) > 4 else None
fallos = 0

print("== 1. Entrar con cada usuario ==")
with sync_playwright() as p:
    b = p.chromium.launch()
    for u in cfg["trabajadores"]:
        ctx = b.new_context()
        try:
            pg = entrar(ctx, cfg, u, credencial(cfg, u)); pg.goto(cfg["url"] + cfg.get("logout", "/logout.php"))
            print(f"  {u:14} OK")
        except SystemExit as e:
            print(f"  {u:14} FALLA · {e}"); fallos += 1
        ctx.close()
    b.close()
print(f"  {len(cfg['trabajadores']) - fallos} de {len(cfg['trabajadores'])} entran")

print("== 2. Contraseña impresa == vault ==")
for u in cfg["trabajadores"]:
    t = subprocess.run(["pdftotext", f"{fichas}/Ficha-acceso-{u}.pdf", "-"], capture_output=True, text=True).stdout
    w = t.split(); i = next((k for k, x in enumerate(w) if x.upper().startswith("CONTRASE")), -1)
    ok = i >= 0 and w[i + 1] == credencial(cfg, u) and u in w
    print(f"  {u:14} {'OK' if ok else 'NO COINCIDE'}"); fallos += 0 if ok else 1

print("== 3. QR ==")
try:
    import cv2
    png = os.path.join(tempfile.mkdtemp(), "qr_check")
    subprocess.run(["pdftoppm", "-png", "-r", "200", "-singlefile",
                    f"{fichas}/Ficha-acceso-{cfg['trabajadores'][0]}.pdf", png], check=True)
    v, _, _ = cv2.QRCodeDetector().detectAndDecode(cv2.imread(png + ".png"))
    ok = v.rstrip("/") == cfg["url"].rstrip("/")
    print(f"  {v!r} {'OK' if ok else 'NO ES LA URL DEL CONFIG'}"); fallos += 0 if ok else 1
except ImportError:
    print("  sin opencv: pip3 install --user --break-system-packages opencv-python-headless")

if marca_vieja:
    print("== 4. Restos de la marca anterior ==")
    for pdf in [manual] + [f"{fichas}/Ficha-acceso-{u}.pdf" for u in cfg["trabajadores"]]:
        t = subprocess.run(["pdftotext", pdf, "-"], capture_output=True, text=True).stdout.lower()
        if marca_vieja.lower() in t:
            print(f"  RESTO en {os.path.basename(pdf)}"); fallos += 1
    print("  limpio" if not fallos else "")
print(f"\n{'TODO OK' if fallos == 0 else str(fallos) + ' FALLOS'}")
sys.exit(1 if fallos else 0)
