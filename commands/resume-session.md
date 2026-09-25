---
description: Retomar una sesion guardada previamente
---

# Resume Session

Carga el estado de una sesion previa y orientate completamente ANTES de hacer cualquier trabajo.

## Instrucciones

1. Si no se proporciona argumento: busca el `*-session.md` mas reciente en `~/.claude/sessions/`.
   El formato lleva hora (`YYYY-MM-DD-HHMMSS-...`), asi que ordena por nombre y toma el ultimo.
   Si hay varios proyectos, prioriza el que coincide con el cwd actual.
2. Si se proporciona fecha (ej: 2024-01-15): busca archivos con ese prefijo; si hay varios ese dia,
   toma el de HORA mayor (o pregunta cual si son de temas distintos).
3. Si se proporciona ruta: lee ese archivo directamente.
4. Lee tambien la memoria del proyecto (`MEMORY.md` y las `project_*.md` relevantes) para
   contrastar el archivo de sesion con el estado de memoria mas reciente.

### Formato de briefing obligatorio:

```
**PROYECTO:** [nombre/tema]
**QUE ESTAMOS CONSTRUYENDO:** [resumen 2-3 frases]
**ESTADO ACTUAL:** [X funcionando / Y en progreso / Z sin empezar]
**QUE NO REINTENTAR:** [enfoques fallidos con razones]
**BLOCKERS / PREGUNTAS ABIERTAS:** [issues pendientes]
**SINCRONIZACION:** [estado git del repo de proyecto: rama, commits ahead/behind del remoto, cambios sin commitear, ultimo tag. Si hay commits sin pushear, AVISAR explicitamente]
**PROXIMO PASO:** [accion exacta recomendada]
```

5. **Recrea la lista de tareas (IMPORTANTE):** si el archivo tiene seccion "Tareas pendientes",
   recrea esas tareas en el harness con TaskCreate (las pending e in_progress), para que el
   TaskList vuelva a reflejar el trabajo exacto. Verifica antes con TaskList que no esten ya.
6. **Verifica la realidad antes de fiarte del archivo:** el archivo refleja el estado AL GUARDAR.
   Si menciona procesos, datos o ficheros, comprueba su estado actual (pudo cambiar). No asumas.
7. **Chequeo de sincronizacion git (OBLIGATORIO si es repo de proyecto):** ejecuta
   `git status -sb` y compara con el remoto (`@{u}..` para commits sin pushear, `git tag` para
   versiones). Rellena la linea **SINCRONIZACION** del briefing. Si hay commits sin pushear o
   cambios sin commitear, AVISA al usuario al inicio (no esperes a que pregunte). Nota: esto NO
   aplica a `~/.claude/` (sin git, sincronizado por Syncthing).

## Reglas criticas
- Lee el archivo COMPLETO antes de responder.
- NUNCA modifiques el archivo de sesion (solo lectura).
- NO empieces a trabajar automaticamente - espera direccion del usuario (salvo recrear tareas).
- Si no hay sesiones guardadas, informa y pregunta que hacer.

$ARGUMENTS
