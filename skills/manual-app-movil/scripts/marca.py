#!/usr/bin/env python3
"""Capa de marca del CLIENTE: banda superior con su logo y pie con sus datos.

Se estampa sobre cada página del PDF del contenido. Va en capa aparte porque una
cabecera CSS `position:fixed` NO se repite bien al imprimir desde el navegador.
La marca se describe en marca.json (ver plantillas/marca.ejemplo.json).
"""
import os
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from pypdf import PdfReader, PdfWriter


def _fuentes(marca):
    try:
        for nombre, ruta in marca.get("fuentes", {}).items():
            pdfmetrics.registerFont(TTFont(nombre, os.path.expanduser(ruta)))
        return marca.get("fuente_normal", "Helvetica"), marca.get("fuente_negrita", "Helvetica-Bold")
    except Exception:
        return "Helvetica", "Helvetica-Bold"          # sin las fuentes, el PDF sale igual


def _capa(ruta, marca, lineas_cabecera, texto_pie_derecha, base_dir):
    normal, negrita = _fuentes(marca)
    W, H = A4
    col = marca["colores"]
    alto_cab, alto_pie, margen = marca.get("alto_cabecera_mm", 26) * mm, marca.get("alto_pie_mm", 16) * mm, 14 * mm
    c = canvas.Canvas(ruta, pagesize=A4)
    c.setFillColor(HexColor(col["fondo"])); c.rect(0, H - alto_cab, W, alto_cab, stroke=0, fill=1)
    if col.get("linea"):
        c.setFillColor(HexColor(col["linea"])); c.rect(0, H - alto_cab - 1.4 * mm, W, 1.4 * mm, stroke=0, fill=1)
    logo = os.path.join(base_dir, marca["logo"])
    alto_logo = marca.get("alto_logo_mm", 7.5) * mm
    from PIL import Image
    an, al = Image.open(logo).size
    c.drawImage(logo, margen, H - alto_cab / 2 - alto_logo / 2, width=alto_logo * an / al,
                height=alto_logo, mask="auto")
    c.setFillColor(HexColor(col.get("texto_cabecera", "#FFFFFF"))); c.setFont(normal, 8.5)
    y = H - alto_cab / 2 + (len(lineas_cabecera) - 1) * 5.5 - 3
    for linea in lineas_cabecera:
        c.drawRightString(W - margen, y, linea); y -= 11
    c.setFillColor(HexColor(col["fondo"])); c.rect(0, 0, W, alto_pie, stroke=0, fill=1)
    c.setFillColor(HexColor(col.get("texto_pie", "#FFFFFF"))); c.setFont(normal, 7.8)
    y = alto_pie / 2 + (len(marca["pie"]) - 1) * 5.5 - 3
    for linea in marca["pie"]:
        c.drawString(margen, y, linea); y -= 11
    c.setFillColor(HexColor("#FFFFFF")); c.setFont(negrita, 10.5)
    c.drawRightString(W - margen, alto_pie / 2 - 2, texto_pie_derecha)
    c.showPage(); c.save()
    return PdfReader(ruta).pages[0]


def aplicar_marca(cuerpo_pdf, marca, lineas_cabecera, pie_derecha, tmp_dir, base_dir="."):
    """pie_derecha(n, total) -> texto de la esquina inferior derecha (nº de página, sigla...)."""
    paginas = PdfReader(cuerpo_pdf).pages
    total, salida = len(paginas), []
    for n, pg in enumerate(paginas, start=1):
        pg.merge_page(_capa(os.path.join(tmp_dir, f"capa_{n}.pdf"), marca, lineas_cabecera,
                            pie_derecha(n, total), base_dir))
        salida.append(pg)
    return salida


def escribir(paginas, destino):
    out = PdfWriter()
    for pg in paginas:
        out.add_page(pg)
    out.write(destino)
    return len(paginas)
