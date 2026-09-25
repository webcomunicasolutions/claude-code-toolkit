---
description: Detectar problemas en la CONFIG GLOBAL ~/.claude/ (no modifica). Scores por categoria con evidencia e historico. Para aplicar mejoras, ver /harness-fix.
---

# Harness Audit (read-only)

Evalua la configuracion global de Claude Code (`~/.claude/`) contra 7 categorias estandarizadas. **No modifica nada** — solo evalua, puntua y guarda el informe.

## Cuando usar este vs los otros

- `/harness-audit` (este): scores 0-10 de tu config GLOBAL `~/.claude/`
- `/harness-fix`: aplicar mejoras en config global
- `/audit`: detectar problemas en un PROYECTO concreto
- `/optimize`: aplicar mejoras en proyecto

## Checklist de inspeccion (OBLIGATORIO, en este orden)

No improvisar que mirar. Ejecutar TODOS estos pasos antes de puntuar:

### 1. settings.json
- `jq empty` (JSON valido), `defaultMode` de permisos, lista `deny` (¿vacia?)
- Permisos peligrosos en `allow` (sudo, sshpass, rm, curl) — evaluar junto al hook de aprobacion
- **Secrets embebidos** (API keys en `mcp.servers.*.env`) — verificar que settings.json esta en `.gitignore`
- Hooks declarados vs archivos reales en `hooks/` (huerfanos en ambos sentidos)
- Timeouts de hooks (unidad = SEGUNDOS; >600 es sospechoso)
- MCPs declarados: ¿responden? ¿credenciales vigentes?

### 2. Fuga de secrets al backup
- `grep settings ~/.claude/.gitignore` — debe estar excluido
- Si hay repo GitHub de backup: `gh api repos/<owner>/<repo>/contents/settings.json` — NO debe existir
- Si existe: comparar token remoto vs local SIN imprimirlos, y probar el remoto contra la API (¿vivo?)

### 3. Contexto siempre cargado
- `wc -l ~/.claude/CLAUDE.md` (<80 lineas)
- `ls ~/.claude/rules/ | wc -l` — TODAS se inyectan en cada mensaje. ¿Hay reglas de lenguajes/dominios que no se usan? (candidatas a `rules-ondemand/`)
- MEMORY.md: contrastar version de Claude Code (`claude --version`), conteos de skills/commands/agents/rules, y fecha de "proxima revision"

### 4. Skills, commands, agents
- Skills sin SKILL.md: `for d in ~/.claude/skills/*/; do [ -f "$d/SKILL.md" ] || echo "$d"; done`
- Archivos `.skill` (ZIP) sueltos junto a su carpeta descomprimida
- Solapamientos evidentes entre skills (fusiones pendientes)

### 5. Sesiones y memoria
- `du -sh ~/.claude/sessions/` (bloat), sistema de memoria activo, fecha ultima revision

### 6. Evals
- ¿Existe `~/.claude/evals/`? ¿Se miden resultados de skills/workflows criticos?

### 7. Coste
- Tabla de model routing vigente (contrastar con familia de modelos actual — skill `claude-api` si hay dudas)
- effortLevel, thinking, tracking (ccusage/claude-monitor)

## Regla de evidencia

Cada hallazgo DEBE citar su prueba: `archivo:linea`, salida de comando, o HTTP code. Un score sin evidencia no vale — repetir la inspeccion.

## Historico

1. Antes de puntuar: leer el ultimo informe en `~/.claude/.audits/harness/` (si existe) para comparar.
2. Al terminar: guardar el informe completo en `~/.claude/.audits/harness/YYYY-MM-DD.md`.
3. Mostrar el delta de score total vs el informe anterior.

## Output

```
## Harness Audit Report
**Fecha:** [YYYY-MM-DD]
**Score total:** XX/70 (anterior: YY/70, delta +/-Z)

| Categoria | Score | Hallazgos (con evidencia) |
|-----------|-------|---------------------------|
| Tool Coverage | X/10 | [detalle + prueba] |
| Context Efficiency | X/10 | ... |
| Quality Gates | X/10 | ... |
| Memory Persistence | X/10 | ... |
| Eval Coverage | X/10 | ... |
| Security Guardrails | X/10 | ... |
| Cost Efficiency | X/10 | ... |

## Top 3 acciones prioritarias
1. [accion mas impactante]
2. ...
3. ...
```

## Auto-mejora

Al cerrar cada auditoria:
1. Si se descubrio un tipo de problema que el checklist no cubria, AÑADIRLO al checklist de este archivo.
2. Registrar el caso en la seccion "Errores conocidos" de abajo si es recurrente.
3. Si `/harness-fix` aplico los fixes, anotar en el informe guardado que se aplico.

## Errores conocidos

- **2026-07-09**: settings.json con API key de n8n llego al repo GitHub de backup porque `.gitignore` no lo excluia; el token estaba VIVO. Leccion: la exclusion del .gitignore se verifica contra el REPO REMOTO, no solo contra el archivo local. Y todo token hallado se prueba contra su API antes de asumir que esta revocado.
- **2026-07-09**: `timeout` de hooks en settings.json esta en segundos; un valor de 5000 (copiado como si fueran ms) daba 83 minutos de timeout.

$ARGUMENTS
