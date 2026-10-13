# Probar APKs desde WSL con emulador Windows y tele real

Build en WSL (JDK 17 fijado en `~/.gradle/gradle.properties`, SDK en `~/Android/Sdk`);
emulador y dispositivos en Windows (mejor GPU y red). Puente: **adb.exe de Windows**
(`/mnt/c/Users/<usuario>/AppData/Local/Android/Sdk/platform-tools/adb.exe`) — NO el adb de WSL
(va tras NAT y no ve los dispositivos).

## Flujo basico

```bash
WADB=/mnt/c/Users/<usuario>/AppData/Local/Android/Sdk/platform-tools/adb.exe
./gradlew :app:assembleRelease --no-daemon
cp app/build/outputs/apk/release/app-release.apk /mnt/c/Temp/x.apk   # el adb.exe lee rutas Windows
"$WADB" -s <dev> install -r -g 'C:\Temp\x.apk'
"$WADB" -s <dev> shell am start -n <paquete>/.MainActivity
```

## Emulador Android TV en Windows

- Lanzar desde WSL via interop: `/mnt/c/.../emulator/emulator.exe -avd <avd_tv>
  -no-snapshot-load -gpu host &` (NO `cmd.exe /c start` con rutas `\\` — falla).
- Esperar arranque: `getprop sys.boot_completed` == 1.
- Reproducir bugs de densidad/viewport: `adb shell wm density N` (160 → CSS 1920; 320 → CSS 960).
- El emulador guarda la config de la app entre reinstalls SI la firma coincide (debug vs
  release NO coinciden → INSTALL_FAILED_UPDATE_INCOMPATIBLE; probar alli con debug).
- Cerrar al terminar: `adb -s emulator-5554 emu kill`.

## Tele real por red

- En la tele: Opciones de desarrollador → Depuracion ADB por red. `adb connect <ip>:5555`.
- La conexion wifi SE CAE SOLA cada cierto tiempo → reconectar sin mas.
- Tras `adb reboot`, la tele puede tardar 3-5 min en volver y quedarse en **unauthorized**:
  hay que aceptar el dialogo de autorizacion EN PANTALLA con el mando ("permitir siempre").
  No se puede resolver en remoto — avisar al usuario.
- Refrescar icono del launcher tras cambiarlo: `pm clear com.google.android.apps.tv.launcherx`
  (rapido, resetea la home) o `adb reboot` (~60s). Reinstalar NO basta.

## Rellenar formularios por adb (setup de la app en la tele)

- `input text 'valor'` + `input keyevent 61` (TAB) + `input keyevent 4` (BACK cierra teclado)
  + `input tap X Y` para botones.
- El primer campo a veces queda mal → **screenshot SIEMPRE antes de Guardar**:
  `adb exec-out screencap -p > pantalla.png`.
- Credenciales desde tu fichero de credenciales con la CLAVE REAL (`jq -r` imprime "null" literal si la clave
  no existe y acabaria escrito en el formulario).

## Validar el auto-arranque

1. Instalar y ABRIR la app una vez (si quedo en stopped state — p.ej. tras `am force-stop` —
   BOOT_COMPLETED no le llega).
2. Conceder overlay: `adb shell appops set <paquete> SYSTEM_ALERT_WINDOW allow`.
3. `adb reboot` → esperar boot_completed=1 → ~25-30 s de margen al receiver →
   `dumpsys activity activities | grep topResumedActivity` debe mostrar la MainActivity.
4. En emulador el ciclo completo tarda ~1 min; en tele real 4-6 min (y puede exigir
   reautorizar adb en pantalla).
