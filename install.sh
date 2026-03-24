#!/bin/bash
# =============================================================================
# Claude Code Toolkit - Installer
# =============================================================================
# Installs agents, hooks, skills, commands, rules, statusline, and optionally
# pulls additional components from Everything Claude Code (ECC).
#
# Run: bash install.sh [--all | --agents | --statusline | --hook | --skills
#                       | --commands | --rules | --ecc | --ecc-only]
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
    warn "Add to settings.json: \"statusline\": { \"command\": \"bash ~/.claude/statusline.sh\" }"
}

install_hook() {
    info "Installing Telegram approval hook..."
    mkdir -p "$CLAUDE_DIR/hooks"
    cp "$SCRIPT_DIR/hooks/telegram-approval/hook_permission_telegram.sh" "$CLAUDE_DIR/hooks/"
    chmod +x "$CLAUDE_DIR/hooks/hook_permission_telegram.sh"
    success "Hook installed to $CLAUDE_DIR/hooks/"
    warn "Set TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID environment variables"
    warn "Add hook to settings.json (see hooks/telegram-approval/README.md)"
}

install_skills() {
    info "Installing skills..."
    local count=0
    for skill_dir in "$SCRIPT_DIR"/skills/*/; do
        [ ! -d "$skill_dir" ] && continue
        local skill_name
        skill_name=$(basename "$skill_dir")
        if [ -f "$skill_dir/SKILL.md" ]; then
            mkdir -p "$CLAUDE_DIR/skills/$skill_name"
            cp "$skill_dir/SKILL.md" "$CLAUDE_DIR/skills/$skill_name/"
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
    install_hook
    echo ""
    info "Importing additional components from ECC..."
    install_ecc
    echo ""
    success "All components installed!"
    echo ""
    info "Next steps:"
    echo "  1. Configure statusline in settings.json"
    echo "  2. Configure Telegram hook in settings.json (optional)"
    echo "  3. Set TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID (optional)"
    echo "  4. Restart Claude Code"
    echo ""
    info "To enable agent teams, add to settings.json:"
    echo '  "agentTeam": { "enabled": true }'
    echo ""
}

show_summary() {
    echo ""
    info "Installed components summary:"
    local agents skills commands rules
    agents=$(find "$CLAUDE_DIR/agents" -name "*.md" 2>/dev/null | wc -l)
    skills=$(find "$CLAUDE_DIR/skills" -name "SKILL.md" 2>/dev/null | wc -l)
    commands=$(find "$CLAUDE_DIR/commands" -name "*.md" 2>/dev/null | wc -l)
    rules=$(find "$CLAUDE_DIR/rules" -name "*.md" 2>/dev/null | wc -l)
    echo "  Agents:   $agents"
    echo "  Skills:   $skills"
    echo "  Commands: $commands"
    echo "  Rules:    $rules"
    echo ""
}

# Parse arguments
case "${1:-}" in
    --agents)     install_agents ;;
    --statusline) install_statusline ;;
    --hook)       install_hook ;;
    --skills)     install_skills ;;
    --commands)   install_commands ;;
    --rules)      install_rules ;;
    --ecc)        install_ecc ;;
    --ecc-only)   install_ecc ; show_summary ;;
    --summary)    show_summary ;;
    --all|"")     install_all ; show_summary ;;
    *)
        echo "Usage: bash install.sh [OPTION]"
        echo ""
        echo "Options:"
        echo "  --all         Install everything (default)"
        echo "  --agents      Install agents only"
        echo "  --skills      Install skills only"
        echo "  --commands    Install commands only"
        echo "  --rules       Install coding rules only"
        echo "  --statusline  Install statusline only"
        echo "  --hook        Install Telegram hook only"
        echo "  --ecc         Import new components from Everything Claude Code"
        echo "  --ecc-only    Only import from ECC (skip toolkit install)"
        echo "  --summary     Show installed component counts"
        exit 1
        ;;
esac
