#!/bin/bash
# =============================================================================
# security_watch.sh - Vigilancia de seguridad del servidor Ubuntu
# =============================================================================
# PRINCIPIO DE DISENO (leccion falsas alarmas 2026-07-19):
#   Este script NO informa de ESTADO, informa de CAMBIOS contra un baseline.
#   Un vigilante que dice "hay 2 claves SSH" todos los dias acaba ignorandose.
#   Este solo habla cuando algo CAMBIA. Silencio = todo igual que ayer.
#
#   Tras avisar de un cambio, el baseline se ACTUALIZA para no repetir la misma
#   alerta cada hora (ese fue exactamente el bug de la cola de emails en julio).
#   El historico completo queda en $LOG aunque el aviso solo se mande una vez.
#
# Frecuencia: cada hora (cron). Latido semanal: lunes 09:00.
# Creado: 2026-07-27
# =============================================================================

set -uo pipefail

BASE="/var/lib/secwatch"
CONF="/etc/secwatch/telegram.conf"
LOG="/var/log/security_watch.log"
HOST=$(hostname)

mkdir -p "$BASE" && chmod 700 "$BASE"

# ---- Config Telegram (fichero 600, NUNCA hardcodear el token aqui) ----------
if [ -r "$CONF" ]; then
    # shellcheck disable=SC1090
    . "$CONF"
else
    echo "$(date '+%F %T') ERROR: falta $CONF" >> "$LOG"
    exit 1
fi

FINDINGS=""
log()     { echo "$(date '+%F %T') $*" >> "$LOG"; }
finding() { FINDINGS="${FINDINGS}$1"$'\n'; log "HALLAZGO: $1"; }

send_telegram() {
    local msg="$1"
    for cid in $CHAT_ID; do
        curl -s -m 20 -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
            -d "chat_id=${cid}" \
            -d "parse_mode=HTML" \
            --data-urlencode "text=${msg}" > /dev/null
    done
}

# -----------------------------------------------------------------------------
# check_hash <nombre> <descripcion> <comando-que-produce-el-estado>
#   Compara el hash del estado actual con el guardado. Si cambia: avisa y
#   guarda el nuevo (para no repetir). Primera vez: solo guarda, sin avisar.
# -----------------------------------------------------------------------------
check_hash() {
    local name="$1" desc="$2" cmd="$3"
    local cur old f="$BASE/$name.hash" d="$BASE/$name.data"

    cur=$(eval "$cmd" 2>/dev/null)
    local curhash; curhash=$(printf '%s' "$cur" | sha256sum | cut -d' ' -f1)

    if [ ! -f "$f" ]; then
        printf '%s' "$curhash" > "$f"; printf '%s\n' "$cur" > "$d"
        log "baseline inicial creado: $name"
        return
    fi

    old=$(cat "$f")
    if [ "$curhash" != "$old" ]; then
        local diff_out
        diff_out=$(diff <(cat "$d") <(printf '%s\n' "$cur") 2>/dev/null \
                   | grep -E '^[<>]' | head -8)
        finding "<b>${desc}</b>%0A<pre>${diff_out}</pre>"
        printf '%s' "$curhash" > "$f"; printf '%s\n' "$cur" > "$d"
    fi
}

# =============================================================================
# 1. CLAVES SSH AUTORIZADAS  <- el paso 1 del manual de cualquier intruso
# =============================================================================
check_hash "authkeys" "CLAVES SSH AUTORIZADAS MODIFICADAS" \
    'for f in /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys; do
        [ -f "$f" ] && ssh-keygen -lf "$f" 2>/dev/null | sed "s|^|$f |"
     done'

# =============================================================================
# 2. USUARIOS, UID 0 Y PRIVILEGIOS SUDO
# =============================================================================
check_hash "users" "USUARIOS DEL SISTEMA MODIFICADOS" \
    'awk -F: "{print \$1\":\"\$3\":\"\$7}" /etc/passwd | sort'

check_hash "sudoers" "REGLAS SUDO MODIFICADAS" \
    'cat /etc/sudoers /etc/sudoers.d/* 2>/dev/null | grep -vE "^\s*#|^\s*$" | sort'

UID0=$(awk -F: '$3==0{print $1}' /etc/passwd | tr '\n' ' ')
if [ "$(echo "$UID0" | wc -w)" -gt 1 ]; then
    finding "<b>CRITICO: mas de una cuenta con UID 0</b>%0A${UID0}"
