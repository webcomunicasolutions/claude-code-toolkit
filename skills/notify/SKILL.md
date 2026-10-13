---
name: notify
description: Enviar notificaciones via Telegram y/o Email desde cualquier proyecto. Usar cuando se necesite alertar, informar o enviar mensajes al usuario.
user_invocable: true
---

# /notify - Notificaciones Telegram + Email

Envia notificaciones al usuario por Telegram, Email o ambos.

## Invocacion

```
/notify <mensaje>                  # Telegram + Email
/notify telegram <mensaje>         # Solo Telegram
/notify email <mensaje>            # Solo Email
/notify test                       # Prueba de conectividad de ambos canales
/notify status                     # Muestra la config actual (enmascarada)
```

## Configuracion (variables de entorno)

Las credenciales NUNCA se escriben en este fichero ni en el repo. Define estas variables en tu shell
(`~/.bashrc`, `~/.zshrc`) o, mejor, cargalas desde tu gestor de credenciales:

| Variable | Para que |
|---|---|
| `TELEGRAM_BOT_TOKEN` | Token del bot (se crea con @BotFather) |
| `TELEGRAM_CHAT_ID` | Tu chat id (escribe al bot y consulta `getUpdates`) |
| `NOTIFY_SMTP_HOST` / `NOTIFY_SMTP_PORT` | Servidor SMTP (opcional, solo para email) |
| `NOTIFY_SMTP_USER` / `NOTIFY_SMTP_PASSWORD` | Credenciales SMTP |
| `NOTIFY_FROM` / `NOTIFY_TO` | Remitente y destinatario del email |

Si falta una variable, informar de cual y no intentar ese canal.

## Implementacion

### Enviar Telegram

```bash
# El token va por -K (fichero de config en memoria), no en la linea de comandos: asi no se ve con `ps`
curl -s -X POST -K <(printf 'url = "https://api.telegram.org/bot%s/sendMessage"\n' "$TELEGRAM_BOT_TOKEN") \
    --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=MENSAJE" \
    --data-urlencode "parse_mode=Markdown"
```

### Enviar Email

Requiere `msmtp`. Generar la config en un fichero temporal (nunca dejar el password en un fichero permanente del repo):

```bash
RC=$(mktemp); chmod 600 "$RC"
cat > "$RC" <<CFG
account default
host ${NOTIFY_SMTP_HOST}
port ${NOTIFY_SMTP_PORT}
auth on
user ${NOTIFY_SMTP_USER}
password ${NOTIFY_SMTP_PASSWORD}
from ${NOTIFY_FROM}
tls on
tls_starttls off
CFG

printf 'Subject: %s\nFrom: %s\nTo: %s\nContent-Type: text/plain; charset=utf-8\n\n%s\n' \
    "ASUNTO" "$NOTIFY_FROM" "$NOTIFY_TO" "CUERPO" | msmtp -C "$RC" "$NOTIFY_TO"
rm -f "$RC"
```

> Nunca pasar el password por linea de comandos (queda visible en `ps`).
> Con puerto 587 usa `tls_starttls on`; con 465, `tls_starttls off`.
> Si `msmtp` no esta: `apt install -y msmtp`, o enviar solo por Telegram (solo necesita `curl`).

## Comportamiento por comando

- `/notify <mensaje>`: enviar por Telegram y por Email (asunto `[Claude Code] Notificacion`); confirmar que canales se usaron.
- `/notify telegram|email <mensaje>`: solo ese canal; confirmar en una linea.
- `/notify test`: mensaje de prueba por ambos canales y reporte de exito/fallo de cada uno.
- `/notify status`: variables definidas (sin valores, enmascarar) y conectividad.

## Reglas

- Si un canal falla, informar pero intentar el otro.
- Nunca mostrar tokens ni passwords en la salida (enmascarar con `***`).
- Mensajes Telegram con Markdown cuando sea apropiado.
- Si el entorno bloquea la red en el sandbox, ejecutar el comando fuera del sandbox (curl y msmtp necesitan red).
