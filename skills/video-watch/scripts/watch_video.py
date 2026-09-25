#!/usr/bin/env python3
"""
video-watch — dar a Claude la capacidad de "ver" cualquier vídeo.

Combina herramientas que ya tenemos en el sistema, SIN API keys ni coste por minuto:
  - yt-dlp            -> descargar cualquier vídeo online (YouTube, Vimeo, X, Instagram, Loom...)
  - youtube-transcript-> captions nativos de YouTube (rápido, gratis)
  - faster-whisper    -> transcripción LOCAL cuando no hay captions (whisper-transcribe)
  - ffmpeg/ffprobe    -> extracción de frames (scene-aware) para ver lo que pasa en pantalla

Salida: una carpeta con transcript + frames + un index.md que Claude lee para "ver" el vídeo.

Uso:
  python3 watch_video.py <URL|ruta_local> [--mode transcript|efficient|balance|burner]
                          [--lang es] [--whisper-model small] [--output-dir DIR]
                          [--max-frames N] [--keep-video]
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile

YOUTUBE_TRANSCRIPT = os.path.expanduser(
    "~/.claude/skills/youtube-transcript/scripts/extract_transcript.py"
)

# frames por modo: (cap_frames | None=sin tope, umbral_escena | None=muestreo uniforme)
MODES = {
    "transcript": (0, None),      # sin frames, solo texto
    "efficient":  (50, None),     # 50 frames equiespaciados (rápido, sin analizar escenas)
    "balance":    (100, 0.40),    # hasta 100 frames por cambios de escena (recomendado)
    "burner":     (None, 0.30),   # todos los cambios de escena, sin tope (lento y pesado)
}


def run(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


def is_url(s: str) -> bool:
    return s.startswith("http://") or s.startswith("https://")


def is_youtube(url: str) -> bool:
    return "youtube.com" in url or "youtu.be" in url


def ffprobe_duration(path: str) -> float:
    r = run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
             "-of", "default=noprint_wrappers=1:nokey=1", path])
    try:
        return float(r.stdout.strip())
    except ValueError:
        return 0.0


def has_stream(path: str, kind: str) -> bool:
    """kind: 'v' (vídeo) o 'a' (audio)."""
    r = run(["ffprobe", "-v", "error", "-select_streams", kind, "-show_entries",
             "stream=codec_type", "-of", "csv=p=0", path])
    return bool(r.stdout.strip())


def download(url: str, out_dir: str) -> str:
    """Descarga el vídeo (≤720p para no engordar) con yt-dlp. Devuelve la ruta local."""
    tmpl = os.path.join(out_dir, "source.%(ext)s")
    fmt = "bv*[height<=720]+ba/b[height<=720]/b"
    r = run([sys.executable, "-m", "yt_dlp", "-f", fmt, "--no-playlist",
             "-o", tmpl, "--merge-output-format", "mp4", url])
    if r.returncode != 0:
        sys.exit(f"[video-watch] yt-dlp falló:\n{r.stderr[-800:]}")
    for f in os.listdir(out_dir):
        if f.startswith("source."):
            return os.path.join(out_dir, f)
    sys.exit("[video-watch] yt-dlp terminó pero no encuentro el archivo descargado.")


def captions_youtube(url: str, lang: str, out_dir: str):
    """Intenta captions nativos de YouTube. Devuelve (texto, ruta) o (None, None)."""
    if not os.path.exists(YOUTUBE_TRANSCRIPT):
        return None, None
    dst = os.path.join(out_dir, "transcript.txt")
    r = run([sys.executable, YOUTUBE_TRANSCRIPT, url, "--format", "text",
             "--languages", lang, "en", "--output", dst])
    if r.returncode == 0 and os.path.exists(dst) and os.path.getsize(dst) > 0:
        with open(dst, encoding="utf-8") as fh:
            return fh.read(), dst
    return None, None


def transcribe_whisper(media: str, lang: str, model: str, out_dir: str):
    """Transcribe LOCALMENTE con faster-whisper. Devuelve (texto, ruta) o (None, None)."""
    wt = shutil.which("whisper-transcribe")
    if not wt:
        return None, None
    r = run([wt, media, "--model", model, "--language", lang, "--output", "stdout"])
    if r.returncode != 0:
        return None, None
    # whisper-transcribe imprime cabecera de progreso en stdout; quedarnos solo con el texto.
    log_prefixes = ("Transcribiendo:", "Modelo:", "Cargando modelo", "Idioma detectado")
    clean = "\n".join(l for l in r.stdout.splitlines()
                      if not l.startswith(log_prefixes)).strip()
    if not clean:
        return None, None
    dst = os.path.join(out_dir, "transcript.txt")
    with open(dst, "w", encoding="utf-8") as fh:
        fh.write(clean + "\n")
    return clean, dst


def scene_timestamps(video: str, threshold: float):
    """Segundos donde ffmpeg detecta un cambio de escena."""
    r = run(["ffmpeg", "-i", video, "-vf",
             f"select='gt(scene,{threshold})',showinfo", "-f", "null", "-"])
    return sorted({float(m) for m in re.findall(r"pts_time:([0-9.]+)", r.stderr)})


def uniform_timestamps(duration: float, n: int):
    if duration <= 0 or n <= 0:
        return []
    step = duration / (n + 1)
    return [round(step * (i + 1), 2) for i in range(n)]


def pick_timestamps(video: str, duration: float, cap, threshold):
    """Lista de segundos donde sacar frames, según el modo."""
    if threshold is None:  # muestreo uniforme (efficient)
        return uniform_timestamps(duration, cap or 50)
    ts = scene_timestamps(video, threshold)
    if not ts:  # vídeo sin cortes claros -> caer a uniforme
        return uniform_timestamps(duration, min(cap or 50, 30))
    if cap and len(ts) > cap:  # demasiadas escenas -> submuestrear uniformemente
        idx = uniform_timestamps(len(ts) - 1, cap)
        ts = [ts[int(round(i))] for i in idx]
    return ts


def extract_frame(video: str, t: float, dst: str):
    r = run(["ffmpeg", "-y", "-ss", f"{t:.2f}", "-i", video,
             "-frames:v", "1", "-q:v", "3", dst])
    return r.returncode == 0 and os.path.exists(dst)


def hms(seconds: float) -> str:
    s = int(seconds)
    return f"{s // 3600:02d}:{(s % 3600) // 60:02d}:{s % 60:02d}"


def main():
    ap = argparse.ArgumentParser(description="Dar a Claude la capacidad de ver un vídeo")
    ap.add_argument("source", help="URL (YouTube/online) o ruta a un vídeo local")
    ap.add_argument("--mode", choices=list(MODES), default="balance")
    ap.add_argument("--lang", "-l", default="es", help="Idioma para transcripción (default: es)")
    ap.add_argument("--whisper-model", default="small",
                    choices=["tiny", "base", "small", "medium", "large-v2", "large-v3"])
    ap.add_argument("--output-dir", "-o", default=None)
    ap.add_argument("--max-frames", type=int, default=None, help="Override del tope de frames")
    ap.add_argument("--keep-video", action="store_true", help="No borrar el vídeo descargado")
    args = ap.parse_args()

    out_dir = args.output_dir or tempfile.mkdtemp(prefix="video-watch-")
    os.makedirs(out_dir, exist_ok=True)
    frames_dir = os.path.join(out_dir, "frames")

    url = is_url(args.source)
    cap, threshold = MODES[args.mode]
    if args.max_frames is not None:
        cap = args.max_frames
    print(f"[video-watch] fuente: {'URL' if url else 'archivo local'} | modo: {args.mode}")
    print(f"[video-watch] salida: {out_dir}")

    # 1) transcripción por captions de YouTube (sin descargar nada)
    text, tpath, method = None, None, None
    if url and is_youtube(args.source):
        text, tpath = captions_youtube(args.source, args.lang, out_dir)
        if text:
            method = "captions YouTube"

    # 2) conseguir el archivo de vídeo SOLO si hace falta (frames, o whisper por falta de captions)
    need_frames = cap != 0
    video = None
    if not url:
        video = os.path.abspath(args.source)
        if not os.path.exists(video):
            sys.exit(f"[video-watch] no existe el archivo: {video}")
    elif need_frames or text is None:
        print("[video-watch] descargando con yt-dlp...")
        video = download(args.source, out_dir)
    else:
        print("[video-watch] captions obtenidos y modo transcript -> no hace falta descargar el vídeo.")

    # 3) whisper local si aún no hay texto
    if text is None and video is not None:
        if not has_stream(video, "a"):
            method = "vídeo MUDO (sin pista de audio)"
            print(f"[video-watch] {method} -> no hay nada que transcribir; solo frames.")
        else:
            print(f"[video-watch] transcribiendo local con faster-whisper ({args.whisper_model})...")
            text, tpath = transcribe_whisper(video, args.lang, args.whisper_model, out_dir)
            if text:
                method = f"faster-whisper ({args.whisper_model}, local)"
            else:
                print("[video-watch] AVISO: no se pudo obtener transcripción.")

    # 4) frames
    frame_list = []
    if need_frames and video is not None and has_stream(video, "v"):
        duration = ffprobe_duration(video)
        print(f"[video-watch] duración: {hms(duration)} | extrayendo frames ({args.mode})...")
        os.makedirs(frames_dir, exist_ok=True)
        for i, t in enumerate(pick_timestamps(video, duration, cap, threshold)):
            name = f"frame_{i:03d}_{int(t):05d}s.png"
            if extract_frame(video, t, os.path.join(frames_dir, name)):
                frame_list.append((t, name))
        print(f"[video-watch] {len(frame_list)} frames extraídos.")
    elif need_frames and video is not None:
        print("[video-watch] fuente sin pista de vídeo -> sin frames (solo audio).")

    # 5) index.md para que Claude lo lea
    index = os.path.join(out_dir, "index.md")
    with open(index, "w", encoding="utf-8") as fh:
        fh.write(f"# video-watch — {os.path.basename(args.source)}\n\n")
        fh.write(f"- Fuente: `{args.source}`\n- Modo: `{args.mode}`\n")
        fh.write(f"- Transcripción: {method or 'NO disponible'}\n")
        fh.write(f"- Frames: {len(frame_list)}\n\n")
        if tpath:
            fh.write(f"## Transcripción\nArchivo: `{tpath}`\n\n")
            if text:
                fh.write("```\n" + text.strip()[:4000] + ("\n...[truncado]" if len(text) > 4000 else "") + "\n```\n\n")
        if frame_list:
            fh.write("## Frames (leer con Read los relevantes)\n\n")
            for t, name in frame_list:
                fh.write(f"- `{hms(t)}` -> `{os.path.join(frames_dir, name)}`\n")

    # 6) limpieza del vídeo descargado
    if url and video is not None and not args.keep_video and os.path.exists(video):
        os.remove(video)

    print(f"\n[video-watch] LISTO. Índice: {index}")
    print("[video-watch] Claude: lee el index.md y luego Read los frames que necesites.")


if __name__ == "__main__":
    main()
