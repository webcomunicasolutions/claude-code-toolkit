# Configuración y credenciales

## Los 3 datos imprescindibles

| Dato | Dónde se ve en Meta | Uso |
|------|---------------------|-----|
| `waba_id` | Business Manager → WhatsApp Accounts, o `GET /me/businesses`→WABAs | plantillas, números |
| `phone_number_id` | WhatsApp Manager → API Setup, o `GET /{waba_id}/phone_numbers` | envíos, media |
| `token` | System User token (ver abajo) | todo |

Con estos 3 la skill opera. `display_phone_number` (el +34…) es informativo; para enviar se usa el `phone_number_id`.

## Token: usar System User (permanente), no el temporal

- El token de "API Setup" del panel es **temporal (24h)** → NO sirve en producción.
- Crear un **System User** en Business Settings → Users → System Users → *Generate token*:
  - Permisos: **`whatsapp_business_management`** (plantillas, config) + **`whatsapp_business_messaging`** (enviar).
  - Asignar el/los WABA(s) y la App al System User (Assets).
  - Elegir caducidad **"Never"** → token permanente.
- Es un secreto crítico (acceso total al WhatsApp del cliente). Guardar en el vault; si se filtra, **rotar** en Meta.

## Verificar que el token funciona (sin enviar nada)
```bash
export WA_TOKEN=... WA_WABA_ID=... WA_PHONE_ID=...
./listar_numeros.sh       # si lista números, el token accede al WABA
./plantilla_listar.sh     # confirma permiso de gestión de plantillas
```
Un mismo System User token puede abarcar **varios WABAs** del mismo Business (probar cada WABA con `listar_numeros.sh`).

## Patrón de credenciales en el vault (recomendado)

Un bloque por número. Si el cliente tiene 2 números en 2 WABAs, dos bloques:
```json
{
  "apis": {
    "whatsapp":          { "telefono": "+34 6..", "phone_number_id": "10365..", "waba_id": "14551..", "access_token": "EAAG..", "api_type": "CLOUD_API" },
    "whatsapp_oficial":  { "telefono": "+34 6..", "phone_number_id": "13602..", "waba_id": "13847..", "access_token": "EAAG.." }
  }
}
```
Uso: `WA_VAULT=~/.credentials/<cliente>.json WA_PATH='.apis.whatsapp_oficial' ./listar_numeros.sh`.

## Arrancar en un proyecto nuevo (checklist)

1. Pedir/obtener `waba_id`, `phone_number_id` y el token System User.
2. Guardar en el vault del cliente (bloque `.apis.whatsapp*`), con puntero — nunca en git.
3. `listar_numeros.sh` + `plantilla_listar.sh` para verificar acceso.
4. Diseñar las plantillas necesarias (`references/plantillas.md`) y crearlas → esperar `APPROVED`.
5. Decidir vía de envío: Cloud directo o Chatwoot (`references/envios.md`).

## Business profile (opcional)
```bash
# leer perfil del número (about, dirección, web, email, vertical)
curl -s -K <(wa_cfg) "$GRAPH/$WA_PHONE_ID/whatsapp_business_profile?fields=about,address,description,email,websites,vertical,profile_picture_url" | jq .
# actualizar
curl -s -K <(wa_cfg) -X POST "$GRAPH/$WA_PHONE_ID/whatsapp_business_profile" \
  -H 'Content-Type: application/json' \
  -d '{"messaging_product":"whatsapp","about":"Clínica veterinaria","email":"info@...","websites":["https://..."]}'
```

## Webhooks (recepción de mensajes y estados)
- Se configuran en la **App** de Meta (Webhooks → WhatsApp Business Account), no por este token.
- Suscripciones típicas: `messages` (mensajes entrantes + estados de entrega/lectura).
- El WABA debe estar **suscrito a la app**: `POST /{waba_id}/subscribed_apps`.
- Verificación del webhook: Meta hace `GET` con `hub.challenge` → responder el challenge.
- Si el número está conectado a **Chatwoot**, los webhooks ya los consume Chatwoot; no montar otro
  consumidor sobre el mismo número sin coordinar (se pisan). Ver `references/envios.md`.
