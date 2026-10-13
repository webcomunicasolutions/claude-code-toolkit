---
name: pwa-desde-web
description: Convertir una web clasica EXISTENTE (PHP/HTML con login y sesion, sin frameworks) en PWA instalable en movil/escritorio, cacheando SOLO el cascaron estatico (los datos siempre van a la red), CON aviso propio de instalacion ("instalar como app") con la marca del cliente. Usar cuando se pida "hacer la web instalable", "que funcione como app en el movil", "que al entrar ofrezca instalarla", "añadir a pantalla de inicio", PWA, manifest o service worker sobre una web ya construida. NOT para construir una PWA desde cero con framework (para eso existe el skill generico progressive-web-app de davila7/claude-code-templates) ni para apps con datos offline.
---

# PWA desde una web existente

Retrofit de PWA sobre una web clasica en produccion (estilo mongolrulez: PHP + HTML/JS sin
frameworks, con login por sesion). Objetivo: instalable y de apertura rapida, SIN romper la
sesion ni servir datos viejos. Los ficheros de `assets/` son la implementacion de referencia (`manifest.webmanifest`, `sw.js`, `instalar_app.js/css`).

## Reglas de oro

1. **Cachear SOLO el cascaron** (CSS/JS/imagenes/fuentes). Los endpoints de datos
   (`/api/`, `/interno/`, o los que tenga el proyecto) NUNCA pasan por la cache: si no,
   la app enseña lecturas/registros viejos y el cliente pierde la confianza.
2. **Navegacion network-first**: las paginas (login/dashboard) van primero a la red para no
   romper la sesion PHP; la cache es solo red de seguridad sin conexion.
3. **POST jamas se intercepta** (guardados, formularios de login).
4. **CDNs no se tocan** (origen distinto → return sin respondWith).
5. **Nombre de cache versionado** (`<proyecto>-pwa-v1`): subir version = invalidar todo lo viejo
   (el `activate` borra caches con otro nombre).
6. **El aviso de instalacion se pone SIEMPRE** (paso 5 del procedimiento). Sin el, la PWA existe
   pero nadie la instala: el navegador lo ofrece en un aviso diminuto o escondido en el menu de
   tres puntos. El cliente pide "que al entrar te ofrezca instalarla" — eso es codigo nuestro,
   no del navegador.
7. **Guardas antes de enseñar el aviso**: nunca en modos de pantalla fija (mural/kiosco/TV),
   nunca dentro de un WebView de una APK propia, nunca si ya esta instalada, y no repetir si el
   usuario dijo "ahora no" (recordarlo ~30 dias). Una barra de "instalar" clavada en la tele de
   un hotel o un local es un incidente, no un detalle.
8. **El icono es SIEMPRE el logotipo del cliente, sobre su color de marca**, y se regenera cuando
   cambia la marca. Detalle y comandos en `references/iconos-de-marca.md`.

## Procedimiento

1. **Manifest**: copiar `assets/manifest-template.webmanifest` a la raiz web como
   `manifest.webmanifest`. Rellenar nombre, `start_url` (la pagina principal REAL, ej.
   `/paginas/index.php`), `scope: "/"` y color de marca en `background_color`/`theme_color`
   (si hay login, el server redirigira solo — no apuntar start_url al login). Añadir tambien
   `id` (fija la identidad de la app aunque cambie start_url), `categories` y **`shortcuts`**
   con las 2-3 pantallas que mas usa el cliente: aparecen al mantener pulsado el icono y es de
   lo que mas se nota. Si el manifest necesita datos del proyecto, puede ser `manifest.php`
   (dinamico) en vez de estatico — es una opcion habitual.
2. **Iconos**: **leer antes `references/iconos-de-marca.md`** — ahi estan la regla
   (siempre el logotipo del cliente sobre su color de marca), los comandos de ImageMagick y las
   trampas que cuestan intentos (`-crop` cuenta los desplazamientos en pixeles aunque escribas
   porcentajes; medir con cuadricula en vez de a ojo; el icono pequeño no es el grande reducido).

   Lo especifico de PWA, que no esta en esa regla:
   - Hacen falta **`icono-192.png` e `icono-512.png`** (Chrome no considera instalable el sitio
     sin los dos) y un **`icono-512-recortable.png`** con `purpose: "maskable"`.
   - Y un **`icono-instalar.png`** aparte para la barra del aviso, donde se ve a ~46px.
