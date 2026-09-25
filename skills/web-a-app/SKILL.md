---
name: web-a-app
description: Orquestador para convertir una web EXISTENTE en "app". Decide entre las tres
  salidas posibles (PWA instalable / APK WebView de movil / APK WebView Android TV-mural) con
  un arbol de decision breve y DERIVA a la skill concreta (pwa-desde-web o apk-webview-android),
  o encadena varias si hace falta. Usar cuando se pida "convierte esta web en app", "hazme una
  app del proyecto", "quiero una app de movil/tablet de esta web", "que esto salga como app en
  la tele/movil", "empaquetar la web como app", "web to app", o cuando haya duda de que formato
  elegir. NOT para apps NATIVAS con logica propia (Compose, Flutter, React Native desde cero),
  NOT para iOS nativo, NOT para construir la web en si (esto parte de una web YA hecha).
---

# web-a-app — de una web existente a "app"

Esta skill NO empaqueta nada por si misma: **decide el formato adecuado y deriva** a la skill
que hace el trabajo. Evita el error tipico de saltar directo a "hago una APK" cuando muchas
veces una PWA resuelve el caso con una fraccion del esfuerzo.

Punto de partida obligatorio: **ya existe una web servida** (con su URL, su login/sesion si lo
tiene). Si no hay web todavia, esto no aplica — primero se construye la web.

## Paso 1 — Cuatro preguntas de decision

Pregunta solo lo que no esté claro por el contexto. Con estas cuatro respuestas basta:

1. **¿Donde se va a ver?** Movil/tablet del personal · Televisor a modo mural · Ambos.
2. **¿Tiene que estar en una tienda** (Play Store / App Store)? Casi siempre NO en proyectos
   internos de cliente.
3. **¿Necesita funcionar SIN conexion** (datos offline)? Un dashboard en vivo normalmente NO
   (los datos siempre van a la red; solo interesa que "abra como app").
4. **¿La "app" tiene que hacer algo que el navegador no puede** (auto-arrancar al encender,
   modo kiosco a pantalla completa, auto-actualizarse, leer hardware, D-pad del mando)?

## Paso 2 — Tabla de decision

| Situacion | Salida | Skill a la que se deriva |
|-----------|--------|--------------------------|
| Solo quieren "abrirla como app" en el movil/escritorio, sin tienda, sin nada especial | **PWA** | `pwa-desde-web` |
| Mural en un **televisor** (Android TV): kiosco, auto-arranque, auto-update, mando a distancia | **APK Android TV** | `apk-webview-android` |
| App de **movil** en kiosco/marca propia fuera de la tienda (WebView), con auto-update | **APK movil (WebView)** | `apk-webview-android` |
| Movil (PWA para el dia a dia) **y** ademas mural en la tele | **PWA + APK TV** | ambas, en ese orden |
| Necesita logica NATIVA real (no envolver la web): pantallas propias, sensores, offline-first | *(fuera de alcance)* | Compose/Flutter/React Native — NO esta skill |

Regla practica: **empieza por la PWA** salvo que haga falta algo que el navegador no da
(kiosco, auto-arranque, auto-update, mando). Ese "algo extra" es lo que justifica la APK.

## Paso 3 — Derivar

Una vez decidido, invoca la skill destino y pasale el contexto (URL de la web, si tiene login
con CSRF, si es TV o movil, densidad/resolucion de la pantalla objetivo):

- **PWA** → skill `pwa-desde-web` (manifest + service worker que cachea SOLO el cascaron; los
  datos siguen yendo a la red; se enlaza desde el index y el login).
- **APK WebView (TV o movil)** → skill `apk-webview-android` (WebView en kiosco, auto-login
  respetando CSRF, fix de viewport por densidad, inmersivo, PIN, auto-arranque BOOT_COMPLETED,
  auto-update por SHA-256 desde el propio servidor, firma desde el vault, icono de marca).
  Antes de escribir codigo Android, esa skill ya recuerda leer `~/.claude/rules-ondemand/`
  (regla Kotlin).

Si el caso es "PWA + APK TV", haz PRIMERO la PWA (es rapida y no toca Android) y luego la APK.

## Errores que esta skill evita

- **Saltar a APK cuando bastaba una PWA** (semanas de Android para algo que resuelve un manifest).
- **Intentar una PWA para un mural de televisor** (una PWA no se auto-arranca al encender la
  tele ni entra en kiosco con el mando; para eso, APK).
- **Prometer la Play Store**: estas salidas son SIN tienda (instalacion directa / "anadir a
  pantalla de inicio"). Si el cliente exige tienda, es otro proyecto (cuenta de desarrollador,
  revision, etc.) y hay que decirlo desde el principio.
- **Reinventar** el service worker o el proyecto Android: el trabajo real vive en las dos skills
  derivadas; aqui solo se decide y se encadena.

## Ejemplo real (nombres cambiados)

Dashboard PHP de un servicio interno de un cliente, servido en un subdominio propio. Se necesitaba (a) que el personal
lo tuviera como app en el movil y (b) un mural permanente en un televisor Android TV. Decision:
**PWA** (via `pwa-desde-web`) para el movil + **APK Android TV** (via `apk-webview-android`) con
auto-login, auto-arranque, modo mural `?tv=1` y auto-update desde el propio servidor. Las dos
salidas conviven sobre la MISMA web sin duplicar logica.

## Auto-mejora

Al cerrar cada aplicacion practica de esta skill:
1. Registrar aprendizajes en `aprendizajes/<caso>.md` (o en esta seccion si es breve): que
   pregunta de decision fue la que de verdad desempato, casos limite (p.ej. Smart TV que NO es
   Android TV, tablet de recepcion, totem tactil), y decisiones que a posteriori resultaron
   erroneas.
2. Si aparece una salida nueva recurrente (p.ej. TWA para Play Store, Electron para escritorio),
   anadir su fila a la tabla de decision y, si merece skill propia, crearla y enlazarla aqui.
3. Si se descubre un criterio de decision mejor, actualizar las cuatro preguntas del Paso 1.

Sin esta fase, la skill se fosiliza y pierde valor con el tiempo.
