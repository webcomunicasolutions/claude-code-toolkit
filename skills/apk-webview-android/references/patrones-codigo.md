# Patrones de codigo — APK WebView Android TV

Probados en una Xiaomi Mi TV con Android 14, densidad 320.

## Indice
1. WebView base
2. Auto-login respetando CSRF
3. Fix de viewport por densidad (CLAVE)
4. Auto-arranque (BOOT_COMPLETED + permiso overlay)
5. Auto-update con SHA-256
6. Firma release desde un fichero fuera del repo
7. Iconos y banner (ImageMagick)

## 1. WebView base

```kotlin
web.settings.apply {
    javaScriptEnabled = true
    domStorageEnabled = true
    loadWithOverviewMode = true   // escala el viewport forzado para que quepa
    useWideViewPort = true
    setSupportZoom(false)         // mural: sin zoom accidental con el mando
}
// Cookies de sesion: CookieManager acceptCookie + flush() en onPageFinished.
// shouldOverrideUrlLoading → return false (todo dentro del WebView).
// onReceivedError SOLO si req.isForMainFrame → reintento con backoff (5→10→20→40→60s).
// FLAG_KEEP_SCREEN_ON + inmersivo (reafirmar en onWindowFocusChanged: los dialogos lo quitan).
```

## 2. Auto-login respetando CSRF

En `onPageFinished`, si la URL es el login y hay credenciales guardadas, rellenar y enviar el
formulario REAL de la pagina (el token CSRF del server viaja solo):

```kotlin
val js = """
    (function(){
      var f=document.getElementById('loginForm');   // IDs del form real del proyecto
      var uu=document.getElementById('username');
      var pp=document.getElementById('password');
      if(f&&uu&&pp){ uu.value=$u; pp.value=$p; f.submit(); }
    })();
"""
web.evaluateJavascript(js, null)
```

`$u`/`$p` serializados como literal JS seguro (escapar `\ " \n \r` y `<` → `<`).
Tras el login el server suele ir a la home SIN el modo kiosco → detectar y reencaminar
(`esDashboardSinTv(url) → loadUrl(tvUrl)`).

## 3. Fix de viewport por densidad (CLAVE)

Un WebView en tele de densidad alta reporta ancho CSS reducido (960 en vez de 1920 con
densidad 320) → el layout pensado para 1920 px no cabe y aparece scroll. Al cargar la pagina
kiosco, inyectar un meta viewport con el ANCHO FISICO REAL:

```kotlin
// anchoFisicoPx = windowManager.defaultDisplay.getRealMetrics(dm).widthPixels
val js = """
    var m=document.querySelector('meta[name=viewport]') || (creado y añadido al head);
    m.setAttribute('content','width=$anchoFisicoPx, user-scalable=no');
"""
```

PROHIBIDO añadir `initial-scale=1`: en densidad 2.0 hace 1 CSS px = 2 device px (todo gigante).
Solo `width=`; `loadWithOverviewMode` escala para que 1 px CSS ≈ 1 px fisico.

## 4. Auto-arranque (BOOT_COMPLETED + permiso overlay)

Toggle en Ajustes (no imponerlo). Android 10+ bloquea abrir una Activity desde segundo plano
salvo que la app tenga "Mostrar sobre otras apps" (SYSTEM_ALERT_WINDOW).

Manifest:
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<receiver android:name=".BootReceiver" android:enabled="true" android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
    </intent-filter>
</receiver>
```

Receiver: comprobar `autoStart && configurada && Settings.canDrawOverlays(context)` y lanzar
MainActivity con `FLAG_ACTIVITY_NEW_TASK`. Al activar el toggle en Ajustes: si falta el
permiso, `startActivity(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, "package:$packageName")`;
fallback por adb: `adb shell appops set <paquete> SYSTEM_ALERT_WINDOW allow`.

QUICKBOOT_POWERON: algunas teles "apagan" suspendiendo y al volver emiten ese broadcast.

## 5. Auto-update con SHA-256

La web del proyecto sirve `/app/version.json` + `/app/<x>.apk` ESTATICOS y PUBLICOS (fuera del
login, como sw.js). Al arrancar, en un executor:

1. GET version.json → si `versionCode` > el propio (BuildConfig), seguir.
2. Descargar APK a cache interna → calcular SHA-256 → comparar con el del JSON (abortar si no).
3. Instalar via FileProvider + intent de instalacion (permiso REQUEST_INSTALL_PACKAGES).

Publicacion: script `deploy-apk.sh` — build release, lee versionCode/Name con `aapt dump
badging`, copia la APK al webroot local y regenera version.json con el sha256. Despues scp de
`/app/` al servidor. La APK va gitignored; version.json puede ir en git.

## 6. Firma release desde un fichero fuera del repo

```kotlin
val firmaProps = Properties().apply {
    val f = File(System.getProperty("user.home"), ".credentials/clientes/<x>-firma.properties")
    if (f.canRead()) f.inputStream().use { load(it) }
}
// signingConfigs solo si firmaProps tiene storeFile; si no, release sin firmar (otra maquina/CI).
```

`.properties` (fuera del repo): storeFile/storePassword/keyAlias/keyPassword. Crear: `keytool -genkeypair
-keyalg RSA -validity 10950` (30 años). Permisos 600, NUNCA en el repo.

## 7. Iconos y banner (ImageMagick)

- Teñir un logo a blanco conservando alpha: `convert logo.png -alpha extract mask.png` →
  rellenar blanco + `-compose CopyOpacity`.
- Icono con 2 logos apilados sobre color de marca: componer en lienzo cuadrado, logos GRANDES
  y compactos, y RECORTAR A CIRCULO sin zoom (`-draw circle` + `compose DstIn`). NO adaptive.
- Simular el recorte circular del launcher ANTES de instalar (misma tecnica) para no iterar
  en la tele.
- Banner leanback (`drawable/banner.png`, 320x180): logos lado a lado, mas holgura que el icono.
- mipmaps: 48/72/96/144/192 px (mdpi→xxxhdpi).
