#!/bin/bash
# Comprueba que ningun MEMORY.md se acerque al limite de carga.
#
# POR QUE EXISTE: en produccion, el MEMORY.md de un proyecto llego a 25,9 KB con el
# limite en 24,4 KB. El harness dejo de cargarlo entero y CORTO 2 entradas EN SILENCIO.
# Cada entrada nueva empujaba otra fuera del contexto: la memoria se perdia sin avisar.
#
# Uso:  ~/.claude/scripts/check_memory_size.sh [ruta_memory.md]
#       sin argumento, revisa TODOS los proyectos.
LIMITE=25000      # bytes: a partir de aqui el harness empieza a cortar
AVISO=20000       # bytes: umbral para compactar antes de tener el problema
estado=0

revisar() {
  local f="$1" b l max proy
  [ -f "$f" ] || return 0
  b=$(stat -c %s "$f"); l=$(grep -c . "$f")
  max=$(awk '{ if (length>m) m=length } END { print m+0 }' "$f")
  proy=$(basename "$(dirname "$(dirname "$f")")")
  if   [ "$b" -ge "$LIMITE" ]; then
    echo "🔴 $proy: ${b} bytes, $l entradas — SE ESTA CORTANDO. Compactar AHORA."; estado=2
  elif [ "$b" -ge "$AVISO" ]; then
    echo "🟡 $proy: ${b} bytes, $l entradas — cerca del limite. Compactar ya."; [ $estado -lt 1 ] && estado=1
  else
    echo "🟢 $proy: ${b} bytes, $l entradas, linea mas larga $max"
  fi
  if [ "$b" -ge "$AVISO" ] && [ "$max" -gt 220 ]; then
    echo "   ⚠️  entradas de mas de 220 caracteres ($max la mayor): el detalle va en su .md, no en el indice."
  fi
  return 0
}

if [ -n "$1" ]; then
  revisar "$1"
else
  for f in ~/.claude/projects/*/memory/MEMORY.md; do revisar "$f"; done
fi

if [ $estado -ge 1 ]; then
  cat <<'AYUDA'

COMO COMPACTAR (sin perder nada: el detalle vive en los .md, MEMORY.md es solo el indice)
  1. Copia de seguridad:  cp MEMORY.md _MEMORY_backup_AAAAMMDD.md
  2. Mueve los punteros a sesiones guardadas (las lineas con .claude/sessions/) a la
     memoria `project_historico_sesiones.md`.
  3. Recorta cada entrada a una linea de ~195 caracteres: titulo + enlace + gancho.
  4. Relee y comprueba que las 3 primeras entradas (las que mas se leen) estan completas.
AYUDA
fi
exit $estado
