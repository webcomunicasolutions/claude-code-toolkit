#!/usr/bin/env python3
"""Marca capturas con recuadros rojos numerados (el orden de los pasos) y las recorta a lo que importa.

Uso: python3 anotar.py plan.json carpeta_salida
plan.json (ver plantillas/plan.ejemplo.json):
  {"p1_confirmar": {"src": "frames/f_105.png", "cajas": [[183,32,247,48],[182,89,443,107]], "recorte": [0,0,800,460]}, ...}
- Coordenadas en píxeles de la imagen ORIGEN (x1,y1,x2,y2). Sacarlas mirando el fotograma a tamaño completo.
- Con una sola caja no se dibuja número. Si la caja está pegada arriba, el número va a su derecha.
- Siempre REVISAR el resultado en una hoja de contactos: un número puede tapar el texto que explica.
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROJO = (220, 20, 20)
FUENTE = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'


def anotar(src, cajas, recorte, destino):
    im = Image.open(src).convert('RGB')
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(FUENTE, 22)
    for i, (a, b, c, e) in enumerate(cajas, 1):
        for w in range(3):
            d.rectangle((a - 4 - w, b - 3 - w, c + 4 + w, e + 3 + w), outline=ROJO)
        if len(cajas) > 1:
            x, y = (a - 4, b - 30) if b > 34 else (c + 8, b - 4)
            d.ellipse((x, y, x + 26, y + 26), fill=ROJO)
            d.text((x + 7, y + 1), str(i), font=f, fill='white')
    if recorte:
        im = im.crop(tuple(recorte))
    im.save(destino, quality=82)


def main():
    plan, salida = json.load(open(sys.argv[1])), sys.argv[2]
    base = os.path.dirname(os.path.abspath(sys.argv[1]))
    os.makedirs(salida, exist_ok=True)
    for nombre, p in plan.items():
        if nombre.startswith('_'):
            continue
        anotar(os.path.join(base, p['src']), p.get('cajas', []), p.get('recorte'), os.path.join(salida, nombre + '.jpg'))
    print('anotadas:', len([k for k in plan if not k.startswith('_')]), '->', salida)


if __name__ == '__main__':
    main()
