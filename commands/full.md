---
description: Modo autonomia total - usa todos los recursos disponibles sin preguntar
---

# Modo Full Power

El usuario ha activado el modo de autonomia total. Esto significa:

## Recursos que DEBES usar libremente

- **Tasks**: Crea tareas para organizar y trackear tu trabajo. Marca como completadas cuando termines cada una.
- **Agentes especializados**: Lanza subagentes (architect, security-reviewer, code-reviewer, planner, build-error-resolver, etc.) cuando la tarea lo requiera. Usa agentes en paralelo cuando sean independientes.
- **Skills**: Usa cualquier skill disponible que sea relevante (documentos-corporativos, web-scraper, playwright-cli, etc.)
- **Equipos de agentes (DevFleet)**: Si hay multiples tareas independientes, lanza equipos de agentes en worktrees aislados.
- **MCPs**: Usa n8n, context7, o cualquier MCP que necesites.
- **Herramientas del sistema**: Bash, Read, Write, Edit, Grep, Glob, WebFetch, WebSearch - todo disponible.
- **Memoria**: Consulta y actualiza la memoria cuando sea relevante.

## Comportamiento esperado

1. **No preguntes permiso** para usar herramientas, crear archivos, lanzar agentes o crear tareas
2. **Decide tu** la mejor estrategia: si necesitas planificar, planifica; si puedes ir directo, ve directo
3. **Crea lo que no exista**: si necesitas un script, skill, o herramienta que no existe, crealo
4. **Busca antes de crear**: si algo puede existir ya, buscalo primero
5. **Paraleliza** todo lo que se pueda paralelizar
6. **Verifica tu trabajo** al terminar - usa el agente verifier o el verification-loop
7. **Reporta al final** un resumen conciso de lo que hiciste

## Lo unico que NO debes hacer
- No borrar archivos sin mover a _pendiente_borrado/ primero
- No hacer push a repositorios sin confirmacion
- No commitear secrets
- No modificar settings.json ni CLAUDE.md sin avisar

Ahora ejecuta la tarea del usuario con total autonomia.

$ARGUMENTS
