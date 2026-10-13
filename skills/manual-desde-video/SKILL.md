---
name: manual-desde-video
description: Convertir una GRABACIÓN (sesión de formación, reunión de Teams/Zoom con pantalla compartida, vídeo de un proveedor) en un manual paso a paso para el cliente - transcripción con hablantes, fotogramas con recuadros rojos numerados, texto para usuario no técnico y PDF con la marca DEL CLIENTE. Usar cuando se diga "hazme un manual de este vídeo", "saca un manual de la grabación", "transcribe la formación y hazle un manual a <cliente>", "manual con capturas del vídeo", o llegue un .mp4 de una formación. NOT para manuales de una web que se puede navegar (eso es manual-app-movil, capturas en vivo) ni para solo transcribir (whisper-transcribe).
---

# Manual desde un vídeo

Método probado con una grabación de 24 min de una formación de un proveedor de software (generación del fichero de corte
de una tronzadora), convertida en un PDF de 7 págs con 12 capturas anotadas, con la marca del cliente, en una tarde.
Conviene mantener en el proyecto del cliente una implementación de referencia (carpetas `docs/manuales/<tema>/`,
`conocimiento/procedimientos/`, `conocimiento/videos/<fecha-tema>/`) y copiar de ella antes de reescribir.

## Qué produce
| Entregable | Dónde (en el proyecto del cliente) | ¿git? |
|---|---|---|
| Transcripción por hablantes + `scribe.json` | `conocimiento/videos/<fecha-tema>/` o `docs/` | Sí |
| Procedimiento en Markdown (la fuente del texto) | `conocimiento/procedimientos/<tema>.md` | Sí |
| Capturas anotadas | `.../img/<tema>/` | Sí (jpg ~60 KB c/u) |
| `manual.html` + script de generación + **PDF** | `docs/manuales/<tema>/` | Sí |
| El vídeo original | carpeta de recibidos | **NO** (`*.mp4` al `.gitignore` ANTES del primer commit) |

## Fases

### 1. Transcribir — `scripts/transcribir.sh <video> <carpeta>`
- Requiere `ffmpeg`, `curl`, `python3` y la variable de entorno `ELEVENLABS_API_KEY` (sácala de tu gestor de credenciales).
- **ElevenLabs Scribe primero** (24 min → 21 s, con hablantes). Whisper local en CPU tarda ~20 min y con un driver CUDA
  viejo la GPU no sirve. Avisar de que el audio sale a un servicio externo si el contenido es delicado.
- Poner nombre a `speaker_N` por el contexto (quién explica, quién pregunta). Los errores del reconocimiento se
  **anotan en la cabecera** (p. ej. un nombre de programa mal oído), el texto no se toca.

### 2. Ver el recorrido — `scripts/fotogramas.sh hojas <video> <carpeta> 15`
Hojas 3x3 con la marca de tiempo (requiere ImageMagick). Con eso + la transcripción se escribe el guion de pasos.

### 3. Leer las pantallas de verdad — `scripts/fotogramas.sh uno <video> <seg> f_<seg>.png`
- Para CADA paso, el fotograma a tamaño completo donde se ve el menú/diálogo abierto. De ahí salen los **nombres
  exactos** de menús, botones, casillas y atajos: lo que se oye en el audio no basta («la tuerca amarilla» resultó
  ser Aplicaciones → Planificador → Producción).
- ⚠️ El tiempo del vídeo **no coincide al segundo** con el de la transcripción: sacar 3-4 candidatos alrededor
  (±10 s) en una hoja de contactos y elegir.

### 4. Escribir el procedimiento (Markdown) — es la fuente
- Pasos numerados, una acción por frase, palabras de la pantalla tal cual. Avisos rojos para lo que bloquea
  («si no marcas X, no aparece»). Tabla de lo pendiente/no resuelto en la sesión.
- Sección **«De dónde sale cada cosa»**: qué está comprobado en fotograma y qué es «deducido». Nada sin ver.

### 5. Anotar capturas — `scripts/anotar.py plan.json <salida>` (plantilla `plantillas/plan.ejemplo.json`)
- Requiere Pillow y la fuente DejaVu Sans Bold.
- Recuadro rojo + número en el orden de los pasos; **recortar** a la zona que se explica (si no, en A4 no se lee).
- Revisar en hoja de contactos: el número puede tapar texto; los fotogramas de pantalla completa traen bandas negras.
- **Quitar datos personales** de terceros antes de que entren en un PDF que se reparte.

### 6. PDF con la marca del cliente
- 🔴 **REGLA: cabecera y pie de CADA página con el logo y los colores DEL CLIENTE, siempre.** La plantilla corporativa
  de quien hace el manual NO se usa para manuales de cliente. Si el cliente no tiene `marca.json`: sacar logo, colores
  y tipografías de su web/plataforma, hacer el `marca.json` y, si hay dudas, enseñar 2-4 propuestas para que elija
  (fase de marca de la skill `manual-app-movil`).
- `manual.html` (copiar `plantillas/manual.ejemplo.html`).
- Montaje: `python3 <ruta>/manual-app-movil/scripts/montar_pdf.py manual.html marca.json salida.pdf "Línea 1" "Línea 2"`
  (Chrome imprime + capa de marca). Si el cliente ya tiene marca hecha en otro manual, **reutilizarla**, no rehacerla.
- **Sin saltos de página forzados**: envolver captura + pie en `<div class="bloque">` (break-inside: avoid) y dejar
  fluir. Los `break-before:page` dejaron una captura sola en una página y otra medio vacía.
- Renderizar todas las páginas (`pdftoppm -r 45` + montage) y **mirarlas**; una a 90 dpi para comprobar que se lee.

### 7. Entregar
- Enviar el PDF por el canal que use el usuario (correo, mensajería) para que lo reenvíe; enseñarlo solo en la sesión
  no es entregarlo. Decir siempre el canal.
- README del manual: fuente, cómo regenerar, **qué NO está verificado** (p. ej. «nadie lo ha probado con un caso real»)
  y si consta enviado.

## Qué decir para lanzarlo desde cualquier cliente
> «Hazme un manual en PDF para <persona> de este vídeo: <ruta del .mp4>, con capturas y la marca de <cliente>.»

## Auto-mejora
Al cerrar cada manual: `aprendizajes/<cliente>-<fecha>.md` con lo que se atascó y lo que habría que parametrizar.
Si un patrón se repite, subirlo a este SKILL.md. Ver `aprendizajes/ejemplo-formacion-erp.md`.
