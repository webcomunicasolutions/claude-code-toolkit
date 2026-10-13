# Clínica veterinaria · servidor RDS con ERP de terceros (agosto 2026)

Caso que originó la skill. Servidor **Windows Server 2025 Standard** (`SRV-CLIENTE`),
RDS con 50 CAL por dispositivo, 5 puestos + el equipo de casa del dueño por VPN.
Programa de gestión: **un ERP veterinario sobre Access**, instalado por su propio técnico.


## Cronología útil

- **10/08** instalación de Windows (edición Evaluation).
- **11/08** conversión a Standard + activación, disco `C:`/`D:`, rol RDS + CAL, 6 usuarios
  por puesto, carpeta común, software base, VPN WireGuard, wallpaper.
- **12/08 madrugada** avisos de RDP resueltos (certificados propios + `.rdp` firmados),
  Windows Update completo, fábrica de accesos.
- **12/08 tarde** traslado físico a la clínica, IP fija `192.168.1.10`, despliegue en los
  3 PCs reales y en el equipo de casa por VPN.

## Lo que costó tiempo (y por qué)

**Dejé al cliente sin RDP dos veces seguidas, por el mismo sitio.** Primero fijé el
certificado TLS sin dar acceso a su clave privada al servicio de RDP. Al reintentarlo,
di el permiso **por nombre** (`NETWORK SERVICE`) en un Windows en español, donde esa
cuenta se llama *SERVICIO DE RED*: `icacls` devolvió error, **no lanzó excepción**, y mi
script imprimió "ACL aplicada" siendo falso. El síntoma en ambos casos fue idéntico:
`Connection reset by peer` en el handshake TLS.

De aquí salieron las dos reglas más valiosas de la skill: **SID en vez de nombre** y
**comprobar `$LASTEXITCODE` de las herramientas externas**.

**El aviso de "editor desconocido" volvió a salir** aunque el servidor estaba
perfectamente configurado, porque el técnico conectaba escribiendo la IP a mano en `mstsc`.
Una conexión escrita a mano no lleva firma. Hay que insistir en el mensaje: **entrar
siempre por el icono**.

**Los `.rdp` firmados están en UTF-16.** Generé el acceso del dueño con `sed` sobre un
`.rdp` ya firmado y salió con el usuario equivocado (`entrada` en vez de `gerente`), sin
que `sed` avisara de nada. Lo detecté verificando el contenido del fichero descargado, no
por el exit code de `rdpsign`.

**Mi propio arreglo del menú de winsetup no funcionaba**: `Write-Output -NoEnumerate` no
sobrevive al `return` de una función. Lo cazó una batería de pruebas que escribí y ejecuté
en el servidor: la primera pasada dio 6 fallos, dos de ellos errores de fondo míos y uno
un test mal planteado. Sin ejecutar las pruebas habría entregado los cuatro "arreglos"
como buenos.

## Lo que encontré al auditar tras el técnico de el ERP

- **`Todos:(OI)(CI)(F)` en la raíz de `C:`** — control total para cualquier usuario en
  todo el disco. Con dos servicios (`MiVetSincro`, `ERPData`) corriendo como
  `LocalSystem` **desde `C:\ERP`**, eso es escalada a SYSTEM en dos pasos.
- **Office Pro Plus 2021 con clave `Office21ProPlus2021MSDNR_Retail`** — licencia de
  MSDN (solo desarrollo y pruebas) y canal Retail (no válido para RDS).
- **TeamViewer QuickSupport** del técnico corriendo desde el Temp de `administrador` con
  conexión saliente activa. Se lo llevó el reinicio (era portable).
- **La base de datos `erp.mdb` (224 MB) está protegida con contraseña**, y no estaba
  en ningún `.config`. Probado sobre una copia con `ACE.OLEDB`: *"No es una contraseña
  válida"*. El backup guardaba los datos pero **no permitía leerlos sin el ERP**.
- Datos reales ya migrados (fechas de 2017 a 2026) con el equipo en **un solo SSD sin
  RAID, sin backup y sin SAI**.

## Detalles del cliente que resultaron útiles

- Usuarios **por puesto físico** (`entrada`, `consulta1-3`, `rayos`), no por persona:
  todos usan todos los equipos y así nadie roba la sesión de otro. Más el usuario
  personal del dueño para entrar desde casa por VPN sin echar a nadie.
- **CAL por dispositivo** (el proveedor las vendió como "per user", eran per-device):
  con modo *Per Device* se rastrean sin dominio y sin avisos. `Win32_TSIssuedLicense`
  reveló los nombres reales de los equipos de la clínica (`TIENDA`, `CONSULTA1`,
  `CONSULTA2`), útil para el inventario.
- **NO montar controlador de dominio**: usuarios locales bastan para 5 puestos, y
  Microsoft desaconseja DC + RDS en la misma máquina.
- Fibra simétrica de **445/505 Mbps** en la clínica: 6 GB de primer backup son minutos.
  Merece la pena medirlo antes de dimensionar la estrategia de copias.

## Pendiente al cerrar (12/08/2026)

Backblaze B2 y backup verificado · permisos de `C:` (con ACL guardada y probando el ERP
después) · contraseña del `.mdb` y exportación a CSV · Office (quitar o licenciar) ·
comprobar el ERP con usuario de puesto y las impresoras · reserva de la IP en el DHCP del
router.
