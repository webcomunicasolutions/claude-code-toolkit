---
description: Definir y ejecutar evaluaciones de features
---

# Eval

Gestiona evaluaciones para medir calidad de implementaciones.

## Instrucciones

### Operaciones

**`define [feature]`** - Crea nueva evaluacion:
1. Crea `.claude/evals/[feature].md` con plantilla:
   - Capability tests (funcionalidad nueva)
   - Regression tests (funcionalidad existente)
   - Criterios de exito

**`check [feature]`** - Ejecuta evaluacion:
1. Lee definicion de `.claude/evals/[feature].md`
2. Verifica cada criterio
3. Registra resultados con timestamp

**`report [feature]`** - Genera reporte:
1. Muestra pass rate por categoria
2. Metricas: pass@1, pass@3
3. Recomendacion: READY / NOT READY / NEEDS WORK

**`list`** - Lista todas las evaluaciones:
1. Muestra cada eval con estado: IN PROGRESS / READY / NOT STARTED

**`clean`** - Limpia logs antiguos (mantiene ultimos 10 runs)

### Criterios de exito estandar
- Capability evals: pass@3 > 90%
- Regression evals: 100% pass rate

$ARGUMENTS
