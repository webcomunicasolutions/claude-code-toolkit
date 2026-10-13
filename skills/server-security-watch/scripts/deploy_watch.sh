#!/bin/bash
# deploy_watch.sh - Despliega la vigilancia COMPLETA en un servidor, de una vez.
#
# Se ejecuta EN LOCAL. Hace el procedimiento entero de la FASE 3 + FASE 4, incluidos los
# pasos que es facil saltarse a mano (y que en un despliegue real se saltaron, con dos falsas
# alarmas como consecuencia):
#   - comprobar que el servidor PUEDE avisar por Telegram, con un envio real (hallazgo 14)
#   - descubrir los dominios reales de Traefik en vez de escribirlos de memoria (hallazgo 16)
#   - PROBAR cada URL antes de meterla en urls.conf, y usar el codigo que devuelve de verdad
#   - auditar al final que no quede ningun dominio del cliente sin vigilar
#
# Uso:
#   ./deploy_watch.sh <host> <usuario> <clave_ssh> [puerto] [fichero_credenciales:ruta_jq_del_password_sudo]
#
# Ejemplos:
#   ./deploy_watch.sh 192.168.1.10 admin ~/.ssh/id_ed25519
#   ./deploy_watch.sh 192.168.1.20 deploy ~/.ssh/id_ed25519 223 \
#       'servidor-ejemplo.json:.servidores.app.password'   # JSON dentro de $HOME/.credentials/
#
# El ultimo argumento solo hace falta si el usuario NO tiene sudo sin password. La password
# viaja por STDIN de 'sudo -S': NUNCA en la linea de comandos (seria visible con ps).

set -uo pipefail
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

HOST="${1:-}"; USUARIO="${2:-}"; CLAVE="${3:-}"; PUERTO="${4:-22}"; VAULTPW="${5:-}"
[ -z "$HOST" ] || [ -z "$USUARIO" ] || [ -z "$CLAVE" ] && {
  sed -n '2,25p' "$0"; exit 1; }
CLAVE="${CLAVE/#\~/$HOME}"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
SSH=(ssh -o ConnectTimeout=30 -o BatchMode=yes -p "$PUERTO" -i "$CLAVE")
DEST="$USUARIO@$HOST"

# Ejecuta un script COMO ROOT en el remoto, con o sin password de sudo
remoto_root() {
  local script="$1"
  scp -q -P "$PUERTO" -i "$CLAVE" "$script" "$DEST:/tmp/_dw.sh" || return 1
  if [ -n "$VAULTPW" ]; then
    local fichero="${VAULTPW%%:*}" ruta="${VAULTPW#*:}"
    jq -r "$ruta" "$HOME/.credentials/$fichero" | \
      "${SSH[@]}" "$DEST" 'sudo -S -p "" bash /tmp/_dw.sh 2>&1; rm -f /tmp/_dw.sh'
  else
    "${SSH[@]}" "$DEST" 'S=""; [ "$(id -u)" != "0" ] && S="sudo -n"; $S bash /tmp/_dw.sh 2>&1; rm -f /tmp/_dw.sh'
  fi
}

echo "=========== $HOST ($USUARIO, puerto $PUERTO) ==========="

# ---- 0) conectividad
"${SSH[@]}" "$DEST" 'hostname -s' >/dev/null 2>&1 || { echo "  ❌ no se puede conectar"; exit 1; }
EQUIPO=$("${SSH[@]}" "$DEST" 'hostname -s' 2>/dev/null)
echo "  conectado: $EQUIPO"

# ---- 1) subir los dos scripts
scp -q -P "$PUERTO" -i "$CLAVE" "$AQUI/security_watch.sh" "$AQUI/service_watch.sh" "$DEST:/tmp/" || {
  echo "  ❌ fallo al subir los scripts"; exit 1; }

# ---- 2) telegram.conf: si no existe, se copia del que se le pase por env TELEGRAM_CONF
if [ -n "${TELEGRAM_CONF:-}" ] && [ -r "$TELEGRAM_CONF" ]; then
  scp -q -P "$PUERTO" -i "$CLAVE" "$TELEGRAM_CONF" "$DEST:/tmp/_tg.conf"
fi

