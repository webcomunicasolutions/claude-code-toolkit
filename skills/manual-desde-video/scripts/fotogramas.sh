#!/usr/bin/env bash
# Dos usos:
#   fotogramas.sh hojas <video> <carpeta> [cada_seg=15]   -> hojas 3x3 con la marca de tiempo (para ver el recorrido)
#   fotogramas.sh uno   <video> <segundo> <salida.png>     -> un fotograma a resolución completa (para anotar)
# OJO: el tiempo del vídeo puede no coincidir al segundo con el de la transcripción: buscar el fotograma
# alrededor (±10 s) y elegir el que enseña el menú/diálogo abierto.
set -euo pipefail
case "$1" in
  hojas)
    V="$2"; D="$3"; N="${4:-15}"; mkdir -p "$D/f"
    ffmpeg -v error -y -i "$V" -vf "fps=1/$N,scale=960:-1" "$D/f/t_%03d.jpg"
    for f in "$D"/f/t_*.jpg; do i=$((10#$(basename "$f" .jpg | cut -c3-)-1)); s=$((i*N))
      printf -v lab "%02d:%02d" $((s/60)) $((s%60))
      mogrify -gravity NorthWest -pointsize 34 -fill yellow -undercolor black -annotate +5+5 "$lab" "$f"; done
    ls "$D"/f/t_*.jpg | split -l 9 - "$D/lista_"
    for l in "$D"/lista_*; do montage $(cat "$l") -tile 3x3 -geometry 640x360+4+4 "$l.jpg"; done
    ls "$D"/lista_*.jpg ;;
  uno)
    ffmpeg -v error -y -ss "$3" -i "$2" -frames:v 1 "$4"; echo "$4" ;;
  *) echo "uso: $0 hojas|uno ..."; exit 1 ;;
esac
