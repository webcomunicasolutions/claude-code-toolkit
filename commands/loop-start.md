---
description: Iniciar loop autonomo con guardrails de seguridad
---

# Loop Start

Inicia un loop de trabajo autonomo con protecciones de seguridad.

## Instrucciones

### Patrones disponibles
1. **sequential** - Tareas en secuencia, una tras otra
2. **continuous** - Loop continuo hasta completar objetivo
3. **parallel** - Multiples agentes en worktrees aislados

### Antes de iniciar (obligatorio)
- [ ] Tests pasan en estado actual
- [ ] Condicion de terminacion clara definida
- [ ] Branch aislado creado (no trabajar en main)

### Flujo de ejecucion
1. Valida el repositorio esta limpio
2. Selecciona patron segun argumento (default: sequential)
3. Crea plan en `.claude/plans/loop-[timestamp].md`
4. Ejecuta iteraciones con checkpoints entre cada paso
5. Verifica progreso en cada checkpoint

### Guardrails de seguridad
- Si no hay progreso en 2 checkpoints consecutivos -> PARAR y reportar
- Si el mismo error aparece 3 veces -> PARAR y escalar
- Maximo de iteraciones definido por el usuario
- Cada iteracion ejecuta tests antes de continuar

### Uso
```
/loop-start [patron] [descripcion del objetivo]
```

$ARGUMENTS
