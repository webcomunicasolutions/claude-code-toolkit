---
description: APLICAR mejoras en la CONFIG GLOBAL ~/.claude/ (settings.json, CLAUDE.md, skills, hooks). Si solo quieres detectar, usa /harness-audit.
---

# Harness Fix (escribe)

Aplica mejoras a la configuracion global de Claude Code (`~/.claude/`). Idealmente ejecuta `/harness-audit` antes para tener el diagnostico, luego este comando aplica los fixes.

## Cuando usar este vs los otros

- `/harness-fix` (este): APLICAR mejoras en config GLOBAL `~/.claude/`
- `/harness-audit`: solo detectar en config global (no modifica)
- `/audit`: detectar en PROYECTO
- `/optimize`: aplicar mejoras en proyecto

## Categorias que cubre

Las mismas 7 que `/harness-audit`:

1. **Tool Coverage** — skills, commands, agents huerfanos o duplicados
2. **Context Efficiency** — CLAUDE.md >80 lineas, MEMORY.md desactualizada
3. **Quality Gates** — hooks rotos, scripts no ejecutables
4. **Memory Persistence** — sesiones huerfanas, archivos efimeros pesados
5. **Eval Coverage** — evals sin actualizar
6. **Security Guardrails** — credenciales hardcodeadas, permisos huerfanos, IPs de cliente en global
7. **Cost Efficiency** — modelo configurado obsoleto, MCPs no usados

## Proceso

1. Si NO hay diagnostico previo (`/harness-audit` no ejecutado en esta sesion), ejecutarlo primero.
2. Presentar al usuario la lista priorizada CRITICAL/HIGH/MEDIUM/LOW.
3. Aplicar cambios en orden, **preguntando antes de cada uno destructivo** (borrar skills, mover archivos, rotar credenciales).
4. Cambios triviales (typos, permisos chmod, fusion de permisos redundantes): aplicar sin pedir.
5. Al final, mostrar resumen consolidado.

## Reglas

- NUNCA borrar archivos directamente: mover a `~/.claude/_pendiente_borrado/` o equivalente.
- Para credenciales: seguir protocolo `~/.claude/rules/credentials-handling.md` (vault primero).
- Para hooks de un cliente concreto: mover al settings.json del proyecto, no dejar en global.
- Validar JSON con `jq empty` despues de cada edicion de settings.json.

## Referencia de implementacion

La auditoria global del 2026-05-27 (sesion "automejora_skills y backup github") aplico exactamente este flujo. Ver:
- `~/.credentials/claude-code.json` (credenciales movidas al vault)
- `~/.claude/rules/system-tools.md` y `update-claude.md` (extraidos de CLAUDE.md)
- Fusion de 73 a 55 permisos en settings.json
