#!/usr/bin/env bash
# Pruebas de seguridad EN VIVO contra una web propia. Solo lectura y peticiones inofensivas.
#
#   auditar_en_vivo.sh <url_base> [pagina_login]      p. ej.  https://panel.cliente.es  login.php
#
# Comprueba: cabeceras de seguridad, flags de la cookie de sesion, HTTPS/HSTS, ficheros que NO deben
# servirse (mirando el CUERPO, no solo el codigo), listado de carpetas, errores PHP visibles, POST sin
# token CSRF y API sin token. Sale con codigo 1 si hay alguna FALLA.
# Skill seguridad-web.
set -uo pipefail
BASE="${1:?uso: auditar_en_vivo.sh <url_base> [pagina_login]}"; BASE="${BASE%/}"
LOGIN="${2:-login.php}"
FALLAS=0; AVISOS=0
ok()    { printf '  OK     %-46s %s\n' "$1" "${2:-}"; }
falla() { printf '  FALLA  %-46s %s\n' "$1" "${2:-}"; FALLAS=$((FALLAS+1)); }
aviso() { printf '  AVISO  %-46s %s\n' "$1" "${2:-}"; AVISOS=$((AVISOS+1)); }
codigo() { curl -sk -o /dev/null -w '%{http_code}' --max-time 20 "$1"; }

echo "== Web: $BASE =="
CAB=$(curl -sk -D - -o /dev/null --max-time 20 "$BASE/$LOGIN")
[[ -n "$CAB" ]] || { echo "No responde $BASE/$LOGIN"; exit 2; }

echo "== 1. Cabeceras de seguridad =="
tiene() { grep -qi "^$1:" <<< "$CAB"; }
tiene 'X-Frame-Options' || grep -qi "frame-ancestors" <<< "$CAB" \
  && ok "anti-iframe (X-Frame-Options / frame-ancestors)" || falla "anti-iframe (clickjacking)" "falta X-Frame-Options"
tiene 'X-Content-Type-Options' && ok "X-Content-Type-Options" || falla "X-Content-Type-Options" "falta nosniff"
tiene 'Referrer-Policy' && ok "Referrer-Policy" || aviso "Referrer-Policy" "falta"
grep -qiE '^x-powered-by:.*php' <<< "$CAB" && aviso "X-Powered-By revela PHP" "$(grep -i '^x-powered-by' <<< "$CAB" | tr -d '\r')" || ok "sin X-Powered-By"
grep -qiE '^server:.*[0-9]' <<< "$CAB" && aviso "Server revela version" "$(grep -i '^server' <<< "$CAB" | tr -d '\r')" || ok "Server sin version"

echo "== 2. Cookie de sesion y HTTPS =="
COOK=$(grep -i '^set-cookie:' <<< "$CAB" | head -1 | tr -d '\r')
if [[ -z "$COOK" ]]; then aviso "cookie de sesion" "la pagina de login no pone cookie (no comprobado)"
else
  grep -qi 'httponly' <<< "$COOK" && ok "cookie HttpOnly" || falla "cookie HttpOnly" "$COOK"
  grep -qi 'samesite' <<< "$COOK" && ok "cookie SameSite" || falla "cookie SameSite" "$COOK"
  if [[ "$BASE" == https://* ]]; then
    grep -qi 'secure' <<< "$COOK" && ok "cookie Secure" || falla "cookie Secure (hay HTTPS)" "$COOK"
  else aviso "cookie Secure" "la web va por HTTP: la sesion viaja en claro"; fi
fi
if [[ "$BASE" == https://* ]]; then
  tiene 'Strict-Transport-Security' && ok "HSTS" || aviso "HSTS" "falta Strict-Transport-Security"
  H=${BASE#https://}; C=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "http://$H/")
  [[ "$C" =~ ^30[178]$ ]] && ok "HTTP redirige a HTTPS" "$C" || aviso "HTTP no redirige a HTTPS" "$C"
else aviso "sin HTTPS" "decision a escribir en el CLAUDE.md del proyecto"; fi

echo "== 3. Lo que NO debe servirse (se mira el cuerpo) =="
for f in .env .env.ejemplo .env.example .env.bak .git/HEAD .git/config .htaccess composer.json composer.lock \
         config.php.bak index.php.bak index.php~ phpinfo.php info.php adminer.php server-status \
         backup.sql dump.sql .DS_Store; do
  C=$(codigo "$BASE/$f")
  if [[ "$C" == 200 ]]; then
    CUERPO=$(curl -sk --max-time 15 "$BASE/$f" | head -c 300)
    if [[ "$CUERPO" == *"<!DOCTYPE"* || "$CUERPO" == *"<html"* || "$CUERPO" == *"<HTML"* ]]; then
      ok "/$f" "200 pero es HTML de la app (no es fuga)"
    else falla "/$f" "200 CON CONTENIDO -> FUGA"; fi
  else ok "/$f" "$C"; fi
done

echo "== 4. Listado de carpetas y errores PHP =="
for d in css/ js/ img/ imagenes/ uploads/ subidas/ funciones/ includes/; do
  CUERPO=$(curl -sk --max-time 15 "$BASE/$d" | head -c 2000)
  [[ "$CUERPO" == *"Index of /"* ]] && falla "listado de /$d" "Options -Indexes" || true
done
ok "listado de carpetas" "(revisadas 8 rutas tipicas)"
ERR=$( { curl -sk --max-time 15 "$BASE/$LOGIN?x[]=1"; curl -sk --max-time 15 -X POST "$BASE/$LOGIN" -d 'usuario[]=a'; } \
      | grep -ciE 'fatal error|warning:|notice:|stack trace|/var/www/|uncaught' )
[[ "$ERR" -eq 0 ]] && ok "sin errores PHP visibles" || falla "errores PHP visibles" "$ERR coincidencias (display_errors?)"

echo "== 5. CSRF y API =="
C=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 15 -X POST "$BASE/$LOGIN" -d 'usuario=auditoria_noexiste&clave=x')
[[ "$C" =~ ^4 ]] && ok "POST de login SIN token CSRF" "$C (rechazado)" \
  || falla "POST de login SIN token CSRF" "$C: revisar que un token vacio NO valga (hash_equals('', ''))"
for api in api.php api/ api/index.php; do
  C=$(codigo "$BASE/$api")
  [[ "$C" == 404 ]] && continue
  [[ "$C" =~ ^(401|403)$ ]] && ok "/$api sin token" "$C" || aviso "/$api sin token" "$C (revisar a mano)"
done

echo
echo "RESULTADO: $FALLAS FALLAS, $AVISOS AVISOS"
[[ $FALLAS -eq 0 ]]
