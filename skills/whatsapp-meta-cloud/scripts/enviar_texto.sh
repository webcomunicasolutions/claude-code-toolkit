#!/usr/bin/env bash
# Envía un mensaje de TEXTO libre. ⚠️ Solo funciona DENTRO de la ventana de 24h
# (el cliente te escribió en las últimas 24h). Fuera de ventana usa una plantilla.
# Uso: ./enviar_texto.sh <telefono> "mensaje"
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
_wa_need_phone
TO="${1:?telefono (ej 34600111222)}"; MSG="${2:?mensaje}"
curl -s -K <(wa_cfg) -X POST "$GRAPH/$WA_PHONE_ID/messages" -H "Content-Type: application/json" \
  -d "$(jq -n --arg to "$TO" --arg m "$MSG" \
        '{messaging_product:"whatsapp",recipient_type:"individual",to:$to,type:"text",text:{preview_url:true,body:$m}}')" \
  | jq '{id:(.messages[0].id // null), status:(.messages[0].message_status // null), error:(.error.message // null)}'
