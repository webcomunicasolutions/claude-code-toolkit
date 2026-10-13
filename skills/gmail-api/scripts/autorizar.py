#!/usr/bin/env python3
"""Obtiene el refresh_token de Gmail con el flujo OAuth de escritorio (loopback) y lo guarda en JSON.

Uso:
    python3 autorizar.py --client-secret descarga_de_google.json
    python3 autorizar.py --client-id XXX --client-secret-valor YYY
Opciones: --salida RUTA (defecto ~/.config/gmail-api/credenciales.json, permisos 600),
          --scopes (defecto gmail.modify), --puerto N (0 = libre), --no-abrir.
Solo biblioteca estandar. El navegador debe poder abrirse en ESTA maquina; si trabajas por SSH,
usa un tunel: ssh -L PUERTO:127.0.0.1:PUERTO usuario@maquina y fija --puerto PUERTO.
"""
import argparse
import base64
import hashlib
import http.server
import json
import os
import pathlib
import secrets
import sys
import threading
import urllib.error
import urllib.parse
import urllib.request
import webbrowser

AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
TOKEN_URL = "https://oauth2.googleapis.com/token"
SCOPES = {
    "lectura": "https://www.googleapis.com/auth/gmail.readonly",
    "modify": "https://www.googleapis.com/auth/gmail.modify",
    "completo": "https://mail.google.com/",
}
SALIDA = pathlib.Path.home() / ".config" / "gmail-api" / "credenciales.json"


def leer_cliente(args):
    if args.client_secret:
        d = json.loads(pathlib.Path(args.client_secret).expanduser().read_text())
        d = d.get("installed") or d.get("web") or d
        return d["client_id"], d["client_secret"]
    if args.client_id and args.client_secret_valor:
        return args.client_id, args.client_secret_valor
    cid, sec = os.environ.get("GMAIL_CLIENT_ID"), os.environ.get("GMAIL_CLIENT_SECRET")
    if cid and sec:
        return cid, sec
    sys.exit("Falta el cliente OAuth: --client-secret fichero.json, o --client-id/--client-secret-valor, "
             "o variables GMAIL_CLIENT_ID y GMAIL_CLIENT_SECRET.")


def esperar_codigo(servidor, estado):
    resultado = {}

    class H(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            q = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
            if "code" in q or "error" in q:
                resultado.update({k: v[0] for k, v in q.items()})
                ok = q.get("state", [""])[0] == estado and "code" in q
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.end_headers()
                self.wfile.write(("<h3>Autorizacion recibida. Puedes cerrar esta pestana.</h3>" if ok
                                  else "<h3>Fallo en la autorizacion. Mira la terminal.</h3>").encode())
                threading.Thread(target=servidor.shutdown, daemon=True).start()
            else:
                self.send_response(404)
                self.end_headers()

        def log_message(self, *a):
            pass

    servidor.RequestHandlerClass = H
    servidor.serve_forever()
    if resultado.get("state") != estado:
        sys.exit("El parametro 'state' no coincide: peticion descartada por seguridad.")
    if "code" not in resultado:
        sys.exit("Google devolvio error: " + resultado.get("error", "desconocido"))
    return resultado["code"]


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--client-secret", help="JSON descargado de Google Cloud (credenciales de escritorio)")
    p.add_argument("--client-id")
    p.add_argument("--client-secret-valor")
    p.add_argument("--salida", default=str(SALIDA))
    p.add_argument("--scopes", default="modify", choices=list(SCOPES),
                   help="lectura | modify (leer, etiquetar, borradores, enviar) | completo (incluye borrar definitivo)")
    p.add_argument("--puerto", type=int, default=0)
    p.add_argument("--no-abrir", action="store_true", help="solo imprime la URL")
    args = p.parse_args()

    cid, secreto = leer_cliente(args)
    scope = SCOPES.get(args.scopes, SCOPES["modify"])
    servidor = http.server.HTTPServer(("127.0.0.1", args.puerto), http.server.BaseHTTPRequestHandler)
    puerto = servidor.server_address[1]
    redirect = f"http://127.0.0.1:{puerto}"
    estado = secrets.token_urlsafe(16)
    verificador = secrets.token_urlsafe(64)
    desafio = base64.urlsafe_b64encode(hashlib.sha256(verificador.encode()).digest()).rstrip(b"=").decode()
    url = AUTH_URL + "?" + urllib.parse.urlencode({
        "client_id": cid, "redirect_uri": redirect, "response_type": "code", "scope": scope,
        "access_type": "offline", "prompt": "consent", "state": estado,
        "code_challenge": desafio, "code_challenge_method": "S256"})
    print("Abre esta URL en el navegador e inicia sesion con TU cuenta de Gmail:\n\n" + url + "\n")
    if not args.no_abrir:
        webbrowser.open(url)
    codigo = esperar_codigo(servidor, estado)

    datos = urllib.parse.urlencode({
        "code": codigo, "client_id": cid, "client_secret": secreto, "redirect_uri": redirect,
        "grant_type": "authorization_code", "code_verifier": verificador}).encode()
    try:
        r = json.load(urllib.request.urlopen(urllib.request.Request(TOKEN_URL, data=datos), timeout=30))
    except urllib.error.HTTPError as e:
        sys.exit(f"Google rechazo el canje del codigo: {e.read().decode('utf-8', 'replace')[:400]}")
    if "refresh_token" not in r:
        sys.exit("No llego refresh_token. Revoca el acceso previo en myaccount.google.com/permissions y repite.")

    salida = pathlib.Path(args.salida).expanduser()
    salida.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    contenido = json.dumps({"client_id": cid, "client_secret": secreto,
                            "refresh_token": r["refresh_token"], "scope": r.get("scope", scope)}, indent=2)
    fd = os.open(salida, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        f.write(contenido)
    os.chmod(salida, 0o600)
    print(f"Credenciales guardadas en {salida} (permisos 600). Scope: {r.get('scope', scope)}")


if __name__ == "__main__":
    main()
