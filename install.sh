#!/bin/bash
# =============================================================================
# Claude Code Toolkit - Installer
# =============================================================================
# Installs agents, hooks, skills, commands, rules, statusline, and optionally
# pulls additional components from Everything Claude Code (ECC).
#
# Run: bash install.sh [--all | --agents | --statusline | --scripts | --hooks | --config
#                       | --skills | --commands | --rules | --ecc | --ecc-only]
# =============================================================================

set -e

CLAUDE_DIR="$HOME/.claude"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOS_DIR="$CLAUDE_DIR/repos"
ECC_REPO="https://github.com/affaan-m/everything-claude-code.git"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

install_agents() {
    info "Installing agents..."
    mkdir -p "$CLAUDE_DIR/agents"
    local count=0
    for f in "$SCRIPT_DIR"/agents/*.md; do
        [ "$(basename "$f")" = "README.md" ] && continue
        cp "$f" "$CLAUDE_DIR/agents/"
        count=$((count + 1))
    done
    success "$count agents installed to $CLAUDE_DIR/agents/"
}

install_statusline() {
    info "Installing statusline..."
    cp "$SCRIPT_DIR/statusline/statusline.sh" "$CLAUDE_DIR/statusline.sh"
    success "Statusline installed to $CLAUDE_DIR/statusline.sh"
    warn "Add to settings.json: \"statusLine\": { \"type\": \"command\", \"command\": \"bash ~/.claude/statusline.sh\" }"
}

install_scripts() {
    info "Installing scripts..."
    mkdir -p "$CLAUDE_DIR/scripts"
    local count=0
    for f in "$SCRIPT_DIR"/scripts/*.sh; do
        [ ! -f "$f" ] && continue
        case "$(basename "$f")" in _*) continue ;; esac   # _*.sh = herramientas internas del kit
        cp "$f" "$CLAUDE_DIR/scripts/"
        chmod +x "$CLAUDE_DIR/scripts/$(basename "$f")"
        count=$((count + 1))
    done
    success "$count scripts installed to $CLAUDE_DIR/scripts/"
}

install_hook() {
    info "Installing hooks..."
    mkdir -p "$CLAUDE_DIR/hooks"
    local count=0
    for f in "$SCRIPT_DIR"/hooks/*/*.sh; do
        [ ! -f "$f" ] && continue
        cp "$f" "$CLAUDE_DIR/hooks/"
        chmod +x "$CLAUDE_DIR/hooks/$(basename "$f")"
        count=$((count + 1))
    done
    success "$count hooks installed to $CLAUDE_DIR/hooks/"
    info "aviso-contexto queda activo con --config. Los demas se activan a mano (ver hooks/*/README.md)."
    warn "Telegram approval: set TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID (see hooks/telegram-approval/README.md)"
}

