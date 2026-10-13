#!/bin/bash
# audio-nota.sh - Convierte texto en nota de voz y la envia por Telegram.
#
# Uso:
#   echo "texto" | audio-nota.sh                  # -> nota de voz a Telegram
#   echo "texto" | audio-nota.sh --local          # -> ademas suena por los altavoces
#   echo "texto" | VOZ=es-ES-ElviraNeural audio-nota.sh
#
# Motor: edge-tts (Microsoft, gratis, sin API key, sin limite de caracteres).
#
# Credenciales de Telegram: variables de entorno (NUNCA hardcodeadas aqui).
#   TELEGRAM_BOT_TOKEN  - token del bot
#   TELEGRAM_CHAT_ID    - chat_id destino
# Ponlas en tu shell (.bashrc/.zshrc) o en un gestor de secretos propio.

set -euo pipefail

VOZ="${VOZ:-es-ES-XimenaNeural}"   # XimenaNeural (f) | AlvaroNeural (m) | ElviraNeural (f)
RATE="${RATE:-+8%}"                # un pelin mas rapido = suena mas natural
LOCAL=0
[ "${1:-}" = "--local" ] && LOCAL=1

if [ -z "${TELEGRAM_BOT_TOKEN:-}" ] || [ -z "${TELEGRAM_CHAT_ID:-}" ]; then
    echo "audio-nota: faltan TELEGRAM_BOT_TOKEN y/o TELEGRAM_CHAT_ID en el entorno" >&2
    exit 1
fi

TEXTO=$(cat)
if [ -z "${TEXTO// }" ]; then
    echo "audio-nota: no hay texto en stdin" >&2
    exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# 1) Texto -> mp3
# Desde 10/2026 Microsoft da 403 en Europa con el host antiguo (speech.platform.bing.com).
# Issue rany2/edge-tts#490. Se prueba primero el host nuevo (api.msedgeservices.com) y, si falla,
# el de la librería. Cuando edge-tts publique el arreglo oficial, esto sigue funcionando.
printf '%s' "$TEXTO" > "$TMP/texto.txt"
if ! python3 -P - "$VOZ" "$RATE" "$TMP/texto.txt" "$TMP/nota.mp3" 2> "$TMP/tts.err" <<'PY'
import asyncio, sys
import edge_tts, edge_tts.communicate as cm
from edge_tts.constants import TRUSTED_CLIENT_TOKEN
voz, rate, fin, fout = sys.argv[1:5]
texto = open(fin, encoding="utf-8").read()
HOSTS = [f"wss://api.msedgeservices.com/tts/cognitiveservices/websocket/v1?Ocp-Apim-Subscription-Key={TRUSTED_CLIENT_TOKEN}", cm.WSS_URL]
async def main():
    ultimo = None
    for url in HOSTS:
        cm.WSS_URL = url
        try:
            await edge_tts.Communicate(texto, voz, rate=rate).save(fout); return
        except Exception as e:
            ultimo = e; print(f"host {url.split('/')[2]}: {str(e)[:150]}", file=sys.stderr)
    raise SystemExit(f"edge-tts fallo en todos los hosts: {ultimo}")
asyncio.run(main())
PY
then
    echo "audio-nota: edge-tts no genero audio:" >&2; cat "$TMP/tts.err" >&2
    exit 1
fi

if [ ! -s "$TMP/nota.mp3" ]; then
    echo "audio-nota: edge-tts no genero audio" >&2
    exit 1
fi

# 2) mp3 -> ogg/opus (formato de nota de voz de Telegram)
ffmpeg -y -loglevel error -i "$TMP/nota.mp3" -c:a libopus -b:a 32k "$TMP/nota.ogg"

SEGS=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP/nota.ogg" 2>/dev/null | cut -d. -f1)

# 3) Enviar como nota de voz
RESP=$(curl -s -X POST -K <(printf 'url = "https://api.telegram.org/bot%s/sendVoice"\n' "$TELEGRAM_BOT_TOKEN") \
    -F "chat_id=${TELEGRAM_CHAT_ID}" \
    -F "voice=@${TMP}/nota.ogg" \
    -F "duration=${SEGS:-0}")

if [ "$(echo "$RESP" | jq -r '.ok')" = "true" ]; then
    echo "✓ Nota de voz enviada a Telegram (${SEGS}s, ${#TEXTO} caracteres, voz $VOZ)"
else
    echo "✗ Telegram fallo: $(echo "$RESP" | jq -r '.description')" >&2
    exit 1
fi

# 4) Opcional: sonar tambien en los altavoces del PC
if [ "$LOCAL" = "1" ]; then
    ffplay -nodisp -autoexit -loglevel error "$TMP/nota.mp3" 2>/dev/null || \
        echo "  (no se pudo reproducir en local)" >&2
fi
