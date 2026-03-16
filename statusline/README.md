# Claude Code Statusline

Rich status bar for Claude Code showing real-time session metrics.

## What it shows

```
📁 ~/projects/myapp │ 🤖 Claude Sonnet 4.5 │ ⏰ Reset: 3h 42m
🧠 23% (231K/1000K) █████░░░░░░░░░░░░░░░ │ In: 180,234 │ Out: 51,002
```

**Line 1:** Current directory | Model name | Time until rate limit reset

**Line 2:** Context usage % | Progress bar | Input/Output tokens

## Features

- Context window usage with color-coded progress bar (green/yellow/red)
- Session tracking: prompt count, burn rate (tokens/min)
- Rate limit estimation (5-hour window, ~125 prompts)
- Git branch display when in a repository
- Cost calculation (based on Claude Sonnet 4.5 pricing)

## Install

```bash
cp statusline.sh ~/.claude/statusline.sh
```

Add to your `~/.claude/settings.json`:

```json
{
  "statusline": {
    "command": "bash ~/.claude/statusline.sh"
  }
}
```

## Requirements

- `jq` - JSON parsing
- `bc` - Cost calculations
- `git` - Branch info (optional)
