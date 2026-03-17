# Custom Commands

Slash commands for Claude Code that activate specialized modes or workflows.

## Available Commands

| Command | Description |
|---------|-------------|
| `/optimize` | Audit and optimize any project for Claude Code using the `claude-code-guide` agent as architect |
| `/n8n` | Activate n8n specialist mode for creating, modifying, and optimizing workflows |

## How Commands Work

Commands are `.md` files placed in `~/.claude/commands/`. When you type `/command-name` in Claude Code, the file contents are injected as instructions.

Unlike skills (which are triggered by natural language), commands are explicitly invoked with the `/` prefix.

## Install

```bash
mkdir -p ~/.claude/commands
cp commands/*.md ~/.claude/commands/
```

## Notes

- `/optimize` uses Claude Code's built-in agents (`claude-code-guide` and `general-purpose`), not custom agents from this toolkit.
- `/n8n` activates a specialist conversational mode - no special agents required.

## Creating Your Own Commands

Create a `.md` file with:
```yaml
---
description: Short description shown in the command list
---

# Command Title

Instructions for Claude...
```

The filename (without `.md`) becomes the command name.
