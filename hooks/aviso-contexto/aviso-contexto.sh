#!/bin/bash
# aviso-contexto.sh — Hook PostToolUse: chivato de uso de contexto.
#
# Claude Code NO expone el % de contexto a hooks/statusline (confirmado). Usamos el TAMANO del
# transcript.jsonl como PROXY BRUTO. Calibrado con datos reales del entorno (proyecto real,
# 2026-06-02): ~4MB de transcript ≈ 50% de contexto; ~8MB ≈ limite. Ajustar TH50/TH75 con la
# experiencia (cuando salte el aviso, comparar con /context real y afinar).
#
# Avisa UNA vez por umbral y sesion (flag en /tmp). Rapido y silencioso si no aplica.

input=$(cat 2>/dev/null)
command -v jq >/dev/null 2>&1 || exit 0

tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
sid=$(printf '%s' "$input" | jq -r '.session_id // "x"' 2>/dev/null)
[ -n "$tp" ] && [ -f "$tp" ] || exit 0

size=$(stat -c%s "$tp" 2>/dev/null || echo 0)
TH50=$((4*1000*1000))   # ~50% contexto (proxy)
TH75=$((6*1000*1000))   # ~75% contexto (proxy)
f50="/tmp/.claude-ctx50-$sid"
f75="/tmp/.claude-ctx75-$sid"
mb=$((size / 1048576))

if [ "$size" -gt "$TH75" ] && [ ! -f "$f75" ]; then
  touch "$f75"
  printf '{"systemMessage":"🚨 Contexto ~75%% (transcript %sMB). CORTA YA: /save-session y continua en sesion nueva con /resume-session."}\n' "$mb"
  exit 0
fi
if [ "$size" -gt "$TH50" ] && [ ! -f "$f50" ]; then
  touch "$f50"
  printf '{"systemMessage":"⚠️ Contexto ~50%% (transcript %sMB). Buen momento para cortar limpio: /save-session. Confirma el dato exacto con /context."}\n' "$mb"
  exit 0
fi
exit 0
