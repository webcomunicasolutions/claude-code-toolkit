#!/usr/bin/env bash
# Librería común para WhatsApp Cloud API (Graph API de Meta).
# El token NUNCA aparece en `ps`: curl lo consume de un config por descriptor.
#
# Credenciales (en orden de prioridad):
#   1) Variables de entorno:  WA_TOKEN  WA_WABA_ID  WA_PHONE_ID
#   2) Vault JSON:            WA_VAULT=/ruta.json  [WA_PATH=.apis.whatsapp]
#      (lee <WA_PATH>.access_token / .waba_id / .phone_number_id)
# Opcional: WA_API_VERSION (def v21.0)
#
# WA_WABA_ID  -> gestiona PLANTILLAS y lista números.
# WA_PHONE_ID -> ENVÍA mensajes y sube media.  (¡son IDs distintos!)
set -euo pipefail

WA_API_VERSION="${WA_API_VERSION:-v21.0}"
GRAPH="https://graph.facebook.com/${WA_API_VERSION}"

_wa_from_vault() { # $1 = campo
  [[ -n "${WA_VAULT:-}" && -f "${WA_VAULT:-}" ]] || return 0
  jq -rj "${WA_PATH:-.apis.whatsapp}.$1 // empty" "$WA_VAULT" 2>/dev/null || true
}

WA_TOKEN="${WA_TOKEN:-$(_wa_from_vault access_token)}"
WA_WABA_ID="${WA_WABA_ID:-$(_wa_from_vault waba_id)}"
WA_PHONE_ID="${WA_PHONE_ID:-$(_wa_from_vault phone_number_id)}"

# curl -K <(wa_cfg): mete el Bearer por descriptor, no por argv.
wa_cfg() { printf 'header = "Authorization: Bearer %s"\n' "$WA_TOKEN"; }

_wa_need_token() { [[ -n "${WA_TOKEN:-}" ]] || { echo "ERROR: falta WA_TOKEN (o WA_VAULT). Ver references/configuracion.md" >&2; exit 1; }; }
_wa_need_waba()  { _wa_need_token; [[ -n "${WA_WABA_ID:-}" ]]  || { echo "ERROR: falta WA_WABA_ID (plantillas/números)." >&2; exit 1; }; }
_wa_need_phone() { _wa_need_token; [[ -n "${WA_PHONE_ID:-}" ]] || { echo "ERROR: falta WA_PHONE_ID (envíos/media)." >&2; exit 1; }; }
