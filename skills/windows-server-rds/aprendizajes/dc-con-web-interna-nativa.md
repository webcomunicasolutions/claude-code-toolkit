# Servidor DC + RDS — preparar MySQL/Apache/PHP nativos para una web interna (09/10/2026)

- **Pila nativa en un DC sin Docker**:
  - MySQL 8.4 zip + `mysqld --install` y Apache Lounge + mod_fcgid + PHP NTS, todos con cuentas virtuales `NT SERVICE\<svc>`.
  - Comprobar los hashes en el propio servidor con `Get-FileHash`. MySQL trae `.asc` (clave B7B3B788A8D3785C). mod_fcgid NO publica hash.
- **`Listen 0.0.0.0:443` + firewall acotado + `Require ip`** en lugar de escuchar en la IP de ZeroTier: si ZeroTier tarda en tener IP al arrancar, Apache no arranca.
- **Variables de entorno a PHP con mod_fcgid**: `FcgidInitialEnv NOMBRE` sin valor NO hereda del entorno del servicio; `PassEnv` sí. Pero los secretos van en un fichero con ACL (ver Gotchas), no en el registro.
- **CA raíz propia con `nameConstraints`** (dominio + rangos IP) y reparto por GPO:
  - `Set-GPRegistryValue` en `HKLM\Software\Policies\Microsoft\SystemCertificates\Root\Certificates\<SHA1>`, valor `Blob`.
  - El `Blob` (formato serializado, no DER) se saca de `HKLM\SOFTWARE\Microsoft\SystemCertificates\ROOT\Certificates\<SHA1>` después de un `certutil -addstore Root`.
- **Sin CRL**, `curl.exe` (Schannel) falla con CRYPT_E_NO_REVOCATION_CHECK: usar `--ssl-no-revoke`.
- **DNS de un DC heredado de VPS**: los reenviadores eran del proveedor antiguo y estaban muertos. Probar `Resolve-DnsName -Server 127.0.0.1` ANTES de poner el cliente en 127.0.0.1, o el servidor se queda sin internet.
- **Reloj**: un PDC con `Type NT5DS` sin fuente va en «Free-running» (iba ~4 min atrasado). Rompe el TOTP y acerca a Kerberos al límite de 5 min. Configurarle NTP externo.
- **`ssh … powershell -EncodedCommand`** con un script largo da «exec request failed on channel 0»: subir el `.ps1` con tu herramienta de copia de ficheros y ejecutarlo con `-File`.
- **Scripts que corren como SYSTEM** (copias, tareas), tras 4 rondas de revisión de seguridad el 10/10:
  - La herramienta va en `C:\Program Files\<empresa>\…`, nunca en `C:\Tools` ni en `C:\Temp`: una carpeta nueva bajo `C:\` hereda Modificar para Usuarios autenticados.
  - Orden **crear → `icacls /setowner *S-1-5-32-544 /L` → `/inheritance:r` + SYSTEM y Administradores `/L` → comprobar**: sin junction, dueño Administradores y sin ACE de escritura ajena.
  - `icacls` **sigue los enlaces** salvo que lleve `/L`.
  - El dueño siempre puede cambiar la ACL: comprobar también el dueño, no solo las ACE.
  - Las carpetas de trabajo bajo `D:\` (Usuarios puede crear) se cierran desde el PADRE.
