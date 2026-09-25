#!/usr/bin/env bash
# Crea (o reenvía a revisión) plantillas desde ficheros JSON.
# Uso: ./plantilla_crear.sh plantilla.json [otra.json ...]
# El JSON sigue el formato de components de Meta (ver references/plantillas.md).
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
_wa_need_waba
[[ $# -gt 0 ]] || { echo "Uso: $0 plantilla.json [...]"; exit 1; }
for f in "$@"; do
  [[ -f "$f" ]] || { echo "✗ no existe $f"; continue; }
  name="$(jq -r '.name' "$f")"
  resp="$(curl -s -K <(wa_cfg) -X POST "$GRAPH/$WA_WABA_ID/message_templates" \
    -H "Content-Type: application/json" -d @"$f")"
  if echo "$resp" | jq -e '.id' >/dev/null 2>&1; then
    echo "✓ $name  id=$(echo "$resp" | jq -r .id)  status=$(echo "$resp" | jq -r .status)"
  else
    echo "✗ $name  ERROR: $(echo "$resp" | jq -r '.error.error_user_msg // .error.message // .')"
  fi
done
