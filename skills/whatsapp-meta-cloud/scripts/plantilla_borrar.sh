#!/usr/bin/env bash
# Borra una plantilla. Por nombre borra TODOS sus idiomas; con id, solo esa versión.
# Uso: ./plantilla_borrar.sh <nombre> [template_id]
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
_wa_need_waba
name="${1:?Uso: $0 <nombre> [template_id]}"
id="${2:-}"
q="name=$name"
[[ -n "$id" ]] && q="hsm_id=$id&name=$name"
curl -s -K <(wa_cfg) -X DELETE "$GRAPH/$WA_WABA_ID/message_templates?$q" | jq .
