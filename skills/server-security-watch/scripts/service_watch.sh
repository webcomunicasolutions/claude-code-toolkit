#!/bin/bash
# service_watch.sh - Vigilante de SERVICIOS y WEBS publicas (reutilizable)
#
# Por que existe (caso real, agosto de 2026):
# el servidor se reinicio solo tras una actualizacion automatica y, al volver, DOS
# servicios no levantaron porque Docker no pudo descargar su imagen: la web de gestion
# del cliente (fichajes, vehiculos, presupuestos, facturas) y Gotenberg (la generacion de PDF
# de los informes de un agente de voz). Estuvieron caidos DOCE DIAS y no salto ni una alerta.
#
# Teniamos vigilancia de las copias, del agente de voz y de los cambios de seguridad, pero NADIE
# comprobaba lo mas basico: que los servicios esten levantados y que la web responda.
# Lo detecto un humano entrando a mano. Eso es lo que arregla este script.
#
# Filosofia (la misma que security_watch.sh): informa de CAMBIOS, no de estado. Avisa
# cuando algo se cae y cuando se recupera. Si todo va bien, calla: una alerta que suena
# a diario se acaba ignorando, y entonces no sirve para nada.

set -uo pipefail
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

BASE="/var/lib/servicewatch"
EQUIPO="$(hostname -s 2>/dev/null || echo servidor)"
CONF="/etc/secwatch/telegram.conf"     # se reutiliza la del vigilante de seguridad
LOG="/var/log/service_watch.log"
FALLOS_PARA_AVISAR=2                   # 2 rondas seguidas: no avisar por un pico de red

mkdir -p "$BASE" && chmod 700 "$BASE"
log() { echo "$(date '+%F %T') $*" >> "$LOG"; }

# URLs publicas que DEBEN responder.
# Van en /etc/secwatch/urls.conf (una por linea), NO escritas aqui: asi el mismo script
# vale para cualquier servidor y se actualiza sin tocar la configuracion del cliente.
#   Formato:  etiqueta|url|codigos aceptables
#   Ejemplo:  Web de gestion (cliente)|https://web.ejemplo.com/|200,302
URLS=()
CONF_URLS="/etc/secwatch/urls.conf"
if [ -r "$CONF_URLS" ]; then
  while IFS= read -r linea; do
    case "$linea" in ''|\#*) continue;; esac
    URLS+=("$linea")
  done < "$CONF_URLS"
fi

avisar() {
  local texto="$1"
  [ -r "$CONF" ] || { log "SIN CONFIG TELEGRAM: $texto"; return; }
  # shellcheck disable=SC1090
  . "$CONF"
  curl -s --max-time 20 -X POST \
    -K <(printf 'url = "https://api.telegram.org/bot%s/sendMessage"\n' "$BOT_TOKEN") \
    --data-urlencode "chat_id=${CHAT_ID}" \
    --data-urlencode "text=${texto}" >/dev/null 2>&1
  log "AVISO ENVIADO: $(echo "$texto" | head -1)"
}

# Devuelve 0 si esta sano. Lleva la cuenta de fallos seguidos para no avisar por un pico,
# y solo avisa en el CAMBIO de estado (sano->caido y caido->sano).
revisar() {
  local clave="$1" etiqueta="$2" sano="$3" detalle="$4"
  local f_cont="$BASE/${clave}.fallos" f_est="$BASE/${clave}.estado"
  local fallos estado_previo
  fallos=$(cat "$f_cont" 2>/dev/null || echo 0)
  estado_previo=$(cat "$f_est" 2>/dev/null || echo "ok")

  if [ "$sano" = "si" ]; then
    echo 0 > "$f_cont"
    if [ "$estado_previo" = "caido" ]; then
      echo "ok" > "$f_est"
      avisar "✅ RECUPERADO - ${EQUIPO}

${etiqueta} vuelve a responder.
$(date '+%d/%m %H:%M')"
    else
      echo "ok" > "$f_est"
    fi
  else
    fallos=$((fallos + 1))
    echo "$fallos" > "$f_cont"
    if [ "$fallos" -ge "$FALLOS_PARA_AVISAR" ] && [ "$estado_previo" != "caido" ]; then
      echo "caido" > "$f_est"
      avisar "🔴 SERVICIO CAIDO - ${EQUIPO}

${etiqueta}
${detalle}

Comprobado ${fallos} veces seguidas.
$(date '+%d/%m %H:%M')
Revisar: docker service ls"
    fi
  fi
}