fi

# =============================================================================
# 3. PERSISTENCIA: cron, timers, servicios
# =============================================================================
check_hash "cron" "TAREAS CRON MODIFICADAS" \
    'crontab -l 2>/dev/null; cat /etc/cron.d/* 2>/dev/null;
     for u in $(cut -d: -f1 /etc/passwd); do crontab -l -u "$u" 2>/dev/null; done'

check_hash "systemd" "SERVICIOS SYSTEMD HABILITADOS MODIFICADOS" \
    'systemctl list-unit-files --state=enabled --no-pager 2>/dev/null | awk "{print \$1}" | sort'

# =============================================================================
# 4. PUERTOS A LA ESCUCHA  <- backdoor o servicio expuesto sin querer
# =============================================================================
# Puertos que cambian solos y no son un hallazgo (p.ej. tuneles inversos de un RMM
# que suben y bajan con cada PC). Van en /etc/secwatch/ports_ignore.conf, una ERE por
# linea, NUNCA dentro del script (hallazgo 12: lo que cambia por servidor va en config).
#   Ejemplo:  ^127\.0\.0\.1:22[0-9]{3}$
# Sin ese fichero el comportamiento es identico al de siempre.
PORTS_IGNORE=""
if [ -r /etc/secwatch/ports_ignore.conf ]; then
    PORTS_IGNORE=$(grep -vE '^[[:space:]]*(#|$)' /etc/secwatch/ports_ignore.conf | paste -sd'|')
fi
PORTS_CMD='ss -tulpn 2>/dev/null | grep LISTEN | awk "{print \$1, \$5}" | sort -u'
[ -n "$PORTS_IGNORE" ] && PORTS_CMD="$PORTS_CMD | grep -vE '$PORTS_IGNORE'"

check_hash "ports" "PUERTOS A LA ESCUCHA MODIFICADOS" "$PORTS_CMD"

# =============================================================================
# 5. BINARIOS SUID  <- puerta trasera clasica a root
# =============================================================================
# Excluye snapshots de contenedores: cambian con cada reinicio/rebuild de imagen
# y suponen ~76% de los SUID detectados -> alerta falsa garantizada.
check_hash "suid" "FICHEROS SUID MODIFICADOS" \
    'find / -xdev -perm -4000 -type f 2>/dev/null | grep -vE "/var/lib/(containerd|docker)/" | sort'

