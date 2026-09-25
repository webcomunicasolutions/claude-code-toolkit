---
name: video-watch
description: >-
  Dar a Claude la capacidad de "ver" CUALQUIER vídeo (YouTube, cualquier vídeo online, o un
  archivo local) sin API keys ni coste: descarga con yt-dlp, saca la transcripción (captions de
  YouTube si existen, o faster-whisper LOCAL si no) y extrae frames scene-aware con ffmpeg para
  ver lo que pasa en pantalla, no solo lo que se dice. Usar cuando el usuario quiera que "veas",
  "mires" o "analices" un vídeo, saques capturas/frames de un vídeo, entiendas un vídeo SIN
  transcripción o sin nadie hablando (demos mudas, tutoriales de pantalla, Looms), o compares lo
  visual con lo dicho. Triggers: "mira este vídeo", "ve este vídeo", "analiza el vídeo", "saca
  capturas del vídeo", "qué pasa en pantalla", "este vídeo no tiene transcripción", "vídeo local",
  "vídeo de Instagram/X/Vimeo/Loom". NOT para solo-transcribir texto (usa youtube-transcript o
  whisper-transcribe), ni para generar/editar vídeo.
---

# video-watch — que Claude vea cualquier vídeo

Da a Claude las dos cosas que necesita para "ver" un vídeo: la **transcripción** (lo que se
dice) y **frames** (lo que se ve). Todo **local, sin API keys y sin coste por minuto** —
al contrario que herramientas tipo `claude-video` que dependen de Whisper API de pago.

Nace de un caso real: un vídeo de curso sin transcripción ni voz del que hubo que sacar
capturas a mano con ffmpeg (`anthropic_courses/`, jun-2026). Esto lo automatiza.

## Cuándo NO usarla
- Solo quieres el texto de un YouTube -> `youtube-transcript` (más directo).
- Solo transcribir un audio/vídeo local a texto -> `whisper-transcribe`.
- Esta skill es para cuando hace falta **ver la pantalla** (o cuando no hay transcripción).

## Uso

```bash
python3 ~/.claude/skills/video-watch/scripts/watch_video.py <URL|ruta_local> --mode balance
```

Genera una carpeta temporal con `transcript.txt`, `frames/` y un **`index.md`**.
Flujo de trabajo: ejecutar -> **leer el `index.md`** -> `Read` de los frames relevantes
(por su timestamp) -> razonar sobre transcripción + imágenes juntas.

### Parámetros
- `source` (obligatorio): URL de YouTube / cualquier vídeo online soportado por yt-dlp, o ruta local.
- `--mode`: `transcript` | `efficient` | `balance` (def.) | `burner`.
- `--lang, -l`: idioma para la transcripción (def. `es`).
- `--whisper-model`: `tiny|base|small(def.)|medium|large-v2|large-v3`. Más grande = mejor pero más lento en CPU.
- `--output-dir, -o`: dónde volcar (def. carpeta temporal).
- `--max-frames`: forzar un tope de frames concreto.
- `--keep-video`: no borrar el vídeo descargado al terminar.

### Modos (cuántos frames)
| Modo | Frames | Cuándo |
|------|--------|--------|
| `transcript` | 0 | Solo texto; ni se molesta en sacar frames. |
| `efficient` | ≤50 equiespaciados | Rápido; vídeos largos donde solo quieres una idea visual. |
| `balance` (def.) | ≤100 por cambio de escena | El punto dulce: capta cuando cambia lo que se ve. |
| `burner` | todos los cambios de escena | Máximo detalle; lento y pesado, para análisis fino. |

## Cómo decide la transcripción
1. Si es **YouTube** -> intenta captions nativos (rápido, gratis) vía `youtube-transcript`.
2. Si no hay captions o **no es YouTube** -> extrae y transcribe **local** con `faster-whisper`.
3. Si la fuente es solo audio (sin pista de vídeo) -> transcribe y omite frames.

## Dependencias del sistema (ya instaladas en este equipo)
- `ffmpeg` / `ffprobe` (apt) — extracción de frames y metadatos.
- `yt-dlp` — como módulo Python: se invoca con `python3 -m yt_dlp`. Instalar/actualizar:
  `pip3 install --user -U yt-dlp --break-system-packages`.
- `whisper-transcribe` — wrapper de faster-whisper en `~/.local/bin/` (transcripción local).
- `youtube-transcript` — script en `~/.claude/skills/youtube-transcript/`.

Si YouTube empieza a rechazar descargas/captions, casi siempre es **yt-dlp desactualizado**:
actualizarlo antes de concluir nada (regla de coordenadas: un fallo no es "está caído").

## Errores conocidos (troubleshooting)

| Síntoma | Causa casi siempre | Solución |
|---|---|---|
| Falla la descarga de YouTube / "yt-dlp falló" / "Sign in to confirm..." / formato no disponible | **yt-dlp desactualizado** (YouTube cambia el sitio y rompe versiones viejas cada pocas semanas) | `pip3 install --user -U yt-dlp --break-system-packages` y reintentar. NO concluir "el vídeo no existe / está caído": un fallo casi siempre es la herramienta, no la fuente (regla de coordenadas). |
| "vídeo MUDO (sin pista de audio)" | El vídeo no tiene audio (demo muda, tutorial de pantalla) | Es correcto: no hay nada que transcribir, se sacan solo frames. No es un error. |
| Transcripción vacía o rara con whisper | Audio muy ruidoso, música, o corte de audio sucio | Subir calidad: `--whisper-model medium` o `large-v3` (más lento). Si es YouTube, tira de captions. |
| Vídeo privado / detrás de login | yt-dlp necesita cookies del navegador | No cubierto aquí; habría que exportar cookies. Pedírmelo si hace falta. |
| Tarda muchísimo | Whisper en CPU sobre vídeo largo, o `balance`/`burner` decodificando entero | `--mode efficient`, `--whisper-model tiny/base`, o captions si es YouTube. |

## Gotchas
- **Whisper en CPU es lento** en vídeos largos. Para >20-30 min: usa captions si es YouTube,
  o `--whisper-model tiny/base`, o `--mode efficient` para no decodificar toda la pista de vídeo.
- `balance`/`burner` decodifican el vídeo entero para detectar escenas (coste real en vídeos
  largos). `efficient` usa saltos rápidos y es mucho más veloz.
- La descarga se limita a ≤720p a propósito (frames nítidos de sobra, menos disco).
- Vídeos privados / con login: yt-dlp puede necesitar cookies; no está cubierto aquí.
- yt-dlp verificado funcionando en v2026.03.17 (2026-07-11). Si falla en el futuro: actualizar (ver tabla).

## Auto-mejora

Al cerrar cada aplicación práctica de esta skill:
1. Registrar aprendizajes en `aprendizajes/<caso>.md` (o en esta sección si es breve): qué modo
   funcionó, sitios donde yt-dlp falló y cómo se resolvió, tiempos reales de whisper por duración.
2. Si el patrón es generalizable, actualizar el cuerpo de este SKILL.md.
3. Errores recurrentes -> añadir a la tabla "Errores conocidos".

Sin esta fase, la skill se fosiliza y pierde valor con el tiempo.
