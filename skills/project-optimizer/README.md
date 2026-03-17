# Project Optimizer Skill

Audit and optimize any project for Claude Code efficiency in 6 phases.

## What it does

Analyzes your project and optimizes it so Claude Code consumes fewer tokens, finds information faster, and works more efficiently.

## Phases

1. **Diagnosis** - Analyze CLAUDE.md size, exposed credentials, file structure, memory system (read-only)
2. **Credentials** - Move secrets from CLAUDE.md to `.credentials.json`, update `.gitignore`
3. **Reduce CLAUDE.md** - Target < 150 lines. Move procedures to rules, context to memories
4. **Memory System** - Create structured memories (project, user, feedback, reference)
5. **Clean Structure** - Organize loose files, move backups to `_pendiente_borrado/`
6. **Verification** - Final scoring (0-10) with before/after comparison

## Install

```bash
mkdir -p ~/.claude/skills/project-optimizer
cp SKILL.md ~/.claude/skills/project-optimizer/
```

## Usage

**Recommended**: Use the `/optimize` command, which runs a 3-step agent pipeline (claude-code-guide diagnoses, general-purpose executes, claude-code-guide verifies).

**Alternative**: Trigger the skill via natural language:
- "optimiza el proyecto"
- "optimizar para claude"
- "revisa el proyecto"
- "project audit"

## Scoring Criteria

| Aspect | 0 pts | 1 pt | 2 pts |
|--------|-------|------|-------|
| CLAUDE.md size | >400 lines | 200-400 | <200 |
| Credentials | In CLAUDE.md | In rules | In .credentials.json |
| Memories | None | Basic | Complete (4+ types) |
| Modular rules | None | 1-2 rules | 3+ with globs |
| Root structure | >15 loose files | 8-15 | <8 |
