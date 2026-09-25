---
name: bridge-watch
description: Modo guardia para Project Bridge. Escucha pasivamente mensajes nuevos en shared/ de cualquier canal y los responde o deriva al usuario. Util cuando hay varios proyectos trabajando en paralelo y se escriben entre si. Trigger automatico via /watch-bridge o cuando el usuario pide "ponte en modo escucha", "watch bridge", "loop bridge".
---

# bridge-watch - Modo guardia para Project Bridge

## Cuando usarla

- Cuando el proyecto local tiene `shared/BRIDGE.md` con canales activos
- Y otro(s) proyecto(s) Claude Code estan trabajando en paralelo y van a
  enviar mensajes proximamente
- El usuario quiere que esta sesion se quede "escuchando" sin tener que
  preguntar cada rato

## Como funciona

Patron de poll periodico con backoff:
1. Cada N segundos revisar archivos `from_<remoto>_*.md` en `shared/`
2. Para cada uno, verificar si existe `to_<remoto>_<tema>_reply.md`
3. Si NO existe → mensaje pendiente → leerlo + responder (o derivar)
4. Si SI existe → ya respondido
5. Programar siguiente wakeup con `ScheduleWakeup`
6. Aplicar backoff: si no hay novedad varios ticks, alargar intervalo

## Backoff de intervalos (mantener cache hot inicialmente)

- **Tick 1-3** (primeros 15 min): 270s (4.5 min) - cache hot
- **Tick 4-6** (15-45 min sin novedad): 600s (10 min) - 1 cache miss aceptable
- **Tick 7-12** (45 min - 4h): 1800s (30 min)
- **A partir de tick 13** (>4h sin novedad): 3600s (1h max)

Cuando llega mensaje y se procesa, RESETEAR a 270s (vuelve a haber actividad).

## Procesamiento de mensaje pendiente

1. Leer `from_<remoto>_<tema>.md`
2. Decidir tipo:
   - **Pregunta tecnica con respuesta deducible del contexto**: responder
     directamente con `to_<remoto>_<tema>_reply.md`
   - **Pregunta que requiere decision del usuario**: NO responder
     automaticamente. Avisar al usuario con resumen y propuesta de
     respuesta. Esperar instruccion antes de responder.
   - **Informativo (FYI)**: actualizar BRIDGE.md como `informativo`,
     no responder.
   - **Mensaje del usuario al usuario** (el otro Claude pide accion
     humana): avisar al usuario, no responder.

3. Si respondes:
   - Crear `to_<remoto>_<tema>_reply.md` en `shared/` local
   - **Copiar** el mismo archivo a `shared/` del proyecto remoto (para que
     lo vea)
   - Actualizar tabla de mensajes en `BRIDGE.md` de AMBOS proyectos:
     entrada original marcada `resuelto`, añadir linea del reply

4. Programar siguiente wakeup

## Comandos

### Activar modo guardia
```
/watch-bridge          # con intervalo default 270s
/watch-bridge 60       # con intervalo custom en segundos
/watch-bridge stop     # cancelar modo guardia
```

### Para auto-activacion al abrir sesion

Añadir al CLAUDE.md del proyecto:
```markdown
## Modo guardia automatico

Al abrir esta sesion, si el ultimo mensaje en `shared/BRIDGE.md` tiene
estado `pendiente` y es saliente reciente (<24h), activar automaticamente
la skill bridge-watch con intervalo 270s.

Tambien activar si la sesion previa guardada en
`~/.claude/sessions/` indica "modo guardia activo".
```

## Implementacion

### Funcion principal (pseudocodigo)

```python
def check_pending(shared_path, remote_names):
    """Revisar mensajes pendientes de cada remoto"""
    pendientes = []
    for remoto in remote_names:
        from_files = glob(f"{shared_path}/from_{remoto}_*.md")
        for f in from_files:
            tema = parse_tema(f)
            reply = f"{shared_path}/to_{remoto}_{tema}_reply.md"
            if not exists(reply):
                pendientes.append((remoto, f, tema))
    return pendientes

def watch_loop():
    pendientes = check_pending()
    if pendientes:
        # Procesar el mas antiguo primero
        remoto, archivo, tema = pendientes[0]
        contenido = read(archivo)
        # Decidir: responder auto vs derivar al usuario
        if puede_responder_solo(contenido):
            responder(remoto, tema, contenido)
            schedule_wakeup(270)  # reset
        else:
            # Avisar usuario, no responder, reprogramar
            informar_usuario(contenido)
            # No reprogramar hasta que usuario decida
    else:
        # Sin novedad, aplicar backoff
        siguiente_intervalo = backoff(ultimo_intervalo, ticks_sin_novedad)
        schedule_wakeup(siguiente_intervalo)
```

### Detectar canales automaticamente

```bash
# Extraer nombres de proyectos remotos del BRIDGE.md
grep -oP "Proyecto remoto.*?\K[a-z_]+$" shared/BRIDGE.md | sort -u
```

### Heuristica para "puedo responder solo"

Responder automaticamente si:
- Es un FYI / acuse de recibo / informativo
- Es una pregunta cuya respuesta esta literalmente en el repo
  (CLAUDE.md, memorias, archivos de codigo)
- El mensaje incluye explicitamente "responde con X si Y"

Derivar al usuario si:
- Pide decision arquitectonica o de negocio
- Pide modificar codigo en produccion
- Pide enviar correo a terceros
- Cita al usuario explicitamente ("preguntale a Juanjo")
- No estamos seguros del contexto

## Salir del modo guardia

- Usuario dice "stop", "cierra", "no escuches mas"
- Usuario cambia de tema (ej. pide trabajar en otra cosa) → pausar pero
  recordar para retomar
- Sesion se cierra → guardar estado en `~/.claude/sessions/`

## Estado entre sesiones

Al cerrar sesion en modo guardia, guardar en
`~/.claude/sessions/YYYY-MM-DD-<proyecto>-bridge-watch-active.md`:

```markdown
# Bridge watch activo
**Proyecto**: <nombre>
**Canales activos**: <lista>
**Ultimo tick**: <fecha>
**Mensajes procesados en sesion**: <N>
**Mensajes derivados al usuario**: <N>
**Proximo intervalo recomendado al retomar**: 270s
```

Cuando se retome el proyecto, esa sesion indica que hay que reactivar
modo guardia inmediatamente.

## Auto-mejora

Al cerrar cada aplicacion practica de esta skill:
1. Registrar en `~/.claude/skills/bridge-watch/aprendizajes/`:
   - Tipos de mensaje que aparecieron
   - Cuales se respondieron solos vs derivados al usuario
   - Si la heuristica de "puedo responder solo" fallo (over o under)
2. Actualizar el cuerpo del SKILL.md si hay patrones nuevos
3. Si se descubre un anti-patron (ej. responder algo que no debias),
   añadirlo a "Errores conocidos"

## Errores conocidos

(vacio al crear, se va llenando)

## Multi-canal

Si el proyecto tiene varios canales (Canal 1, 2, 3 en BRIDGE.md),
revisar TODOS en cada tick. Procesar por orden de aparicion (FIFO).
Si dos llegan a la vez, el del canal con menor numero gana
(canal 1 > canal 2 > canal 3).
