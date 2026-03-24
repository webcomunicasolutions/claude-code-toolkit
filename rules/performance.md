# Performance

## Seleccion de modelo
| Modelo | Costo | Usar para |
|--------|-------|-----------|
| Haiku 4.5 | 1x | Tareas simples, clasificacion, formateo |
| Sonnet 4.6 | 4x | Implementacion, refactoring, debugging |
| Opus 4.6 | 15x | Arquitectura, investigacion, specs ambiguos |

## Gestion del context window
- Los primeros 80% del contexto son efectivos; el ultimo 20% degrada calidad
- Con muchos MCPs/tools, 200k de contexto puede ser ~70k efectivo
- Compactar en puntos logicos (entre features, no en medio de implementacion)

## Extended thinking
- Activado por default (alwaysThinkingEnabled: true)
- Util para: analisis complejo, debugging dificil, decisiones arquitecturales
- Toggle: Alt+T (Linux/Windows), Option+T (macOS)

## Optimizacion de codigo
- No optimizar prematuramente - primero que funcione, luego que sea rapido
- Medir antes de optimizar (benchmarks, profiling)
- Algoritmos correctos > micro-optimizaciones
- Caching solo donde hay beneficio medible

## Build troubleshooting
- Usar agente build-error-resolver para errores de compilacion
- Analizar errores metodicamente
- Implementar fixes incrementalmente
- Validar cada correccion antes de seguir
