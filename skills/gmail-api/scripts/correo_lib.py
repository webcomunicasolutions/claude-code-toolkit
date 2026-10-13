#!/usr/bin/env python3
"""Libreria minima para la API de Gmail (solo biblioteca estandar de Python).

Credenciales (por orden de prioridad):
  1. Variables de entorno GMAIL_CLIENT_ID, GMAIL_CLIENT_SECRET, GMAIL_REFRESH_TOKEN
  2. Fichero JSON: variable GMAIL_API_CREDENCIALES o ~/.config/gmail-api/credenciales.json
     (lo crea scripts/autorizar.py)

Uso como libreria:
    import sys; sys.path.insert(0, "<ruta>/skills/gmail-api/scripts")
    import correo_lib as g
    tok = g.token()
    for m in g.listar(tok, "is:unread newer_than:7d"):
        print(g.cabeceras(tok, m["id"]))

Uso desde linea de comandos: ver --help.
IMPORTANTE: enviar() y papelera() actuan de verdad. Pedir confirmacion al usuario antes.
"""
import argparse
import base64
import json
import mimetypes
import os
import pathlib
import sys
import urllib.error
import urllib.parse
import urllib.request
from email.message import EmailMessage

TOKEN_URL = "https://oauth2.googleapis.com/token"
API = "https://gmail.googleapis.com/gmail/v1/users/me"
RUTA_POR_DEFECTO = pathlib.Path.home() / ".config" / "gmail-api" / "credenciales.json"


class ErrorGmail(Exception):
    """Error de la API con el detalle devuelto por Google."""


def ruta_credenciales():
    return pathlib.Path(os.environ.get("GMAIL_API_CREDENCIALES", RUTA_POR_DEFECTO)).expanduser()


def cargar_credenciales():
    """Devuelve dict con client_id, client_secret y refresh_token."""
    env = {k: os.environ.get("GMAIL_" + k.upper()) for k in ("client_id", "client_secret", "refresh_token")}
    if all(env.values()):
        return env
    ruta = ruta_credenciales()
    if not ruta.exists():
        raise ErrorGmail(f"No hay credenciales: ni variables GMAIL_* ni {ruta}. Ejecuta scripts/autorizar.py")
    datos = json.loads(ruta.read_text())
    faltan = [k for k in env if not datos.get(k)]
    if faltan:
        raise ErrorGmail(f"Faltan campos en {ruta}: {', '.join(faltan)}")
    return {k: datos[k] for k in env}


def _peticion(req, timeout=60):
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            cuerpo = r.read()
            return json.loads(cuerpo) if cuerpo else {}
    except urllib.error.HTTPError as e:
        raise ErrorGmail(f"HTTP {e.code}: {e.read().decode('utf-8', 'replace')[:500]}") from None


def token():
    """Access token nuevo a partir del refresh_token (caduca en ~1 h)."""
    c = cargar_credenciales()
    datos = urllib.parse.urlencode({**c, "grant_type": "refresh_token"}).encode()
    return _peticion(urllib.request.Request(TOKEN_URL, data=datos), 30)["access_token"]


def api(tok, ruta, params=None, metodo="GET", cuerpo=None):
    url = f"{API}/{ruta}"
    if params:
        url += "?" + urllib.parse.urlencode(params, doseq=True)
    headers = {"Authorization": f"Bearer {tok}"}
    data = None
    if cuerpo is not None:
        data = json.dumps(cuerpo).encode()
        headers["Content-Type"] = "application/json"
    return _peticion(urllib.request.Request(url, data=data, headers=headers, method=metodo))


def sin_leer(tok, etiqueta="INBOX"):
    """(no_leidos, total) de una etiqueta."""
    d = api(tok, f"labels/{etiqueta}")
    return d.get("messagesUnread", 0), d.get("messagesTotal", 0)


