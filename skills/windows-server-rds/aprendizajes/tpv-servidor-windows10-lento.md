# Comercio con TPV/servidor Windows 10 + TSplus + MySQL 5.1 (agosto 2026)

Caso: Equipo con Windows 10 Pro 22H2 que hace de **TPV y servidor** a la vez
(ERP de gestion + TPV, MySQL 5.1.34 x64, TSplus 16.30, concentrador de surtidores).
Quejas de lentitud. Dos días de trabajo con acceso por SSH.

## Gotchas nuevos (probados en producción)

### Desplegar un `.ps1` creado en Linux a un Windows: tres trampas encadenadas
1. **Caracteres no-ASCII.** Un guion largo en un comentario, en UTF-8 **sin BOM**, lo lee
   Windows como CP1252 y se convierte en tres caracteres, **uno de ellos una comilla doble**.
   Esa comilla cierra un string y descoloca el parser entero (27 errores a partir de la línea 41).
   → `grep -P '[^\x00-\x7F]' script.ps1` debe dar **0**.
2. **Saltos LF.** Impiden cerrar un here-string (`@"..."@`) en PowerShell 5.1.
   → `sed 's/$/\r/'` antes del `scp`. Mejor aún: **no usar here-strings**, montar los textos con
   array + `-join`.
3. **Validar con `pwsh` 7 NO SIRVE**: tolera ambas cosas y el fallo aparece solo en el destino.
   → validar con Windows PowerShell 5.1 **en el servidor**:
   `[System.Management.Automation.Language.Parser]::ParseFile($ruta,[ref]$t,[ref]$e)`.

**Atajo que esquiva las tres:** enviar el script por `-EncodedCommand`
(`iconv -f UTF-8 -t UTF-16LE | base64 -w0`). No depende de encoding ni de saltos de línea.

### OpenSSH en Windows para una cuenta de administrador
La clave **no** se lee de `~/.ssh/authorized_keys` sino de
`C:\ProgramData\ssh\administrators_authorized_keys`, y el `icacls` hay que hacerlo **por SID**
(`*S-1-5-32-544`, `*S-1-5-18`): en un Windows en español `Administrators` no existe e **icacls
falla sin lanzar excepción**, dejando la clave ignorada en silencio.

### Sesiones que pierden el escritorio al reconectar
Síntoma: "cuando vuelvo a entrar por RDP nunca mantiene el escritorio".
Causa: `MaxDisconnectionTime` en
`HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services`. Estaba en **60000 ms = 1 minuto**.
`RDP-Tcp` tiene `fInheritMaxDisconnectionTime=1`, así que **hereda ese valor aunque figure como 0**.
Arreglo: 12 h (`43200000`). Solo tiene sentido si sobra RAM: las sesiones desconectadas la ocupan.

### El fondo de pantalla con TSplus
`Control Panel\Desktop\Wallpaper` **no basta**: TSplus repone el suyo
(`C:\wsession\WinXshell\wallpaper.jpg`) al iniciar sesión. Hay que usar la **política**
`HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System\Wallpaper` + `WallpaperStyle=2`.

### MySQL 5.1 en Windows
- **`innodb_buffer_pool_size = 4G` no arranca**; con **3G** arranca en 15 s. El techo está entre
  ambos. No deja rastro en el log: se cuelga antes de inicializar InnoDB.
- Nombre de usuario: **máximo 16 caracteres**.
- Con `skip-name-resolve` en `my.ini`, el host del usuario debe ser **`127.0.0.1`**, no `localhost`.
- `tmp_table_size` alto **no sirve de nada** sin subir también `max_heap_table_size`: el límite
  efectivo es el menor de los dos, y su valor por defecto son 16 MB.

### Esperar a que un servicio arranque
`Start-Sleep` fijo da falsos negativos y dispara rollbacks innecesarios. Comprobar que **acepta
conexiones** (`TcpClient.Connect`), no que el servicio figure como `Running`.

### Otros de PowerShell 5.1
`foreach(){...} | Format-Table` no es válido (envolver en `$( )`).
`New-LocalUser -Description`: máximo 48 caracteres.

## Método que funcionó

- **Antes de vigilar un proceso, confirmar en qué sesión está el usuario y qué ejecuta.** Perdí
  media hora vigilando `ProgramaTPV` (sesión 1, el TPV) cuando la usuaria trabajaba con
  `ProgramaGestion` (sesión 4, gestión). Distinto programa, distinta sesión.
- **Prueba A/B para demostrar una causa**: medir 90 s con el servicio sospechoso y 90 s sin él.
  Aquí destapó que un conector de facturación escaneaba 647.506 filas cada segundo y medio:
  CPU de mysqld 10,57 % → 0,07 %, filas leídas 34,6 M → 730 K, con **el mismo número de consultas**.
  Ese contraste (mismas consultas, 47× las filas) es lo que convence a un proveedor.
- **Slow query log a 2 s** activado en caliente (`SET GLOBAL`, se desactiva solo al reiniciar):
  es lo que da la consulta literal y el `Rows_examined`, que es la prueba del índice que falta.
- **Descartar con medidas antes de afirmar**: 10 min de vigilancia por segundo durante los
  episodios, registrando cualquier proceso que deje de responder. Cero anomalías = el servidor
  no es el culpable, y eso se puede decir con datos en vez de con impresiones.

## Cosas del cliente que conviene mirar siempre

- **¿El SAI tiene el cable de datos conectado?** Aquí había SAI pero Windows no veía ninguna
  batería: en un corte largo el equipo se va en seco igual. 9 apagados incorrectos en el SMART.
- **¿La copia lógica de la BD depende de que un programa esté abierto?** Aquí el dump diario lo
  lanzaba una aplicación de escritorio del ERP; alguien la cerró el 3 de agosto y estuvo 11 días
  sin copia sin que nadie se enterara.
- **Contar las vías de acceso remoto.** Había **16 servicios**: cada técnico que pasó en cinco
  años dejó el suyo. Identificar de quién es cada una leyendo su configuración
  (`client32.ini` → gateway, `MeshAgent.msh` → MeshServer) antes de proponer quitar nada.
- **Exclusiones de Defender sobre la carpeta de datos de la BD**: aquí no había ninguna.
