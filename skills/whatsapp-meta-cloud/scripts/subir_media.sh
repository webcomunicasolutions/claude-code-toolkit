#!/usr/bin/env bash
# Sube un fichero (imagen/pdf/video/audio) al número y devuelve su media_id,
# para enviarlo luego en mensajes (dentro de ventana 24h) o como cabecera.
# ⚠️ Para el HEADER de una PLANTILLA en su CREACIÓN se necesita el "header_handle"
#    del Resumable Upload API (distinto) — ver references/plantillas.md.
# Uso: ./subir_media.sh <fichero> [mime_type]
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
_wa_need_phone
F="${1:?fichero}"; MIME="${2:-$(file -b --mime-type "$F")}"
[[ -f "$F" ]] || { echo "✗ no existe $F"; exit 1; }
curl -s -K <(wa_cfg) -X POST "$GRAPH/$WA_PHONE_ID/media" \
  -F "messaging_product=whatsapp" -F "type=$MIME" -F "file=@$F;type=$MIME" \
  | jq '{media_id:(.id // null), error:(.error.message // null)}'
