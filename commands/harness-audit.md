---
description: Auditoria del harness de Claude Code - scores por categoria
---

# Harness Audit

Evalua la configuracion actual de Claude Code contra 7 categorias estandarizadas.

## Instrucciones

Analiza la configuracion actual de Claude Code y puntua de 0-10 cada categoria:

### Categorias de evaluacion

1. **Tool Coverage (0-10):** Cuantos skills, commands, agents hay? Cubren las necesidades?
2. **Context Efficiency (0-10):** CLAUDE.md es conciso? Se usa memoria correctamente? Hay bloat?
3. **Quality Gates (0-10):** Hay hooks de calidad? Tests automaticos? Linting?
4. **Memory Persistence (0-10):** Se guardan sesiones? Hay sistema de memoria? Es util?
5. **Eval Coverage (0-10):** Hay evaluaciones definidas? Se miden resultados?
6. **Security Guardrails (0-10):** Hay permisos configurados? Hooks de seguridad? Secrets protegidos?
7. **Cost Efficiency (0-10):** Se usa model routing? Se optimizan tokens? Hay tracking de costos?

### Output

```
## Harness Audit Report
**Fecha:** [timestamp]
**Score total:** XX/70

| Categoria | Score | Hallazgos |
|-----------|-------|-----------|
| Tool Coverage | X/10 | [detalle] |
| Context Efficiency | X/10 | [detalle] |
| Quality Gates | X/10 | [detalle] |
| Memory Persistence | X/10 | [detalle] |
| Eval Coverage | X/10 | [detalle] |
| Security Guardrails | X/10 | [detalle] |
| Cost Efficiency | X/10 | [detalle] |

## Top 3 acciones prioritarias
1. [accion mas impactante]
2. [segunda accion]
3. [tercera accion]
```

$ARGUMENTS
