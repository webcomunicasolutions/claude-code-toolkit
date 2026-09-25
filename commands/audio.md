---
description: Enviarme por Telegram una nota de voz con lo que acabas de explicar
---

# /audio - Nota de voz por Telegram

Convierte una explicacion en una **nota de voz corta** y se la manda al usuario
por Telegram. Para cuando no puede (o no quiere) leer: conduciendo, con las
manos ocupadas, etc.

## Invocacion

```
/audio                 # resume TU ULTIMO mensaje y lo manda hablado
/audio <texto>         # lee ese texto concreto
/audio largo           # resumen mas extenso (hasta ~90s) en vez de ~40s
/audio mujer           # usa voz femenina (es-ES-ElviraNeural)
```

## Lo importante: NO leas tu mensaje literal

**Nunca** pases el texto de tu respuesta tal cual al conversor. Cuatro pantallas
de texto son cuatro minutos de audio insoportable, y escuchando no se puede
saltar parrafos ni releer.

Escribe un **guion hablado nuevo**:

- **30-45 segundos** (unos 500-700 caracteres). Con `largo`, hasta ~90s (1400).
- **Tono de conversacion**, como si se lo contaras por telefono a un colega:
  "Oye, te resumo lo de X..." No es un informe leido en voz alta.
- **Solo la conclusion y el porque**. Lo que tiene que hacer o decidir. El
  detalle ya esta escrito arriba, quien lo quiera lo lee.
- **Sin formato**: nada de markdown, viñetas, tablas, URLs, rutas de archivo,
  numeros de version ni `codigo`. No se pueden oir. Si hay que mencionar una
  cifra, dila redonda ("cuatrocientos euros", no "400,00 EUR").
- **Frases cortas.** Se escucha, no se lee.
- Escribir los numeros y siglas **como se pronuncian** cuando ayude
  (edge-tts lee bien el espanol, pero una IP o un slug tecnico suenan fatal:
  omitelos o describelos).

## Como se envia

```bash
echo "GUION HABLADO" | ~/.claude/scripts/audio-nota.sh
```

Requiere las variables de entorno `TELEGRAM_BOT_TOKEN` y `TELEGRAM_CHAT_ID`
(ponlas en tu shell o en tu gestor de secretos; el script las lee del entorno,
nunca hardcodeadas).

Variantes:

```bash
# voz femenina
echo "texto" | VOZ=es-ES-ElviraNeural ~/.claude/scripts/audio-nota.sh

# que suene ademas por los altavoces del PC
echo "texto" | ~/.claude/scripts/audio-nota.sh --local

# mas lento / mas rapido
echo "texto" | RATE=+0% ~/.claude/scripts/audio-nota.sh
```

El script hace: edge-tts (texto -> mp3) -> ffmpeg (-> ogg/opus) -> Telegram
`sendVoice`. Devuelve una linea con la duracion y los caracteres.

**Ejecutar siempre con `dangerouslyDisableSandbox: true`** (necesita red).

## Motor y coste

- **edge-tts** (Microsoft): **gratis, sin API key, sin limite**. Voces
  `es-ES-AlvaroNeural` (m, por defecto), `es-ES-ElviraNeural` (f),
  `es-ES-XimenaNeural` (f).
- Si prefieres un motor de pago (voz clonada, mejor prosodia), sustituye el
  paso 1 del script por tu proveedor de TTS preferido; solo cambia esa parte.
- Credenciales de Telegram: variables de entorno `TELEGRAM_BOT_TOKEN` /
  `TELEGRAM_CHAT_ID`. **Nunca escribirlas en un archivo del repo.**

## Tras enviarlo

Confirmar en **una linea** ("Te lo he mandado por Telegram, 34 segundos").
No repitas el guion por escrito: el objetivo era no tener que leer.

## Auto-mejora

Al cerrar cada uso: si el usuario dice que fue muy largo, muy corto, que la voz
no encaja o que se perdio algo, ajustar aqui la duracion objetivo, la voz o las
reglas del guion.
