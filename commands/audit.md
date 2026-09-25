---
description: Detectar problemas en el PROYECTO actual (no modifica). Para aplicar mejoras, ver /optimize.
---

# Audit Project (read-only)

Lanza al agente `project-auditor` sobre el proyecto actual y entrega un reporte priorizado con hallazgos y plan de accion. **No modifica nada** — solo detecta.

## Cuando usar este vs los otros

- `/audit` (este): detectar en PROYECTO sin tocar nada
- `/optimize`: APLICAR mejoras en proyecto (puede ejecutar `/audit` antes)
- `/harness-audit`: detectar en CONFIG GLOBAL `~/.claude/`
- `/harness-fix`: APLICAR mejoras en config global

Si se pasan argumentos ($ARGUMENTS), enfocar la auditoria en esa categoria o ruta. Ejemplos:
- `/audit` - auditoria completa
- `/audit security` - solo seguridad
- `/audit skills` - solo skills locales
- `/audit .claude/` - solo configuracion Claude

## Instrucciones

1. Invocar el agente `project-auditor` (subagent_type) con el contexto del directorio actual.
2. Pasarle al agente la categoria o ruta del argumento (si hay).
3. Mostrar el reporte tal cual lo devuelve el agente.
4. Al final, preguntar al usuario que hallazgos quiere abordar primero.

## Despues de la auditoria

Si el usuario quiere actuar sobre los hallazgos:
- Para mejoras de skills/configuracion: aplicar Edit/Write directamente
- Para refactoring de codigo: invocar agentes especializados (code-reviewer, security-reviewer)
- Para reorganizacion grande: usar skill `project-optimizer`

NO modificar nada sin confirmacion del usuario, salvo cambios triviales (typos, permisos chmod +x obvios).