# Configuracion base: settings.json (bypass + bloqueos de borrado + Opus + statusline + voz + aviso de contexto)
# y plantilla de CLAUDE.md. NUNCA pisa lo que ya tienes: hace copia y fusiona.
install_config() {
    info "Installing base configuration..."
    mkdir -p "$CLAUDE_DIR"
    local base="$SCRIPT_DIR/config-base/settings.base.json"
    local dest="$CLAUDE_DIR/settings.json"
    if [ ! -f "$dest" ]; then
        cp "$base" "$dest"
        success "settings.json creado desde la plantilla"
    elif ! command -v jq >/dev/null 2>&1; then
        cp "$base" "$CLAUDE_DIR/settings.toolkit.json"
        warn "jq no esta instalado: no puedo fusionar. Plantilla en $CLAUDE_DIR/settings.toolkit.json (fusionala a mano)"
    else
        local bak="$dest.bak-$(date +%Y%m%d-%H%M%S)"
        cp "$dest" "$bak"
        # Lo tuyo manda; de la plantilla se anaden las claves que te falten,
        # los bloqueos (deny) se suman y el hook de contexto se anade si no estaba.
        jq -s '
          .[0] as $b | .[1] as $c
          | ($b * $c)
          | .permissions.deny = ((($b.permissions.deny // []) + ($c.permissions.deny // [])) | unique)
          | .hooks.PostToolUse = (
              ($c.hooks.PostToolUse // []) as $u
              | if ($u | tostring | test("aviso-contexto")) then $u else $u + $b.hooks.PostToolUse end)
        ' "$base" "$bak" > "$dest.tmp" && mv "$dest.tmp" "$dest"
        success "settings.json fusionado (copia del anterior: $bak)"
    fi
    if [ ! -f "$CLAUDE_DIR/CLAUDE.md" ]; then
        cp "$SCRIPT_DIR/config-base/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
        success "CLAUDE.md creado: rellena la seccion 'Quien soy'"
    else
        cp "$SCRIPT_DIR/config-base/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.toolkit"
        info "Ya tenias CLAUDE.md: la plantilla queda en CLAUDE.md.toolkit para comparar"
    fi
    warn "Modo bypass ACTIVADO: Claude no pide permiso para cada accion. Los borrados (rm, git clean,"
    warn "docker volume rm...) siguen bloqueados en permissions.deny. Para volver a modo con permisos:"
    warn "  quita \"defaultMode\": \"bypassPermissions\" de ~/.claude/settings.json"
}

install_skills() {
    info "Installing skills..."
    local count=0
    for skill_dir in "$SCRIPT_DIR"/skills/*/; do
        [ ! -d "$skill_dir" ] && continue
        local skill_name
        skill_name=$(basename "$skill_dir")
        if [ -f "$skill_dir/SKILL.md" ]; then
            # Copia la skill COMPLETA (scripts, referencias, plantillas), no solo SKILL.md
            mkdir -p "$CLAUDE_DIR/skills/$skill_name"
            cp -r "$skill_dir"/. "$CLAUDE_DIR/skills/$skill_name/"
            count=$((count + 1))
        fi
    done
    success "$count skills installed to $CLAUDE_DIR/skills/"
}

install_commands() {
    info "Installing commands..."
    mkdir -p "$CLAUDE_DIR/commands"
    local count=0
    for f in "$SCRIPT_DIR"/commands/*.md; do
        [ "$(basename "$f")" = "README.md" ] && continue
        cp "$f" "$CLAUDE_DIR/commands/"
        count=$((count + 1))
    done
    success "$count commands installed to $CLAUDE_DIR/commands/"
}

install_rules() {
    info "Installing rules..."
    mkdir -p "$CLAUDE_DIR/rules"
    local count=0
    for f in "$SCRIPT_DIR"/rules/*.md; do
        [ "$(basename "$f")" = "README.md" ] && continue
        cp "$f" "$CLAUDE_DIR/rules/"
        count=$((count + 1))
    done
    success "$count rules installed to $CLAUDE_DIR/rules/"
}

install_ecc() {
    info "Installing components from Everything Claude Code (ECC)..."
    mkdir -p "$REPOS_DIR"

    # Clone or update ECC
    if [ -d "$REPOS_DIR/everything-claude-code" ]; then
        info "Updating ECC repository..."
        cd "$REPOS_DIR/everything-claude-code"
        git pull --quiet 2>/dev/null || warn "Could not update ECC (network issue?)"
    else
        info "Cloning ECC repository..."
        git clone --depth 1 "$ECC_REPO" "$REPOS_DIR/everything-claude-code"
    fi

    local ecc_dir="$REPOS_DIR/everything-claude-code"
    local added=0

    # Import ECC agents (only new ones we don't already have)
    if [ -d "$ecc_dir/agents" ]; then
        mkdir -p "$CLAUDE_DIR/agents"
        for f in "$ecc_dir"/agents/*.md; do
            [ ! -f "$f" ] && continue
            local name
            name=$(basename "$f")
            if [ ! -f "$CLAUDE_DIR/agents/$name" ]; then
                cp "$f" "$CLAUDE_DIR/agents/"
                echo "  + Agent: $name"
                added=$((added + 1))
            fi
        done
    fi

    # Import ECC skills (only new ones)
    if [ -d "$ecc_dir/skills" ]; then
        for skill_dir in "$ecc_dir"/skills/*/; do
            [ ! -d "$skill_dir" ] && continue
            local skill_name
            skill_name=$(basename "$skill_dir")
            if [ ! -d "$CLAUDE_DIR/skills/$skill_name" ] && [ -f "$skill_dir/SKILL.md" ]; then
                mkdir -p "$CLAUDE_DIR/skills/$skill_name"
                cp "$skill_dir/SKILL.md" "$CLAUDE_DIR/skills/$skill_name/"
                echo "  + Skill: $skill_name"
                added=$((added + 1))
            fi
        done
    fi

    # Import ECC commands (only new ones)
    if [ -d "$ecc_dir/commands" ]; then
        mkdir -p "$CLAUDE_DIR/commands"
        for f in "$ecc_dir"/commands/*.md; do
            [ ! -f "$f" ] && continue
            local name
            name=$(basename "$f")
            [ "$name" = "README.md" ] && continue
            if [ ! -f "$CLAUDE_DIR/commands/$name" ]; then
                cp "$f" "$CLAUDE_DIR/commands/"
                echo "  + Command: $name"
                added=$((added + 1))
            fi
        done
    fi

    # Import ECC rules (only new ones)
    for rules_subdir in "$ecc_dir"/rules/common "$ecc_dir"/rules/*/; do
        [ ! -d "$rules_subdir" ] && continue
        mkdir -p "$CLAUDE_DIR/rules"
        for f in "$rules_subdir"/*.md; do
            [ ! -f "$f" ] && continue
            local name
            name=$(basename "$f")
            if [ ! -f "$CLAUDE_DIR/rules/$name" ]; then
                cp "$f" "$CLAUDE_DIR/rules/"
                echo "  + Rule: $name"
                added=$((added + 1))
            fi
        done
    done

    if [ $added -gt 0 ]; then
        success "$added new components imported from ECC"
    else
        success "ECC synced - no new components to import"
    fi
}

install_all() {
    echo ""
    echo "==========================================="
    echo " Claude Code Toolkit - Installer"
    echo "==========================================="
    echo ""
    install_agents
    install_rules
    install_skills
    install_commands
    install_statusline
    install_scripts
    install_hook
    install_config
    echo ""
    info "Importing additional components from ECC..."
    install_ecc
    echo ""
    success "All components installed!"
    echo ""
    info "Next steps:"
    echo "  1. Rellena la seccion 'Quien soy' de ~/.claude/CLAUDE.md"
    echo "  2. Dependencias de las skills (Whisper, OCR, Office...): bash install-deps.sh"
    echo "  3. Notas de voz /audio y hook de Telegram (opcional): TELEGRAM_BOT_TOKEN y TELEGRAM_CHAT_ID"
    echo "  4. Reinicia Claude Code"
    echo ""
}

show_summary() {
    echo ""
    info "Installed components summary:"
    local agents skills commands rules scripts
    agents=$(find "$CLAUDE_DIR/agents" -name "*.md" 2>/dev/null | wc -l)
    skills=$(find "$CLAUDE_DIR/skills" -name "SKILL.md" 2>/dev/null | wc -l)
    commands=$(find "$CLAUDE_DIR/commands" -name "*.md" 2>/dev/null | wc -l)
    rules=$(find "$CLAUDE_DIR/rules" -name "*.md" 2>/dev/null | wc -l)
    scripts=$(find "$CLAUDE_DIR/scripts" -name "*.sh" 2>/dev/null | wc -l)
    echo "  Agents:   $agents"
    echo "  Skills:   $skills"
    echo "  Commands: $commands"
    echo "  Rules:    $rules"
    echo "  Scripts:  $scripts"
    echo ""
}

# Parse arguments
# Accepts one or more flags in a single invocation (e.g. --commands --agents),
# not just the first one - each is processed in order, then a single summary
# is shown if more than one component flag was given.
if [ $# -eq 0 ]; then
    install_all
    show_summary
    exit 0
fi

multi=0
[ $# -gt 1 ] && multi=1

for arg in "$@"; do
    case "$arg" in
        --agents)     install_agents ;;
        --statusline) install_statusline ;;
        --hook|--hooks) install_hook ;;
        --config)     install_config ;;
        --skills)     install_skills ;;
        --commands)   install_commands ;;
        --rules)      install_rules ;;
        --scripts)    install_scripts ;;
        --ecc)        install_ecc ;;
        --ecc-only)   install_ecc ; [ "$multi" -eq 0 ] && show_summary ;;
        --summary)    show_summary ;;
        --all)        install_all ; [ "$multi" -eq 0 ] && show_summary ;;
        *)
            echo "Usage: bash install.sh [OPTION ...]"
            echo ""
            echo "Options (one or more, e.g. --commands --agents):"
            echo "  --all         Install everything (default)"
            echo "  --agents      Install agents only"
            echo "  --skills      Install skills only"
            echo "  --commands    Install commands only"
            echo "  --rules       Install coding rules only"
            echo "  --statusline  Install statusline only"
            echo "  --scripts     Install helper scripts only"
            echo "  --hooks       Install hooks only"
            echo "  --config      Base settings.json (bypass + bloqueos + Opus + statusline) y CLAUDE.md"
            echo "  --ecc         Import new components from Everything Claude Code"
            echo "  --ecc-only    Only import from ECC (skip toolkit install)"
            echo "  --summary     Show installed component counts"
            exit 1
            ;;
    esac
done

[ "$multi" -eq 1 ] && show_summary
