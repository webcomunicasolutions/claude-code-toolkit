---
name: quality-loop
description: Loop autónomo de calidad con VERIFICADOR INDEPENDIENTE. Fusiona test-and-fix, quality-gate, adversarial-review y verification-loop en un solo flujo. El agente que ejecuta los fixes NO es el que da el visto bueno — un crítico separado verifica con evidencia para que el ejecutor no pueda inventar éxito ("mentir en el loop"). Agnóstico al tipo de proyecto (código, n8n, prompts, infra, docs). Usar cuando se diga "quality loop", "loop de calidad", "revisa en loop", "test and fix", "busca fallos hasta que quede perfecto", "modo loop crítico", "chequea mi trabajo en loop". NOT para un único cambio trivial ni para revisiones de solo estilo.
---

# Quality Loop — Loop adversarial con verificador independiente

Loop autónomo que revisa, encuentra fallos, los arregla y **un agente distinto verifica que el arreglo es real** — repitiendo hasta veredicto limpio o hasta que deje de haber progreso. Fusiona en una sola skill lo mejor de `verification-loop` (fases objetivas), `quality-gate` (panel adversarial en paralelo), `adversarial-review` (prompts bug-bounty) y `test-and-fix` (loop hasta 0 bugs), y añade lo que ninguna tenía: **separación ejecutor/verificador** y **guardrail de producción**.

## Principio central (lo que hace distinta a esta skill)

**El que arregla NO es el que aprueba.** En un loop de un solo agente, el mismo modelo que aplica un fix tiende a declararlo correcto sin evidencia (sesgo de confirmación). Por eso:

- Un **EJECUTOR** descubre y aplica los fixes.
- Un **VERIFICADOR independiente** (agente separado, contexto limpio) intenta REFUTAR cada fix con un comando/observación concreta. Solo lo que el verificador confirma con evidencia cuenta como resuelto.
- El loop avanza por **evidencia**, no por afirmaciones. "Lo arreglé" sin prueba = no arreglado.

> Regla del harness aplicada: *"Code review SIEMPRE en sesión separada — la que escribió el código está sesgada"* (`rules/performance.md`). Esta skill la convierte en mecánica obligatoria.

## Cuándo usar / cuándo NO

USAR: tras una feature o sesión de cambios, antes de un release/PR importante, cuando se pide "revisa todo y arréglalo en loop hasta que quede perfecto".

NO usar: un cambio trivial de una línea (basta revisar a ojo), revisiones de solo estilo (usar el linter), o cuando no hay forma de obtener evidencia objetiva del resultado (primero conseguir esa forma).

## GUARDRAILS (leer antes de empezar — bloqueantes)

1. **Producción de cliente / cambios irreversibles → NO aplicar sin confirmación.** Si el trabajo a revisar toca producción de un cliente, infra en vivo, BD con datos, o algo irreversible: el loop ENCUENTRA y PROPONE, deja los fixes como drafts/diffs, y PARA pidiendo confirmación explícita. Escalar al riesgo (`CLAUDE.md` → "Revisión adversarial"). Nunca tocar producción de cliente en modo autónomo.
2. **Límite de rondas:** máximo 5 por defecto. Si se alcanza sin veredicto limpio, parar y reportar lo que queda.
3. **Parar si no hay progreso:** si una ronda no reduce el nº de hallazgos abiertos respecto a la anterior, parar y escalar (evita loops infinitos y quema de tokens).
4. **No inventar éxito:** prohibido declarar "perfecto/0 bugs" sin que el VERIFICADOR lo respalde con evidencia. Ante la duda, reportar el hallazgo, no ocultarlo (`rules/anti-hallucination.md`).
5. **Backup antes de tocar:** si se van a aplicar fixes sobre archivos/datos no triviales, snapshot/backup primero (workflow JSON, dump de BD, copia del prompt).

## El loop

### Fase 0 — Descubrir proyecto y alcance
- Detectar el **tipo de proyecto**: código (lenguaje + build/tests), workflows n8n, prompts/agentes LLM, infra/IaC, docs. Determina qué verificadores objetivos existen.
- Detectar el **alcance a revisar**: `git diff` de la rama / cambios de la sesión / lo que el usuario señale. No revisar el repo entero si solo cambió una parte.
- Detectar si toca **producción** (ver Guardrail 1). Si sí, fijar modo "propón, no apliques".

### Fase 1 — Verificación objetiva (lo que aplique al tipo)
Correr lo que el proyecto soporte; saltar lo que no exista (no inventar pasos):
- **Código:** lint con `--fix` → build → typecheck → tests → scan de secretos. (Como `verification-loop`.)
- **n8n:** validar el JSON del workflow, revisar nodos por secretos hardcodeados, expresiones rotas, SQL crudo; dry-run/test execution si es seguro.
- **Prompts/LLM:** coherencia interna, contradicciones, reglas que se pisan, fugas de PII, jailbreak/inyección.
- **Infra/docs:** linters específicos, validadores, links, coordenadas verificables.
Si algo objetivo falla, arreglarlo ANTES de gastar agentes (no revisar sobre algo roto).

