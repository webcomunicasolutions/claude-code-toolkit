---
name: apk-webview-android
description: Crear una APK Android TV (o movil) que envuelve una web EXISTENTE en un WebView modo kiosco/mural - auto-login respetando CSRF, fix de viewport por densidad, modo inmersivo, config protegida por PIN, auto-arranque al encender, auto-update con SHA-256 desde el propio servidor web, firma desde fichero externo e icono de marca. Usar cuando se pida "app para la tele", "APK del dashboard", "que la web salga en la television como app", kiosco Android TV, o envolver una web en WebView. Antes de escribir codigo Android conviene leer la regla Kotlin del kit (`rules/kotlin.md`). NOT para apps nativas con logica propia (Compose) ni para iOS.
---

# APK WebView para Android TV (kiosco/mural)

La APK es el "marco": todo el contenido vivo lo pone la web (se actualiza sin reinstalar).
Kotlin clasico SIN Compose (~2.4 MB), minSdk 23, sin cleartext (solo HTTPS).

**Estructura recomendada** (probada en hardware real): `MainActivity`, `BootReceiver`,
`data/{Config,SettingsStore,Updater}.kt`, `deploy-apk.sh` y un README con notas tecnicas.
Los fragmentos clave estan en `references/patrones-codigo.md`.

## Decisiones de diseño (validadas en produccion)

- **Usuario dedicado de solo-lectura** en la web para la tele (menor privilegio), creado por el
  endpoint oficial de usuarios (deja audit trail). Credenciales en tu gestor de credenciales.
- **Credenciales cifradas** en el dispositivo: EncryptedSharedPreferences (API 23+).
- **Auto-login inyectando el formulario real** por JS (rellenar y submit): respeta el token
  CSRF que pone el servidor. NO replicar el POST a mano.
- **Config por PIN** desde el mando (tecla MENU/INFO abre dialogo). BACK no cierra la app
  (es un mural); para salir/reconfigurar: MENU → PIN.
- **Auto-update sin panel de flota**: la web sirve `/app/version.json` + la APK estatica;
  la app compara versionCode al arrancar, descarga, VERIFICA SHA-256 e instala.
- **Keystore dedicado por cliente fuera del repo** (p. ej. `~/.credentials/clientes/<x>-firma.{jks,properties}`),
  leido por build.gradle.kts; 30 años; SIN el keystore no hay updates instalables — no perderlo.
- **Auto-arranque opcional** (toggle en Ajustes): receiver BOOT_COMPLETED. En Android 10+
  exige el permiso "Mostrar sobre otras apps" (ver patrones).

## Procedimiento

1. Crear el proyecto con la estructura recomendada, poner paquete, URLs (Config.kt) y marca.
   JDK 17 + SDK en `~/Android/Sdk` (WSL).
2. Crear keystore nuevo (guardado fuera del repo) + usuario de solo-lectura en la web (endpoint oficial).
3. Adaptar los 4 puntos sensibles leyendo `references/patrones-codigo.md`:
   auto-login (IDs del form real), viewport (ancho del diseño del mural), auto-arranque,
   update-server (rutas en el servidor del proyecto).
4. Icono y banner de marca: leer **`../pwa-desde-web/references/iconos-de-marca.md`** (regla comun a
   PWA y APK: siempre el logotipo del cliente, el sistema recorta, y las trampas de ImageMagick)
   y luego "Icono" en `references/patrones-codigo.md` para lo de Android — NO usar adaptive-icon
   con logos apilados (los recorta).
5. Probar: emulador Windows y despues TELE REAL — flujo completo en
   `references/pruebas-android.md` (build WSL, adb.exe de Windows como puente).
6. Publicar: `deploy-apk.sh` (build + version.json con SHA-256) y subir `/app/` al servidor
   web del proyecto. Commit sin la APK (gitignored; version.json si va en git).

## Errores conocidos (NO reintentar)

- **`initial-scale=1` en el meta viewport**: en densidad 2.0 hace 1 CSS px = 2 device px →
  tarjetas gigantes. Solo `width=<px fisicos>` y dejar que loadWithOverviewMode escale.
- **adaptive-icon con dos logos apilados**: el zoom 72/108dp recorta el logo alto → usar
  ic_launcher legacy recortado a circulo SIN zoom.
- **Launcher Google TV cachea iconos**: reinstalar NO refresca; `pm clear
  com.google.android.apps.tv.launcherx` o `adb reboot`.
- **`am force-stop` deja la app en "stopped state"** → BOOT_COMPLETED ya no le llega hasta
  abrirla a mano. No usar force-stop antes de probar el auto-arranque.
- **jq -r con clave inexistente imprime "null" literal** → verificar la clave real del fichero de credenciales
  antes de inyectarla en formularios por adb.
- **adb wifi a la tele se cae solo** → reconectar `adb connect <ip>:5555`. Tras reboot de la
  tele puede pedir REAUTORIZACION en pantalla (aceptar con el mando, "permitir siempre").
- **Firmas mezcladas**: si el dispositivo tiene la build debug, `install -r` de la release
  falla (INSTALL_FAILED_UPDATE_INCOMPATIBLE). Desinstalar antes, o probar con debug.
- **El WebView da `net::ERR_TIMED_OUT` pero la app SÍ habla con el servidor** (latido/API propias
  OK): mirar el **proxy global del sistema** ANTES que nada — `adb shell settings get global
  http_proxy`. Un proxy huerfano de una sesion de depuracion (p.ej. `10.0.2.2:8092`, la IP del host en el emulador) lo respeta
  Chromium pero no `HttpURLConnection`, asi que la app parece viva y la pantalla no carga.
  Arreglo: `adb shell settings put global http_proxy :0` + reiniciar la app. (Descartar service
  worker con `pm clear`, DNS con `-dns-server 8.8.8.8` e IPv6 mirando si el dominio tiene AAAA.)
- **La tele se apaga sola tras 4 h**: es el **apagado automatico por inactividad** de Android TV,
  y `FLAG_KEEP_SCREEN_ON` NO lo evita (solo impide que se apague la pantalla, no que el televisor
  se suspenda). Al despertar vuelve al launcher, no a la app. En CUALQUIER instalacion de mural:
  Ajustes → Preferencias del dispositivo → Energia → "Apagar automaticamente: Nunca" +
  salvapantallas desactivado. Sintoma tipico: el inventario marca la tele caida siempre a la misma
  hora, y el uptime del ultimo latido es exactamente ~14.400 s.

## Referencias

- `references/patrones-codigo.md` — patrones clave con codigo: auto-login CSRF, viewport,
  BootReceiver + permiso overlay, Updater SHA-256, firma desde fichero externo, iconos ImageMagick.
- `references/pruebas-android.md` — probar desde WSL con emulador Windows y tele real
  (adb.exe puente, rellenar formularios por adb, validar reboot/auto-arranque).

## Auto-mejora

Al cerrar cada aplicacion practica de esta skill:
1. Registrar aprendizajes en `aprendizajes/<caso>.md` (o en esta seccion si es breve)
2. Si el patron es generalizable, actualizar el cuerpo de este SKILL.md
3. Si se descubre un error recurrente, añadirlo a "Errores conocidos"

Sin esta fase, la skill se fosiliza y pierde valor con el tiempo.
