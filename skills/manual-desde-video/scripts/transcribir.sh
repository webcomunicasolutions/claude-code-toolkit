#!/usr/bin/env bash
# Transcribe un vídeo/audio con ElevenLabs Scribe (con hablantes) y deja transcripcion.md por turnos.
# Uso: transcribir.sh <video_o_audio> <carpeta_salida> [idioma=spa]
# Clave: variable de entorno ELEVENLABS_API_KEY (sácala de tu gestor de credenciales; nunca se imprime ni se escribe en el script).
set -euo pipefail
IN="$1"; OUT="$2"; LANG_CODE="${3:-spa}"
: "${ELEVENLABS_API_KEY:?Define ELEVENLABS_API_KEY en el entorno}"
mkdir -p "$OUT"
ffmpeg -v error -y -i "$IN" -vn -ac 1 -b:a 64k "$OUT/audio.mp3"
curl -sf -o "$OUT/scribe.json" -w "Scribe HTTP %{http_code} en %{time_total}s\n" \
  -H "xi-api-key: $ELEVENLABS_API_KEY" \
  -F model_id=scribe_v1 -F language_code="$LANG_CODE" -F diarize=true -F tag_audio_events=false \
  -F file=@"$OUT/audio.mp3" https://api.elevenlabs.io/v1/speech-to-text
python3 - "$OUT" <<'PY'
import json, sys, collections
out = sys.argv[1]
d = json.load(open(f"{out}/scribe.json"))
turnos, cur = [], None
for w in d["words"]:
    if w.get("type") == "spacing" and cur: cur["t"] += w["text"]; continue
    if w.get("type") != "word": continue
    if cur is None or w.get("speaker_id") != cur["sp"]:
        cur = {"sp": w.get("speaker_id"), "start": w["start"], "t": w["text"]}; turnos.append(cur)
    else: cur["t"] += w["text"]
with open(f"{out}/transcripcion.md", "w") as f:
    for t in turnos:
        s = int(t["start"]); f.write(f"**[{s//60:02d}:{s%60:02d}] {t['sp']}:** {t['t'].strip()}\n\n")
print(len(turnos), "turnos;", dict(collections.Counter(t["sp"] for t in turnos)))
print("Renombra speaker_N a mano (sed) según el contexto y anota en la cabecera los errores de reconocimiento.")
PY
