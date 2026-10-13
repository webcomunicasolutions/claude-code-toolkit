# Iconos de marca (PWA, APK, favicon)

Regla comun a todo lo que genere el icono de una app o de una web para un cliente (PWA, APK, favicon).

**Leer esta regla ANTES de generar cualquier icono.** Las skills `pwa-desde-web` y `apk-webview-android` la citan en vez de repetirla.

## Regla 1 — El icono es el LOGOTIPO DEL CLIENTE, sobre su color de marca

Nunca un icono generico, ni una letra, ni el logo de quien hace el trabajo. Ese icono se va a quedar en la
pantalla de inicio del movil del cliente, al lado del WhatsApp, y es lo primero que ve de nuestro
trabajo cada mañana.

**Y se REGENERA cuando cambia la marca.** Si se repinta la web y los iconos se quedan con el
color viejo, la app desentona con su propia web. Caso real: se cambio la paleta entera de un panel y los iconos siguieron con el verde anterior hasta que se reviso.

## Regla 2 — El sistema SIEMPRE recorta: deja margen y compruebalo recortando

Cada plataforma se come los bordes a su manera:

| Donde | Que hace | Margen |
|---|---|---|
| PWA, icono `maskable` | Android lo recorta hasta un CIRCULO | logo al ~60% del lienzo |
| PWA, icono normal (`any`) | se ve entero | logo al ~82% |
| APK, `adaptive-icon` | zoom 72/108dp: recorta los bordes | nunca logos apilados (los parte) |
| Barra de instalar / listas | se ve a ~46px | ver regla 4 |

**No basta con dejar el margen: hay que recortar de verdad y mirarlo.** El recorte circular, en
DOS ordenes — encadenarlo en una sola devuelve la imagen vacia y parece que el icono esta roto:

```bash
convert -size 512x512 xc:black -fill white -draw "circle 256,256 256,20" circulo.png
convert icono-512-recortable.png circulo.png -alpha off -compose CopyOpacity -composite prueba.png
```

## Regla 3 — Generacion: recortar el logo a su contenido ANTES de encajarlo

Un logo con transparencia alrededor queda descentrado dentro del cuadrado si no se recorta antes.

```bash
convert logo.png -trim +repage logo_recortado.png          # imprescindible
convert -size 512x512 xc:"#COLORMARCA" \
  \( logo_recortado.png -resize 420x420 \) -gravity center -composite icono-512.png
```

### Dos trampas que cuestan intentos

**a) `-crop`: los DESPLAZAMIENTOS van en pixeles aunque el tamaño lo escribas en %.**
`-crop 62%x68%+20%+0` **no** empieza en el 20% del ancho: empieza en el pixel 20. En un caso real
eso hizo que el recorte cogiera la cola de la mascota del logo y le cortara la cabeza, tres veces seguidas.
Calcular los cuatro numeros en pixeles: `-crop 247x176+78+0`.

**b) Para recortar un elemento del logo, MIDE con una cuadricula. No calcules a ojo.**

```bash
convert logo.png -background '#COLORMARCA' -flatten -resize 600x \
  \( -size 600x400 xc:none -stroke yellow -strokewidth 1 \
     -draw "line 120,0 120,400  line 240,0 240,400  line 360,0 360,400  line 480,0 480,400" \) \
  -composite rejilla.png
```

Se mira, se anota donde empieza y acaba el elemento en %, y se pasa a pixeles.

## Regla 4 — El icono grande y el pequeño NO son el mismo

A ~46px (barra de instalar, listas, notificaciones) un logo con varios elementos es una mancha de
color. Ahi va una version simplificada: **solo el simbolo principal**, recortado en **cuadrado**
alrededor de el.

Cuidado al recortarlo: si se coge una **franja apaisada**, al encajarla en un cuadrado se reduce
por el ancho y el simbolo acaba **mas pequeño que antes** — el remedio, peor que la enfermedad.

**Comprobacion obligatoria**, porque a tamaño real no se juzga:

```bash
convert icono-instalar.png -resize 46x46 -scale 400% vista.png   # -scale, sin suavizar
```

## Regla 5 — Nada de esto se valida leyendo el comando

Los cinco fallos de esta regla (color viejo, logo descentrado, cabeza cortada, simbolo mas
pequeño, imagen vacia en la comprobacion) **pasaron todos los filtros de "el comando parece
correcto"** y solo se vieron al abrir la imagen. Generar, mirar, y solo entonces darlo por bueno.

## Donde se usa

- `pwa-desde-web` — iconos 192/512, maskable y el de la barra de instalar.
- `apk-webview-android` — icono y banner de la APK (ademas, su propio aprendizaje: el launcher de
  Google TV cachea los iconos y reinstalar no los refresca).
