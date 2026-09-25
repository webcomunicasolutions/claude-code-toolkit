# Plantillas de mensaje (message templates)

Índice: [Anatomía](#anatomía) · [Categorías](#categorías) · [Idioma](#idioma) ·
[Componentes](#componentes) · [Diseño visual](#diseño-visual-emojis-y-formato) ·
[Header con imagen](#header-con-imagen-logobanner) · [Botones](#botones) ·
[Ejemplos completos](#ejemplos-completos) · [Aprobación](#ciclo-de-aprobación) · [Editar](#editar-una-plantilla)

## Anatomía

Una plantilla es un JSON que se envía a `POST /{WABA_ID}/message_templates`:
```json
{
  "name": "envio_factura",         // minúsculas, números y _  (único por idioma)
  "language": "es",                // ver "Idioma"
  "category": "UTILITY",           // UTILITY | MARKETING | AUTHENTICATION
  "parameter_format": "POSITIONAL",// POSITIONAL ({{1}}) o NAMED ({{nombre}})
  "components": [ ... ]            // HEADER? BODY (obligatorio) FOOTER? BUTTONS?
}
```
Crear: `./plantilla_crear.sh envio_factura.json` → queda `PENDING`.

## Categorías

| Categoría | Para | Coste/nota |
|-----------|------|------------|
| **UTILITY** | Confirmaciones, facturas, recordatorios de una gestión existente | Más barata, aprueba fácil si es transaccional |
| **MARKETING** | Promos, novedades, reenganche | Más cara, más escrutinio |
| **AUTHENTICATION** | Códigos OTP | Formato especial |

Meta **recategoriza** si el contenido no encaja (una "UTILITY" con tono promocional pasa a MARKETING).

## Idioma

- `language` debe **coincidir EXACTO** al crear y al enviar. `es` (español genérico) y `es_ES`
  (España) son **distintos**: si creas en `es` y envías con `es_ES`, falla.
- Recomendado: **`es`** salvo que haya razón para regionalizar. Ser consistente en todo el proyecto.

## Componentes

- **HEADER** (opcional, 1): `format` = `TEXT` | `IMAGE` | `VIDEO` | `DOCUMENT` | `LOCATION`.
  - TEXT admite 1 variable. IMAGE/VIDEO/DOCUMENT necesitan `example.header_handle` (ver abajo).
- **BODY** (obligatorio): texto con `{{1}}`, `{{2}}`… y `example.body_text`. Admite formato.
- **FOOTER** (opcional): texto corto, sin variables (ej. "Clínica Veterinaria Ejemplo").
- **BUTTONS** (opcional): hasta 10 combinando URL / QUICK_REPLY / PHONE_NUMBER / COPY_CODE.

Los ejemplos (`example`) son **obligatorios** cuando hay variables o header media, o Meta rechaza.

## Diseño visual (emojis y formato)

WhatsApp renderiza formato dentro del texto de BODY/HEADER/FOOTER:

| Efecto | Sintaxis | Resultado |
|--------|----------|-----------|
| Negrita | `*texto*` | **texto** |
| Cursiva | `_texto_` | _texto_ |
| Tachado | `~texto~` | ~~texto~~ |
| Monoespacio | ```` ```texto``` ```` | `texto` |
| Salto de línea | `\n` en el JSON | nueva línea |

Buenas prácticas visuales:
- **Emojis** al inicio de bloques y para separar secciones (🐾 📄 ✅ 📅 💳 📍 ⏰ 👇). No abusar (1–3 por mensaje).
- Una **línea separadora** ayuda: `━━━━━━━━━━━━━━`.
- Título en **negrita** + datos clave en su línea. Mensaje escaneable, no un párrafo denso.
- FOOTER con el nombre del negocio da profesionalidad.
- HEADER de **imagen** (logo/banner) es lo que más sube la percepción de calidad (ver siguiente sección).

Ejemplo de BODY cuidado:
```
📄 *Factura {{2}}*
━━━━━━━━━━━━━━
Hola {{1}}, aquí tienes tu factura de *Clínica Veterinaria Ejemplo*. 🐾

Pulsa el botón para ver o descargar el PDF 👇
```

## Header con imagen (logo/banner)

El HEADER de imagen NO se sube por `/media` (eso es para mensajes). En la **creación** de la plantilla
se necesita un **`header_handle`** del *Resumable Upload API*:

```bash
# 1) crear sesión de subida en la APP (necesita APP_ID y el fichero)
LEN=$(stat -c%s logo.jpg); TYPE=image/jpeg
SES=$(curl -s -K <(wa_cfg) -X POST \
  "$GRAPH/$WA_APP_ID/uploads?file_length=$LEN&file_type=$TYPE" | jq -r .id)   # upload:xxxx
# 2) subir los bytes -> devuelve el handle (h)
HANDLE=$(curl -s -X POST "$GRAPH/$SES" \
  -H "Authorization: OAuth $WA_TOKEN" -H "file_offset: 0" \
  --data-binary @logo.jpg | jq -r .h)
# 3) usar HANDLE en el componente HEADER de la plantilla:
#   {"type":"HEADER","format":"IMAGE","example":{"header_handle":["<HANDLE>"]}}
```
Al **enviar**, el header de imagen se rellena con un `link` o `media_id` (ver `references/envios.md`).
Requiere `WA_APP_ID` (el ID de la App de Meta). Guardarlo en el vault junto a las credenciales.

## Botones

```json
{ "type": "BUTTONS", "buttons": [
  { "type": "URL", "text": "Ver factura", "url": "https://dominio/{{1}}",
    "example": ["https://dominio/doc.php?id=1&t=abc"] },
  { "type": "QUICK_REPLY", "text": "Confirmar" },
  { "type": "PHONE_NUMBER", "text": "Llamar", "phone_number": "+34952000000" }
]}
```
- **URL dinámica** (`.../{{1}}`): el ejemplo debe ser una URL concreta (no `{{1}}`). Al enviar se pasa
  **solo la parte variable** (la ruta), Meta la concatena al dominio fijo.
- ⚠️ El botón URL dinámico por **Cloud directo** funciona; por **Chatwoot** su soporte es dudoso → si
  vas por Chatwoot, considera poner el enlace en el BODY. Ver `references/gotchas.md` y `envios.md`.

## Ejemplos completos

Ver ficheros de ejemplo en `assets/ejemplos/`:
- `envio_factura_boton.json` — header texto + body + botón URL dinámico.
- `envio_factura_link.json` — enlace en el cuerpo (robusto por Chatwoot).
- `recordatorio_cita.json` — recordatorio con emojis, header imagen y quick replies.

## Ciclo de aprobación

- Al crear → `PENDING`. Meta revisa (de minutos a horas). Estados: `APPROVED`, `REJECTED`, `PAUSED`, `DISABLED`.
- Comprobar: `./plantilla_listar.sh envio_factura`.
- `REJECTED`: Meta da un motivo; corregir el JSON y volver a crear (mismo `name` reenvía).
- Solo se puede **enviar** cuando está `APPROVED`.

## Editar una plantilla

- `./plantilla_editar.sh <template_id> componentes.json` (el id lo da `plantilla_listar.sh`).
- Solo editable en `APPROVED`/`REJECTED`/`PAUSED`; reentra a revisión.
- Se puede cambiar `components` y a veces `category`; **no** el `name` ni el `language`.
- Editar una `APPROVED` la pone otra vez `PENDING` hasta reaprobación (durante ese tiempo la versión
  vigente sigue enviándose).
