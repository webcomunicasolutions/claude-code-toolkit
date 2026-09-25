---
description: Guardar estado de sesion actual para retomar despues
---

# Save Session

Captura y preserva el contexto de trabajo actual para retomarlo en futuras sesiones
SIN perder NADA: contexto, tareas, entorno y enganche con la memoria del proyecto.

## Instrucciones

1. `mkdir -p ~/.claude/sessions/` si no existe.

2. **Higiene previa (IMPORTANTE):** verifica que NO queden procesos en background ni queries/jobs
   colgados de esta sesion (revisa background tasks; si hay BD, comprueba el PROCESSLIST). Cierra
   o documenta los que queden. Una query colgada puede bloquear recursos despues de cerrar.

3. **Vuelca la lista de tareas:** ejecuta TaskList y copia su estado COMPLETO (id, estado, subject,
   descripcion de pending/in_progress) para la seccion "Tareas pendientes".

4. **Auto-auditoria ANTES de escribir (semaforo):** contrasta tu contexto real contra cada seccion:
   - Si editaste N archivos -> deben estar TODOS en "Estado de archivos".
   - Si hubo errores -> "Que NO funciono" NO puede ser vacio/N/A.
   - Si hay tarea in_progress -> "Proximo paso" debe ser ESPECIFICO (>15 palabras, no generico).
   - Si tocaste BD/datos -> "Backups" es obligatoria.
   Emite un semaforo: VERDE (todo cubierto) / AMARILLO (huecos menores) / ROJO (falta algo critico).
   Si ROJO, completa antes de guardar.

5. **Nombre del archivo (anti-colision):** `YYYY-MM-DD-HHMMSS-<descripcion-corta>-session.md` en
   `~/.claude/sessions/`. La HORA evita sobrescribir cuando hay varias sesiones del mismo dia/proyecto
   o por Syncthing entre equipos. SIEMPRE la ruta `~/.claude/sessions/` (nunca `.clone`).

6. El archivo DEBE contener TODAS estas secciones (usa "N/A" si no aplica, nunca omitas):

### Plantilla obligatoria:

```
# Sesion: [titulo descriptivo]
**Fecha:** YYYY-MM-DD HH:MM
**Proyecto:** [ruta del proyecto]

## Que estamos construyendo
[1-3 parrafos con contexto suficiente para alguien que no conoce la sesion]

## Que FUNCIONO (solo exitos confirmados)
- [Exito con evidencia: test results, comportamiento verificado]

## Que NO funciono (CRITICO - previene reintentos)
- [Enfoque fallido]: [error exacto / razon del fallo]

## Que NO se ha intentado aun
- [Enfoques prometedores sin probar]

## Estado actual de archivos
| Archivo | Estado | Notas |
|---------|--------|-------|
| path/file | modificado/nuevo/eliminado | detalle |

## Estado de git
[git status -sb; git log @{u}.. (commits sin pushear); git stash list. "N/A" si no es repo git]

## Entorno y comandos clave
[Comando de arranque/run; conexion a BD (referenciando .credentials.json, SIN secretos); puerto
(lsof); env vars relevantes SIN secretos; rutas absolutas importantes]

## Procesos vivos / en marcha
[Que DEBE seguir corriendo (cron, contenedores, jobs largos) + comando para verificarlo
(crontab -l, docker ps, etc.). "N/A" si ninguno]

## Backups y puntos de restauracion
[Ruta + timestamp + tamano>0 + comando de restore. OBLIGATORIA si se toco BD/datos]

## Tareas pendientes (volcado de TaskList - recrear con TaskCreate al retomar)
| # | Estado | Tarea | Detalle para recrear |
|---|--------|-------|----------------------|
| .. | pending/in_progress | [subject] | [descripcion] |
[incluir TODAS las pending/in_progress; las completed se resumen en una linea]

## Decisiones pendientes del usuario
[Lo que requiere input HUMANO (no lo que Claude desbloquea trabajando): que decidir, opciones
A/B con tradeoffs, que queda bloqueado hasta decidir. "N/A" si ninguna]

## Decisiones tomadas
- [Decision]: [razon/tradeoff]

## Blockers y preguntas abiertas
- [Issue tecnico sin resolver]

## Proximo paso exacto
[Una sola accion precisa para retomar con minimo esfuerzo cognitivo]
```

7. **Contrato verificable de MEMORY.md (CORAZON de la continuidad - NO declarar guardado sin esto):**
   La lista de tareas del harness NO persiste entre sesiones; lo unico que se autocarga es la memoria.
   - Actualiza/crea la memoria `project_*.md` del proyecto con el estado y la cola de pendientes.
   - Anade/actualiza en `MEMORY.md` un puntero a esa memoria y al archivo de sesion recien creado.
   - **RELEE ambos y CONFIRMA por grep** que (a) el nombre del .md recien creado aparece en MEMORY.md
     y (b) la cola de pendientes esta en `project_*.md`.
   - Emite: "Memoria sincronizada: MEMORY.md referencia <archivo>; project_X.md tiene N pendientes".
   - Si el puntero NO aparece, PARA y avisa antes de declarar guardado.
   - **CONTROL DE TAMANO (obligatorio, no saltarselo):** ejecuta
     `~/.claude/scripts/check_memory_size.sh <ruta del MEMORY.md del proyecto>`.
     Si sale 🔴 o 🟡, **COMPACTA ANTES de dar la sesion por guardada** y dilo al usuario.
     Por que: el limite de carga esta en ~24,4 KB y al pasarlo el harness **corta entradas EN
     SILENCIO** — cada entrada nueva empuja otra fuera del contexto y la memoria se pierde sin
     avisar. Detectado en produccion en dos proyectos distintos el mismo dia: uno con 25,9 KB (2
     entradas ya cortadas) y otro con 26,5 KB que llevaba tiempo igual sin que nadie lo notara.
     Compactar es: punteros a sesiones al `project_historico_sesiones.md` + cada entrada en UNA
     linea de ~195 caracteres (titulo, enlace y gancho; el detalle vive en su .md).

8. **Documento guia canonico (si el proyecto tiene `docs/ESTADO_PROYECTO.md`):** actualizalo con el
   estado real (es la verdad "oficial" que va en git y ve el programador del cliente). El archivo de
   sesion en `~/.claude/sessions/` queda para lo EFIMERO (procesos vivos, proximo paso, que NO
   funciono); ESTADO_PROYECTO.md para lo duradero. NO automatices commits a git: deja los cambios
   listos y, si procede, proponselos al usuario (no commitear/pushear sin su OK).

9. **Sincronizacion del repo:** si en un repo de PROYECTO hay commits sin pushear o cambios sin
   commitear, AVISA y PROPON al usuario commitear/pushear antes de cerrar (no forzar). No aplica a
   `~/.claude/` (sin git, lo sincroniza Syncthing).

10. Muestra el archivo creado, el semaforo de auto-auditoria y la confirmacion de memoria. Pide OK.

## Reglas
- "Que NO funciono" es la seccion mas importante - previene reintentos de enfoques fallidos.
- "Tareas pendientes" debe permitir reconstruir el TaskList exacto al retomar.
- No declarar "guardado" hasta pasar el contrato de MEMORY.md (paso 7).
- ESTADO_PROYECTO.md (duradero, en git) y archivo de sesion (efimero, en ~/.claude) NO se duplican.
