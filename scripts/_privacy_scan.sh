#!/bin/bash
# _privacy_scan.sh — escanea rutas del kit PUBLICO buscando datos personales o de clientes.
# Uso: bash scripts/_privacy_scan.sh <ruta> [<ruta>...]   (sin argumentos: todo el kit)
# Salida: fichero:linea:coincidencia. Vacio = limpio. Revisar cada coincidencia a mano (hay falsos positivos).
# NO se instala: es herramienta interna del mantenimiento del kit.
cd "$(dirname "$0")/.." || exit 1
paths=("$@"); [ ${#paths[@]} -eq 0 ] && paths=(.)

# Nombres de personas, empresa, clientes y dominios propios (case-insensitive)
NAMES='yeye|juan ?jos[eé]|s[aá]nchez bernal|webcomunica|optimizaconia|actaroo|damelacarta|olivia|i[nñ]aki|serrano|monda\b|carmen|catalina|benjam[ií]n|acrisal|alfaanimal|alfa ?animal|alumigonza|aluminios ?gonz|gonzaga|trujillano|doblea|drogueria|rodriguez|fervet|fixmemalaga|framancha|harinera|molino|guaro|lemar|indeco|logistransol|moncayo|luis ?rosa|mancomunidad|marauto|med_?homes|mediterranean ?homes|mondaglass|rogoluma|urbaneja|blackshaw|castillo ?de ?monda|ayuntamiento|co[ií]n\b|zadarma|manhattan|surdist|preference\.com|prefsuite|prefgest|gesfac|gestfacturas|gestorvet|lucushost|yhnmlz|wgwebcomunica|bonelacoin|prevesalud|ruiz ?urbano'

# Patrones de datos sensibles
PAT='[0-9]{8}[A-HJ-NP-TV-Z]\b|\b[A-HJ-NP-SUVW][0-9]{7}[0-9A-J]\b|\bES[0-9]{2}[ ]?[0-9]{4}|\b[6789][0-9]{2}[ .]?[0-9]{2,3}[ .]?[0-9]{2,3}[ .]?[0-9]{0,3}\b|\b([0-9]{1,3}\.){3}[0-9]{1,3}\b|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[a-z]{2,}|sk_[A-Za-z0-9]{20,}|BEGIN [A-Z ]*PRIVATE KEY|Bearer [A-Za-z0-9_.-]{20,}|xi-api-key: *[a-f0-9]{20,}|[0-9]{9,10}:AA[A-Za-z0-9_-]{30,}'

grep -rInE -i --exclude-dir=.git --exclude-dir=_pendiente_borrado --exclude=_privacy_scan.sh \
  --exclude='*.ttf' --exclude='*.otf' --exclude='*.woff*' --exclude='LICENSE*' --exclude='OFL*' \
  -o "$NAMES" "${paths[@]}" | sed 's/^/NOMBRE: /'
grep -rInE --exclude-dir=.git --exclude-dir=_pendiente_borrado --exclude=_privacy_scan.sh \
  --exclude='*.ttf' --exclude='*.otf' --exclude='*.woff*' --exclude='LICENSE*' --exclude='OFL*' \
  -o "$PAT" "${paths[@]}" | grep -v -E '127\.0\.0\.1|0\.0\.0\.0|192\.168\.1\.(1|100)\b|10\.0\.0\.1\b|example\.(com|org)|@anthropic\.com|noreply@|user@|you@|tu@|ejemplo' | sed 's/^/DATO: /'
exit 0
