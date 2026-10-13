#!/bin/bash
# =============================================================================
# identify_ips.sh - Identifica DE QUIEN son las IPs que acceden al servidor
# =============================================================================
# Ejecutar EN LA MAQUINA LOCAL (necesita salida a internet para RDAP).
#   ./identify_ips.sh root@1.2.3.4
#
# Por que existe: sin esto se confunde al programador que teletrabaja con un
# atacante. Un rango identificado ahorra horas de angustia y evita el error
# contrario (dar por bueno un acceso que no lo es).
#
# NOTA: `whois` no suele estar instalado; RDAP por HTTPS funciona siempre.
# =============================================================================

set -uo pipefail
TARGET="${1:?Uso: identify_ips.sh root@host}"

echo "=== Recopilando IPs con acceso CORRECTO en $TARGET ==="
IPS=$(ssh "$TARGET" 'journalctl -u ssh --no-pager 2>/dev/null | grep "Accepted" \
      | grep -oE "from [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | awk "{print \$2}" | sort -u')

if [ -z "$IPS" ]; then echo "Sin datos de acceso en el journal."; exit 0; fi

echo "$IPS" | wc -l | xargs echo "  IPs distintas encontradas:"
echo
printf "%-17s %-11s %-9s %s\n" "IP" "ACCESOS" "PAIS" "OPERADOR"
printf "%-17s %-11s %-9s %s\n" "-----------------" "-----------" "---------" "--------------------"

for ip in $IPS; do
    n=$(ssh "$TARGET" "journalctl -u ssh --no-pager 2>/dev/null | grep -c 'Accepted.*from $ip '" 2>/dev/null || echo "?")
    info=$(timeout 12 curl -sL -H "Accept: application/json" \
        "https://rdap.arin.net/registry/ip/$ip" 2>/dev/null \
        | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    ents=[v[3] for e in d.get('entities',[]) for v in e.get('vcardArray',[None,[]])[1] if v[0]=='fn']
    print((d.get('country') or '--') + '|' + (ents[0] if ents else (d.get('name') or '?'))[:38])
except Exception: print('--|(sin datos)')" 2>/dev/null)
    printf "%-17s %-11s %-9s %s\n" "$ip" "$n" "${info%%|*}" "${info#*|}"
done

cat <<'GUIA'

--- COMO INTERPRETAR ---
  ISP residencial/movil del pais (Starlink, Vodafone, Movistar...)
      -> casi siempre personal propio teletrabajando. CONFIRMARLO igual.
      -> OJO: Starlink y las moviles usan CGNAT: la IP cambia sola.
         Un mismo trabajador aparece con VARIOS rangos /16 distintos.
  Cloud (AWS, Azure, GCP, DigitalOcean, Hetzner, OVH)
      -> NO es un domicilio. O es una VPN comercial, un script propio,
         o alguien validando credenciales robadas. Investigar SIEMPRE.
  Pais que no encaja con el negocio
      -> investigar aunque los accesos hayan sido correctos.

--- SIGUIENTE PASO ---
  Para una IP dudosa, medir CUANTO duro la sesion:
    journalctl -u ssh --no-pager | grep -A5 "Accepted.*<IP>"
  Sesion de 1-3 segundos = automatizada (script o validacion de credencial),
  NO una persona. Una persona explorando deja minutos y comandos.
GUIA