3. **Service worker**: copiar `assets/sw-template.js` a la raiz como `sw.js` y ajustar los
   prefijos de endpoints de datos del proyecto. DEBE servirse desde la raiz (el scope del SW
   no puede subir por encima de donde vive el fichero).
4. **Enlazar** en TODAS las paginas de entrada (index Y login):
   ```html
   <link rel="manifest" href="/manifest.webmanifest">
   <meta name="theme-color" content="#RRGGBB">
   <script>if('serviceWorker' in navigator)navigator.serviceWorker.register('/sw.js');</script>
   ```
5. **Aviso de instalacion** (lo que el cliente realmente ve): copiar
   `assets/instalar-app-template.js` y `assets/instalar-app-template.css` a la raiz web como
   `instalar_app.js` / `instalar_app.css`, sustituir los marcadores `{{NOMBRE_APP}}`, `{{ICONO}}`
   y `{{GUARDA_EXTRA}}`, y enlazarlos en las MISMAS paginas de entrada del paso 4 (login e index).
   El HTML del aviso es literal: no meter ahi datos de usuario ni de BD (va por `innerHTML`).
   **Icono del aviso ≠ icono de la app**: en la barra se ve a ~46px y los logotipos con lineas de
   texto pequeño (taglines, subtitulos, "GRUPO", "HOTELS · RESORTS") se convierten en manchas. Usar
   ahi una version simplificada (`icon-banner.png`, solo los simbolos y el logotipo principal) y
   dejar el icono completo para el manifest. Comprobarlo SIEMPRE reduciendo a 46px y mirandolo.
   Como funciona: se captura `beforeinstallprompt` con `preventDefault()`, se guarda el evento y
   se llama a `prompt()` en el click del boton (exige gesto del usuario). En iOS no existe ese
   evento: se enseñan las instrucciones "Compartir → Añadir a pantalla de inicio".

   **En MOVIL no esperar al evento: pintar la barra SIEMPRE.** Chrome dispara
   `beforeinstallprompt` cuando le parece (guarda el evento hasta que considera que el usuario
   ha usado bastante la web), asi que esperarlo significa que el aviso **casi nunca sale** y el
   cliente cree que no se hizo. Se ofrece a los ~2-3 s de cargar y, si al pulsar el evento
   todavia no ha llegado, se enseñan los pasos a mano — que funcionan igual. En ESCRITORIO si se
   espera al evento: alli no hay pantalla de inicio y la barra seria ruido.

   **Tres guiones distintos, porque dos navegadores NO PUEDEN instalar** y hay que decirlo en vez
   de dejar al usuario pulsando un boton que no hace nada:
   - **iPhone con Safari** → pasos "Compartir → Añadir a pantalla de inicio → Añadir".
   - **iPhone con otro navegador** (Chrome/Firefox/Edge de iOS) → **no pueden**: pedir que lo
     abran en Safari y ofrecer copiar la direccion.
   - **Firefox de Android** → **tampoco**: su "Añadir a la pantalla de inicio" crea un acceso
     directo que vuelve a abrirse DENTRO de Firefox, no es una app instalada. Pedir Chrome.
6. **Verificar** (dev-browser o navegador): en DevTools → Application: el manifest carga sin
   errores, el SW queda "activated and is running" y CONTROLANDO la pagina (recargar una vez:
   el primer load no esta controlado), y una peticion a un endpoint de datos sale SIEMPRE por
   red (columna Size ≠ "ServiceWorker"). Probar la instalacion real en un movil.
7. **Desplegar**: el SW requiere HTTPS en produccion (localhost exento).

## Errores conocidos

- **Datos sensibles: nada de network-first con copia.** La plantilla guarda las paginas como red de seguridad sin conexion; en paneles con datos de clientes/facturas eso deja copias en el movil. Navegacion solo red + pagina estatica de sin conexion.
- **Una prueba de Playwright que se cuelga en `goto` no es siempre el SW**: repetir con `service_workers='block'` antes de culparlo. En un caso real era una pagina de 27 s (vista MySQL que no filtraba), no la PWA.

