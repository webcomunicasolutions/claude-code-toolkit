#!/usr/bin/env python3
"""Ficha de acceso personal por trabajador: usuario, contraseña (del vault) y QR a la web.

Uso: python3 generar_fichas.py config.json marca.json salida/
LAS FICHAS LLEVAN CONTRASEÑAS: su carpeta va SIEMPRE al .gitignore.
"""
import base64, io, json, os, subprocess, sys, tempfile
import qrcode
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from marca import aplicar_marca, escribir
from pypdf import PdfReader

cfg, marca_json, salida = json.load(open(sys.argv[1])), sys.argv[2], sys.argv[3]
marca = json.load(open(marca_json)); base = os.path.dirname(os.path.abspath(marca_json))
os.makedirs(salida, exist_ok=True)
vault = json.load(open(os.path.expanduser(cfg["vault"]["fichero"])))
nodo = vault
for parte in cfg["vault"]["ruta_usuarios"].split("."):
    nodo = nodo[parte]
usuarios = nodo
buf = io.BytesIO(); qrcode.make(cfg["url"], border=1).save(buf, format="PNG")
QR = "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()
CSS = """@page{size:A4;margin:40mm 18mm 26mm 18mm}body{font-family:"%(fuente)s",Arial,sans-serif;color:#2B3048;margin:0}
.nombre{font-size:24pt;font-weight:600;color:%(marca)s;margin:0;line-height:1.2}
.rol{color:%(acento)s;font-weight:600;font-size:13pt;margin:1mm 0 9mm}
.caja{border:.8mm solid %(marca)s;border-radius:4mm;padding:8mm 9mm;display:flex;gap:9mm;align-items:center}
.datos{flex:1}.et{font-size:9.5pt;color:#7A8099;text-transform:uppercase;letter-spacing:.08em;margin-top:5mm}
.et:first-child{margin-top:0}.val{font-family:monospace;font-size:22pt;color:%(marca)s;line-height:1.2}
.url{font-size:13pt;font-weight:600;color:%(marca)s}.qr{text-align:center;font-size:9pt;color:#7A8099;width:46mm}
.qr img{width:46mm;display:block}ol{font-size:12pt;line-height:1.75;padding-left:6mm;margin:10mm 0 0}
.aviso{background:#F2F7FC;border-left:1.2mm solid %(acento)s;padding:4.5mm 6mm;font-size:11pt;margin-top:9mm}"""
CSS = CSS % {"fuente": marca.get("fuente_html", "Arial"), "marca": marca["colores"]["fondo"],
             "acento": marca["colores"].get("linea", marca["colores"]["fondo"])}

from html import escape as esc
os.umask(0o077)   # las fichas llevan contraseñas: solo legibles por el usuario

def html_ficha(u, d):
    return f"""<!doctype html><html lang="es"><head><meta charset="utf-8"><style>{CSS}</style></head><body>
<p class="nombre">{esc(d.get('nombre', u))}</p><p class="rol">{esc(cfg['roles'].get(d.get('rol',''), d.get('rol','')))}</p>
<div class="caja"><div class="datos">
<div class="et">Dirección</div><div class="url">{cfg['url'].replace('https://','')}</div>
<div class="et">Usuario</div><div class="val">{esc(u)}</div>
<div class="et">Contraseña</div><div class="val">{esc(d[cfg['vault'].get('campo_password','password')])}</div>
</div><div class="qr"><img src="{QR}">Apunta con la cámara<br>para abrir la web</div></div>
<ol><li>Lee el código QR con la cámara del móvil, o escribe la dirección en Chrome o Safari.</li>
<li>Escribe tu usuario y tu contraseña exactamente como aparecen aquí y pulsa <strong>ENTRAR</strong>.</li>
<li>Instala la aplicación siguiendo el manual.</li></ol>
<div class="aviso"><strong>Esta hoja es personal.</strong> Todo lo que se ficha y se firma con tu usuario
queda a tu nombre. No se la enseñes ni se la prestes a nadie.</div></body></html>"""

with tempfile.TemporaryDirectory() as tmp:
    todas = []
    for u in cfg["trabajadores"]:
        h = os.path.join(tmp, f"{u}.html"); open(h, "w", encoding="utf-8").write(html_ficha(u, usuarios[u]))
        cuerpo = os.path.join(tmp, f"{u}.pdf")
        subprocess.run(["google-chrome", "--headless", "--disable-gpu", "--no-sandbox",
                        "--no-pdf-header-footer", f"--print-to-pdf={cuerpo}", "file://" + h],
                       check=True, capture_output=True)
        pags = aplicar_marca(cuerpo, marca, ["Ficha de acceso", "Personal e intransferible"],
                             lambda n, t: marca.get("sigla", ""), tmp, base)
        destino = os.path.join(salida, f"Ficha-acceso-{u}.pdf")
        print("ficha:", os.path.basename(destino), "paginas:", escribir(pags, destino))
        todas.extend(PdfReader(destino).pages)
    print("combinado:", escribir(todas, os.path.join(salida, "Fichas-acceso-TODAS-para-imprimir.pdf")))
