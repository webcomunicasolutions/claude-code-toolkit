---
name: project-bridge
description: "Comunicacion estructurada entre proyectos de Claude Code. Crear canal shared/, enviar mensajes, leer y responder mensajes de otros proyectos."
user_invocable: true
---

# Project Bridge - Comunicacion entre proyectos

Protocolo para que dos proyectos de Claude Code se comuniquen de forma estructurada a traves de una carpeta `shared/` con mensajes en Markdown.

## Invocacion

```
/project-bridge setup <ruta_proyecto_remoto>    # Crear canal con otro proyecto
/project-bridge send <tema>                      # Enviar mensaje al proyecto vinculado
/project-bridge inbox                            # Ver mensajes pendientes de respuesta
/project-bridge reply <archivo_mensaje>          # Responder a un mensaje recibido
/project-bridge status                           # Ver estado del canal
```

## Conceptos

- **Proyecto local**: El proyecto donde se ejecuta la skill (directorio de trabajo actual)
- **Proyecto remoto**: El otro proyecto con el que se comunica
- **Canal**: La carpeta `shared/` dentro del proyecto local
- **Mensaje**: Un archivo Markdown con formato estandarizado

## Comportamiento interactivo

Cuando el usuario invoca un comando sin los parametros necesarios, **preguntar siempre** en vez de fallar:

- `/project-bridge` o `/project-bridge setup` sin ruta → Preguntar: "¿Con que proyecto quieres crear un canal? Dame la ruta o el nombre del proyecto."
- `/project-bridge send` sin tema → Preguntar: "¿Sobre que tema quieres enviar un mensaje?"
- `/project-bridge reply` sin archivo → Mostrar inbox y preguntar: "¿A cual quieres responder?"
- Si ya existe `shared/BRIDGE.md`, leerlo para saber el proyecto remoto vinculado y no volver a preguntar.

### Deteccion automatica de proyecto remoto

Si el usuario da solo un nombre (ej: "gestioo_info") en vez de ruta completa:
1. Buscar en el mismo directorio padre del proyecto local (`../{{nombre}}/`)
2. Buscar en `~/proyectos/` recursivamente (max 2 niveles)
3. Si no se encuentra, pedir la ruta completa

### Soporte multi-canal

Un proyecto puede tener canales con varios proyectos remotos. En ese caso:
- `shared/BRIDGE.md` tiene multiples secciones, una por canal
- Al hacer `send` o `inbox`, si hay mas de un canal, preguntar: "¿A cual proyecto? Tienes canales con: X, Y, Z"
- Si solo hay un canal, usarlo directamente sin preguntar

## Comandos

### setup - Crear canal

Crea la carpeta `shared/` en el proyecto local y la configura.

1. Si no se proporciona ruta, preguntar al usuario con que proyecto quiere comunicarse
2. Resolver la ruta (busqueda automatica si solo se da el nombre)
3. Crear `shared/` en la raiz del proyecto local
4. Crear `shared/BRIDGE.md` con la configuracion del canal:

```markdown
# Project Bridge

## Canal
- **Proyecto local**: {{nombre del proyecto local (nombre del directorio)}}
- **Ruta local**: {{ruta absoluta del proyecto local}}
- **Proyecto remoto**: {{nombre del proyecto remoto}}
- **Ruta remoto**: {{ruta absoluta del proyecto remoto}}
- **Creado**: {{fecha}}

## Mensajes
| Fecha | Archivo | Direccion | Tema | Estado |
|-------|---------|-----------|------|--------|
```

3. Añadir referencia en el CLAUDE.md del proyecto local:
   - En la seccion mas apropiada (tabla de info, referencias, etc.)
   - Texto: `Comunicacion con {{proyecto_remoto}} | shared/BRIDGE.md`

4. Informar al usuario que debe configurar el proyecto remoto tambien (ejecutar `/project-bridge setup <ruta_este_proyecto>` desde el otro proyecto)

### send - Enviar mensaje

Crea un mensaje para el proyecto remoto.

1. Nombre del archivo: `from_{{proyecto_local}}_{{tema_snake_case}}.md`
2. Formato del mensaje:

```markdown
# Mensaje de {{proyecto_local}} -> {{proyecto_remoto}}

**Fecha**: {{YYYY-MM-DD}}
**De**: Proyecto {{proyecto_local}}
**Para**: Proyecto {{proyecto_remoto}}

## Contexto
{{Breve contexto de por que se envia el mensaje}}

## Detalle
{{Contenido principal: problema, pregunta, informacion, etc.}}

## Accion esperada
{{Que se espera que haga el proyecto remoto: investigar, arreglar, confirmar, etc.}}
```

3. Actualizar la tabla de mensajes en `shared/BRIDGE.md`:
   - Direccion: `->` (enviado)
   - Estado: `pendiente`

### inbox - Ver mensajes pendientes

1. Leer `shared/BRIDGE.md` del proyecto local
2. Buscar archivos `to_{{proyecto_local}}_*.md` en `shared/` que no tengan respuesta
3. Buscar tambien en la carpeta `shared/` del proyecto remoto (si es accesible) archivos `from_{{proyecto_remoto}}_*.md` sin reply
4. Mostrar lista de mensajes pendientes

### reply - Responder mensaje

1. Leer el mensaje original
2. Crear respuesta con nombre: `to_{{proyecto_origen}}_{{tema_snake_case}}_reply.md`
3. Formato de respuesta:

```markdown
# Respuesta de {{proyecto_local}} -> {{proyecto_origen}}

**Fecha**: {{YYYY-MM-DD}}
**De**: Proyecto {{proyecto_local}}
**Para**: Proyecto {{proyecto_origen}}
**Re**: {{nombre_archivo_original}}

## Resultado
{{Respuesta al mensaje: hallazgos, solucion, confirmacion, etc.}}

## Acciones tomadas
{{Si se hicieron cambios, listarlos}}

## Siguiente paso
{{Si queda algo pendiente, indicar quien debe actuar}}
```

4. Actualizar tabla en `shared/BRIDGE.md`:
   - Añadir linea de respuesta con direccion `<-` (recibido) y estado `respondido`
   - Marcar mensaje original como `respondido`

### status - Ver estado del canal

1. Leer `shared/BRIDGE.md`
2. Mostrar resumen: mensajes totales, pendientes, ultimo mensaje

## Reglas

1. **Siempre usar la carpeta `shared/` del proyecto local** - nunca escribir directamente en el proyecto remoto
2. **Respetar el formato** - los mensajes deben ser legibles tanto por humanos como por Claude Code
3. **Un tema por mensaje** - no mezclar temas distintos en un mismo mensaje
4. **Actualizar BRIDGE.md** - siempre mantener la tabla de mensajes actualizada
5. **No borrar mensajes** - son el historial de comunicacion entre proyectos
6. **Nombres descriptivos** - el tema en el nombre del archivo debe ser claro y en snake_case
7. **Contexto suficiente** - cada mensaje debe tener suficiente contexto para que el otro proyecto entienda sin necesidad de preguntar