- **SW cacheando `/api/`**: sintoma = datos congelados tras la primera visita. Revisar los
  prefijos excluidos en el fetch handler ANTES de desplegar.
- **Cambios en CSS/JS que no llegan**: stale-while-revalidate tarda 1 recarga en refrescar.
  Para forzar en un despliegue importante: subir la version del nombre de cache.
- **start_url fuera del scope** → la instalacion falla en silencio (Chrome lo avisa solo en
  DevTools → Application → Manifest).
- **El aviso de instalar no aparece nunca**: no es el codigo, casi siempre es que el navegador
  no considera instalable el sitio. Comprobar por orden: HTTPS · manifest con iconos 192 Y 512 ·
  service worker con manejador de `fetch` (sin `fetch`, Chrome no dispara el evento) · y que NO
  este ya instalada (una vez instalada, `beforeinstallprompt` deja de dispararse). Firefox de
  escritorio no instala PWAs; en iOS solo Safari, y a mano.
- **`prompt()` fuera de un gesto del usuario** → el navegador lo ignora. Hay que guardar el
  evento y llamarlo dentro del `click`. Ademas el evento se CONSUME: solo sirve una vez.
- **Probar el aviso en dev-browser**: no se puede falsear el user agent (`setUserAgent` no existe
  en la sandbox) y, si la pagina ya cargo el script, una segunda instancia evaluada a mano NO
  sustituye a la primera — el banner lo pinta la original y el test miente. Solucion: una pagina
  de prueba SIN el `<script>`, y ahi evaluar el fichero tras redefinir `navigator.userAgent`.
  El evento se simula con `new Event('beforeinstallprompt')` + `prompt`/`userChoice` de mentira.
- **Mejor con Playwright que con dev-browser** : `new_context()` SI
  admite `user_agent`, asi que se prueban los cuatro casos de verdad, cada uno en su contexto
  limpio (localStorage aparte, que es lo que recuerda el "ahora no"):
  ```python
  ctx = navegador.new_context(viewport={"width":390,"height":844}, user_agent=UA_ANDROID)
  ```
  Con eso se comprueban: barra en Android · pasos de iPhone · aviso de Firefox · que en
  escritorio NO salga · que "ahora no" se recuerde · que no aparezca si ya esta instalada
  (se simula redefiniendo `window.matchMedia` con un `add_init_script`). 14 comprobaciones en
  un solo guion.
- **Al desplegar cambios de CSS/JS, subir la version del SW en el MISMO despliegue.** Es el fallo
  facil: se sube el codigo nuevo y el movil sigue enseñando el diseño viejo, porque el cascaron
  esta cacheado. Meterlo en el guion de despliegue o en su checklist, no en la memoria de nadie.
- **`theme-color` por pantalla**: si una pagina tiene un fondo distinto (p. ej. el login claro y
  el panel con cabecera de color), cada una necesita el suyo. Con uno solo, en el movil la barra
  del sistema sale de un color que no pega con la pagina que hay debajo.

## Variantes ya probadas

- **Web con TODO el JS y CSS en dos ficheros master**: no se copian `instalar_app.js/css` sueltos, se integra el aviso
  en el JS master (funcion `prepararInstalacion`) y los estilos en el CSS master.
- **Panel con datos sensibles (facturas)**: el SW NO guarda ninguna navegacion, ni como red de seguridad; sin red
  enseña una `sin_conexion.html` estatica. El aviso solo sale con `window.isSecureContext` (si el panel tambien se usa
  por `http://IP-LAN`, ahi no se puede instalar). Prueba automatizada de 22 comprobaciones, incluida "no hay .php en la
  cache", que cazo un mutante.
- **Web que tambien se muestra en un mural/TV**: guarda para no ofrecer nunca la instalacion en ese modo (ver `{{GUARDA_EXTRA}}`).

## Auto-mejora

Al cerrar cada aplicacion practica de esta skill:
1. Registrar aprendizajes en `aprendizajes/<caso>.md` (o en esta seccion si es breve)
2. Si el patron es generalizable, actualizar el cuerpo de este SKILL.md
3. Si se descubre un error recurrente, añadirlo a "Errores conocidos"

Sin esta fase, la skill se fosiliza y pierde valor con el tiempo.
