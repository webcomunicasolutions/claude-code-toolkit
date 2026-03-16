# Claude Code Toolkit

A collection of hooks, agents, skills, and utilities to supercharge your [Claude Code](https://docs.anthropic.com/en/docs/claude-code) experience.

## What's inside

| Component | Description |
|-----------|-------------|
| [**Telegram Approval Hook**](hooks/telegram-approval/) | Approve/deny Claude Code actions remotely from your phone via Telegram |
| [**Statusline**](statusline/) | Rich status bar showing context usage, tokens, costs, and session tracking |
| [**Project Optimizer**](skills/project-optimizer/) | Audit and optimize any project for Claude Code efficiency |
| [**8 Custom Agents**](agents/) | Code reviewer, TDD cycle, principal engineer, devil's advocate, and more |

## Quick Install

```bash
# Clone the repo
git clone https://github.com/webcomunicasolutions/claude-code-toolkit.git
cd claude-code-toolkit

# Run the installer (copies components to ~/.claude/)
bash install.sh
```

Or install individual components manually - see each component's README.

## Components

### Hooks

#### [Telegram Approval](hooks/telegram-approval/)
Smart PreToolUse hook that classifies operations by risk level and lets you approve dangerous ones via Telegram with interactive buttons.

- **3 modes**: Terminal only, Terminal + Telegram (hybrid), Telegram blocking
- **Smart filtering**: Safe ops auto-approve, dangerous ops require approval
- **Configurable sensitivity**: `all`, `smart` (default), `critical`
- **Reminders & relaunch**: Auto-reminders + relaunch button on timeout

### Statusline

#### [Custom Statusline](statusline/)
Rich status bar for Claude Code showing real-time metrics:

- Context window usage with progress bar
- Input/output token counts
- Session tracking (prompts, burn rate)
- Git branch info
- Time until rate limit reset

### Skills

#### [Project Optimizer](skills/project-optimizer/)
6-phase audit and optimization workflow:

1. **Diagnosis** - Analyze project state without changes
2. **Credentials** - Find and secure exposed secrets
3. **Reduce CLAUDE.md** - Target < 150 lines
4. **Memory system** - Set up persistent memories
5. **Clean structure** - Organize files and remove clutter
6. **Verification** - Final checks and scoring (0-10)

### Agents

8 specialized agents for different workflows:

| Agent | Purpose |
|-------|---------|
| `code-reviewer` | Senior code review for quality, security, and maintainability |
| `principal-engineer` | Martin Fowler-style engineering leadership and pragmatism |
| `tdd-red` | TDD Red phase - Write failing tests first |
| `tdd-green` | TDD Green phase - Minimum code to pass tests |
| `tdd-refactor` | TDD Refactor phase - Improve quality keeping tests green |
| `test-generator` | Comprehensive test case generation |
| `devils-advocate` | Challenge assumptions and force critical thinking |
| `verifier` | Verification gate - Evidence before claims, always |

## Manual Installation

### Agents
```bash
cp agents/*.md ~/.claude/agents/
```

### Statusline
```bash
cp statusline/statusline.sh ~/.claude/statusline.sh
# Add to settings.json:
# "statusline": { "command": "bash ~/.claude/statusline.sh" }
```

### Telegram Hook
See [hooks/telegram-approval/README.md](hooks/telegram-approval/README.md) for full setup (requires a Telegram bot).

### Project Optimizer Skill
```bash
mkdir -p ~/.claude/skills/project-optimizer
cp skills/project-optimizer/SKILL.md ~/.claude/skills/project-optimizer/
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- `jq` and `curl` (for hooks and statusline)
- `bc` (for statusline cost calculations)
- A Telegram bot (only for the Telegram hook)

## Contributing

PRs welcome! If you have a useful agent, hook, or skill for Claude Code, open a PR.

## License

MIT
