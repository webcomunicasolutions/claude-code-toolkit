# Caso 2 · manual de un panel (móvil + ordenador) y de un bot de Telegram

16 páginas, hecho y enviado en ~1 h.

## Lo nuevo que funcionó
- **Capturas contra una COPIA LOCAL de la BD de producción** (volcado de solo lectura): datos reales y se puede enseñar
  crear/editar/subir foto sin escribir en producción. El script de capturas se niega a correr si la URL no es local.
- **Bot de chat sin sesión**: recrear el chat en HTML/CSS (burbujas, teclado inline) con los textos LITERALES sacados de
  las ejecuciones del flujo de automatización (nodo de envío → `result.text` y `reply_markup`).
- **Recortes por selector** (`locator.screenshot()`) en vez de por píxeles: resuelve el recorte manual por coordenadas.
- Contrastar cada afirmación del manual con el código ANTES de imprimir: cambió 3 frases (umbral de sugerencias, mayúsculas
  del usuario, qué hace realmente la papelera) y destapó un fallo (un botón sin aviso).

## Gotchas
- Volcado de producción con vistas: `DEFINER` de otro usuario → error 1356 en local. Quitarlo con `sed` al cargar.
- Una captura justo tras elegir una foto salió con el aviso «Preparando la foto…» (dura 4 s): esperar a que desaparezca.
- PDF de 10 MB: PNG a 3x. Pasar a JPG 700 px (móvil) / 1600 px (ordenador) → 4 MB. El **logo de la capa de marca se incrusta
  en CADA página**: a 500 px eran 15 copias; usar uno de ~180 px para la cabecera.
- Demasiados `.rompe` + móviles de 52 mm → 22 páginas medio vacías. Móvil 45 mm / pequeño 40 mm y saltos solo entre partes → 15-16.

## Para parametrizar
- Mockup de chat de Telegram como plantilla reutilizable (`plantillas/`), con un CSS `.tg`.