def listar(tok, q, maximo=50, incluir_spam=False):
    """Busca con sintaxis Gmail (from:, subject:, newer_than:, has:attachment...).
    Por defecto Gmail excluye SPAM y PAPELERA: usar incluir_spam=True para revisarlos."""
    out, pagina = [], None
    while len(out) < maximo:
        p = {"q": q, "maxResults": min(100, maximo - len(out))}
        if incluir_spam:
            p["includeSpamTrash"] = "true"
        if pagina:
            p["pageToken"] = pagina
        d = api(tok, "messages", p)
        out += d.get("messages", [])
        pagina = d.get("nextPageToken")
        if not pagina:
            break
    return out[:maximo]


def cabeceras(tok, mid):
    """From, Subject, Date, To, Message-ID (en minusculas) + _snippet, _labels, _id, _thread."""
    d = api(tok, f"messages/{mid}", {"format": "metadata",
            "metadataHeaders": ["From", "To", "Subject", "Date", "Message-ID"]})
    h = {x["name"].lower(): x["value"] for x in d.get("payload", {}).get("headers", [])}
    h.update(_snippet=d.get("snippet", "")[:160], _labels=d.get("labelIds", []), _id=mid,
             _thread=d.get("threadId", ""))
    return h


def mensaje(tok, mid):
    """Mensaje completo (formato full)."""
    return api(tok, f"messages/{mid}", {"format": "full"})


def _decodificar(b64):
    return base64.urlsafe_b64decode(b64 + "=" * (-len(b64) % 4))


def cuerpo_texto(msg):
    """Texto plano del mensaje (o HTML si no hay texto plano)."""
    texto, html = [], []

    def recorrer(parte):
        mime, data = parte.get("mimeType", ""), parte.get("body", {}).get("data")
        if data and not parte.get("filename"):
            t = _decodificar(data).decode("utf-8", "replace")
            (texto if mime == "text/plain" else html if mime == "text/html" else []).append(t)
        for sub in parte.get("parts", []) or []:
            recorrer(sub)

    recorrer(msg.get("payload", {}))
    return "\n".join(texto) or "\n".join(html)


def adjuntos(msg):
    """Lista de {filename, mimeType, size, attachmentId} del mensaje completo."""
    out = []

    def recorrer(parte):
        if parte.get("filename") and parte.get("body", {}).get("attachmentId"):
            out.append({"filename": parte["filename"], "mimeType": parte.get("mimeType", ""),
                        "size": parte["body"].get("size", 0),
                        "attachmentId": parte["body"]["attachmentId"]})
        for sub in parte.get("parts", []) or []:
            recorrer(sub)

    recorrer(msg.get("payload", {}))
    return out


def descargar_adjunto(tok, mid, adjunto_id, destino):
    """Guarda el adjunto en 'destino' y devuelve los bytes escritos."""
    d = api(tok, f"messages/{mid}/attachments/{adjunto_id}")
    contenido = _decodificar(d.get("data", ""))
    destino = pathlib.Path(destino)
    destino.parent.mkdir(parents=True, exist_ok=True)
    destino.write_bytes(contenido)
    return len(contenido)


def modificar(tok, mid, add=None, quitar=None):
    """Anade/quita etiquetas (ids como 'UNREAD', 'INBOX', 'STARRED' o ids de etiquetas propias)."""
    return api(tok, f"messages/{mid}/modify", metodo="POST",
               cuerpo={"addLabelIds": add or [], "removeLabelIds": quitar or []})


def marcar_leido(tok, mid):
    return modificar(tok, mid, quitar=["UNREAD"])


def archivar(tok, mid):
    return modificar(tok, mid, quitar=["INBOX"])


def etiquetas(tok):
    return api(tok, "labels").get("labels", [])


def crear_etiqueta(tok, nombre):
    return api(tok, "labels", metodo="POST", cuerpo={"name": nombre})


def papelera(tok, mid):
    """Mueve a la papelera (recuperable 30 dias). Pedir confirmacion antes."""
    return api(tok, f"messages/{mid}/trash", metodo="POST")


