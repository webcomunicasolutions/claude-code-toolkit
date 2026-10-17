#!/bin/bash
# Comprueba que ningun MEMORY.md se acerque al limite de carga.
#
# POR QUE EXISTE: en produccion, el MEMORY.md de un proyecto llego a 25,9 KB con el
# limite en 24,4 KB. El harness dejo de cargarlo entero y CORTO 2 entradas EN SILENCIO.
# Cada entrada nueva empujaba otra fuera del contexto: la memoria se perdia sin avisar.
#
# Y en otro caso real los ficheros de instrucciones (CLAUDE.md global + rules/ + los del proyecto)
# pasaron de 150 KB, el tope del harness: la regla rol-jefe-delegacion.md habia crecido a 47 KB
# porque su diario de aprendizajes se apuntaba DENTRO de una regla que se carga siempre.
# Por eso, sin argumento, tambien se mide la parte global que se carga en TODAS las sesiones.
#
# Uso:  ~/.claude/scripts/check_memory_size.sh [ruta_memory.md]
#       sin argumento, revisa TODOS los proyectos, la config global (CLAUDE.md + rules/)
#       y los CLAUDE.md de la carpeta de proyectos (PROYECTOS_DIR, por defecto ~/proyectos).
PROYECTOS_DIR="${PROYECTOS_DIR:-$HOME/proyectos}"
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

# --- Instrucciones globales: CLAUDE.md + rules/*.md (se cargan en todas las sesiones) ---
# El tope del harness son 150 KB para TODO (global + cliente + proyecto). La parte global
# debe dejar sitio a los ficheros del proyecto (suelen ser 20-40 KB).
REGLAS_LIMITE=120000   # bytes: con un proyecto normal ya se pasa de 150 KB
REGLAS_AVISO=100000
REGLA_MAX=10000        # bytes: una sola regla por encima de esto suele ser un diario, no una regla

revisar_reglas() {
  local total f b grandes=""
  total=$(cat ~/.claude/CLAUDE.md ~/.claude/rules/*.md 2>/dev/null | wc -c)
  for f in ~/.claude/rules/*.md; do
    [ -f "$f" ] || continue
    b=$(stat -c %s "$f")
    [ "$b" -gt "$REGLA_MAX" ] && grandes="$grandes $(basename "$f")=${b}"
  done
  if   [ "$total" -ge "$REGLAS_LIMITE" ]; then
    echo "🔴 GLOBAL (CLAUDE.md + rules/): ${total} bytes — con los ficheros de proyecto se pasa de 150 KB. Recortar AHORA."; estado=2
  elif [ "$total" -ge "$REGLAS_AVISO" ]; then
    echo "🟡 GLOBAL (CLAUDE.md + rules/): ${total} bytes — queda poco margen para los ficheros de proyecto."; [ $estado -lt 1 ] && estado=1
  else
    echo "🟢 GLOBAL (CLAUDE.md + rules/): ${total} bytes"
  fi
  if [ -n "$grandes" ]; then
    echo "   ⚠️  reglas de mas de ${REGLA_MAX} bytes:$grandes"
    echo "      Una regla que crece por diseno (diario, casos) va a rules-ondemand/ con un puntero; en rules/ solo el destilado."
  fi
  return 0
}

# --- CLAUDE.md de proyectos: se cargan junto con los globales (cliente + proyecto) ---
# Caso real: el CLAUDE.md de un proyecto llego a 24 KB con todo el historial de versiones en una
# linea de 7,8 KB. El historial va a un fichero propio; en el CLAUDE.md solo lo vigente.
PROY_AVISO=15000
PROY_LIMITE=20000

revisar_claude_proyectos() {
  local f b n=0 avisos=0
  if [ ! -d "$PROYECTOS_DIR" ]; then
    echo "⚠️  CLAUDE.md de proyectos: la carpeta '$PROYECTOS_DIR' no existe (define PROYECTOS_DIR). No revisado."
    [ $estado -lt 1 ] && estado=1; return 0
  fi
  while IFS= read -r f; do
    n=$((n+1)); b=$(stat -c %s "$f")
    if [ "$b" -ge "$PROY_LIMITE" ]; then
      echo "🔴 ${f#"$PROYECTOS_DIR"/}: ${b} bytes — compactar (historial a fichero propio, aqui solo lo vigente)."; estado=2; avisos=$((avisos+1))
    elif [ "$b" -ge "$PROY_AVISO" ]; then
      echo "🟡 ${f#"$PROYECTOS_DIR"/}: ${b} bytes — cerca del limite."; [ $estado -lt 1 ] && estado=1; avisos=$((avisos+1))
    fi
  done < <(find "$(cd -- "$PROYECTOS_DIR" && pwd)" -maxdepth 4 -name CLAUDE.md -not -path '*/_pendiente_borrado/*' -not -path '*/node_modules/*' 2>/dev/null)
  [ $avisos -eq 0 ] && echo "🟢 CLAUDE.md de proyectos: $n revisados, todos por debajo de ${PROY_AVISO} bytes"
  return 0
}

if [ -n "$1" ]; then
  revisar "$1"
else
  for f in ~/.claude/projects/*/memory/MEMORY.md; do revisar "$f"; done
  echo
  revisar_reglas
  echo
  revisar_claude_proyectos
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
