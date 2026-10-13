#!/usr/bin/env python3
"""Monta el PDF final: Chrome imprime manual.html y encima se estampa la marca.

Uso: python3 montar_pdf.py manual.html marca.json salida.pdf ["Línea 1 cabecera" "Línea 2"]
"""
import json, os, subprocess, sys, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from marca import aplicar_marca, escribir

html, marca_json, destino = sys.argv[1], sys.argv[2], sys.argv[3]
lineas = sys.argv[4:] or ["Manual de la aplicación"]
marca = json.load(open(marca_json))
base = os.path.dirname(os.path.abspath(marca_json))
with tempfile.TemporaryDirectory() as tmp:
    cuerpo = os.path.join(tmp, "cuerpo.pdf")
    subprocess.run(["google-chrome", "--headless", "--disable-gpu", "--no-sandbox",
                    "--no-pdf-header-footer", f"--print-to-pdf={cuerpo}",
                    "file://" + os.path.abspath(html)], check=True, capture_output=True)
    pags = aplicar_marca(cuerpo, marca, lineas, lambda n, t: f"{n} / {t}", tmp, base)
    print("paginas:", escribir(pags, destino), "->", destino)
