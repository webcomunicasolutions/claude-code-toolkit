#!/bin/bash
# Audit Reminder Hook
# Avisa si el proyecto actual no se ha auditado en >14 dias.
# No bloquea, no audita: solo recuerda.

set -e

AUDIT_DIR="$HOME/.claude/.audits"
mkdir -p "$AUDIT_DIR"

# Hash del cwd para identificar el proyecto
PROJECT_HASH=$(pwd | md5sum | cut -d' ' -f1)
MARKER="$AUDIT_DIR/$PROJECT_HASH"

# Solo en proyectos (no en home directo, no en /tmp)
case "$PWD" in
  "$HOME"|"$HOME/"|/tmp/*|/) exit 0 ;;
esac

if [ -f "$MARKER" ]; then
  LAST=$(stat -c %Y "$MARKER" 2>/dev/null || stat -f %m "$MARKER" 2>/dev/null)
  NOW=$(date +%s)
  DAYS=$(( (NOW - LAST) / 86400 ))
  if [ "$DAYS" -ge 14 ]; then
    echo "Auditoria del proyecto vencida ($DAYS dias). Ejecuta /audit cuando puedas."
  fi
else
  # Primera vez en este proyecto: solo si tiene .claude/ o CLAUDE.md
  if [ -d ".claude" ] || [ -f "CLAUDE.md" ]; then
    echo "Proyecto Claude Code sin auditoria previa. Ejecuta /audit para empezar."
  fi
fi

exit 0
