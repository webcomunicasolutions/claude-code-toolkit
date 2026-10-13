#!/bin/bash
# barrido_fugas_web.sh - Busca ficheros de configuracion y repositorios servidos por error
#                        en TODOS los dominios propios. Solo lectura: hace peticiones GET.
#
# POR QUE EXISTE (incidente real, 2026-09-01):
# el .env de una centralita (aplicacion PHP) vivia dentro del docroot y fue DESCARGADO desde internet.
# Lo encontro l9scan (leakix.net), un escaner PUBLICO que ademas indexa y publica lo que halla,
# a las HORAS de subirse el fichero. Dentro iban el password de la BD, el secreto TOTP del 2FA,
# la clave que cifra los passwords de toda la flota y dos tokens de API.
# El barrido posterior de 73 dominios encontro CUATRO servicios mas igual de expuestos.
# Aquel barrido se hizo A MANO y no quedo nada reutilizable: este script es esa pieza que faltaba.
#
# LA TRAMPA QUE HACE FALTA ESQUIVAR (y por la que un 'curl -o /dev/null -w %{http_code}' NO vale):
# los paneles de EasyPanel, n8n y cualquier SPA responden 200 con su HTML a CUALQUIER ruta
# inventada. En el barrido de 2026-09-01, de 16 respuestas 200, DOCE eran falsos positivos.
# Por eso aqui el veredicto lo decide el CONTENIDO, nunca el codigo HTTP.
#
# USO
#   barrido_fugas_web.sh dominios.txt              # un dominio por linea (con o sin https://)
#   barrido_fugas_web.sh -d ejemplo.com            # un dominio suelto
#   barrido_fugas_web.sh dominios.txt -o informe.md
#   ... -j 8        peticiones en paralelo (por defecto 6)
#   ... -t 12       timeout por peticion en segundos (por defecto 10)
#
# SALIDA: tabla por pantalla y, con -o, un informe en Markdown.
# Codigo de salida: 0 si no hay fugas, 1 si hay alguna FUGA, 2 por error de uso.

set -uo pipefail
export LC_ALL=C

RUTAS=(
    ".env" ".env.local" ".env.bak" ".env.ejemplo" ".env.example" ".env.save" ".env.old"
    ".git/HEAD" ".git/config"
    "config.php.bak" "conexion.php.bak" "wp-config.php.bak"
    "composer.json" "package.json"
    ".DS_Store" ".htpasswd"
    "backup.sql" "dump.sql" "database.sql"
)

TIEMPO=10
HILOS=6
INFORME=""
DOMINIOS=()

while [ $# -gt 0 ]; do
    case "$1" in
        -d) DOMINIOS+=("$2"); shift 2 ;;
        -o) INFORME="$2"; shift 2 ;;
        -j) HILOS="$2"; shift 2 ;;
        -t) TIEMPO="$2"; shift 2 ;;
        -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
        -*) echo "opcion desconocida: $1" >&2; exit 2 ;;
        *)  [ -r "$1" ] || { echo "no puedo leer '$1'" >&2; exit 2; }
            while IFS= read -r l; do
                l="${l%%#*}"; l="$(echo "$l" | tr -d '[:space:]')"
                [ -n "$l" ] && DOMINIOS+=("$l")
            done < "$1"
            shift ;;
    esac
