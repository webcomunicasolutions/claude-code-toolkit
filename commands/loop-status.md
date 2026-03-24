---
description: Ver estado del loop autonomo activo
---

# Loop Status

Muestra el estado del loop de trabajo actual.

## Instrucciones

1. Busca el plan de loop mas reciente en `.claude/plans/loop-*.md`
2. Lee el archivo y reporta:
   - Patron activo (sequential/continuous/parallel)
   - Fase actual y ultimo checkpoint exitoso
   - Checks fallidos (si los hay)
   - Progreso: tareas completadas / total
3. Si se usa `--watch`: refresca periodicamente mostrando transiciones de estado

$ARGUMENTS
