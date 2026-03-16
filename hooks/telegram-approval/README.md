# Telegram Approval Hook

Smart PreToolUse hook for Claude Code that classifies operations by risk and lets you approve dangerous ones via Telegram.

> Full standalone version with installer: [claude-telegram-hook](https://github.com/webcomunicasolutions/claude-telegram-hook)

## How it works

```
Claude Code action → Risk classification → Safe? Auto-approve
                                         → Dangerous? → Telegram/Terminal approval
```

### Risk Classification

**Auto-approved (safe):**
- Read-only: `ls`, `cat`, `grep`, `find`, `git status/log/diff`
- Queries: `jq`, `ping`, `dig`, `npm list`, `pip list`

**Requires approval (dangerous):**
- Destructive: `rm`, `chmod`, `kill`, `systemctl`
- System: `apt`, `docker rm/stop`, `sudo`
- Git writes: `git push`, `git reset`, `git rebase`

### 3 Operating Modes

| Mode | When | Behavior |
|------|------|----------|
| Terminal only | Telegram OFF | Passthrough to Claude's y/n prompt |
| Terminal + Telegram | Telegram ON + tmux | Terminal prompt + Telegram after 120s |
| Telegram blocking | Telegram ON, no tmux | Telegram buttons only |

## Setup

### 1. Create a Telegram Bot

1. Message [@BotFather](https://t.me/BotFather) on Telegram
2. Send `/newbot` and follow the prompts
3. Save the bot token
4. Get your chat ID by messaging [@userinfobot](https://t.me/userinfobot)

### 2. Set Environment Variables

```bash
export TELEGRAM_BOT_TOKEN="your-bot-token"
export TELEGRAM_CHAT_ID="your-chat-id"
```

### 3. Install the Hook

```bash
cp hook_permission_telegram.sh ~/.claude/hooks/
```

### 4. Configure in settings.json

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "type": "command",
        "command": "bash ~/.claude/hooks/hook_permission_telegram.sh"
      }
    ]
  }
}
```

### 5. Toggle Telegram Mode

```bash
# Enable Telegram approval
touch /tmp/claude_telegram_active

# Disable (terminal only)
rm -f /tmp/claude_telegram_active
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `TELEGRAM_BOT_TOKEN` | - | Bot token from BotFather |
| `TELEGRAM_CHAT_ID` | - | Your Telegram user ID |
| `TELEGRAM_PERMISSION_TIMEOUT` | `300` | Seconds before timeout |
| `TELEGRAM_SENSITIVITY` | `smart` | `all`, `smart`, or `critical` |
| `TELEGRAM_FALLBACK_ON_ERROR` | `allow` | Fallback if Telegram unreachable |
| `TELEGRAM_MAX_RETRIES` | `2` | Relaunch attempts on timeout |

## Requirements

- `curl`, `jq`
- Optional: `tmux` (for hybrid mode)