done
[ ${#DOMINIOS[@]} -gt 0 ] || { echo "sin dominios. Uso: $0 dominios.txt | -d dominio" >&2; exit 2; }

TRABAJO=$(mktemp -d); trap 'rm -rf "$TRABAJO"' EXIT

# Decide si el cuerpo es una FUGA de verdad o la SPA respondiendo a cualquier cosa.
# Se le pasa la ruta pedida y el fichero con el cuerpo; imprime FUGA|<que es> o FALSO|<por que>.
veredicto() {
    local ruta="$1" cuerpo="$2"
    local cabeza; cabeza=$(head -c 600 "$cuerpo" 2>/dev/null | tr -d '\000')
    # Cualquier cosa que empiece por HTML es la aplicacion respondiendo, no el fichero
    if echo "$cabeza" | grep -qiE '^\s*(<!doctype|<html|<\?xml|<svg)'; then
        echo "FALSO|responde HTML (SPA/panel), no el fichero"; return
    fi
    if [ ! -s "$cuerpo" ]; then echo "FALSO|cuerpo vacio"; return; fi
    case "$ruta" in
        .git/HEAD)
            grep -qE '^ref:[[:space:]]+refs/' "$cuerpo" \
                && echo "FUGA|repositorio git servido (permite reconstruir el codigo y su historial)" \
                || echo "FALSO|no parece un HEAD de git" ;;
        .git/config)
            grep -qE '^\[core\]|repositoryformatversion' "$cuerpo" \
                && echo "FUGA|configuracion de git servida (puede llevar la URL del remoto con credenciales)" \
                || echo "FALSO|no parece un config de git" ;;
        composer.json|package.json)
            grep -qE '^\s*\{' "$cuerpo" \
                && echo "AVISO|manifiesto de dependencias servido (revela version y librerias)" \
                || echo "FALSO|no es JSON" ;;
        *.sql|backup.sql|dump.sql|database.sql)
            grep -qiE 'CREATE TABLE|INSERT INTO|DROP TABLE' "$cuerpo" \
                && echo "FUGA|volcado de base de datos descargable" \
                || echo "FALSO|no parece un dump" ;;
        .htpasswd)
            grep -qE '^[^:]+:\$?[0-9a-zA-Z./$]+' "$cuerpo" \
                && echo "FUGA|hashes de contrasenas servidos" || echo "FALSO|no parece htpasswd" ;;
        .DS_Store)
            head -c 8 "$cuerpo" | grep -q "Bud1" \
                && echo "AVISO|.DS_Store servido (lista nombres de fichero)" || echo "FALSO|no es un .DS_Store" ;;
        *)
            # Ficheros de entorno y backups de config: se buscan lineas CLAVE=VALOR
            local n; n=$(grep -cE '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]{2,}[[:space:]]*=' "$cuerpo" 2>/dev/null || echo 0)
            if [ "$n" -ge 2 ]; then
                local sensibles; sensibles=$(grep -oiE '^[[:space:]]*[A-Za-z_]*(PASS|PASSWORD|SECRET|TOKEN|KEY|APIKEY|DSN|DB_)[A-Za-z0-9_]*' "$cuerpo" \
                    | tr -d ' ' | sort -u | head -6 | paste -sd, -)
                if [ -n "$sensibles" ]; then echo "FUGA|CREDENCIALES: $sensibles"
                else echo "FUGA|$n variables de entorno servidas"; fi
            elif grep -qiE '<\?php' "$cuerpo"; then
                echo "FUGA|codigo PHP servido en claro (no ejecutado)"
            else
                echo "FALSO|contenido no reconocible como fuga"
            fi ;;
    esac
}

sondear() {   # sondear <dominio>  -> escribe lineas "estado|dominio|ruta|http|detalle" en $TRABAJO
    local dom="$1" base
    case "$dom" in https://*|http://*) base="$dom" ;; *) base="https://$dom" ;; esac
    base="${base%/}"
    local salida="$TRABAJO/$(echo "$base" | tr -c 'a-zA-Z0-9' '_')"

    # ¿Responde el dominio? Si no, no tiene sentido sondear 17 rutas contra el
    local vivo; vivo=$(curl -s -o /dev/null -w '%{http_code}' -m "$TIEMPO" -L --insecure "$base/" 2>/dev/null)
    if [ "$vivo" = "000" ]; then echo "MUERTO|$base|-|000|no responde" >> "$salida"; return; fi

    for ruta in "${RUTAS[@]}"; do
        local cuerpo="$TRABAJO/c$$_$RANDOM"
        local http; http=$(curl -s -o "$cuerpo" -w '%{http_code}' -m "$TIEMPO" --insecure "$base/$ruta" 2>/dev/null)
        if [ "$http" = "200" ]; then
            local v; v=$(veredicto "$ruta" "$cuerpo")
            echo "${v%%|*}|$base|$ruta|$http|${v#*|}" >> "$salida"
        fi
        rm -f "$cuerpo"
    done
    [ -f "$salida" ] || echo "LIMPIO|$base|-|$vivo|todas las rutas bloqueadas" >> "$salida"
}
export -f sondear veredicto
export TRABAJO TIEMPO
export RUTAS_SERIALIZADAS="${RUTAS[*]}"

echo "Barrido de fugas: ${#DOMINIOS[@]} dominios x ${#RUTAS[@]} rutas (${HILOS} en paralelo)"
echo
printf '%s\n' "${DOMINIOS[@]}" | xargs -P "$HILOS" -I{} bash -c 'RUTAS=($RUTAS_SERIALIZADAS); sondear "$@"' _ {}