def construir(para, asunto, texto, html=None, cc=None, adjuntos_rutas=(), responde_a=None):
    """Construye el mensaje MIME. responde_a = cabeceras() del original para hilar la respuesta."""
    m = EmailMessage()
    m["To"], m["Subject"] = para, asunto
    if cc:
        m["Cc"] = cc
    if responde_a:
        m["In-Reply-To"] = m["References"] = responde_a.get("message-id", "")
    m.set_content(texto)
    if html:
        m.add_alternative(html, subtype="html")
    for ruta in adjuntos_rutas:
        ruta = pathlib.Path(ruta)
        tipo, _ = mimetypes.guess_type(ruta.name)
        principal, sub = (tipo or "application/octet-stream").split("/", 1)
        m.add_attachment(ruta.read_bytes(), maintype=principal, subtype=sub, filename=ruta.name)
    return m


def _raw(m):
    return base64.urlsafe_b64encode(m.as_bytes()).decode()


def crear_borrador(tok, m, thread_id=None):
    """Guarda el mensaje como borrador (no se envia). Devuelve el borrador con su id."""
    msg = {"raw": _raw(m)}
    if thread_id:
        msg["threadId"] = thread_id
    return api(tok, "drafts", metodo="POST", cuerpo={"message": msg})


def enviar(tok, m, thread_id=None):
    """ENVIA de verdad. Solo tras ver el texto final con el usuario y recibir su OK explicito."""
    msg = {"raw": _raw(m)}
    if thread_id:
        msg["threadId"] = thread_id
    return api(tok, "messages/send", metodo="POST", cuerpo=msg)


def enviar_borrador(tok, draft_id):
    """ENVIA un borrador existente. Misma cautela que enviar()."""
    return api(tok, "drafts/send", metodo="POST", cuerpo={"id": draft_id})


def listar_borradores(tok, maximo=20):
    return api(tok, "drafts", {"maxResults": maximo}).get("drafts", [])


def _cli(argv=None):
    p = argparse.ArgumentParser(description="Cliente minimo de Gmail (lectura y borradores). "
                                "Enviar y borrar solo desde codigo, tras confirmar con el usuario.")
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("sin-leer", help="no leidos y total de INBOX")
    b = sub.add_parser("buscar", help="lista cabeceras de una busqueda")
    b.add_argument("consulta")
    b.add_argument("-n", type=int, default=20)
    b.add_argument("--spam", action="store_true", help="incluir SPAM y PAPELERA")
    a = sub.add_parser("adjuntos", help="lista y descarga adjuntos de un mensaje")
    a.add_argument("id")
    a.add_argument("--destino", help="carpeta donde descargarlos (sin ella solo los lista)")
    br = sub.add_parser("borrador", help="crea un borrador (NO envia)")
    br.add_argument("--para", required=True)
    br.add_argument("--asunto", required=True)
    br.add_argument("--texto", required=True)
    args = p.parse_args(argv)

    tok = token()
    if args.cmd == "sin-leer":
        print("sin leer: %d / total: %d" % sin_leer(tok))
    elif args.cmd == "buscar":
        for m in listar(tok, args.consulta, args.n, args.spam):
            h = cabeceras(tok, m["id"])
            print(f"{h['_id']} | {h.get('date', '')} | {h.get('from', '')} | {h.get('subject', '')}")
    elif args.cmd == "adjuntos":
        for ad in adjuntos(mensaje(tok, args.id)):
            print(ad["filename"], ad["mimeType"], ad["size"])
            if args.destino:
                nombre = pathlib.Path(ad["filename"]).name  # evita rutas del remitente
                n = descargar_adjunto(tok, args.id, ad["attachmentId"], pathlib.Path(args.destino) / nombre)
                print("  guardado:", n, "bytes")
    elif args.cmd == "borrador":
        r = crear_borrador(tok, construir(args.para, args.asunto, args.texto))
        print("borrador creado:", r.get("id"))


if __name__ == "__main__":
    try:
        _cli()
    except ErrorGmail as e:
        sys.exit(f"Error: {e}")
