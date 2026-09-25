# Custom Commands

Slash commands for Claude Code that activate specialized modes or workflows.

## Available Commands

| Command | Description |
|---------|-------------|
| `/audio` | Send yourself a short Telegram voice note summarizing what Claude just explained (needs `TELEGRAM_BOT_TOKEN`/`TELEGRAM_CHAT_ID` and `scripts/audio-nota.sh`) |
| `/audit` | Detect problems in the CURRENT project (read-only). To apply fixes, see `/optimize` |
| `/autoresearch` | Autonomous continuous-improvement loop (Karpathy's AutoResearch pattern) applied to any project |
| `/build-fix` | Systematically resolve build/compilation errors |
| `/checkpoint` | Create a checkpoint of the current code state |
| `/code-review` | Exhaustive code review with a security checklist |
| `/devfleet` | Orchestrate multiple agents in parallel using git worktrees |
| `/eval` | Define and run feature evaluations |
| `/full` | Full-autonomy mode - use all available resources without asking |
| `/harness-audit` | Detect problems in the GLOBAL config `~/.claude/` (read-only). Scores per category, with evidence and history. To apply fixes, see `/harness-fix` |
| `/harness-fix` | APPLY fixes to the GLOBAL config `~/.claude/` (settings.json, CLAUDE.md, skills, hooks). To only detect, use `/harness-audit` |
| `/loop-start` | Start an autonomous loop with safety guardrails |
| `/loop-status` | Check the status of the active autonomous loop |
| `/model-route` | Pick the optimal model for a task given cost/quality tradeoffs |
| `/optimize` | APPLY improvements to the CURRENT project (shrinks CLAUDE.md, creates memories, cleans structure). To only detect, use `/audit` |
| `/plan` | Create a detailed implementation plan before coding |
| `/resume-session` | Resume a previously saved session |
| `/save-session` | Save the current session state to resume it later |
| `/tdd` | Test-driven development - RED/GREEN/REFACTOR |
| `/watch-bridge` | Guard mode over `shared/BRIDGE.md` - listens for new messages from sibling projects (requires the `project-bridge` skill set up first) |

## How Commands Work

Commands are `.md` files placed in `~/.claude/commands/`. When you type `/command-name` in Claude Code, the file contents are injected as instructions.

Unlike skills (which are triggered by natural language), commands are explicitly invoked with the `/` prefix.

## Install

```bash
mkdir -p ~/.claude/commands
cp commands/*.md ~/.claude/commands/
```

Or use the toolkit's `install.sh --commands` (see the repo root).

## Notes

- `/optimize` and `/audit`/`/harness-audit`/`/harness-fix` form two read/write pairs: one detects
  (project vs global config), the other applies. Run the read-only one first if unsure.
- `/audio` depends on `scripts/audio-nota.sh` (installed by `install.sh --scripts`) and on
  `edge-tts`/`ffmpeg` being available on the system. It never touches any TTS credit-based service -
  it uses the free, keyless `edge-tts` engine by default.
- `/watch-bridge` assumes you've set up a `shared/BRIDGE.md` channel with the `project-bridge` skill
  first; without it there's nothing to watch.
- Two commands from the source config were intentionally left out of this public toolkit:
  a "new web" orchestrator and an EasyPanel deploy helper, both hardwired to a private PHP stack,
  a private Docker Hub image and internal client paths. They're not portable as-is.

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
