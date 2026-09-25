---
name: precios-ia
description: Precios vigentes de las APIs de IA de pago (OpenAI y Google Gemini) y qué combinación conviene para cada tarea - chat/agente, transcripción de audio, visión e imágenes. Usar cuando el usuario pregunte "cuánto cuesta", "qué modelo pongo", "qué es más barato", "cambiar de modelo", al montar o revisar un workflow n8n con IA, o antes de decidir proveedor para un cliente. Incluye el método para REFRESCAR los precios, que caducan rápido.
---

# Precios de APIs de IA — tabla viva

⚠️ **Los precios caducan en semanas** (Luna bajó un 80% el 30/07/2026; Gemini 3.6 Flash
bajó a la mitad y gpt-5.6-sol un 20/33% en el mes transcurrido entre el 04/08 y el
03/09/2026). Si la fecha de abajo tiene más de ~30 días, REFRESCAR antes de decidir.
Nunca citar de memoria.

**Última verificación: 2026-09-03** · Fuentes: `ai.google.dev/gemini-api/docs/pricing`
y `developers.openai.com/api/docs/pricing` (ambas cargaron correctamente), contrastadas
con llamadas reales usando las claves del vault (`gemini.json`, `openai.json`).

## OpenAI — texto/chat ($ por millón de tokens, contexto corto)

| Modelo | Entrada | Cacheada | Salida | ¿Responde con nuestra clave? |
|---|---|---|---|---|
| **gpt-5.6-luna** | **0,20** | 0,02 | **1,20** | ✅ 03/09 |
| gpt-5.4-nano | 0,20 | 0,02 | 1,25 | ✅ 03/09 |
| gpt-5-nano | 0,05 | 0,005 | 0,40 | ✅ 03/09 |
| gpt-5-mini | 0,25 | 0,025 | 2,00 | ✅ 03/09 |
| gpt-5.4-mini | 0,75 | 0,075 | 4,50 | ✅ 03/09 |
| gpt-5.1 | 1,25 | 0,125 | 10,00 | ✅ 03/09 |
| gpt-5.2 | 1,75 | 0,175 | 14,00 | ✅ 03/09 |
| **gpt-5.6-terra** | 2,00 | 0,20 | 12,00 | ✅ 03/09 |
| gpt-5.4 | 2,50 | 0,25 | 15,00 | ✅ 03/09 |
| **gpt-5.6-sol** | **4,00** ⬇ | 0,40 | **20,00** ⬇ | ✅ 03/09 |
| gpt-5.5 *(nuevo en la tabla)* | 5,00 | 0,50 | 30,00 | ✅ 03/09 |
| gpt-5.5-pro / gpt-5.4-pro | 30,00 | — | 180,00 | no probado |

⬇ **gpt-5.6-sol bajó** de 5,00/30,00 a **4,00/20,00** desde la última revisión (−20% entrada, −33% salida).
Contexto largo ≈ el doble (Luna: 0,40 / 1,80). Batch y Flex: −50%.

## Google Gemini — texto/chat ($ por millón de tokens)

