#!/usr/bin/env bash
# Lista los números de teléfono del WABA: display, nombre verificado, calidad,
# estado de verificación y su phone_number_id (el que hace falta para enviar).
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
_wa_need_waba
curl -s -K <(wa_cfg) \
  "$GRAPH/$WA_WABA_ID/phone_numbers?fields=display_phone_number,verified_name,quality_rating,code_verification_status,platform_type,id&limit=50" \
  | jq -r '.data[]? | "\(.display_phone_number)  \(.verified_name)  q=\(.quality_rating)  verif=\(.code_verification_status)  phone_id=\(.id)"'
