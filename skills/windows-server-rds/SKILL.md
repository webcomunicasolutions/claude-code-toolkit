---
name: windows-server-rds
description: Montar, endurecer y documentar servidores Windows Server de clientes, con foco en RDS (Escritorio Remoto multipuesto) y en programas de gestión instalados por terceros. Cubre el método completo - quitar los avisos de seguridad de RDP con certificados propios y .rdp firmados, una "fábrica" de accesos en el propio servidor para preparar los PCs uno a uno, auditoría de lo que deja el técnico del ERP, permisos, independencia de los datos del cliente frente al fabricante, y despliegue de fondo y accesos a todos los usuarios. Usar cuando se trabaje con un Windows Server de cliente, cuando salga "El editor de esta conexión remota no se puede identificar" o "No se puede comprobar la identidad del equipo remoto", cuando haya que preparar puestos para entrar por Escritorio Remoto, cuando un técnico externo haya instalado un ERP y haya que documentar qué tocó, o cuando el cliente pregunte "¿y si algún día el programa deja de funcionar?". NOT para servidores Linux (usar linux-server-audit).
---

# Windows Server de cliente · método completo

Nacido del montaje completo del servidor de una clínica veterinaria (Windows Server 2025 + RDS + un ERP
sobre Access, agosto 2026). Todo lo de aquí está **probado en producción**, y los gotchas son fallos
reales que costaron tiempo o dejaron a alguien sin servicio.

## Regla cero

Es el servidor de un cliente. **Cualquier cambio que afecte a producción se confirma
antes.** Y nada se declara hecho sin evidencia ejecutada: no vale leer la configuración,
hay que comprobar el comportamiento (ver "Verificar de verdad").

---

## 1. Quitar los avisos de seguridad de RDP

Son **tres avisos distintos** y se confunden. Cada uno tiene su causa y su arreglo:

| Aviso que ve el usuario | Causa | Arreglo |
|---|---|---|
| "El **editor** de esta conexión remota no se puede identificar" | el `.rdp` no está firmado | firmar con `rdpsign` + registrar la huella del certificado en el PC |
| "No se puede comprobar la **identidad del equipo remoto**" | el certificado TLS del servidor es autofirmado y desconocido | certificado propio + instalarlo como raíz de confianza en el PC |
| "Estás abriendo un archivo RDP…" (Win11) | protección del propio Windows | `Unblock-File` sobre el `.rdp`; si insiste, casilla una vez por PC |

### Cómo se hace

1. **`scripts/crear-certs-rdp.ps1`** — dos certificados propios de 10 años en
   `C:\Tools\rdp-signing` (ACL solo admins): uno TLS para el servidor y uno de firma de
   código. Exporta los `.cer` públicos y el `.pfx` (su contraseña **a tu gestor de credenciales**).

   Emitir uno propio no es capricho: el autofirmado que genera Windows **caduca en 6
   meses y se regenera solo**, así que el aviso de identidad reaparecería en todos los
   PCs cada medio año.

2. **`scripts/aplicar-cert-rdp.ps1`** — fija el certificado TLS en
   `HKLM\...\Terminal Server\WinStations\RDP-Tcp\SSLCertificateSHA1Hash`.
   **Reinicia `TermService`**: hacerlo sin nadie conectado.

