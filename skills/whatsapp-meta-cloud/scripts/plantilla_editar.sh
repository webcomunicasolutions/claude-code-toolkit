#!/usr/bin/env bash
# Edita una plantilla existente (por su template_id). Solo se pueden editar
# plantillas en estado APPROVED/REJECTED/PAUSED, y campos limitados (components,
# y category si no está en uso). Reentra a revisión. Ver references/plantillas.md.
# Uso: ./plantilla_editar.sh <template_id> <componentes.json>
#   componentes.json = { "category": "...", "components": [...] }
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
_wa_need_token
id="${1:?Uso: $0 <template_id> <componentes.json>}"
f="${2:?falta el JSON con components}"
[[ -f "$f" ]] || { echo "✗ no existe $f"; exit 1; }
curl -s -K <(wa_cfg) -X POST "$GRAPH/$id" -H "Content-Type: application/json" -d @"$f" | jq .
