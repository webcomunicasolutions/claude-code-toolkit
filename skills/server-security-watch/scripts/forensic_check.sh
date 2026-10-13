#!/bin/bash
# =============================================================================
# forensic_check.sh - Chequeo forense de intrusion en servidor Ubuntu
# =============================================================================
# Ejecutar EN el servidor (o via ssh root@host 'bash -s' < forensic_check.sh).
# SOLO LECTURA: no modifica nada.
#
# Responde a: "puede haber alguien dentro que no haya hecho nada todavia?"
# Busca las huellas que un intruso deja aunque no cause danio visible.
# =============================================================================

set -uo pipefail
DIAS="${1:-7}"

sec() { echo; echo "######## $* ########"; }

echo "=========================================================="
echo " CHEQUEO FORENSE - $(hostname) - $(date '+%F %T')"
echo " Ventana de analisis: ultimos $DIAS dias"
echo "=========================================================="

# -----------------------------------------------------------------------------
sec "0. LIMITES DEL ANALISIS (declararlos SIEMPRE en el informe)"
echo "-- ventana real que cubren los logs --"
echo -n "  journal desde: "; journalctl --no-pager 2>/dev/null | head -1 | cut -c1-16
echo -n "  auth.log mas antiguo: "; ls -t /var/log/auth.log* 2>/dev/null | tail -1
echo "-- wtmp/lastlog vivos? (si el mtime es viejo, 'last' NO sirve) --"
stat -c "  %y  %n" /var/log/wtmp /var/log/lastlog 2>/dev/null
echo "-- existe .bash_history por cuenta? (si no, no hay traza de comandos) --"
for h in /root/.bash_history /home/*/.bash_history; do
    [ -e "$h" ] && stat -c "  %y  %n (%s bytes)" "$h" || echo "  NO EXISTE: $h"
done
command -v debsums >/dev/null && echo "  debsums: disponible" || echo "  debsums: NO instalado (integridad no verificable)"

# -----------------------------------------------------------------------------
sec "1. ACCESOS SSH CORRECTOS (por cuenta e IP)"
journalctl -u ssh --since "$DIAS days ago" --no-pager 2>/dev/null \
  | grep "Accepted" | grep -oE "Accepted (publickey|password) for [a-z_]+ from [0-9.]+" \
  | sort | uniq -c | sort -rn | head -25

sec "1b. HISTORICO COMPLETO (todo lo que quede en el journal)"
journalctl -u ssh --no-pager 2>/dev/null | grep "Accepted" \
  | grep -oE "for [a-z_]+ from [0-9.]+" | sort | uniq -c | sort -rn | head -25

sec "2. FUERZA BRUTA (contexto: ~20-40/hora es ruido normal de internet)"
echo -n "  intentos fallidos en $DIAS dias: "
journalctl -u ssh --since "$DIAS days ago" --no-pager 2>/dev/null | grep -cE "Failed password|Invalid user"
echo "  -- top usuarios probados (si son admin/pi/ubuntu = bots, no dirigido) --"
journalctl -u ssh --since "$DIAS days ago" --no-pager 2>/dev/null \
  | grep -oE "Invalid user [a-zA-Z0-9_.-]+" | sort | uniq -c | sort -rn | head -8

# -----------------------------------------------------------------------------
sec "3. CLAVES SSH AUTORIZADAS  <-- el paso 1 del manual de todo intruso"
for f in /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys; do
    [ -f "$f" ] || continue
    echo "-- $f (mtime: $(stat -c %y "$f" | cut -d. -f1)) --"
    ssh-keygen -lf "$f" 2>/dev/null | sed 's/^/    /'
done
echo "-- claves en rutas inesperadas --"
find / -xdev -name "authorized_keys*" -not -path "*/docker/*" -not -path "*/man/*" 2>/dev/null \
  -printf "  %TY-%Tm-%Td  %p\n"

sec "4. USUARIOS Y PRIVILEGIOS"
echo "-- cuentas UID 0 (debe haber SOLO root) --"; awk -F: '$3==0{print "  "$1}' /etc/passwd
echo "-- cuentas con password activa --"; awk -F: '$2!~/^[*!]/ {print "  "$1}' /etc/shadow 2>/dev/null
echo "-- sudoers.d (ojo a NOPASSWD: es root sin pedir nada) --"
grep -rhv "^#\|^$" /etc/sudoers.d/ 2>/dev/null | sed 's/^/  /'
echo "-- grupo sudo --"; getent group sudo | sed 's/^/  /'

# -----------------------------------------------------------------------------
sec "5. PERSISTENCIA: cron, timers, servicios"
echo "-- crontab root --"; crontab -l 2>/dev/null | grep -v "^#" | sed 's/^/  /'
echo "-- crontabs de otros usuarios --"; ls -l /var/spool/cron/crontabs/ 2>/dev/null | tail -n +2 | sed 's/^/  /'
echo "-- /etc/cron.d --"; ls -l --time-style=long-iso /etc/cron.d/ | tail -n +2 | sed 's/^/  /'
echo "-- at --"; atq 2>/dev/null | sed 's/^/  /' || echo "  sin trabajos"
echo "-- servicios systemd creados/modificados en 30d --"
find /etc/systemd/system -name "*.service" -mtime -30 -printf "  %TY-%Tm-%Td  %p\n" 2>/dev/null

sec "6. PROCESOS Y PUERTOS"
echo "-- procesos ejecutandose desde /tmp, /dev/shm, /var/tmp (malware clasico) --"
ls -l /proc/*/exe 2>/dev/null | grep -E "/tmp/|/dev/shm|/var/tmp" | sed 's/^/  /' || echo "  NINGUNO (bien)"
echo "-- puertos a la escucha --"
ss -tulpn 2>/dev/null | grep LISTEN | awk '{print "  "$1,$5,$7}' | sort -u
echo "-- conexiones salientes establecidas (excluye loopback y redes privadas) --"
ss -tunp state established 2>/dev/null | grep -vE "127.0.0.1|::1|10\.|172\.1[6-9]\.|172\.2[0-9]\.|192\.168\." | sed 's/^/  /' | head -15

