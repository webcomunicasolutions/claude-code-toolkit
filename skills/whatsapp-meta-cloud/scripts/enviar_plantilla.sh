#!/usr/bin/env bash
# Envía una plantilla APROBADA por Cloud API DIRECTO (no pasa por Chatwoot).
# Teléfono con prefijo país y SIN + (ej 34600111222).
#
# Uso simple (solo parámetros de texto del BODY, en orden {{1}} {{2}} ...):
#   ./enviar_plantilla.sh <telefono> <plantilla> <idioma> [body1] [body2] ...
#
# Uso avanzado (header imagen, botón dinámico, etc.) — pasar components crudos:
#   WA_COMPONENTS='[{"type":"header","parameters":[{"type":"image","image":{"link":"https://..."}}]},
#                   {"type":"body","parameters":[{"type":"text","text":"María"}]},
#                   {"type":"button","sub_type":"url","index":"0","parameters":[{"type":"text","text":"factura.php?id=1"}]}]' \
#   ./enviar_plantilla.sh 34600111222 envio_factura es
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
_wa_need_phone
TO="${1:?telefono (ej 34600111222)}"; TPL="${2:?nombre plantilla}"; LANG="${3:?idioma (es|es_ES|en_US)}"
shift 3 || true

if [[ -n "${WA_COMPONENTS:-}" ]]; then
  COMP=",\"components\":${WA_COMPONENTS}"
elif [[ $# -gt 0 ]]; then
  params=""
  for v in "$@"; do params+="$(jq -Rn --arg v "$v" '{type:"text",text:$v}'),"; done
  COMP=",\"components\":[{\"type\":\"body\",\"parameters\":[${params%,}]}]"
else
  COMP=""
fi

curl -s -K <(wa_cfg) -X POST "$GRAPH/$WA_PHONE_ID/messages" -H "Content-Type: application/json" \
  -d "{\"messaging_product\":\"whatsapp\",\"to\":\"$TO\",\"type\":\"template\",\"template\":{\"name\":\"$TPL\",\"language\":{\"code\":\"$LANG\"}$COMP}}" \
  | jq '{to:(.contacts[0].wa_id // null), id:(.messages[0].id // null), status:(.messages[0].message_status // null), error:(.error.message // null)}'
