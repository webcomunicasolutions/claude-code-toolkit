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

# Todo lo que se escribe en el home de un usuario se hace CON SUS PERMISOS, no como root:
# si el usuario pone un enlace simbolico (~/.bashrc -> /etc/...), solo podra tocar lo que ya
# podia tocar el mismo. Comprobar "-L" antes no basta (carrera entre comprobar y escribir).
como() {   # como <usuario> <comando...>
    local usr="$1"; shift
    if [ "$usr" = "root" ] || [ "$(id -un)" = "$usr" ]; then "$@"
    elif command -v runuser >/dev/null 2>&1; then runuser -u "$usr" -- "$@"
    else su -s /bin/sh "$usr" -c '"$0" "$@"' -- "$@"; fi
}

for u in $USUARIOS; do
    home=$(getent passwd "$u" | cut -d: -f6)
    [ -n "$home" ] && [ -d "$home" ] || { echo "  $u -> sin home, saltando"; continue; }
    rc="$home/.bashrc"
    [ -f "$rc" ] || { echo "  $u -> sin .bashrc, saltando"; continue; }

    if grep -qF "$MARCA" "$rc"; then
        echo "  $u -> ya configurado"
    else
        como "$u" cp -- "$rc" "${rc}.bak_${FECHA}"
        printf '%s\n' "$BLOQUE" | como "$u" tee -a -- "$rc" >/dev/null
        echo "  $u -> configurado (backup .bak_${FECHA})"
    fi

    hist="$home/.bash_history"
    if [ ! -e "$hist" ] && [ ! -L "$hist" ]; then
        como "$u" sh -c 'umask 077; : >> "$1"' _ "$hist" && echo "       + creado .bash_history (no existia)"
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
