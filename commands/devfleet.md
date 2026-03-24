---
description: Orquestar multiples agentes en paralelo con worktrees
---

# DevFleet

Orquesta multiples agentes Claude Code trabajando en paralelo, cada uno en su propio git worktree aislado.

## Instrucciones

### Flujo de trabajo
1. **Planificar**: Descompone la tarea del usuario en sub-misiones independientes
2. **Aprobar**: Presenta el plan completo al usuario antes de ejecutar
3. **Ejecutar**: Lanza agentes en worktrees aislados (maximo 3 concurrentes)
4. **Monitorear**: Reporta progreso de cada agente
5. **Consolidar**: Merge de resultados y reporte final

### Para cada sub-mision:
1. Crea worktree: `git worktree add /tmp/claude/fleet-[nombre] -b fleet/[nombre]`
2. Lanza agente con Agent tool (isolation: "worktree")
3. Al completar, reporta: archivos cambiados, trabajo hecho, errores

### Restricciones
- Maximo 3 agentes concurrentes (el resto en cola)
- Dependencias deben formar DAG (sin ciclos)
- Conflictos de merge se dejan en branch para resolucion manual
- Cada agente tiene contexto aislado

### Reporte final
```
## DevFleet Report
**Misiones:** X completadas / Y total
**Branches:** [lista de branches con cambios]
**Archivos modificados:** [total]
**Errores:** [si los hay]
**Proximos pasos:** [merge manual necesario / listo para merge]
```

$ARGUMENTS
