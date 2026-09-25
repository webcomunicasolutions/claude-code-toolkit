#!/usr/bin/env bash
# Lista las plantillas del WABA con su estado (PENDING/APPROVED/REJECTED...).
# Uso: ./plantilla_listar.sh [nombre_a_filtrar]
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
_wa_need_waba
filtro="${1:-}"
curl -s -K <(wa_cfg) \
  "$GRAPH/$WA_WABA_ID/message_templates?fields=name,status,category,language,id&limit=200" \
  | jq -r --arg f "$filtro" \
      '.data[]? | select($f=="" or (.name|test($f))) | "\(.name)  [\(.language)]  \(.category)  -> \(.status)  (id \(.id))"'
