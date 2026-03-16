#!/bin/bash
# =============================================================================
# Claude Code Toolkit - Installer
# =============================================================================
# Copies agents, hooks, skills, and statusline to ~/.claude/
# Run: bash install.sh [--all | --agents | --statusline | --hook | --skill]
# =============================================================================

set -e

CLAUDE_DIR="$HOME/.claude"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

install_agents() {
    info "Installing agents..."
    mkdir -p "$CLAUDE_DIR/agents"
    cp "$SCRIPT_DIR"/agents/*.md "$CLAUDE_DIR/agents/" 2>/dev/null || true
    # Remove the README from agents dir (it's not an agent)
    rm -f "$CLAUDE_DIR/agents/README.md"
    success "Agents installed to $CLAUDE_DIR/agents/"
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

install_skill() {
    info "Installing project-optimizer skill..."
    mkdir -p "$CLAUDE_DIR/skills/project-optimizer"
    cp "$SCRIPT_DIR/skills/project-optimizer/SKILL.md" "$CLAUDE_DIR/skills/project-optimizer/"
    success "Skill installed to $CLAUDE_DIR/skills/project-optimizer/"
}

install_all() {
    echo ""
    echo "==============================="
    echo " Claude Code Toolkit Installer"
    echo "==============================="
    echo ""
    install_agents
    install_statusline
    install_hook
    install_skill
    echo ""
    success "All components installed!"
    echo ""
    info "Next steps:"
    echo "  1. Configure statusline in settings.json"
    echo "  2. Configure Telegram hook in settings.json (optional)"
    echo "  3. Set TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID (optional)"
    echo "  4. Restart Claude Code"
}

# Parse arguments
case "${1:-}" in
    --agents)     install_agents ;;
    --statusline) install_statusline ;;
    --hook)       install_hook ;;
    --skill)      install_skill ;;
    --all|"")     install_all ;;
    *)
        echo "Usage: bash install.sh [--all | --agents | --statusline | --hook | --skill]"
        exit 1
        ;;
esac
