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

VOZ="${VOZ:-es-ES-AlvaroNeural}"   # AlvaroNeural (m) | ElviraNeural (f) | XimenaNeural (f)
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
python3 -m edge_tts --voice "$VOZ" --rate="$RATE" --text "$TEXTO" \
    --write-media "$TMP/nota.mp3" >/dev/null 2>&1

if [ ! -s "$TMP/nota.mp3" ]; then
    echo "audio-nota: edge-tts no genero audio" >&2
    exit 1
fi

# 2) mp3 -> ogg/opus (formato de nota de voz de Telegram)
ffmpeg -y -loglevel error -i "$TMP/nota.mp3" -c:a libopus -b:a 32k "$TMP/nota.ogg"

SEGS=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP/nota.ogg" 2>/dev/null | cut -d. -f1)

# 3) Enviar como nota de voz
RESP=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendVoice" \
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