# ---------- 1) servicios de Docker Swarm con replicas incompletas ----------
if command -v docker >/dev/null 2>&1; then
  while read -r nombre replicas; do
    [ -z "$nombre" ] && continue
    quiere="${replicas#*/}"; tiene="${replicas%/*}"
    clave="svc_$(echo "$nombre" | tr -c 'a-zA-Z0-9' '_')"
    # 0/0 = servicio escalado a cero A PROPOSITO (parado por quien lo administra).
    # No es una caida y avisar de ello es un falso positivo: se detecto el 31-08-2026 en
    # un servidor donde 'app_n8n' esta deliberadamente a 0/0, y el vigilante mando una
    # alerta roja en su primera hora de vida. Una alerta que grita en falso se acaba
    # ignorando, y entonces no sirve para el dia que grite de verdad.
    if [ "$quiere" = "0" ]; then
      revisar "$clave" "Servicio ${nombre}" "si" ""
    elif [ "$tiene" = "$quiere" ] && [ "$tiene" != "0" ]; then
      revisar "$clave" "Servicio ${nombre}" "si" ""
    else
      revisar "$clave" "Servicio ${nombre}" "no" "Replicas: ${replicas} (deberia ser ${quiere}/${quiere})"
    fi
  done < <(docker service ls --format '{{.Name}} {{.Replicas}}' 2>/dev/null)
fi

# ---------- 1 bis) contenedores de Docker Compose (maquinas SIN Swarm) ----------
# No todos los servidores usan Swarm: un servidor de IPTV de un hotel levanta sus cuatro
# contenedores (tvheadend, panel, kiosko) con docker compose, y el bloque de arriba no ve
# NADA ahi. Sin esto, instalar el vigilante en esa maquina seria teatro: no detectaria que
# la television lleva caida desde ayer.
# Se filtra por la etiqueta de compose a proposito: en Swarm los contenedores llevan
# etiquetas com.docker.swarm.* y ya los cubre el bloque anterior, asi que no se duplican.
if command -v docker >/dev/null 2>&1; then
  while IFS=$'\t' read -r cnombre cestado; do
    [ -z "$cnombre" ] && continue
    clave="cnt_$(echo "$cnombre" | tr -c 'a-zA-Z0-9' '_')"
    if [ "$cestado" = "running" ]; then
      revisar "$clave" "Contenedor ${cnombre}" "si" ""
    else
      revisar "$clave" "Contenedor ${cnombre}" "no" "Estado: ${cestado} (deberia estar running)"
    fi
  done < <(docker ps -a --filter 'label=com.docker.compose.project' \
             --format '{{.Names}}\t{{.State}}' 2>/dev/null)
fi

# ---------- 2) webs publicas ----------
for fila in "${URLS[@]}"; do
  IFS='|' read -r etiqueta url aceptables <<< "$fila"
  clave="url_$(echo "$etiqueta" | tr -c 'a-zA-Z0-9' '_')"
  codigo=$(curl -s -o /dev/null -w '%{http_code}' --max-time 25 "$url" 2>/dev/null || echo "000")
  if echo ",${aceptables}," | grep -q ",${codigo},"; then
    revisar "$clave" "${etiqueta}" "si" ""
  else
    revisar "$clave" "${etiqueta}" "no" "Responde HTTP ${codigo} (esperado: ${aceptables})
${url}"
  fi
done

log "ronda completada"
exit 0
