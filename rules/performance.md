# Performance

## Seleccion de modelo
Precios orientativos por 1M tokens (input/output) — **compruébalos siempre**, cambian con frecuencia:

| Modelo | Model ID (ejemplo) | Precio orientativo | Usar para |
|--------|----------|--------|-----------|
| Haiku 4.5 | `claude-haiku-4-5` | $1/$5 (1x) | Tareas simples, clasificacion, formateo |
| Sonnet 5 | `claude-sonnet-5` | $2/$10 (2x) | Implementacion, refactoring, debugging, subagentes |
| Opus 4.8 | `claude-opus-4-8` | $5/$25 (5x) | Arquitectura, investigacion, specs ambiguos |
| Fable 5 | `claude-fable-5` | $10/$50 (10x) | Sesion principal: razonamiento y trabajo agentico mas exigente |

Nota: un modelo "de razonamiento siempre activo" (thinking no configurable, contexto grande) suele
reservarse solo para la sesión principal, nunca para subagentes. Al construir apps con la API de
Claude, un valor por defecto razonable es el modelo grande (p. ej. Opus) salvo que el volumen obligue
a bajar de gama.

## Gestion del context window (Lost in the Middle)
- Inicio (~40%) y final del contexto se leen bien; el MEDIO se vuelve borroso
- Cada tool result se acumula en el medio, empujando lo importante a zona borrosa
- Con muchos MCPs/tools, 200k de contexto puede ser ~70k efectivo
- Compactar en puntos logicos (entre features, no en medio de implementacion)
- Fijar datos clave al inicio de la conversacion (key fact summary block)
- Recortar outputs verbosos de tools - quedarse solo con lo relevante
- Delegar trabajo exploratorio a sub-agentes (contexto aislado, solo devuelven resumen)
- Mejor iniciar sesion nueva con resumen que forzar sesion larga

## Agentes - reglas de eficiencia
- Max 4-5 tools por agente - menos opciones = mejores decisiones
- Code review SIEMPRE en sesion separada (la que escribio el codigo esta sesgada)
- Tool descriptions: incluir CUANDO NO usar cada tool, no solo cuando si

## Extended thinking
- Util para: analisis complejo, debugging dificil, decisiones arquitecturales
- Si el harness lo soporta como opcion, activarlo por defecto y usar el toggle
  correspondiente para casos puntuales donde no aporte (respuestas triviales)

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