RES="$TRABAJO/_todo"; cat "$TRABAJO"/* 2>/dev/null | grep -v '^$' > "$RES" || true
# OJO: 'grep -c ... || echo 0' imprime DOS lineas cuando no hay coincidencias
# (grep ya imprime su 0 y ademas sale con codigo 1). Se cuenta con wc -l, que no falla.
contar() { grep -c "^$1|" "$RES" 2>/dev/null | head -1 || true; }
FUGAS=$(grep "^FUGA|" "$RES" 2>/dev/null | wc -l)
AVISOS=$(grep "^AVISO|" "$RES" 2>/dev/null | wc -l)
FALSOS=$(grep "^FALSO|" "$RES" 2>/dev/null | wc -l)
MUERTOS=$(grep "^MUERTO|" "$RES" 2>/dev/null | wc -l)
LIMPIOS=$(grep "^LIMPIO|" "$RES" 2>/dev/null | wc -l)

if [ "$FUGAS" -gt 0 ]; then
    echo "🔴 FUGAS REALES ($FUGAS) — tapar YA y, si el log muestra descargas externas, ROTAR:"
    grep '^FUGA|' "$RES" | while IFS='|' read -r _ d r h det; do printf '   %s/%s\n      -> %s\n' "$d" "$r" "$det"; done
    echo
fi
if [ "$AVISOS" -gt 0 ]; then
    echo "🟡 AVISOS ($AVISOS) — no son credenciales, pero sobran en internet:"
    grep '^AVISO|' "$RES" | while IFS='|' read -r _ d r h det; do printf '   %s/%s  (%s)\n' "$d" "$r" "$det"; done
    echo
fi
if [ "$MUERTOS" -gt 0 ]; then
    echo "⚫ NO RESPONDEN ($MUERTOS) — no se han podido comprobar:"
    grep '^MUERTO|' "$RES" | while IFS='|' read -r _ d _ _ _; do printf '   %s\n' "$d"; done
    echo
fi
echo "Resumen: ${FUGAS} fugas · ${AVISOS} avisos · ${LIMPIOS} limpios · ${FALSOS} respuestas 200 descartadas por contenido · ${MUERTOS} sin respuesta"

if [ -n "$INFORME" ]; then
    {
        echo "# Barrido de fugas web — $(date '+%Y-%m-%d %H:%M')"
        echo
        echo "${#DOMINIOS[@]} dominios sondeados contra ${#RUTAS[@]} rutas sensibles."
        echo "El veredicto lo decide el **contenido**, no el código HTTP: los paneles y las SPA"
        echo "responden 200 con su HTML a cualquier ruta inventada."
        echo
        echo "| Estado | Dominio | Ruta | Qué es |"
        echo "|---|---|---|---|"
        grep -E '^(FUGA|AVISO)\|' "$RES" | sort | while IFS='|' read -r e d r h det; do
            echo "| ${e} | ${d} | \`/${r}\` | ${det} |"
        done
        [ "$FUGAS" -eq 0 ] && [ "$AVISOS" -eq 0 ] && echo "| ✅ | — | — | Sin fugas ni avisos |"
        echo
        echo "**Resumen:** ${FUGAS} fugas · ${AVISOS} avisos · ${LIMPIOS} limpios · ${FALSOS} descartados por contenido · ${MUERTOS} sin respuesta"
        if [ "$MUERTOS" -gt 0 ]; then
            echo; echo "## No respondieron"; grep '^MUERTO|' "$RES" | cut -d'|' -f2 | sed 's/^/- /'
        fi
        echo; echo "## Si hay una fuga"
        echo "1. **Tapar** y verificar con \`curl\` que ya da 403."
        echo "2. **Mirar el log de accesos** buscando peticiones con **200** a ese fichero:"
        echo "   un UA \`l9scan/leakix\`, \`zgrab\` o \`python-requests\` es descarga confirmada."
        echo "3. **Si hubo 200 externo, ROTAR los secretos**: taparlo no basta."
        echo "4. **Causa raíz**: las credenciales van en las *variables de entorno* del servicio,"
        echo "   nunca como fichero en el docroot. El \`.htaccess\` es contención y un redespliegue lo borra."
    } > "$INFORME"
    echo "Informe: $INFORME"
fi

[ "$FUGAS" -gt 0 ] && exit 1 || exit 0
