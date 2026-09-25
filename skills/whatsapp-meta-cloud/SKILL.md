---
name: whatsapp-meta-cloud
description: Gestión total de WhatsApp Cloud API de Meta (Graph API) reutilizable en cualquier proyecto con solo token + waba_id + phone_id. Cubre plantillas de mensaje (crear/listar/editar/borrar, header texto e imagen, botones, categorías, idiomas, diseño visual con emojis), envío de plantillas y texto, subida de media, gestión de números, configuración y webhooks; y el envío vía Chatwoot para que quede registrado en la conversación. Usar cuando se trabaje con WhatsApp Business/Cloud API, plantillas de Meta, envío de WhatsApp (facturas, avisos, recordatorios, notificaciones), WABA, message_templates, graph.facebook.com, o integración WhatsApp con Chatwoot. Triggers - "plantilla whatsapp", "enviar whatsapp", "whatsapp cloud", "meta template", "waba", "message_templates", "crear plantilla meta", "mandar factura por whatsapp", "whatsapp business api".
---

# WhatsApp Meta Cloud

Gestión completa de la **WhatsApp Cloud API** de Meta (Graph API `graph.facebook.com`).
Objetivo: operar cualquier cuenta con solo **3 datos** — `token`, `waba_id`, `phone_number_id`.

## Concepto clave que evita el 90% de los errores

| Dato | Para qué sirve |
|------|----------------|
| **WABA_ID** (WhatsApp Business Account) | Gestiona **plantillas** y lista **números**. |
| **PHONE_NUMBER_ID** | **Envía** mensajes y sube media. |
| **Token** (System User, permanente) | Autentica todo (Bearer). |

⚠️ WABA_ID y PHONE_NUMBER_ID **son IDs distintos**. Confundirlos da 404/permiso.
Un WABA puede tener **varios números**; y una empresa puede tener **varios WABAs** (cada uno
con SUS plantillas: una plantilla aprobada en un WABA no existe en otro).

## Quickstart

1. Cargar credenciales (una de dos formas):
   ```bash
   # a) variables de entorno
   export WA_TOKEN="EAAG..."  WA_WABA_ID="1455..."  WA_PHONE_ID="1036..."
   # b) desde un vault JSON (no expone el token en ps)
   export WA_VAULT=~/.credentials/<cliente>.json  WA_PATH='.apis.whatsapp'
   ```
2. Operar con los scripts (`scripts/`, ya ejecutables):
   ```bash
   ./listar_numeros.sh                         # números del WABA + phone_id + calidad
   ./plantilla_listar.sh [filtro]              # plantillas y su estado
   ./plantilla_crear.sh mi_plantilla.json      # crea -> PENDING (Meta revisa)
   ./enviar_plantilla.sh 34600111222 nombre es "Param1" "Param2"
   ./enviar_texto.sh 34600111222 "Hola"        # SOLO dentro de ventana 24h
   ```

Los scripts leen credenciales vía `_lib.sh` (env vars o vault) y **nunca exponen el token en `ps`**
(curl lo consume por descriptor). `WA_API_VERSION` por defecto `v21.0`.

## Scripts disponibles

| Script | Qué hace | Necesita |
|--------|----------|----------|
| `listar_numeros.sh` | Números del WABA, calidad, phone_id | WABA |
| `plantilla_listar.sh [filtro]` | Plantillas y estado | WABA |
| `plantilla_crear.sh f.json [...]` | Crea/reenvía a revisión | WABA |
| `plantilla_editar.sh <id> comp.json` | Edita plantilla existente | token |
| `plantilla_borrar.sh <nombre> [id]` | Borra por nombre o id | WABA |
| `enviar_plantilla.sh <tel> <tpl> <idioma> [body...]` | Envía plantilla (Cloud directo) | PHONE |
| `enviar_texto.sh <tel> "msg"` | Texto libre (ventana 24h) | PHONE |
| `subir_media.sh <fichero> [mime]` | Sube media, devuelve media_id | PHONE |

## Cómo trabajar — navegación

Leer el reference que aplique (no cargarlos todos):

- **Arrancar en un proyecto nuevo / credenciales / permisos / obtener los IDs / token permanente**
  → `references/configuracion.md`
- **Diseñar plantillas** (componentes, header imagen, botones, categorías, idioma, **diseño visual con
  emojis y formato**, aprobación, edición) → `references/plantillas.md`
- **Enviar** (plantilla vs texto, parámetros de body/header/botón, ventana 24h, **envío vía Chatwoot**
  para que quede registrado) → `references/envios.md`
- **Gotchas** (errores que cuestan horas, ya pagados) → `references/gotchas.md`

## Principios (no obvios)

- **Los PDF/adjuntos NO se mandan como media en plantillas proactivas.** Se manda una plantilla con
  **botón URL** o **enlace en el cuerpo** apuntando al fichero alojado en la web (idealmente con token
  firmado). Ver `references/envios.md`.
- **Fuera de la ventana de 24h solo se pueden enviar plantillas APROBADAS.** Texto libre solo si el
  cliente escribió en las últimas 24h.
- **Diseño primero, aprobación después:** cada reenvío a revisión de Meta tarda; deja la plantilla bien
  (emojis, formato, header) antes de crearla. Ver `references/plantillas.md`.
- **Credenciales siempre por puntero al vault**, nunca hardcodeadas en scripts, docs ni commits.

## Auto-mejora

Al cerrar cada aplicación práctica de esta skill:
1. Registrar aprendizajes en `references/gotchas.md` (o `aprendizajes/<caso>.md` si es extenso).
2. Si el patrón es generalizable, actualizar el cuerpo de este SKILL.md o el reference correspondiente.
3. Si se descubre un error recurrente, añadirlo a la sección "Errores conocidos" de `gotchas.md`.

Sin esta fase la skill se fosiliza y pierde valor.
