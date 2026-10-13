---
name: manual-app-movil
description: Fabricar el manual de usuario de una web o app para los trabajadores del cliente, con CAPTURAS REALES de la web en tamaño móvil, PDF con la marca DEL CLIENTE (no la de quien hace el manual) y una ficha de acceso personal por trabajador con QR y sus credenciales leídas de tu gestor de credenciales. Usar cuando se pida "un manual para los trabajadores", "manual de uso de la app/web", "explicarles cómo se instala en el móvil", "fichas de acceso para el personal", o haya que documentar una plataforma de cliente para gente no técnica. NOT para documentación técnica ni para el QA de la web (para eso, qa-web-roles).
---

# Manual de app/web para trabajadores

Método probado con una web de gestión de una empresa de instalaciones: 11 páginas con capturas reales + 6 fichas
personales, hecho y enviado al cliente en una sesión. Dependencias: Python 3, `playwright` (con Chromium),
`reportlab`, `pypdf`, `qrcode`, `Pillow`, `opencv-python-headless` (solo para verificar el QR), Google Chrome y `poppler-utils`.
Ante la duda, copiar los scripts de `scripts/` y adaptar, no reescribir de memoria.

**Si la fuente es una GRABACIÓN** (formación, Teams con pantalla compartida) y no una web que se pueda navegar → skill
`manual-desde-video`, que reutiliza el `montar_pdf.py` y la marca de esta.

## Qué produce

| Entregable | Contenido | ¿git? |
|---|---|---|
| `Manual-<app>.pdf` | Instalación + uso diario, capturas reales, igual para todos, SIN credenciales | Sí |
| `fichas_acceso/Ficha-<usuario>.pdf` | Una hoja por persona: usuario, contraseña, QR a la web | **NO** |
| `generar_*.sh/py` + `manual.html` | Para rehacerlo cuando cambie algo | Sí |

## Las 6 fases

### 1. Coordenadas y permiso
- URL real (la definitiva, no la provisional), usuarios y la ruta de sus credenciales en tu gestor (un JSON fuera del repo; ver `plantillas/config.ejemplo.json`).
  Selectores del login por defecto: `input[name=usuario]`, `input[name=contrasena]` y `button[type=submit]`; si la web usa otros,
  añadir al config un objeto `login` con las claves `campo_usuario`, `campo_password` y `boton`. En `vault`, `ruta_usuarios` es la ruta
  (separada por puntos) hasta el objeto de usuarios y `campo_password` (por defecto `password`) el campo de cada uno.
- **Tocar producción de cliente exige confirmación explícita.** Entrar a MIRAR es aceptable;
  pulsar cualquier botón que guarde, NO (un fichaje no se borra desde la web).

### 2. Capturas como si fuera un móvil — `scripts/capturar.py`
El navegador se hace pasar por un teléfono con cuatro datos: `viewport` 390×844,
`device_scale_factor` 3, `is_mobile`/`has_touch` y el `user_agent` del móvil. Así la web sirve
su versión móvil (menú plegado, barra de instalar). Es lo que hace el modo dispositivo de Chrome,
pero por programa: se le dice a qué páginas ir y dónde guardar cada imagen.
- Capturar **con el usuario del rol al que va dirigido el manual**, no con admin: el manual
  debe enseñar lo que esa persona ve.
- Volcar también el TEXTO de cada pantalla: de ahí salen los nombres exactos de los botones.
- **Límite:** solo se captura lo que dibuja la web. El menú de Chrome y la hoja Compartir de
  Safari son del sistema: o se piden capturas reales al usuario, o se ilustran, o se aprovecha
  lo que la propia web explique.

### 3. Recortes y datos personales
Recortar cada captura a lo que se explica. **Quitar datos personales** (teléfonos, direcciones
de terceros) antes de que entren en un PDF que se reparte.

### 4. El manual es una página web — `plantillas/manual.ejemplo.html`
HTML+CSS con `@page` A4 y medidas en mm. Ventaja: cambiar una frase es una línea.
- Texto a la izquierda, móvil a la derecha (`.fila` + `.tel`), tablas para "qué significa" y
  "si algo no va", avisos para lo que bloquea.
- `break-inside: avoid` en filas, tablas y avisos, o se parten entre páginas.

### 5. PDF en dos capas — `scripts/montar_pdf.py` + `scripts/marca.py`
Chrome imprime el HTML a PDF (el contenido) y encima se estampa la capa de marca
(cabecera con el logo, pie con la dirección y el número de página).
- **Por qué dos capas:** una cabecera `position:fixed` NO se repite bien al imprimir.
- Los márgenes de `@page` tienen que dejar hueco a la banda (arriba 36 mm, abajo 24 mm).

### 6. Fichas personales — `scripts/generar_fichas.py`
Una hoja por trabajador leyendo usuario y contraseña **del gestor de credenciales**, con QR a la URL.
- **Nunca** meter credenciales en el manual general ni en git: `fichas_acceso/` al `.gitignore`.
- Entregar en mano; el propio texto recuerda que lo que se ficha queda a nombre de esa persona.

## Verificación obligatoria (sin esto no está hecho)
1. **Entrar con cada usuario** de las fichas: N de N (declarar cuántos de cuántos).
2. **Cruzar** la contraseña impresa en el PDF con la del gestor, por script (`scripts/verificar.py` hace los pasos 1-4).
3. **Leer el QR** del PDF ya generado (`cv2.QRCodeDetector`) y comprobar que abre la URL buena.
4. **Buscar restos** de la marca anterior en el PDF: `pdftotext ... | grep -i <marca vieja>`.
5. Renderizar todas las páginas a imagen y **mirarlas**: huecos, cortes, textos en inglés del
   navegador de pruebas ("Choose Files").
6. Escribir en el README lo **NO verificado** (p. ej. que nadie lo ha probado en un móvil real).

## Escribir para el trabajador
- **Copiar las palabras de la pantalla.** Si el botón pone "Iniciar Jornada", eso se escribe.
- Una frase, una acción. Lo que tiene orden va numerado.
- **No escribir lo que no se ha visto.** Si no se pudo probar un botón, se describe sin nombrarlo.
- La tabla de problemas sale de los bloqueos REALES encontrados al probar, no de suposiciones.

## Marca del cliente, no la nuestra
🔴 **REGLA: cabecera y pie de cada página SIEMPRE con el logo y los colores del cliente.**
El manual lo lee su plantilla: va con SU logo, SUS colores y SUS datos (`marca.json`).
Sacar logo, colores y tipografías de su web y de la propia plataforma. Si hay varias ideas,
enseñar **2-4 propuestas en una página HTML** y que el cliente elija (funcionó: eligió en minutos).
Dejar las no elegidas guardadas.

## Auto-mejora
Al cerrar cada manual: registrar en `aprendizajes/<cliente>-<fecha>.md` qué se atascó, qué
gotcha nuevo apareció y qué habría que parametrizar. Si el patrón se repite, subirlo a este SKILL.md.
