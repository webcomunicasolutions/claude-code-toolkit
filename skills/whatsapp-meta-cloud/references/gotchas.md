# Gotchas — errores que cuestan horas (ya pagados)

## IDs y cuentas
- **WABA_ID ≠ PHONE_NUMBER_ID.** El WABA gestiona plantillas/números; el phone_id envía. Un 404 o
  "permiso" casi siempre es usar uno donde iba el otro.
- **Una empresa puede tener 2 números en 2 WABAs DISTINTOS.** Las plantillas son por WABA: hay que
  crear la misma plantilla en **cada** WABA. Verificar con `listar_numeros.sh` sobre cada WABA
  (caso real un cliente veterinario: pruebas `1455…` y oficial `1384…`, WABAs separados).
- Un **System User token** suele abarcar todos los WABAs del Business → sirve para ambos. Probar.

## Token
- El token de "API Setup" es **temporal (24h)**. Para producción, **System User token permanente**
  con permisos `whatsapp_business_management` + `whatsapp_business_messaging`.
- Nunca hardcodear el token (ni en workflows n8n, ni en scripts, ni en commits). Si aparece en el chat
  o en un repo → **rotarlo** en Meta. Guardar siempre por puntero al vault.

## Plantillas
- **Idioma exacto**: crear en `es` y enviar con `es_ES` → falla. Ser consistente (recomendado `es`).
- **`example` obligatorio** cuando hay variables o header media, o Meta rechaza al crear.
- **Botón URL dinámico**: el `example` del botón debe ser una **URL concreta** (no `{{1}}`). Al enviar
  se manda solo la **ruta** variable; Meta la concatena al dominio fijo. No meter el dominio dos veces.
- **Header de imagen en la creación** usa `header_handle` del *Resumable Upload API* (necesita `APP_ID`),
  **no** el `media_id` de `/media`. Son cosas distintas (ver `plantillas.md`).
- Cada **reenvío a revisión tarda**: dejar la plantilla bien (texto, emojis, header) antes de crearla.
- Meta puede **recategorizar** UTILITY→MARKETING si el tono es promocional.
- **El BODY no puede empezar ni terminar con una variable `{{n}}`.** Debe haber texto fijo antes y
  después. Error de Meta: "Las variables no pueden estar al principio ni al final de la plantilla".

## Envío
- **Ventana 24h**: fuera de ella, solo plantillas aprobadas; el texto libre falla.
- `message_status: accepted` = Meta lo aceptó, **no** que se entregó. La entrega/lectura llega por webhook.
- Número destino **E.164 sin `+`** (`34600111222`).

## Chatwoot
- Chatwoot solo puede cursar plantillas que existan y estén `APPROVED` en el **WABA de ese inbox**
  (las sincroniza de Meta automáticamente).
- **`processed_params` cubre el BODY con certeza; el botón URL dinámico por Chatwoot es dudoso** →
  para envíos por Chatwoot, plantilla con el **enlace en el cuerpo** ({{n}}=URL) es lo robusto.
- ✅ **VERIFICADO (Chatwoot 4.14.2):** el mensaje enviado con `template_params` se **guarda** con
  `content_type: "text"` y `status: "delivered"` — NO es un fallo ni un envío como texto plano: la
  plantilla se cursa bien y llega **fuera de la ventana de 24h**. No confundir el almacenamiento interno
  de Chatwoot con el modo de envío real.
- Enviar `outgoing` por API con el token de un agente puede **disparar el handoff** (apagar el bot en
  esa conversación). Coordinar con el equipo del bot.
- El envío por Cloud directo **NO** aparece en Chatwoot; si se quiere trazabilidad, ir por Chatwoot.

## Números / calidad
- `quality_rating`: GREEN (bien) / YELLOW / RED (riesgo de bloqueo por reportes de usuarios).
- `code_verification_status: EXPIRED` (verificación del display name caducada) no impide enviar por API,
  pero conviene re-verificar para el nombre visible.
- Hay **límites de mensajería** por número (tier 250/1k/10k/…); suben con volumen y calidad.

## Errores conocidos
_(añadir aquí los que vayan apareciendo — sección de auto-mejora)_

- `(#132000)` número de parámetros del body no coincide con la plantilla → revisar cuántos `{{n}}` tiene.
- `(#132001)` plantilla no existe / idioma no coincide → revisar `name` + `language` exactos.
- `(#131009)` parámetro inválido (p. ej. salto de línea o carácter no permitido en un botón URL).
- `100 Invalid parameter` al crear → falta `example`, o `components` mal formado, o categoría inválida.

## App ID: cómo obtenerlo cuando el cliente no lo sabe (2026-07-22, un cliente veterinario)
- `GET /debug_token?input_token=<token>` FALLA con token de system user (`#100 You must
  provide an app access token...`) — no sirve para descubrir el app_id del propio token.
- Lo que SÍ funciona: **`GET /{waba_id}/subscribed_apps`** → devuelve la app suscrita al
  WABA con su `id` = App ID válido para la Resumable Upload API (`POST /{app_id}/uploads`).
- Frecuente en cuentas gestionadas: la app es del PARTNER (no del cliente), por eso el
  cliente "no sabe de qué le hablas" cuando le pides el App ID. Pregúntate primero si la
  app es tuya antes de pedirlo.
- El `header_handle` devuelto al subir (h=4:...) es de UN SOLO USO por creación de
  plantilla; en los JSON versionados dejar placeholder.

## Botones: en el MÓVIL solo se ven los DOS primeros

Verificado con plantilla real (un cliente veterinario, 2026-07-23): una plantilla con **4 QUICK_REPLY**
se crea y Meta la aprueba sin problema, y en **WhatsApp de escritorio salen los cuatro**...
pero en el **móvil solo se muestran los DOS primeros** y el resto queda escondido tras un
desplegable.

Consecuencias prácticas:
- El **orden** de los botones decide qué ve realmente el usuario. Poner en las dos primeras
  posiciones los que de verdad importan.
- No diseñar flujos que asuman que se ven 3 o 4 botones. Si hay que ofrecer más opciones,
  contar con que las demás cuestan un toque extra.
- Caso de uso donde importa: plantilla **bilingüe** con botones en dos idiomas (el botón
  pulsado hace de señal de idioma). Alternar idiomas (`Sí` · `Yes` · `No puedo` · `Can't`)
  deja visible la confirmación en ambos idiomas; agruparlos por idioma
  (`Sí` · `No puedo` · `Yes` · `Can't`) deja al segundo idioma sin nada visible en su lengua.

Comprobarlo SIEMPRE en un móvil real antes de dar por buena una plantilla con más de 2 botones:
en escritorio no se aprecia el problema.
