# Envíos

Índice: [Ventana 24h](#la-ventana-de-24-horas) · [Formato del número](#formato-del-número-destino) ·
[Enviar plantilla (Cloud directo)](#enviar-plantilla-cloud-directo) ·
[Parámetros](#parámetros-body-header-botón) · [Texto](#enviar-texto) ·
[PDF/adjuntos](#pdf-y-adjuntos-enlace-no-media) · [Vía Chatwoot](#envío-vía-chatwoot-registrado-en-la-conversación)

## La ventana de 24 horas

- **Dentro de 24h** desde el último mensaje del cliente → se puede enviar **texto libre**, imágenes, etc.
- **Fuera de 24h** (mensaje proactivo: "te mando tu factura") → **solo plantillas APROBADAS**.
- Casi todos los envíos de negocio (facturas, avisos) son proactivos → **plantilla obligatoria**.

## Formato del número destino

E.164 con prefijo país y **sin `+`**: `34600111222`. Sin espacios ni guiones.

## Enviar plantilla (Cloud directo)

```bash
# solo params de texto del body ({{1}} {{2}} ...):
./enviar_plantilla.sh 34600111222 envio_factura es "Iliana" "ALF-2026/2359"

# con botón URL dinámico / header imagen -> pasar components crudos:
WA_COMPONENTS='[
  {"type":"body","parameters":[{"type":"text","text":"Iliana"},{"type":"text","text":"ALF-2026/2359"}]},
  {"type":"button","sub_type":"url","index":"0","parameters":[{"type":"text","text":"doc.php?d=f&id=16521&t=abc"}]}
]' ./enviar_plantilla.sh 34600111222 envio_factura es
```
Respuesta OK: `{"status":"accepted","id":"wamid...."}`. `accepted` = Meta lo aceptó (aún no entregado).

## Parámetros (body, header, botón)

Estructura de `components` al enviar:
```json
[
  {"type":"header","parameters":[{"type":"image","image":{"link":"https://.../logo.jpg"}}]},
  {"type":"body","parameters":[{"type":"text","text":"Iliana"},{"type":"text","text":"F-2359"}]},
  {"type":"button","sub_type":"url","index":"0","parameters":[{"type":"text","text":"doc.php?id=1&t=x"}]}
]
```
- **header** imagen: `image.link` (URL pública) o `image.id` (media_id de `subir_media.sh`).
- **body**: un `{type:"text",text:...}` por cada `{{n}}`, en orden.
- **button** url dinámico: `sub_type:"url"`, `index` del botón (0-based), y el `text` es **solo la ruta**
  variable que Meta concatena al dominio fijo de la plantilla.

## Enviar texto

```bash
./enviar_texto.sh 34600111222 "Hola, tu cita es mañana a las 10:00"   # SOLO dentro de 24h
```
`preview_url:true` genera vista previa de enlaces.

## PDF y adjuntos: enlace, no media

Para mandar un PDF (factura, presupuesto) de forma proactiva **no se adjunta el fichero**:
- Se usa una plantilla con **botón URL** o **enlace en el cuerpo** que apunta al PDF alojado en la web.
- Proteger el enlace con **token firmado** (HMAC) para que no haya IDOR ni se necesite login.
  Patrón de referencia: endpoint público `doc.php?d=f&id=<id>&t=<hmac>` (ejemplo de un ERP propio).
- Alternativa (dentro de 24h): subir el PDF con `subir_media.sh` y mandarlo como documento — pero fuera
  de ventana no sirve, por eso el enlace es el patrón general.

## Envío vía Chatwoot (registrado en la conversación)

Cuando el número está gestionado por **Chatwoot** (agentes humanos + bot), enviar por Cloud directo
**no queda registrado** en Chatwoot. Para que aparezca en la conversación del cliente, enviar por la API
de Chatwoot (Chatwoot cursa la plantilla por su conexión al mismo WABA; solo cursa plantillas que existan
en ESE WABA — las sincroniza de Meta).

Flujo (Chatwoot v3/v4, `api_access_token` header):
```
1. Buscar contacto:  GET  /api/v1/accounts/{acc}/contacts/search?q=<E164>
2. Si no existe:     POST /api/v1/accounts/{acc}/contacts   {inbox_id,name,phone_number:"+34..."}
3. source_id:        POST /api/v1/accounts/{acc}/contacts/{id}/contact_inboxes {inbox_id}
4. Conversación:     POST /api/v1/accounts/{acc}/conversations {source_id,inbox_id,contact_id}
5. Enviar plantilla: POST /api/v1/accounts/{acc}/conversations/{conv}/messages
   {
     "content": "<texto que se registra>",
     "message_type": "outgoing",
     "template_params": { "name":"envio_factura_link", "category":"utility",
                          "language":"es", "processed_params": {"1":"Iliana","2":"F-2359","3":"https://.../doc.php?..."} }
   }
```
Notas:
- ✅ **VERIFICADO (Chatwoot 4.14.2, 2026-07-04):** este formato `template_params` **cursa la plantilla
  de verdad** y se **entrega fuera de la ventana de 24h**. Chatwoot lo **almacena** con
  `content_type: "text"` y `status: "delivered"` — eso es normal, NO significa que fuera texto plano.
  El `content` que envías es solo lo que se ve en el panel; a WhatsApp va el cuerpo de la plantilla con
  los `processed_params` sustituidos.
- `processed_params` (objeto `{"1":..,"2":..}`) cubre los parámetros del **BODY**.
- ✅ **BOTÓN URL dinámico por Chatwoot SÍ funciona (verificado 2026-07-04, v4.14.2)** con
  `processed_params` **estructurado**:
  ```json
  "processed_params": { "body": {"1":"Jefe","2":"F-2359"},
                        "buttons": [{"type":"url","parameter":"doc.php?d=f&id=1&t=abc"}] }
  ```
  Así se puede usar la plantilla con **botón** ("Ver factura") en vez de enlace en el cuerpo, y sigue
  quedando registrado en Chatwoot. `parameter` = solo la ruta variable del botón.
- El número (inbox) tiene su **WABA**; la plantilla debe estar `APPROVED` en ese WABA.
- ⚠️ **Handoff del bot**: un `outgoing` por API cuenta como "escribió un agente" → puede apagar el bot en
  esa conversación (si hay handoff tipo ALFIA). Coordinar con el equipo del bot.
- Implementación PHP de referencia: `<tu-app>/nucleo/whatsapp.php`.
