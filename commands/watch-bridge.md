---
description: Activa modo guardia sobre shared/BRIDGE.md - escucha mensajes nuevos de otros proyectos en paralelo
allowed-tools: ["Read", "Write", "Edit", "Bash", "ScheduleWakeup", "TaskCreate", "TaskUpdate", "Skill"]
argument-hint: "[stop|<intervalo_segundos>]"
---

# /watch-bridge — Modo guardia Project Bridge

Activa la skill `bridge-watch` sobre este proyecto: leer `shared/BRIDGE.md`,
detectar canales activos, y entrar en loop periodico revisando si hay
mensajes nuevos de proyectos hermanos.

## Argumentos

- Sin argumento → activar con intervalo default (270s, cache hot)
- `stop` → desactivar (cancelar siguiente wakeup)
- Número → intervalo custom en segundos (clamp 60-3600)

## Procedimiento

1. **Si argumento es `stop`**:
   - No reprogramar wakeup
   - Confirmar al usuario: "Modo guardia desactivado"

2. **Si activar (con o sin intervalo)**:
   - Verificar que existe `shared/BRIDGE.md` en el proyecto local. Si no
     existe, abortar con: "Este proyecto no tiene Project Bridge configurado.
     Usa /project-bridge setup primero."
   - Extraer nombres de proyectos remotos del BRIDGE.md
   - Hacer primer check inmediato de mensajes pendientes
   - Si hay alguno pendiente → procesarlo segun heuristica de la skill
   - Programar siguiente wakeup con `ScheduleWakeup`
   - Mostrar resumen al usuario: canales activos, ultimo mensaje procesado,
     proximo tick

## Invocacion

Usa la skill `bridge-watch` con `Skill` para cargar el procedimiento completo.

ARGUMENTS: $ARGUMENTS
