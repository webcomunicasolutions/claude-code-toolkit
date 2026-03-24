---
name: autonomous-loops
description: Patrones para ejecutar Claude Code de forma autónoma en loops. Desde pipelines secuenciales hasta DAGs con múltiples agentes. Usar cuando se necesite automatización repetitiva o CI/CD con IA.
---

# Autonomous Loops

## Espectro de complejidad

### 1. Sequential Pipeline (`claude -p`)
```bash
#!/bin/bash
set -e
claude -p "Analyze the codebase structure" > analysis.md
claude -p "Based on analysis.md, create implementation plan" > plan.md
claude -p "Implement step 1 from plan.md"
claude -p "Run tests and fix any failures"
```
- Cada llamada es un paso enfocado
- `set -e` propaga exit codes
- Óptimo para: cambios únicos enfocados

### 2. Continuous PR Loop
```bash
while true; do
  git checkout -b fix/$(date +%s)
  claude -p "$TASK_PROMPT" --max-turns 20
  git add -A && git commit -m "fix: automated change"
  git push -u origin HEAD
  gh pr create --fill
  gh pr checks --watch
  if [ $? -eq 0 ]; then gh pr merge --auto; break; fi
  claude -p "Fix the CI failures shown in the PR checks"
done
```
- Flags recomendados: `--max-runs N`, `--max-cost $X`
- Context bridge: `SHARED_TASK_NOTES.md` persiste entre iteraciones

### 3. Parallel con Worktrees
```bash
git worktree add /tmp/agent-1 -b agent/task-1
git worktree add /tmp/agent-2 -b agent/task-2
(cd /tmp/agent-1 && claude -p "Task 1") &
(cd /tmp/agent-2 && claude -p "Task 2") &
wait
```

### 4. De-Sloppify Pattern
Después de cada implementación, un segundo agente limpia:
- Tests que prueban comportamiento del lenguaje (no del código)
- Type checks redundantes
- Error handling over-defensivo
- Dos agentes enfocados > un agente constrained

## Decision Framework
| Escenario | Patrón |
|-----------|--------|
| Cambio único | Sequential Pipeline |
| Spec escrito, iterativo | Continuous PR Loop |
| Tareas independientes | Parallel Worktrees |
| Post-limpieza | De-Sloppify |

## Guardrails obligatorios
- Condición de terminación explícita
- Máximo de iteraciones
- Presupuesto de costo
- Tests verdes como gate
- Branch aislado (nunca main)
