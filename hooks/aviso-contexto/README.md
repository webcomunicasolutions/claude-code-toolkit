# aviso-contexto

Hook `PostToolUse` que avisa una sola vez por sesion cuando la conversacion se acerca al limite de contexto (~50 % y ~75 %).

Claude Code no expone el % de contexto a los hooks, asi que usa el **tamano del transcript** como estimacion bruta (4 MB ~ 50 %, 6 MB ~ 75 %). Ajusta `TH50` y `TH75` en el script comparando con `/context`.

Requiere `jq`. Silencioso si no aplica.

## Instalacion

```bash
mkdir -p ~/.claude/hooks
cp aviso-contexto.sh ~/.claude/hooks/ && chmod +x ~/.claude/hooks/aviso-contexto.sh
```

Anade en `~/.claude/settings.json` (dentro de `"hooks"`):

```json
"PostToolUse": [
  {
    "matcher": "",
    "hooks": [
      {
        "type": "command",
        "command": "bash ~/.claude/hooks/aviso-contexto.sh",
        "timeout": 10
      }
    ]
  }
]
```

Si ya tienes otros `PostToolUse`, anade el objeto a la lista existente.