# =============================================================================
# 6. PROCESOS EJECUTANDOSE DESDE DIRECTORIOS TEMPORALES  <- malware clasico
# =============================================================================
TMPPROC=$(ls -l /proc/*/exe 2>/dev/null | grep -E '/tmp/|/dev/shm|/var/tmp' | head -5)
if [ -n "$TMPPROC" ]; then
    finding "<b>CRITICO: proceso ejecutandose desde directorio temporal</b>%0A<pre>${TMPPROC}</pre>"
fi

# =============================================================================
# 7. LOGINS DESDE RANGOS DESCONOCIDOS
# -----------------------------------------------------------------------------
# Comparamos por /16, NO por IP exacta: un trabajador que entra por Starlink/4G (CGNAT)
# cambia de IP sola. Alertar por IP exacta generaria ruido constante.
# known_nets.txt arranca VACIO: precargarlo ANTES de la 1a ejecucion con los rangos /16
# de ESTE servidor (salida de identify_ips.sh), o alertara de tu propia gente.
# =============================================================================
KNOWN="$BASE/known_nets.txt"
if [ ! -f "$KNOWN" ]; then
    : > "$KNOWN"   # vacio a proposito: un fichero con comentarios contaria como patrones en grep -Ff
    log "known_nets.txt creado VACIO: precargar los rangos conocidos de este servidor"
fi

# Rangos que alertan SIEMPRE aunque figuren como conocidos (cloud sin explicar).
# Sin esto, el auto-aprendizaje normaliza un acceso sospechoso tras la 1a alerta.
ALERT_ALWAYS="$BASE/alert_always.txt"
[ -f "$ALERT_ALWAYS" ] || : > "$ALERT_ALWAYS"

VISTAS=$(journalctl -u ssh --since "70 minutes ago" --no-pager 2>/dev/null \
    | grep "Accepted" \
    | grep -oE 'from [0-9]+\.[0-9]+\.[0-9]+' | awk '{print $2}' | sort -u)

NEWNETS=$(printf '%s\n' "$VISTAS" | grep -vFf "$KNOWN" 2>/dev/null || true)

if [ -s "$ALERT_ALWAYS" ]; then
    REINCIDENTES=$(printf '%s\n' "$VISTAS" | grep -Fxf "$ALERT_ALWAYS" 2>/dev/null || true)
    for net in $REINCIDENTES; do
        det=$(journalctl -u ssh --since "70 minutes ago" --no-pager 2>/dev/null \
            | grep "Accepted" | grep "$net" | tail -3 | sed -E 's/.*sshd\[[0-9]+\]: //')
        finding "<b>ACCESO DESDE RANGO CLOUD BAJO VIGILANCIA: ${net}.x</b>%0A<pre>${det}</pre>%0A<i>Rango sin explicar. NO se auto-aprende.</i>"
    done
fi

if [ -n "$NEWNETS" ]; then
    for net in $NEWNETS; do
        detalle=$(journalctl -u ssh --since "70 minutes ago" --no-pager 2>/dev/null \
            | grep "Accepted" | grep "$net" | tail -3 | sed -E 's/.*sshd\[[0-9]+\]: //')
        finding "<b>LOGIN DESDE RANGO DESCONOCIDO: ${net}.x</b>%0A<pre>${detalle}</pre>"
        grep -qxF "$net" "$ALERT_ALWAYS" 2>/dev/null || echo "$net" >> "$KNOWN"  # aprende, salvo vigilados
    done
fi

# =============================================================================
# 8. LOGIN DE ROOT POR CONTRASENA DESDE RANGO DESCONOCIDO
#    (los de rangos conocidos se resumen en el latido semanal, no alertan)
# =============================================================================
ROOTPW=$(journalctl -u ssh --since "70 minutes ago" --no-pager 2>/dev/null \
    | grep "Accepted password for root" \
    | grep -vFf "$KNOWN" | tail -3 | sed -E 's/.*sshd\[[0-9]+\]: //' || true)
if [ -n "$ROOTPW" ]; then
    finding "<b>ROOT ENTRO POR CONTRASENA DESDE RANGO DESCONOCIDO</b>%0A<pre>${ROOTPW}</pre>"
fi

# =============================================================================
# 8b. ACCESOS A PANELES DE ADMINISTRACION DESDE RANGOS DESCONOCIDOS
# -----------------------------------------------------------------------------
# Requiere reglas iptables LOG con prefijo PANEL<puerto>. Instalarlas asi
# (registran, NO bloquean; el rate limit evita llenar el disco en un escaneo):
#   iptables -I DOCKER-USER -p tcp --dport 3000 -m conntrack --ctstate NEW \
#            -m limit --limit 20/min -j LOG --log-prefix "PANEL3000 "
#   iptables -I INPUT       -p tcp --dport 10086 -m conntrack --ctstate NEW \
#            -m limit --limit 20/min -j LOG --log-prefix "PANEL10086 "
# Para puertos publicados por Docker la regla DEBE ir en DOCKER-USER: UFW no
# filtra el trafico de Docker (ver references/hallazgos.md).
# =============================================================================
# Auto-reparacion: las reglas iptables NO sobreviven a un reinicio. En vez de
# depender de iptables-persistent, el vigilante las recrea si faltan (idempotente
# gracias a -C). Asi la vigilancia de paneles se restaura sola tras un reboot.
PANELES_VIGILADOS="${PANELES_VIGILADOS:-3000:DOCKER-USER 10086:INPUT}"
for entry in $PANELES_VIGILADOS; do
    p="${entry%%:*}"; chain="${entry##*:}"
    if ! iptables -C "$chain" -p tcp --dport "$p" -m conntrack --ctstate NEW \
         -m limit --limit 20/min -j LOG --log-prefix "PANEL${p} " 2>/dev/null; then
        iptables -I "$chain" -p tcp --dport "$p" -m conntrack --ctstate NEW \
                 -m limit --limit 20/min -j LOG --log-prefix "PANEL${p} " 2>/dev/null \
            && log "regla LOG recreada para el puerto $p en $chain (tras reinicio?)"
    fi
done

PANEL_HITS=$(journalctl -k --since "70 minutes ago" --no-pager 2>/dev/null \
    | grep -oE 'PANEL[0-9]+ .*SRC=[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' \
    | sed -E 's/(PANEL[0-9]+).*SRC=([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+/\1 \2/' \
    | sort -u || true)

if [ -n "$PANEL_HITS" ]; then
    PANEL_DESCONOCIDOS=$(printf '%s\n' "$PANEL_HITS" | while read -r panel net; do
        grep -qxF "$net" "$KNOWN" 2>/dev/null || echo "  ${panel} <- ${net}.x"
    done)
    if [ -n "$PANEL_DESCONOCIDOS" ]; then
        finding "<b>ACCESO A PANEL DE ADMINISTRACION DESDE RANGO DESCONOCIDO</b>%0A<pre>${PANEL_DESCONOCIDOS}</pre>%0A<i>Estos paneles dan control total. Valorar cerrarlos al exterior.</i>"
    fi
fi

# =============================================================================
# 9. FUERZA BRUTA ANOMALA (umbral alto: el ruido de fondo es ~80/dia)
# =============================================================================
BRUTE=$(journalctl -u ssh --since "70 minutes ago" --no-pager 2>/dev/null \
    | grep -cE "Failed password|Invalid user" || true)
if [ "${BRUTE:-0}" -gt 300 ]; then
    finding "<b>PICO DE FUERZA BRUTA: ${BRUTE} intentos en 1h</b>%0A(ruido normal: ~20-40/h)"
fi

# =============================================================================
# ENVIO
# =============================================================================
if [ -n "$FINDINGS" ]; then
    send_telegram "🚨 <b>SEGURIDAD - ${HOST}</b>%0A$(date '+%d/%m %H:%M')%0A%0A${FINDINGS}%0A<i>Revisar: ${LOG}</i>"
    log "ALERTA ENVIADA"
else
    log "OK - sin cambios"
fi

# -----------------------------------------------------------------------------
# LATIDO SEMANAL: lunes a partir de las 09:00, UNA sola vez por semana.
#
# Guardia por semana ISO (fichero marcador), NO por hora: sin esto el latido se
# reenvia en cada ejecucion de esa hora, y si el cron cambia de frecuencia se
# duplica o se pierde. El marcador lo hace idempotente.
#
# NO se trunca el log: el vigilante jamas debe destruir su propia evidencia.
# Los contadores se calculan desde la fecha del ultimo latido.
# -----------------------------------------------------------------------------
HB_FILE="$BASE/last_heartbeat"
CUR_WEEK=$(date +%G-W%V)
LAST_WEEK=$(cat "$HB_FILE" 2>/dev/null || echo "")

if [ "$(date +%u)" = "1" ] && [ "$(date +%H)" -ge 9 ] && [ "$CUR_WEEK" != "$LAST_WEEK" ]; then
    SEM_OK=$(grep -c "OK - sin cambios" "$LOG" 2>/dev/null || echo 0)
    SEM_AL=$(grep -c "ALERTA ENVIADA" "$LOG" 2>/dev/null || echo 0)
    ROOT_PW=$(journalctl -u ssh --since "7 days ago" --no-pager 2>/dev/null \
        | grep -c "Accepted password for root" || echo 0)
    NUEVOS=$(journalctl -u ssh --since "7 days ago" --no-pager 2>/dev/null \
        | grep "Accepted" | grep -oE 'from [0-9]+\.[0-9]+\.[0-9]+' | awk '{print $2}' \
        | sort -u | grep -vFf "$KNOWN" | wc -l || echo 0)

    send_telegram "OK <b>Vigilante seguridad - ${HOST}</b>%0AResumen semanal $(date '+%d/%m')%0A%0A\
Chequeos sin cambios: ${SEM_OK}%0AAlertas enviadas: ${SEM_AL}%0ALogins root por contrasena (7d): ${ROOT_PW}%0A\
Rangos nuevos detectados: ${NUEVOS}%0A%0A<i>El vigilante esta activo.</i>"

    printf '%s' "$CUR_WEEK" > "$HB_FILE"
    log "latido semanal enviado ($CUR_WEEK)"
fi

# ---- Rotacion del log (sin perder historico: se conserva el .1) --------------
if [ -f "$LOG" ] && [ "$(stat -c %s "$LOG" 2>/dev/null || echo 0)" -gt 2000000 ]; then
    mv "$LOG" "${LOG}.1"
    log "log rotado (>2MB)"
fi

exit 0