| Modelo | Entrada | Salida | ¿Responde con nuestra clave? |
|---|---|---|---|
| Gemini 3.5 Flash-Lite | **0,30** (texto/imagen/vídeo/**audio**) | 2,50 | ✅ 03/09 |
| Gemini 3.1 Flash-Lite | 0,25 (audio 0,50) | 1,50 | ✅ 03/09 |
| **Gemini 3.8 Flash** *(nuevo)* | **0,75** ⏳ | **3,75** ⏳ | ✅ 03/09 |
| **Gemini 3.7 Flash** *(nuevo)* | **0,75** ⏳ | **3,75** ⏳ | ✅ 03/09 |
| **Gemini 3.6 Flash** | **0,75** ⬇ | **3,75** ⬇ | ✅ 03/09 |
| Gemini 3.5 Flash | 1,50 | 9,00 | ✅ 03/09 |
| Gemini 3.1 Pro Preview | 2,00 (>200k: 4,00) | 12,00 (>200k: 18,00) | ✅ 03/09 |
| ~~Gemini 2.5 Pro / Flash / Flash-Lite~~ | *(siguen con precio en la web)* | — | ❌ **404 retirados** (re-verificado 03/09) |

⏳ **OJO, es precio promocional:** 0,75/3,75 **hasta el 31/12/2026**. El **1/1/2027 se
dobla a 1,50/7,50**. Cualquier cálculo a un año vista debe usar la tarifa de 2027.

⬇ Gemini 3.6 Flash **bajó a la mitad** (era 1,50/7,50) desde la última revisión.

Batch y Flex: −50%. Grounding con Google Search: 14 $/1.000 peticiones pasado el tramo gratis.

### Modelos especializados de Gemini (de la web oficial, no probados salvo indicación)

| Modelo | Precio | Nota |
|---|---|---|
| Gemini 3.5 Transcribe | 2,00 audio entrada / 12,00 texto salida | ✅ probado 03/09 — ver trampa del campo raro |
| Gemini 3.5 Live Translate | 3,50 audio entrada / 21,00 audio salida | no probado |
| Gemini 3.1 Flash-Lite Image | 0,25 entrada / 1,50 imagen salida | no probado |
| Veo 3.1 (vídeo) | 0,40–0,60 $/segundo (720p–4K) | no probado |
| Lyria 3 (música) | 0,04 clip 30s / 0,08 canción | no probado |
| Gemini Embedding 2 | 0,20 texto / 0,45 imagen / 6,50 audio | no probado |

## VOZ en OpenAI — las tres familias

### 1. Voz → texto (transcribir) · $ por minuto

| Modelo | Precio | Para qué |
|---|---|---|
| **gpt-4o-mini-transcribe** | **0,003** | El caballo de batalla: notas de voz de Telegram/WhatsApp |
| gpt-transcribe | 0,0045 | Algo mejor, 50% más caro |
| whisper-1 · gpt-4o-transcribe | 0,006 | Whisper clásico; `whisper-1` es el más compatible con n8n |
| gpt-4o-transcribe-diarize | 0,006 | **Separa quién habla** — grabaciones de llamadas o reuniones |
| gpt-live-transcribe · gpt-realtime-whisper | 0,017 | Transcripción **en directo**, mientras se habla |
| gpt-realtime-translate | 0,034 | Traducción hablada en directo |

#### ✅ Circuito de notas de voz (WhatsApp/Telegram) — RE-PROBADO 2026-09-03

WhatsApp y Telegram envían las notas de voz en **OGG/Opus**. Probado de punta a punta
(TTS → fichero `.ogg` de 5,9 s → `POST /v1/audio/transcriptions`, `language=es`):

| Modelo | Tiempo | Resultado |
|---|---|---|
| **gpt-4o-mini-transcribe** | **0,8 s** | correcta ("nombre propio", "empresa X") |
| gpt-transcribe | 0,8 s | correcta, la mejor de las rápidas ("nombre propio", "empresa", "empresa X") |
| gpt-4o-transcribe | 0,9 s | correcta ("empresa", "empresa X") |
| whisper-1 | 0,8 s | falló el nombre de marca → "WebCommunica" |
| gpt-4o-transcribe-diarize | 3,5 s | la peor: "frutas al zorro". 4× más lenta |

→ **Ganador para notas de voz: `gpt-4o-mini-transcribe`** (rápido y el más barato).
Pasar siempre `language=es`. Coste real: **1 minuto = 0,003 $**; mil notas al mes = 3 $.

⚠️ Ninguno acierta los nombres propios de marca al 100%. Si importa, se corrige en el
prompt del agente posterior, no cambiando de transcriptor.

### 2. Texto → voz (locutar)

| Modelo | Precio | Para qué |
|---|---|---|
| tts-1 | 15,00 $ / 1M caracteres | Locuciones normales (avisos, IVR, mensajes) |
| tts-1-hd | 30,00 $ / 1M caracteres | Más calidad, el doble de precio |
| gpt-4o-mini-tts | 12,00 $ / 1M tokens de audio | Permite dar instrucciones de tono |

Referencia: 1M de caracteres ≈ **un libro entero**. Para locuciones de centralita el
coste es despreciable.

### 3. Conversación en tiempo real (agente de voz que habla y escucha)

| Modelo | Audio ent. | Audio sal. | Texto ent. | Texto sal. |
|---|---|---|---|---|
| gpt-realtime-2.1 | 32,00 | 64,00 | 4,00 | 24,00 |
| **gpt-realtime-2.1-mini** | **10,00** | **20,00** | 0,60 | 2,40 |
| gpt-audio-1.5 | 32,00 | 64,00 | 2,50 | 10,00 |
| gpt-audio-mini | 10,00 | 20,00 | 0,60 | 2,40 |

⚠️ Esta familia es la **alternativa a ElevenLabs** para tu agente de voz telefónico. Antes de
plantear un cambio hay que comparar de verdad contra la factura real de ElevenLabs
(minutos/mes) — el precio por token de audio NO es comparable a ojo con el de
créditos de ElevenLabs.

## 🏆 Combinación recomendada (a 2026-09-03) — SIN CAMBIOS respecto a 2026-08-04

| Tarea | Modelo | Por qué |
|---|---|---|
| **Cerebro / chat / agente** | `gpt-5.6-luna` | 0,20/1,20 — sigue siendo el más barato con diferencia. Aun con la bajada de Gemini Flash a 0,75/3,75, Luna es **3,75× más barato en entrada y 3,1× en salida** |
| **Notas de voz** | `gpt-4o-mini-transcribe` | 0,003 $/min. Luna **NO admite audio de entrada** (re-verificado 03/09) |
| **Imágenes / OCR** | `gpt-5.6-luna` | admite imagen de entrada, sin coste extra de modelo (verificado 03/09) |
| Tareas duras puntuales | `gpt-5.6-terra` | 2,00/12,00, mejor relación que gpt-5.4 (2,50/15,00) |
| Si hace falta Google (barato) | `Gemini 3.5 Flash-Lite` | 0,30/2,50, el Gemini más barato y cobra el audio a tarifa de texto |
| Si hace falta Google (potente) | `Gemini 3.8 Flash` | 0,75/3,75 **mientras dure la promo**; ojo al 1/1/2027 |

**Regla práctica:** hoy todo lo de alto volumen sigue yendo a OpenAI; Gemini solo si se
necesita algo suyo en concreto (grounding con Search, audio nativo, o su ecosistema).

### 💡 Dato nuevo: el transcriptor más barato ya NO es de OpenAI

Medido en vivo el 03/09 con la misma nota de voz (≈25 tokens de audio por segundo,
≈1.500 tokens/minuto):

| Vía | $ / minuto | Comentario |
|---|---|---|
| **Gemini 3.5 Flash-Lite** (audio directo al modelo) | **≈0,0011** | El más barato: **2,7× más barato** que gpt-4o-mini-transcribe. Transcripción correcta |
| Gemini 3.6/3.7/3.8 Flash | ≈0,0021 | |
| **gpt-4o-mini-transcribe** | **0,003** | **El recomendado igualmente** |
| gpt-4o-transcribe *(el que usa producción)* | 0,006 | |
| Gemini 3.5 Transcribe | ≈0,0062 | El modelo "especialista" sale **el doble de caro** que usar Flash-Lite normal |

**Por qué NO cambio la recomendación pese a esto:** el ahorro real es de ~1,90 $/mes a
mil notas de voz. No compensa meter un **segundo proveedor en la ruta crítica** de las
notas de voz cuando el cerebro ya es OpenAI (otra clave, otro modo de fallo, otro sitio
donde mirar cuando se rompa). **Solo merece la pena si el audio pasa a ser el grueso del
gasto** (miles de minutos/mes): ahí sí, `Gemini 3.5 Flash-Lite` directo, sin transcriptor
delante.

## 📊 MATRIZ DE CAPACIDADES — probada en vivo (2026-09-03)

✅/❌ = **comprobado con llamada real** usando nuestras claves, no copiado de la documentación.

| Modelo | Texto | **Imagen** | **Audio** | Salida | Tools |
|---|---|---|---|---|---|
| **gpt-5.6-luna** | ✅ | ✅ | ❌ | texto | ✅ |
| gpt-5.6-terra | ✅ | ✅ | ❌ | texto | ✅ |
| gpt-5.6-sol | ✅ | ✅ | ❌ | texto | ✅ |
| gpt-5.4-mini / -nano | ✅ | ✅ | ❌ | texto | ✅ |
| gpt-5.5 / 5.2 / 5.1 / 5-mini / 5-nano | ✅ | ✅ | ❌ | texto | ✅ |
| gpt-realtime-2.1 / -mini | ✅ | ✅ | ✅ | **texto + audio** | ✅ |
| **gpt-audio-mini** | ✅ | ❌ | **✅** | texto | ✅ |
| gpt-4o-*-transcribe | ❌ | ❌ | ✅ | texto | ❌ |
| tts-1 / gpt-4o-mini-tts | ✅ | ❌ | ❌ | **audio** | ❌ |
| **Gemini 3.8 / 3.7 / 3.6 Flash** | ✅ | ✅ | **✅** | texto | ✅ |
| Gemini 3.5 Flash / Flash-Lite | ✅ | ✅ | **✅** | texto | ✅ |
| Gemini 3.1 Flash-Lite / Pro Preview | ✅ | ✅ | **✅** | texto | ✅ |
| Gemini 3.5 Transcribe | ✅ | — | ✅ | texto (campo raro) | — |

**La diferencia que decide:** toda la familia OpenAI de **texto** sigue sin tragar audio;
**todos los Gemini sí**. Con OpenAI hay que poner un transcriptor delante
(`gpt-4o-mini-transcribe`, 0,003 $/min) o usar la familia `gpt-audio-*`.

Aun así **compensa OpenAI**: transcribir un minuto cuesta 0,003 $, y la diferencia de
precio del modelo (Luna 0,20/1,20 frente a Gemini 3.8 Flash 0,75/3,75) se lo come de
sobra en cuanto hay volumen de texto.

*(Vídeo: Gemini lo admite según su documentación; **no verificado por nosotros**.)*

## Modalidades de `gpt-5.6-luna` — RE-COMPROBADO en vivo (2026-09-03)

| Entrada | ¿Acepta? | Prueba real |
|---|---|---|
| Texto | ✅ | `chat/completions` → 200, "OK" |
| **Imagen** | ✅ | PNG en base64 con `image_url` → identificó el color correctamente |
| **Audio** | ❌ | `input_audio` (mp3) → **400**: *"Content blocks are expected to be either text or image_url type"* |

→ Para OCR de facturas, tickets o fotos de clientes, **Luna vale y es baratísima**.
Solo hay que poner un transcriptor delante cuando entre una nota de voz.

## 🟢 Qué usa PRODUCCIÓN ahora mismo (verificado 2026-09-03)

Workflow **Segundo Cerebro v031** (`7qdwW11mss61CGHk`, activo):

| Nodo | Modelo | Estado |
|---|---|---|
| Gemini Orquestador *(el nombre engaña: es OpenAI)* | `gpt-5.6-luna` | ✅ vivo |
| OpenAI Chat Model (sub-agentes) | `gpt-5.6-luna` | ✅ vivo |
| Gemini Transcribir *(el nombre engaña: es OpenAI)* | `gpt-4o-transcribe` | ✅ vivo |

**Ningún modelo en producción ha sido retirado.** (Mejora opcional, no urgente: bajar el
transcriptor a `gpt-4o-mini-transcribe` ahorra la mitad, 0,006 → 0,003 $/min, a costa de
algo de precisión en nombres propios. Decisión del usuario.)

## Trampas conocidas (pisadas de verdad)

- **`gemini-3.5-transcribe` NO devuelve el texto donde lo esperas** (03/09/2026): lo mete
  en `candidates[0].content.parts[0].audioTranscription.text`, **no** en `parts[].text`.
  Un parser normal ve la respuesta **vacía** y parece que el modelo ha fallado, cuando ha
  devuelto 200 y la transcripción correcta. Además sale **el doble de caro** que pasarle el
  audio a `gemini-3.5-flash-lite` a secas: no compensa usarlo.

- **El error de audio de OpenAI ENGAÑA** (03/09/2026). Mandando un `.ogg` a Luna responde
  *"Invalid value: 'opus'. Supported values are: 'wav' and 'mp3'"* — parece que **sí** admite
  audio y que solo falla el formato. Al convertir a mp3 aparece el error de verdad:
  *"Content blocks are expected to be either text or image_url type"*. **La validación de
  formato se ejecuta ANTES que la de modalidad.** No concluir "acepta audio" por el primer error.

- **Los modelos con razonamiento se comen el `max_completion_tokens`** (03/09/2026): con
  `max_completion_tokens: 16`, luna/terra/sol/gpt-5.5/gpt-5-mini/gpt-5-nano devolvieron
  **200 con `content` vacío** (gastaron el presupuesto razonando). No es un fallo del modelo.
  Para probar disponibilidad, dar **≥300 tokens** o se marca ❌ un modelo que funciona.

- **Precio promocional de los Gemini Flash 3.6/3.7/3.8**: 0,75/3,75 solo **hasta el
  31/12/2026**; el 1/1/2027 **se dobla** a 1,50/7,50. Un presupuesto a cliente a 12 meses
  que use la tarifa de hoy se queda corto a la mitad del año.

- **El nodo OpenAI de n8n tiene `whisper-1` HARDCODEADO** en la operación transcribe
  (verificado en el código de v1 y v2, 04/08/2026): no hay selector de modelo. Para usar
  `gpt-4o-transcribe` o `gpt-4o-mini-transcribe` en n8n hay que montar un **HTTP Request**
  a `/v1/audio/transcriptions` (multipart: `file` binario + `model` (+ `language`)) con
  credencial predefinida `openAiApi`. Devuelve `{text}`, igual que el nodo nativo.

- **`gemini-2.5-*` está retirado para claves nuevas** (re-verificado 03/09/2026): **sigue
  apareciendo con precio en la página oficial de precios** y en `ListModels`, pero
  `generateContent` devuelve **404 "no longer available to new users"**. Una clave nueva NO
  revive un workflow que apunte a ese modelo: hay que cambiar el modelo.
  **Listado y con precio publicado ≠ utilizable.** (Caso real: Segundo Cerebro, 04/08/2026.)

- **Estar listado ≠ poder usarlo.** Verificar siempre con una llamada real.
- Las claves nuevas de Gemini empiezan por **`AQ.`**, ya no por `AIza`.
- Los agregadores de precios (OpenRouter, blogs) **mezclan la tarifa Batch con la
  estándar**: Gemini 3.5 Flash aparecía a 0,75/4,50 y la oficial es **1,50/9,00**.
  Ir siempre a la página oficial.
- **`jq` peta con audio en base64**: construir el JSON con `jq -n --arg` y un base64 de un
  audio de unos segundos da *"Argument list too long"*. Montar el cuerpo con Python
  (`json.dumps`) y mandarlo con `urllib` o `curl -d @fichero`.

## Cómo refrescar (procedimiento)

1. `WebFetch` a las dos páginas oficiales de precios (arriba) y volcar la tabla.
2. Probar en vivo cada modelo candidato con las claves del vault: una llamada
   mínima a `generateContent` / `chat/completions` (**con ≥300 tokens de salida**,
   ver trampas), y marcar ✅/❌.
3. Comprobar qué modelos usa **producción** (workflow Segundo Cerebro) y que sigan vivos.
4. Actualizar tablas + fecha, recalcular la combinación recomendada y anotar en
   "Trampas" cualquier modelo retirado o límite de modalidad nuevo.
5. **Si la combinación recomendada CAMBIA, o si un modelo de producción ha sido retirado,
   avisar al usuario** (skill `notify`). Si no cambia nada relevante, actualizar el fichero
   en silencio: un aviso de "todo sigue igual" cada mes se acaba ignorando.

Refresco automático: ver `REFRESCO.md` en esta misma carpeta.

## Auto-mejora

Al cerrar cada uso de esta skill:
1. Actualizar la tabla con lo verificado y su fecha.
2. Añadir a "Trampas conocidas" cualquier sorpresa nueva.
3. Si cambia la combinación recomendada, dejar escrito **por qué** cambió.

## 🖼️ Generación de IMAGEN — Gemini (probado 2026-08-12, precios parcialmente pendientes)

Probado con llamada real usando una clave de pago propia (vault `<proyecto>.json → apis.<servicio>`).
`POST {base_url}/models/<modelo>:generateContent` con
`generationConfig.imageConfig = {aspectRatio, imageSize}`.

| Modelo | Salida real | Notas |
|---|---|---|
| **nano-banana-pro-preview** | **2752 × 1536** | con `imageSize:"2K"`. Calidad de foto de producto |
| gemini-3.1-flash-image | 1376 × 768 | tamaño nativo: **ignora la resolución pedida en el prompt** |
| gemini-3-pro-image, gemini-2.5-flash-image | listados | sin probar |
| imagen-4.0-generate/ultra/fast-001 | listados | usan `:predict`, no `:generateContent` |

**Precio (03/09/2026):** la web oficial solo publica **`Gemini 3.1 Flash-Lite Image`:
0,25 $/1M entrada, 1,50 $/1M tokens de imagen de salida**. Los modelos de arriba
(`nano-banana-pro-preview`, `gemini-3.1-flash-image`) **NO aparecen con precio en la
página oficial → coste por imagen SIGUE SIN VERIFICAR.** No citarlo de memoria ni
presupuestarlos a un cliente sin medir el gasto real en la consola de facturación.

⚠️ Gotcha: el `base_url` del vault **ya incluye `/v1beta`**. Concatenar otro `/v1beta` → **404**
(pisado el 2026-08-12; casi se diagnostica como "modelo no disponible").
