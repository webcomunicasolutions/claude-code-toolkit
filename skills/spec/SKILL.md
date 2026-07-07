---
name: spec
description: Arranque estructurado spec-driven para tareas grandes (método Karpathy 3 capas - spec, verificador, entorno). Invocar cuando se vaya a empezar un proyecto o feature grande y se quiera definir bien el objetivo, trocear el trabajo y fijar criterios de calidad ANTES de ejecutar. Triggers - "/spec", "vamos a especificar", "montemos la spec", "arranque spec-driven", "define el objetivo antes de empezar". NOT para tareas triviales o ya bien definidas (ahí basta con ejecutar directo).
---

# Spec-Driven — Arranque de tarea grande (método Karpathy)

Skill **procedimental de arranque**. No ejecuta el proyecto: produce la *spec*
(el plano) y el plan de verificación antes de que empiece la ejecución. Se
invoca a mano cuando el usuario ve que la tarea es lo bastante grande como para
merecer estructura. Para tareas no triviales del día a día basta con el hábito
recogido en la memory `feedback-spec-driven-arranque` (entrevistar → trocear →
validar); esta skill es la versión completa y explícita.

## Base conceptual (Karpathy, 3 capas)
- **Spec** = el plano. Cómo se le entrega el objetivo y el contexto.
- **Verificador** = el control de calidad. Cómo se valida lo generado.
- **Entorno** = el taller donde viven ambos y mejora con el tiempo (CLAUDE.md,
  rules, skills, memorias). En este entorno el taller YA existe y es maduro, así
  que esta skill se centra en **spec** y **verificador**.

Idea rectora: *"Puedes externalizar tu pensamiento, pero no tu comprensión."*

## Cuándo usarla
- Feature/proyecto nuevo, migración, research amplio, entregable de cliente.
- Cuando el objetivo real no está claro o la tarea es grande y ambigua.

## Cuándo NO usarla
- Tareas triviales, cambios pequeños, algo ya bien definido → ejecutar directo.
- Revisiones de solo estilo.

## Fase 1 — Entrevista para el OBJETIVO REAL (spec)
No aceptar la tarea tal cual. Distinguir tarea de objetivo:
- "créame un informe" → *tarea*. ¿Para qué, para quién, qué decisión habilita,
  qué pasa si no existe? → *objetivo real*.

Hacer 2-5 preguntas dirigidas (usar AskUserQuestion si hay decisiones cerradas)
para extraer lo que el usuario ya tiene en la cabeza pero no ha verbalizado:
- Objetivo real y criterio de "hecho".
- Destinatario / contexto de uso.
- Restricciones duras (stack, deadline, presupuesto de tokens, cliente).
- Qué NO entra en el alcance.

Cerrar la fase escribiendo una **spec breve** (objetivo, alcance, fuera de
alcance, restricciones). Confirmar con el usuario antes de seguir.

## Fase 2 — Trocear en bloques (ágil, no cascada)
- Dividir el objetivo en bloques pequeños e independientes.
- Orden de ejecución + qué se valida al terminar cada bloque.
- Regla: ejecutar un bloque → revisar → seguir. Nunca un bloque enorme "a la
  primera".

## Fase 3 — Criterios de calidad + verificador
Antes de ejecutar nada, definir explícitamente:
- **Qué es "bien"** para este entregable (lista concreta de requisitos de
  calidad). No "hazlo bien" — decir qué es bien.
- **Verificador independiente**: qué agente/skill hará de crítico con esos
  criterios (`quality-loop`, `adversarial-review`, `code-reviewer`,
  `verifier`…). El que ejecuta NO se autovalida.
- **Señal externa**: fuentes reales a conectar (docs, informes previos, la
  propia app/tests como feedback). Pasar fuentes concretas, no "busca en
  internet".

## Fase 4 — Reglas de la tarea (siempre / preguntar / nunca)
Fijar para esta tarea concreta:
- Acciones que **siempre** debo hacer sin preguntar.
- Acciones que debo **preguntar** antes de ejecutar (decisiones clave,
  irreversibles).
- Acciones que **nunca** debo hacer.

## Salida de la skill
Un documento de arranque (en el proyecto o en scratchpad si es efímero):
`SPEC.md` con: objetivo real, alcance/fuera de alcance, restricciones, bloques
ordenados, criterios de calidad, verificador elegido, reglas siempre/preguntar/
nunca. A partir de ahí, ejecutar bloque a bloque validando con el verificador.

## Auto-mejora
Al cerrar cada aplicación práctica de esta skill:
1. Registrar aprendizajes en `aprendizajes/<caso>.md` (o en esta sección si es
   breve): qué preguntas de la entrevista dieron más señal, qué troceo funcionó,
   qué criterios de calidad faltaron y se detectaron tarde.
2. Si el patrón es generalizable, actualizar el cuerpo de este SKILL.md.
3. Si se repite un error, añadirlo a una sección "Errores conocidos".

Sin esta fase, la skill se fosiliza y pierde valor con el tiempo.
