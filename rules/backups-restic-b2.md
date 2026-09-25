# Backups restic + Backblaze B2 — estándar único (LEY)

Regla nacida de una decisión explícita: en todos los servidores, Windows y Linux, donde se ponga restic y
Backblaze debe implementarse lo mismo — avisos, prueba, todo igual. Un estándar que se ha ido puliendo
servidor a servidor y que merece mantenerse.

Aplica a **todo** despliegue de restic (con B2 o con repositorio local), tanto si son unos pocos
servidores como una flota de decenas de buckets.

## Los 8 innegociables

Un backup no está terminado hasta que los ocho están puestos **y demostrados con salida real**:

1. **Bucket privado**, key de aplicación **restringida a ese bucket** con Read+Write.
2. **Object Lock habilitado SIN retención por defecto.** Con retención, restic falla en cada
   copia (no puede borrar su fichero de lock) y `forget --prune` deja de rotar. No se puede
   deshabilitar después: acertar a la primera.
3. **Contraseña del repositorio en el vault** + copia cifrada fuera del equipo + **en papel**.
   Sin ella no hay recuperación posible, jamás. Y **el fichero de credenciales del servidor se
   excluye de la propia copia**.
4. **Retención escalonada**, no solo días: `--keep-last N --keep-daily 30 --keep-weekly 12
   --keep-monthly 24 --keep-yearly 5`. El daño que arruina a un cliente es el silencioso
   (una ficha borrada meses atrás que se echa en falta después), no el visible.
5. **Aviso inmediato por mensajería (Telegram u otro) cuando falla.** El éxito NO se anuncia de
   madrugada: se entierra y se deja de mirar. El éxito lo comunica un **informe diario a hora
   humana**.
6. **Verificación real de datos**: `restic check --read-data-subset=N%` periódico. El `check`
   a secas solo valida la ESTRUCTURA: un repositorio puede pasarlo con los datos corruptos.
7. **Prueba de restauración automática y periódica**, con **fichero canario** de hash conocido
   escrito antes de cada copia (los ficheros vivos cambian y no sirven de semáforo). Copia que
   no se restaura es copia que no se sabe si funciona.
8. **Vigilante externo** (desde fuera del propio servidor vigilado) que comprueba a
   diario la antigüedad del último snapshot. Es lo ÚNICO que detecta el **silencio** —servidor
   apagado, tarea desactivada—, que por definición ninguna alerta local puede detectar.

## Gotchas ya pagados (no volver a descubrirlos)

- **restic guarda las rutas de Windows como `/C/Carpeta/x.mdb`**, no `C:\Carpeta\x.mdb`. Un
  `--include 'C:\...'` restaura **0 ficheros y devuelve exit 0**: parece que fue bien.
- **Windows: `--use-fs-snapshot` (VSS) obligatorio** si hay bases de datos o ficheros abiertos.
  Y la tarea programada corre como **SYSTEM**, que es quien puede crear la instantánea.
- **Cuentas del sistema por SID, nunca por nombre**: en Windows en español
  `icacls /grant "NETWORK SERVICE:..."` falla y **icacls NO lanza excepción**. Usar `*S-1-5-20`,
  `*S-1-5-32-544`, `*S-1-5-18`, comprobando `$LASTEXITCODE`.
- **`2>&1` sobre un comando nativo con `$ErrorActionPreference='Stop'` lanza excepción** por cada
  línea de stderr: un aviso cosmético posterior al trabajo reporta como FALLIDO un backup bueno.
  Envolver restic en una función que ponga `Continue`.
- **El veredicto se lee del TEXTO** (`"no errors were found"`), no del código de salida: restic
  devuelve 1 si luego falla al borrar su caché temporal. Exit 3 = ficheros en uso → aviso, no fallo.
- **TLS 1.2 forzado** antes de llamar a APIs externas de mensajería (Server 2012 R2 negocia
  TLS 1.0 y muchas APIs modernas lo rechazan).
- **Borrar las credenciales del entorno en el `finally`** del script.
- **Un backup bueno anunciado como fallido es tan dañino como el contrario**: se acaba ignorando
  la alerta. Distinguir siempre "con avisos" de "roto".

## Qué hacer al tocar CUALQUIER servidor con restic

1. Comprobar los 8 puntos **contra la realidad** (`restic snapshots`, la tarea/cron, el bucket),
   no contra la ficha del proyecto.
2. Si falta alguno, **decírselo al usuario en ese momento**, aunque la sesión fuera de otra cosa.
3. No dar por bueno un backup por que exista la carpeta, la tarea o la ficha: **contar snapshots**.
4. Antes de experimentar con ajustes de bucket, probar en un bucket de pruebas dedicado, nunca en
   el de un cliente.