sec "7. FICHEROS SUID (puerta trasera a root)"
find / -xdev -perm -4000 -type f -mtime -30 2>/dev/null | sed 's/^/  /' || true
echo "  (vacio = ningun SUID nuevo en 30 dias)"

sec "8. CAMBIOS RECIENTES EN /etc Y /root"
find /etc -type f -mtime -"$DIAS" -printf "%TY-%Tm-%Td %TH:%TM  %p\n" 2>/dev/null \
  | grep -vE "easypanel|/etc/letsencrypt|resolv.conf|mtab" | sort -r | head -15 | sed 's/^/  /'
find /root -maxdepth 2 -type f -mtime -"$DIAS" -printf "%TY-%Tm-%Td %TH:%TM  %p\n" 2>/dev/null | sort -r | head -10 | sed 's/^/  /'

sec "9. INTEGRIDAD DE LOGS (manipulacion)"
journalctl --verify 2>&1 | grep -vE "^PASS" | head -5 || true
echo "  (sin FAIL arriba = logs no manipulados)"
ls -l --time-style=long-iso /var/log/auth.log* 2>/dev/null | sed 's/^/  /'

sec "10. FIREWALL Y FAIL2BAN"
ufw status verbose 2>/dev/null | head -20 | sed 's/^/  /'
echo "-- fail2ban --"; fail2ban-client status sshd 2>/dev/null | sed 's/^/  /'

sec "11. PARCHES PENDIENTES"
[ -f /var/run/reboot-required ] && cat /var/run/reboot-required | sed 's/^/  /' || echo "  sin reinicio pendiente"
echo "-- ultimos paquetes actualizados --"
grep -E " upgrade " /var/log/dpkg.log 2>/dev/null | tail -5 | sed 's/^/  /'

# -----------------------------------------------------------------------------
sec "12. SECRETOS EN CLARO (revisar y sacar a un gestor de credenciales)"
echo "-- credenciales visibles en el crontab --"
crontab -l 2>/dev/null | grep -inE "token=|password=|api[_-]?key|secret" | sed -E 's/(token=|password=)[^ &"]*/\1***/gI' | sed 's/^/  /' || echo "  ninguna"
echo "-- credenciales en .bash_history --"
for h in /root/.bash_history /home/*/.bash_history; do
    [ -f "$h" ] || continue
    n=$(grep -icE "\-p[a-z0-9]{8,}|password=|token=" "$h" 2>/dev/null || echo 0)
    [ "$n" -gt 0 ] && echo "  $h: $n lineas con posibles secretos"
done
echo "-- scripts con secretos hardcodeados en /root/scripts --"
grep -rlriE "BOT_TOKEN=|PASSWORD=|API_KEY=" /root/scripts/ 2>/dev/null | sed 's/^/  /' || echo "  ninguno"

echo
echo "=========================================================="
echo " FIN. Interpretacion y falsos positivos: references/hallazgos.md"
echo "=========================================================="