### Fase 2 — Panel adversarial en paralelo (los EJECUTORES/buscadores)
Lanzar en paralelo los críticos que correspondan al proyecto, con prompts **adversariales** (incentivo a romper, no a validar). Mínimo: `code-reviewer` (o el reviewer del lenguaje), `security-reviewer`, `devils-advocate`. Añadir los de dominio (`database-reviewer`, reviewer de prompt, etc.). Cada uno:
- Solo reporta lo **reproducible/concreto** (archivo:línea o nodo + cómo se manifiesta). Nada teórico, nada de estilo.
- Recibe la lista de fixes ya aplicados en rondas previas (para no repetir).
- Si no encuentra nada: "SIN HALLAZGOS — listo para producción".

### Fase 3 — Triage y aplicar fixes (EJECUTOR)
- Consolidar y deduplicar hallazgos. Priorizar CRÍTICO/ALTO/MEDIO/BAJO.
- Descartar falsos positivos **con argumento** (ser crítico también con los agentes: no todo hallazgo es real).
- Aplicar los fixes seguros. Los que tocan producción/irreversible → dejar como draft/diff (Guardrail 1).
- Registrar qué se cambió y por qué (input para el verificador).

### Fase 4 — VERIFICADOR INDEPENDIENTE (el corazón anti-mentira)
Lanzar un agente **nuevo, de contexto limpio** (`verifier` u otro reviewer NO usado como ejecutor). Su único trabajo: por cada fix supuestamente aplicado, **intentar demostrar que NO funciona** o que introdujo regresión, con un comando/observación concreta. Devuelve por fix: `CONFIRMADO` (con evidencia) | `NO RESUELTO` | `REGRESIÓN`.
- Solo los `CONFIRMADO` se cierran. Los demás vuelven a la cola de hallazgos abiertos.
- Para producción (donde no se aplicó), el verificador audita que el **draft** es correcto y completo, no que está desplegado.

### Fase 5 — Gate de decisión (¿otro loop o parar?)
- **Veredicto limpio** = el panel de Fase 2 no produce hallazgos NUEVOS **y** el verificador de Fase 4 confirma todos los fixes → PARAR, reportar éxito con evidencia.
- **Progreso** = el nº de hallazgos abiertos (no confirmados) es MENOR que al inicio de la ronda anterior → otra ronda (Fase 2), pasando el estado acumulado.
- **Sin progreso** o **límite de rondas** o **bloqueo en producción** → PARAR y escalar al usuario con lo pendiente.

## Reporte final (siempre)
```
## Quality Loop — Reporte
Proyecto: <ruta>   Tipo: <código/n8n/prompt/infra>   Modo: <aplicar | propón (producción)>
Rondas: N/5   Veredicto: LIMPIO | PENDIENTE | ESCALADO

| Hallazgo | Sev | Estado | Verificación (evidencia) |
|----------|-----|--------|--------------------------|
| ...      | CRÍTICO | CONFIRMADO/DRAFT/ABIERTO | <comando/observación> |

Fixes aplicados: <lista>
Drafts pendientes de tu OK (producción/irreversible): <lista>
Falsos positivos descartados (con motivo): <lista>
Qué falta / por qué se paró: <...>
```

## Notas de implementación
- Concurrencia: lanzar los críticos de Fase 2 en un solo mensaje (paralelo). El verificador de Fase 4 va DESPUÉS (depende de los fixes).
- Estado entre rondas: mantener una lista acumulada de hallazgos (abiertos/cerrados/falsos positivos) para no repetir trabajo ni "olvidar" un fallo.
- Para loops largos desatendidos, considerar `loop-operator` o `/loop`; pero el gate de decisión (Fase 5) siempre lo evalúa un razonamiento explícito, no un contador ciego.
- Esta skill **reemplaza funcionalmente** a `quality-gate`, `adversarial-review`, `verification-loop` y `test-and-fix`. Consolidación ejecutada 2026-07-09: las 4 movidas a `~/.claude/_pendiente_borrado_skills_20260709/` (borrar definitivo tras 30 días si no se echan en falta).

## Auto-mejora
Al cerrar cada aplicación práctica de esta skill:
1. Registrar aprendizajes en `aprendizajes/<caso>.md` (o en esta sección si es breve): falsos positivos típicos por tipo de proyecto, comandos de verificación que funcionaron, gotchas.
2. Si el patrón es generalizable, actualizar el cuerpo de este SKILL.md.
3. Si se descubre un error recurrente, añadirlo a una sección "Errores conocidos".
Sin esta fase, la skill se fosiliza.
