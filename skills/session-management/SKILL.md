---
name: session-management
description: Sistema de persistencia de sesiones entre conversaciones. Guardar estado, retomar trabajo, prevenir reintentos de enfoques fallidos. Usar con /save-session y /resume-session.
---

# Session Management

## Concepto
Persistir el contexto de trabajo entre sesiones de Claude Code para:
- Retomar donde se dejó sin perder progreso
- Evitar reintentar enfoques que ya fallaron
- Mantener decisiones y tradeoffs documentados

## Directorio: `~/.claude/sessions/`

## Formato de archivo
`YYYY-MM-DD-HHMMSS-<descripcion>-session.md` (la HORA evita colisiones cuando hay varias sesiones
el mismo día o si sincronizas `~/.claude/` entre varios equipos)

## Secciones obligatorias
1. **Qué estamos construyendo** — contexto para alguien nuevo
2. **Qué FUNCIONÓ** — éxitos confirmados con evidencia
3. **Qué NO funcionó** — CRÍTICO: previene reintentos inútiles
4. **Qué NO se ha intentado** — ideas prometedores pendientes
5. **Estado de archivos** — tabla de archivos modificados
6. **Estado de git** — branch, commits sin pushear, stash (N/A si no es repo)
7. **Entorno y comandos clave** — arranque, conexión BD (sin secretos), puerto, rutas
8. **Procesos vivos** — qué debe seguir corriendo + cómo verificarlo (cron, docker)
9. **Backups y puntos de restauración** — ruta+timestamp+restore (obligatoria si se tocó BD)
10. **Tareas pendientes** — volcado del TaskList para RECREAR al retomar
11. **Decisiones pendientes del usuario** — lo que requiere input humano (separado de blockers)
12. **Decisiones tomadas** — con razón/tradeoff
13. **Blockers** — issues técnicos sin resolver
14. **Próximo paso exacto** — una sola acción para retomar

## Principios
- La sección "Qué NO funcionó" es la MÁS importante
- Incluir errores exactos, no descripciones vagas
- Nunca omitir secciones (usar "N/A" si no aplica)
- El archivo de sesión es READ-ONLY al retomar
- No auto-empezar trabajo al retomar — esperar dirección del usuario (salvo recrear tareas)

## Continuidad infalible (lo que hace que NO se pierda nada)
- **Tareas**: el TaskList del harness NO persiste entre sesiones. save-session lo vuelca a la
  sección "Tareas pendientes"; resume-session lo recrea con TaskCreate.
- **Memoria**: lo único que se autocarga en cada sesión nueva es `MEMORY.md` + las memorias del
  proyecto. save-session SIEMPRE actualiza la memoria del proyecto con la cola de pendientes y un
  puntero al archivo de sesión. Así, aun sin invocar resume-session, la próxima sesión ve lo
  pendiente.
- **Higiene**: antes de guardar, cerrar/documentar procesos en background y queries colgadas
  (pueden seguir consumiendo o bloqueando recursos tras cerrar la sesión).
- **Verificar al retomar**: el archivo refleja el estado AL GUARDAR; contrastar con la realidad
  actual (procesos, datos, ficheros pudieron cambiar) antes de fiarse.

## Workflow
```
Guardar: /save-session
Retomar: /resume-session [fecha | ruta]
Listar:  ls ~/.claude/sessions/
```

## Si conviven varios mecanismos de sesión, fijar cuál es el canónico
Es fácil terminar con dos sistemas a la vez (p. ej. este skill + un hook `Stop` que escribe su
propio fichero de estado por proyecto). Cuando eso pase:
- Decide UNO como canónico — normalmente `/save-session`, porque genera el fichero rico de arriba,
  actualiza la memoria del proyecto y, si existe, un `docs/ESTADO_PROYECTO.md` como verdad
  duradera.
- Retira el otro mecanismo del `settings.json` (no lo dejes "por si acaso" corriendo en paralelo:
  genera confusión sobre cuál manda) y dilo explícitamente en este SKILL.md para que no se
  reinvente ni se consulte el fichero equivocado.

## Dónde vive cada cosa
- **Duradero / en git / lo ve otra persona del equipo**: `docs/ESTADO_PROYECTO.md` (del proyecto).
- **Efímero / en `~/.claude/` / para retomar tú**: `~/.claude/sessions/*-session.md`.
- **Autocargado en cada sesión nueva**: `MEMORY.md` + memorias del proyecto (lo único que se carga
  solo).
No duplicar lo duradero en el efímero. El chequeo de sincronización con git es parte de
`/resume-session`.

## Control de tamaño de MEMORY.md (comprobar al guardar)

`MEMORY.md` es un ÍNDICE, no el contenido. Los harnesses de contexto suelen tener un límite de
carga (del orden de 20-25 KB); pasado ese límite, el fichero se trunca **en silencio**: cada
entrada nueva empuja otra fuera y la memoria se pierde sin que nadie se entere. Si tu setup tiene
un script que mida el tamaño (por ejemplo `scripts/check_memory_size.sh`), ejecútalo al cerrar
sesión; si no lo tiene, un simple `wc -c MEMORY.md` con un umbral propio sirve de aviso temprano.

**Compactar** = mover los punteros a sesiones ya cerradas a un histórico aparte + dejar cada
entrada activa en UNA línea corta (título, enlace y un gancho de por qué importa). El detalle vive
en su propio `.md`, nunca en el índice. Guardar una copia de seguridad del índice antes de tocarlo.
