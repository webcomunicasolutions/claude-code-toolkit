# audit-reminder

Hook `SessionStart` que, al abrir Claude Code en un proyecto, avisa si no se ha auditado en mas de 14 dias (o nunca, si el proyecto tiene `CLAUDE.md` o `.claude/`). No bloquea ni audita: solo recuerda que existe `/audit`.

Guarda marcas por proyecto en `~/.claude/.audits/` (el hash del directorio). Para marcar un proyecto como auditado: `touch ~/.claude/.audits/$(pwd | md5sum | cut -d' ' -f1)`.

## Instalacion

```bash
mkdir -p ~/.claude/hooks
cp audit_reminder.sh ~/.claude/hooks/ && chmod +x ~/.claude/hooks/audit_reminder.sh
```

Anade en `~/.claude/settings.json` (dentro de `"hooks"`):

```json
"SessionStart": [
  {
    "matcher": "startup",
    "hooks": [
      {
        "type": "command",
        "command": "~/.claude/hooks/audit_reminder.sh"
      }
    ]
  }
]
```