3. **`scripts/Generar-RDP.ps1`** — la **fábrica**. Se instala en
   `C:\Tools\rdp-generator` con un acceso directo en el escritorio del administrador.
   Pregunta a qué IP conectarán los equipos (lista las del servidor y etiqueta cuál es
   VPN y cuál cambiará de sede) y para qué usuarios (los saca del grupo "Usuarios de
   escritorio remoto"). Produce un paquete listo para pendrive: `.rdp` firmados,
   certificados, `preparar-pc-cliente.ps1` y un `PREPARAR-<puesto>.cmd` por usuario.

4. **`scripts/preparar-pc-cliente.ps1`** — se ejecuta una vez por PC (normalmente por
   doble clic en su `.cmd`): `hosts`, certificado de firma en `TrustedPublisher` + `Root`,
   huella en `TrustedCertThumbprints`, certificado del servidor en `Root`, y el `.rdp` al
   escritorio público. Termina comprobando si ese PC **resuelve el nombre**.

### La decisión de diseño que lo hace mantenible: conectar por NOMBRE

Los `.rdp` apuntan a `SRV-CLIENTE`, nunca a la IP:

- El certificado se emite a nombre del servidor. Conectando por IP el nombre no
  coincide y el aviso de identidad sigue saliendo.
- **La firma cubre `full address`**: si el `.rdp` llevara la IP, cambiar de red obligaría
  a regenerar y re-firmar todos los accesos. Por nombre sobreviven a la mudanza; solo
  cambia la línea del `hosts` de cada PC.

Con dominio esto se despliega por GPO. **Sin dominio hay que ir PC por PC**, y
de ahí la fábrica: convierte el trabajo en "doble clic en el `.cmd` que toca".

---

## 2. Auditar lo que deja un técnico externo

Cuando el fabricante del ERP instala, hay que documentar qué tocó **el mismo día**.
`scripts/auditoria-servidor.ps1` (solo lee) saca: sistema y hardware, red y puertos a la
escucha, software instalado **con fecha**, servicios no-Microsoft, arranque automático y
tareas programadas, usuarios y grupos, recursos compartidos, reglas de firewall, y de la
carpeta del ERP: tamaño, permisos, bases de datos con fechas, ejecutables y ficheros de
configuración marcando los que contienen credenciales **sin volcar los valores**.

Lo que apareció en el caso origen y conviene buscar siempre:

- **`Todos` y `Usuarios` con Control Total en la raíz de `C:`**, heredado a todo el disco.
  Es "dar permisos" a lo bruto, y regala: borrado de la base de datos por cualquier
  usuario, ransomware desde cualquier puesto, y **escalada a SYSTEM** si algún servicio
  corre desde una carpeta escribible (se sustituye el `.exe` y Windows lo ejecuta).
- **Office con licencia que no cubre RDS.** Comprobar el canal:
  `Get-CimInstance SoftwareLicensingProduct | ? { $_.Name -match 'Office' -and $_.PartialProductKey }`
  Si sale `...MSDNR_Retail` es clave de MSDN/Visual Studio: **solo desarrollo y pruebas,
  prohibida en producción**. Y Retail tampoco vale para escritorio remoto multiusuario
  (hace falta LTSC por volumen o M365 con activación compartida).
- **Herramientas de acceso remoto del técnico** (TeamViewer QuickSupport en el Temp del
  perfil, con conexión saliente viva). Cerrarlas al terminar.
- Software y drivers inesperados, versiones antiguas con vulnerabilidades conocidas.

---

## 3. Independencia de los datos del cliente (lo que casi nadie comprueba)

La pregunta del cliente es siempre la misma: *"¿y si mañana el programa deja de
funcionar o el fabricante sube el precio?"*. Tener backup **no** es tener los datos.

Comprobar de verdad si se puede leer la base de datos **sin el programa**, y hacerlo
**sobre una copia**, nunca sobre la base activa:

```powershell
# Access (.mdb/.accdb) — el motor suele estar ya instalado por el propio ERP
$cn = New-Object System.Data.OleDb.OleDbConnection "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=C:\Temp\copia.mdb;"
$cn.Open()   # si pide contraseña, salta aquí
$cn.GetSchema('Tables') | Where-Object { $_.TABLE_TYPE -eq 'TABLE' }
```

En el caso origen el `.mdb` **está protegido con contraseña** y no estaba en ningún `.config`:
el backup guardaba los datos pero no permitía leerlos. Plan cuando pasa esto:

1. **Pedir la contraseña y el esquema de tablas al fabricante, por escrito.** Los datos
   son del cliente y el RGPD (art. 20, portabilidad) respalda poder extraerlos.
2. Si no colaboran: los componentes suelen ser .NET y la cadena de conexión se recupera
   decompilando (herramienta `ilspycmd`). Es el cliente accediendo a **sus propios
   datos**.
3. Con la contraseña en tu gestor de credenciales, montar **exportación periódica a CSV/SQLite** junto al
   backup. Eso es lo que convierte "tengo una copia" en "tengo mis datos".

Y antes de que entre un solo dato real: **backup fuera del equipo funcionando y probado**
(restauración incluida) y **SAI**. Un `.mdb` con varios usuarios y un corte de luz se
corrompe, y Access tiene un límite duro de 2 GB por fichero.

---

## 4. Cosas que se aplican a TODOS los usuarios de un RDS

- **Iconos**: al **escritorio público** (`C:\Users\Public\Desktop`), no uno por uno. Lo
  heredan los existentes y los futuros. Mejor copiar el `.lnk` que creó el instalador
  (menú Inicio) que fabricar uno nuevo.
- **Fondo de pantalla**: `Control Panel\Desktop\Wallpaper` **no basta** — en Server
  2025 / Win11 el tema lo sobrescribe al iniciar sesión. Lo que manda es la directiva
  `HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System\Wallpaper` (+
  `WallpaperStyle=2`), que además impide cambiarlo. Aplicarla en el perfil DEFAULT, en
  los SIDs montados en `HKEY_USERS` (sesiones abiertas) y en los `NTUSER.DAT` de los
  perfiles sin sesión → `scripts/aplicar-wallpaper-todos.ps1`.
- **Refrescar algo dentro de una sesión RDP ajena** (desde SSH corres en la sesión 0, que
  no la toca): tarea programada con
  `New-ScheduledTaskPrincipal -UserId <equipo>\<usuario> -LogonType Interactive` y
  `Start-ScheduledTask`. Se ejecuta dentro de su sesión. Comprobar
  `(Get-ScheduledTaskInfo).LastTaskResult -eq 0`.
- Revisar **qué ve el usuario** en el escritorio público: utilidades de la placa base,
  la herramienta de soporte remoto del proveedor de TI y el cliente de backup **no** deben estar a
  la vista del personal (una llamada de estafa telefónica y les guían para dar acceso).

---

## 5. Verificar de verdad

`Get-ChildItem "Cert:\LocalMachine\Remote Desktop"` dice qué **hay**, no qué se está
**sirviendo**. Para saberlo, handshake real (`scripts/check_rdp_cert.py`): X.224 pidiendo
`0x03` (TLS+CredSSP; con `0x01` el servidor responde `failureCode=5` si exige NLA, que es
lo correcto) y luego leer la huella del certificado servido.

Otras verificaciones que hay que hacer y no suponer:

- Los `.rdp` firmados: que el fichero contenga `signature:s:` (no fiarse del exit code).
- Copias a pendrive o entre equipos: **hash SHA256 origen vs destino**.
- Sesiones y perfiles: `quser`, `C:\Users\<usuario>`, y el evento 21 de
  `TerminalServices-LocalSessionManager`.
- Apagado limpio vs corte de luz: eventos **1074** (ordenado) y **41** (inesperado).
- CAL consumidas: `Win32_TSLicenseKeyPack` y `Win32_TSIssuedLicense` (esta dice **qué
  equipos** han pedido licencia, útil para inventario).

---

## 6. Gotchas (fallos reales — no repetir)

**Permisos y cuentas del sistema**
- **Cuentas integradas SIEMPRE por SID, nunca por nombre.** En un Windows en español
  `icacls /grant "NETWORK SERVICE:(R)"` falla ("No se efectuó ninguna asignación entre
  los nombres de cuenta y los SID"). Usar `*S-1-5-20`. Otros: `*S-1-5-32-544` admins,
  `*S-1-5-32-545` usuarios, `*S-1-5-18` SYSTEM.
- **`icacls` NO lanza excepción al fallar**: hay que mirar `$LASTEXITCODE` o darás por
  aplicado algo que no se aplicó.
- Al fijar un certificado en RDP-Tcp, **primero** dar lectura de su clave privada a
  `NETWORK SERVICE` (fichero en `ProgramData\Microsoft\Crypto\Keys\<UniqueName>`).
  Sin eso el servidor acepta el TCP y **corta el handshake**: RDP inservible.

- **Secretos de un servicio: NUNCA en el valor `Environment` del registro del servicio.** La clave
  `HKLM\SYSTEM\CurrentControlSet\Services\<svc>` tiene por defecto `Authenticated Users: ReadKey`:
  cualquier usuario del dominio lee el valor. Usar un fichero con ACL explícita sin herencia
  (SYSTEM/Administradores F + `NT SERVICE\<svc>` R). Lo cazó la revisión de seguridad, no el autor.
- **En un DC no hay cuentas locales**: `New-LocalUser` crea una de DOMINIO. Para que un servicio corra con
  una cuenta propia, usar la cuenta virtual `NT SERVICE\<svc>` (`sc config <svc> obj= "NT SERVICE\<svc>"`), sin clave.
- **Cerrar la ACL de la carpeta padre corta a los servicios**: si los servicios leían el padre gracias a `Users`
  (las cuentas virtuales están en Usuarios), al quitarlo Apache da 403 y MySQL no arranca tras reiniciar. Dar
  `(RX)` solo sobre el padre (sin `(OI)(CI)`) a cada `NT SERVICE\<svc>`.
- **`Move-Item` en el mismo volumen conserva la ACL de origen**: el fichero movido no hereda de su nueva
  carpeta. Después, `icacls <f> /reset`. Síntoma en Apache: «Could not open configuration file … Access is denied».

**PowerShell**
- `Write-Output -NoEnumerate` **no sobrevive al `return` de una función**. Para devolver
  siempre un array: `return ,$array`.
- No usar `$input` como variable: es automática (enumerador del pipeline).
- `New-LocalUser` **no** mete al usuario en el grupo "Usuarios"; hay que añadirlo. Y una
  descripción de más de 48 caracteres hace que falle en silencio.
- `powershell -File script.ps1 -Lista a,b,c` **no parsea arrays**: llega como un único
  string. Normalizar dentro del script (y validar contra la realidad).
- `Start-Process -ArgumentList` de PS 5.1 **une los argumentos sin entrecomillar**: se
  rompe con rutas con espacios. En un `.cmd`, elevarse relanzándose a sí mismo
  (`net session` + `Start-Process '%~f0' -Verb RunAs`) y pasar `-File "%~dp0x.ps1"`.
- `reg load HKU\X` **SIEMPRE** con su `reg unload` (con `[gc]::Collect()` + espera antes).
  Si queda montado, **los perfiles nuevos fallan al crearse**.

**Ficheros**
- Los `.rdp` firmados quedan en **UTF-16LE con BOM**: `sed`/`grep` de Linux no los edita
  (parecen editarse y no cambia nada). Manejarlos con `Get-Content`/.NET o Python con
  `encoding='utf-16'`.
- El `hosts` puede estar **en solo lectura** (limpiadores) y, sobre todo, **protegido por
  Windows Defender** (`Acceso denegado` incluso siendo admin y con el ReadOnly quitado).
  Vías: Notepad como administrador, o `Add-MpPreference -ExclusionPath` sobre el hosts.
  **Que un fallo del `hosts` no aborte el resto**: los certificados son lo que quita los
  avisos, y en red plana Windows resuelve el nombre igualmente.
- `Set-Content` sobre el hosts falla en algunos equipos con
  `GetContentWriterArgumentError`. Usar `[IO.File]::WriteAllLines()`.

**Instalación de software**
- **`winget` no funciona en sesión no interactiva** (WinRM/SSH/tarea): `0x8a15000f`
  aunque esté instalado. No perder tiempo con `source reset`: descarga directa.
- Los desinstaladores de **GIGABYTE** (`uninst.exe /S`) devuelven **exit 0 sin
  desinstalar**. Por GUI + desactivar "APP Center Download & Install" en BIOS.
- **Windows Update no se puede instalar por WinRM/SSH**: lanzarlo con una **tarea
  programada como SYSTEM** (o `Invoke-WUJob` de PSWindowsUpdate).
- **WireGuard**: importar túneles **por la GUI**. Por `/installtunnelservice` funciona
  pero no aparece en la ventana y luego no hay forma de gestionarlo.

- **PowerShell NO distingue mayúsculas en las variables**: `$ESTADO` (ruta) y `$estado` (tabla)
  son la MISMA. Un script de copias escribía el estado en
  `System32\System.Collections.Hashtable` y el informe decía «nunca ejecutado», sin error.
  Nombres de constantes que no coincidan con ningún local (`$FICHERO_ESTADO`). Detector:
  `grep -oE '\$[A-Za-z_][A-Za-z0-9_]*' x.ps1 | sort -u | awk '{l=tolower($0);a[l]=a[l]" "$0;n[l]++} END{for(k in a) if(n[k]>1) print a[k]}'`
- **PS 5.1: `@($json | ConvertFrom-Json).Count` da 1** con un array JSON (lo emite como un
  objeto). Asignar antes: `$l = $json | ConvertFrom-Json; @($l).Count`.

- **Una carpeta nueva en la raíz de D: (o C:) hereda `BUILTIN\Users:(RX)`**: lo que se aparte ahí (copias de `.env`,
  `.ini`, `.cnf`) lo pueden leer todos los usuarios. Caso real: 3 copias con credenciales estuvieron ~1 min en
  `D:\_pendiente_borrado`. Al crear `_pendiente_borrado` (o cualquier carpeta de trabajo), cerrarla en el acto:
  `icacls <dir> /inheritance:r /grant:r *S-1-5-18:(OI)(CI)F *S-1-5-32-544:(OI)(CI)F` (sin /T: los hijos heredan).
- **Avisos de Telegram «que no llegan»**: comprobar con `getMe` + `getChat` QUÉ bot y QUÉ chat. Los avisos iban a
  un bot y el usuario solo miraba otro (misma cuenta, chats distintos). `ok=true` de la API no es «lo ha visto».

**Antes de apagar un servidor con un ERP dentro**
- Parar sus servicios y cerrar la aplicación: un Access abierto + apagado sucio =
  corrupción. Comprobar los `.ldb`/`.laccdb` (ojo: los hay huérfanos de años atrás).
  Apagar **desde el menú de Windows** (deja evento 1074 y cierra servicios en orden).

---

## 7. Al reutilizar los scripts en otro cliente

Los de `scripts/` vienen del primer caso (nombres como `SRV-CLIENTE`, `CLIENTE-Datos`). Antes de usarlos, cambiar:

| Script | Qué parametrizar |
|---|---|
| `crear-certs-rdp.ps1` | `FriendlyName` de los certs, `Subject`, `DnsName` |
| `aplicar-cert-rdp.ps1` | la huella del certificado TLS |
| `Generar-RDP.ps1` | `$NOMBRE`, `$PREFIJO`, `FriendlyName` de los certs |
| `preparar-pc-cliente.ps1` | `$NombreServidor` por defecto (lee la huella del `.cer`, eso ya es genérico) |
| `auditoria-servidor.ps1` | nada: recibe `-CarpetaApp` por parámetro |
| `aplicar-wallpaper-todos.ps1` | la ruta de la imagen (`-Imagen`) |
| `postinstalacion-erp.ps1` | `$RAIZ`, `$GRUPO`, `$NOMBRE` (plantilla para cualquier ERP) |

Con **dominio**, preferir GPO a ir PC por PC: certificado de firma por
"Directivas de clave pública" y la huella por
`Configuración de usuario → Componentes de Windows → Servicios de Escritorio remoto`.

---

## Auto-mejora

Al cerrar cada aplicación práctica de esta skill:
1. Registrar aprendizajes en `aprendizajes/<cliente>-<fecha>.md`.
2. Si el patrón es generalizable, actualizar el cuerpo de este SKILL.md.
3. Si aparece un fallo nuevo, añadirlo a **Gotchas** con su síntoma exacto (el mensaje
   de error literal es lo que hace que se reconozca la próxima vez).

Sin esta fase la skill se fosiliza.
