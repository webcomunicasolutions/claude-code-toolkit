---
description: Seleccionar modelo optimo segun tarea y presupuesto
---

# Model Route

Recomienda el modelo Claude optimo segun la complejidad de la tarea.

## Instrucciones

Analiza la descripcion de la tarea y recomienda:

### Modelos disponibles
| Modelo | Costo | Mejor para |
|--------|-------|------------|
| **Haiku 4.5** | 1x (bajo) | Clasificacion, ediciones simples, formateo, grep |
| **Sonnet 4.6** | 4x (medio) | Implementacion, refactoring, debugging, testing |
| **Opus 4.6** | 15x (alto) | Arquitectura, revision profunda, specs ambiguas, multi-archivo complejo |

### Decision framework
- **Trivial** (1 archivo, cambio claro) -> Haiku
- **Standard** (implementacion, refactoring, tests) -> Sonnet
- **Complejo** (arquitectura, investigacion, specs ambiguos) -> Opus

### Output requerido
1. **Modelo recomendado:** [nombre]
2. **Confianza:** alta/media/baja
3. **Justificacion:** [por que este modelo]
4. **Alternativa:** [si el primero no rinde, usar este]

$ARGUMENTS
