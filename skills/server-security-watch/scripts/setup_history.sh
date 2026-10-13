#!/bin/bash
# =============================================================================
# setup_history.sh - Activa registro de comandos con timestamp
# =============================================================================
# Uso (EN el servidor):  ./setup_history.sh root deploy webmaster
#   Sin argumentos: aplica a root + todas las cuentas con UID >= 1000 y shell.
#
# POR QUE: sin HISTTIMEFORMAT no queda rastro de QUE se ejecuto ni CUANDO.
# Caso real (2026-07-27): una cuenta con sudo NOPASSWD y 100+ accesos SSH no
# tenia ni fichero .bash_history -> imposible saber que se hizo con ella.
# Esto no se arregla mirando atras, solo empezando a grabar.
#
# Idempotente: si ya esta configurado, no duplica.
# LIMITACION: el history solo cubre shells interactivas y lo puede borrar el
# propio usuario. Para auditoria a prueba de borrado, usar auditd (ver SKILL.md).
# =============================================================================
set -u

FECHA=$(date +%Y%m%d)
MARCA="# === secwatch: history con timestamp ==="

if [ $# -gt 0 ]; then
    USUARIOS="$*"
else
    USUARIOS="root $(awk -F: '$3>=1000 && $7~/(bash|sh)$/ {print $1}' /etc/passwd | tr '\n' ' ')"
fi

BLOQUE=$(cat <<'EOF'

# === secwatch: history con timestamp ===
export HISTTIMEFORMAT="%F %T "
export HISTSIZE=100000
export HISTFILESIZE=200000
export HISTCONTROL=
shopt -s histappend
case "${PROMPT_COMMAND:-}" in
    *"history -a"*) ;;
    *) export PROMPT_COMMAND="history -a;${PROMPT_COMMAND:-}" ;;
esac
EOF
)

for u in $USUARIOS; do
    home=$(getent passwd "$u" | cut -d: -f6)
    [ -n "$home" ] && [ -d "$home" ] || { echo "  $u -> sin home, saltando"; continue; }
    rc="$home/.bashrc"
    [ -f "$rc" ] || { echo "  $u -> sin .bashrc, saltando"; continue; }

    if grep -qF "$MARCA" "$rc"; then
        echo "  $u -> ya configurado"
    else
        cp -a "$rc" "${rc}.bak_${FECHA}"
        printf '%s\n' "$BLOQUE" >> "$rc"
        echo "  $u -> configurado (backup .bak_${FECHA})"
    fi

    hist="$home/.bash_history"
    if [ -L "$hist" ]; then
        echo "       ! $hist es un enlace simbolico: NO se toca (posible intento de escalada)"
    elif [ ! -e "$hist" ]; then
        touch "$hist"
        chown -h "$u:$(id -gn "$u" 2>/dev/null || echo "$u")" "$hist" 2>/dev/null
        chmod 600 "$hist"
        echo "       + creado .bash_history (no existia)"
    fi
done

echo
echo "--- verificacion ---"
for u in $USUARIOS; do
    home=$(getent passwd "$u" | cut -d: -f6)
    [ -f "$home/.bashrc" ] || continue
    printf "  %-16s HISTTIMEFORMAT: %s\n" "$u" "$(grep -c HISTTIMEFORMAT "$home/.bashrc")"
done
echo
echo "NOTA: aplica a sesiones NUEVAS. Las ya abiertas no lo tienen."