cat > "$TMP/instalar.sh" <<'INS'
#!/bin/bash
mkdir -p /root/scripts /etc/secwatch /root/_pendiente_borrado
[ -f /root/scripts/security_watch.sh ] && cp /root/scripts/security_watch.sh "/root/_pendiente_borrado/security_watch.sh.$(date +%Y%m%d)"
install -m 700 -o root -g root /tmp/security_watch.sh /root/scripts/security_watch.sh
install -m 700 -o root -g root /tmp/service_watch.sh  /root/scripts/service_watch.sh
[ -f /tmp/_tg.conf ] && [ ! -f /etc/secwatch/telegram.conf ] && install -m 600 -o root -g root /tmp/_tg.conf /etc/secwatch/telegram.conf
rm -f /tmp/security_watch.sh /tmp/service_watch.sh /tmp/_tg.conf
echo "  scripts: md5 $(md5sum /root/scripts/security_watch.sh | cut -c1-8) / $(md5sum /root/scripts/service_watch.sh | cut -c1-8)"

# ---- comprobar que PUEDE avisar (hallazgo 14: un vigilante mudo no sirve de nada)
if [ ! -f /etc/secwatch/telegram.conf ]; then
  echo "  ❌ FALTA /etc/secwatch/telegram.conf -> este servidor NO PODRA AVISAR"
else
  . /etc/secwatch/telegram.conf
  if curl -s --max-time 20 -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
       --data-urlencode "chat_id=${CHAT_ID}" \
       --data-urlencode "text=✅ $(hostname -s): vigilancia desplegada, este servidor puede avisar." \
       | grep -q '"ok":true'; then echo "  ✅ puede avisar por Telegram"
  else echo "  ❌ NO consigue enviar por Telegram"; fi
fi

# ---- descubrir dominios de Traefik y PROBARLOS antes de configurarlos (hallazgos 13 y 16)
if [ ! -f /etc/secwatch/urls.conf ]; then
  doms=$(grep -rhoE 'Host\(`[^`]+`\)' /etc/easypanel/traefik/ 2>/dev/null \
         | grep -oE '`[^`]+`' | tr -d '`' | sort -u \
         | grep -viE "traefik|phpmyadmin|dbgate|pgweb|rediscommander|^www\.")
  { echo "# Generado por deploy_watch.sh el $(date +%F). Codigos COMPROBADOS, no supuestos."
    echo "# Revisar: puede que sobre alguna herramienta interna o falte un dominio propio."
  } > /etc/secwatch/urls.conf
  for d in $doms; do
    c=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "https://$d/" 2>/dev/null)
    case "$c" in
      200|301|302) echo "$d|https://$d/|200,301,302" >> /etc/secwatch/urls.conf; echo "    + $d (HTTP $c)";;
      401|403)     echo "$d|https://$d/|200,301,302,401,403" >> /etc/secwatch/urls.conf; echo "    + $d (HTTP $c, pide auth)";;
      *)           echo "# NO vigilado: $d devuelve $c" >> /etc/secwatch/urls.conf; echo "    - $d descartado (HTTP $c)";;
    esac
  done
  chmod 600 /etc/secwatch/urls.conf
else
  echo "  urls.conf ya existia: se respeta"
fi

# ---- crons
crontab -l 2>/dev/null | grep -q service_watch  || (crontab -l 2>/dev/null; echo "*/5 * * * * /root/scripts/service_watch.sh >/dev/null 2>&1") | crontab -
crontab -l 2>/dev/null | grep -q security_watch || (crontab -l 2>/dev/null; echo "25 * * * * PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /root/scripts/security_watch.sh >/dev/null 2>&1") | crontab -

# ---- 2 pasadas de cada uno (la 1a crea la linea base, la 2a debe callar)
/root/scripts/service_watch.sh  >/dev/null 2>&1; /root/scripts/service_watch.sh  >/dev/null 2>&1
/root/scripts/security_watch.sh >/dev/null 2>&1; /root/scripts/security_watch.sh >/dev/null 2>&1

vig=$(ls -1 /var/lib/servicewatch/ 2>/dev/null | grep -c estado)
cai=$(grep -l caido /var/lib/servicewatch/*.estado 2>/dev/null | wc -l)
echo "  vigilando: $vig elementos | marcados como caidos: $cai"
[ "$cai" -gt 0 ] && { echo "  ⚠️  REVISAR (¿caida real o falso positivo?):"
  grep -l caido /var/lib/servicewatch/*.estado 2>/dev/null | sed 's|.*/||; s/.estado//; s/^/      /'; }
echo "  ultima linea del vigilante de seguridad: $(tail -1 /var/log/security_watch.log 2>/dev/null | cut -c1-70)"
INS

remoto_root "$TMP/instalar.sh"
echo "=========================================================="
