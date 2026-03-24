---
name: agentic-engineering
description: Patrones de ingenieria agentica - workflows dirigidos por IA con supervision humana. Usar cuando se disenan sistemas multi-agente, loops autonomos, o pipelines de IA.
---

# Agentic Engineering

## Principios operativos

### Criterios de finalizacion
Define que significa "hecho" ANTES de ejecutar. Sin criterios claros, los agentes loop indefinidamente.

### Descomposicion de trabajo
Regla de 15 minutos: cada unidad de trabajo debe ser completable en ~15 min por un agente.

### Routing por complejidad
| Complejidad | Modelo | Ejemplos |
|-------------|--------|----------|
| Clasificacion, ediciones simples | Haiku | Formateo, grep, renombrar |
| Implementacion, refactoring | Sonnet | Features, tests, debugging |
| Arquitectura, multi-archivo | Opus | Diseno, revision profunda |

### Eval-First Loop
1. Define evaluaciones antes de implementar
2. Ejecuta baseline
3. Implementa cambios
4. Re-ejecuta evals
5. Compara deltas

### Revision enfocada en:
- Invariantes y edge cases
- Limites de error
- Suposiciones de seguridad
- Acoplamiento oculto

### Disciplina de costo
Track por tarea: modelo usado, tokens, reintentos, tiempo, resultado.

## Patrones de orquestacion

### Orchestrator-Worker
Un agente principal delega a workers especializados. El orchestrator:
- Descompone la tarea
- Asigna a workers apropiados
- Consolida resultados
- Verifica calidad

### Pipeline
Secuencia de agentes donde la salida de uno es la entrada del siguiente:
Plan -> Implement -> Test -> Review -> Deploy

### Fan-Out/Fan-In
Un agente envia la misma tarea a multiples workers (ej: mismo cambio en multiples archivos), luego consolida.
