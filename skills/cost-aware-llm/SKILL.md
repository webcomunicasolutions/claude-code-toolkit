---
name: cost-aware-llm
description: Patrones para controlar costos de API de LLMs. Model routing, budget tracking, prompt caching, retry inteligente. Usar cuando se construyan pipelines de IA o se optimicen costos.
---

# Cost-Aware LLM Pipeline

## Selección inteligente de modelo
| Tarea | Modelo | Costo relativo |
|-------|--------|---------------|
| Clasificación, formateo | Haiku | 1x |
| Implementación general | Sonnet | 4x |
| Arquitectura, investigación | Opus | 15x |

Regla: empieza con el modelo más barato que pueda hacer el trabajo. Escala solo si la calidad no es suficiente.

## Budget tracking inmutable
```python
@dataclass(frozen=True)
class CostTracker:
    total_cost: float
    total_tokens: int
    calls: int

    def with_call(self, cost: float, tokens: int) -> 'CostTracker':
        return CostTracker(
            total_cost=self.total_cost + cost,
            total_tokens=self.total_tokens + tokens,
            calls=self.calls + 1
        )
```
- Nunca mutar estado - sin acumulación oculta de costos
- Set budget limits ANTES de procesar batches

## Retry inteligente
- Retry SOLO errores transitorios: network, rate limits, 5xx
- Fail fast en permanentes: auth errors, malformed requests, 4xx
- Exponential backoff: 1s, 2s, 4s, 8s, máximo 3 reintentos

## Prompt caching
- System prompts largos - cachear server-side
- Reduce latencia y costos de tokens
- Implementar en: Anthropic (cache_control), OpenAI (cached prompts)

## Observabilidad
- Log CADA llamada: modelo, tokens in/out, costo, latencia
- Dashboard de gasto acumulado
- Alertas cuando se acerca al budget

## Principios
- Security de datos > minimización ciega de costos
- Batch processing cuando sea posible (menor overhead)
- Evaluar calidad vs costo periódicamente
- No usar Opus para tareas que Sonnet hace bien
