# Credentials Handling

Cuando el usuario proporcione credenciales (passwords, tokens, API keys,
claves SSH, connection strings, OAuth secrets) en una conversacion o cuando
las detecte en archivos del proyecto, seguir este protocolo SIN excepciones.

## Vault global
Ubicacion unica: `~/.credentials/`
Permisos: `700` (solo el usuario)
Sincronizacion: la que use el usuario entre equipos (Syncthing, Dropbox privado, etc.)
Formato: JSON en texto plano
Schema: `~/.credentials/_schema.md`
Indice: `~/.credentials/INDEX.md`

## Estructura
```
~/.credentials/
  ├── INDEX.md              ← mapa humano de que hay donde
  ├── _schema.md            ← plantilla JSON estandar obligatoria
  ├── <proyecto>.json       ← un archivo por proyecto/dominio
  └── <categoria>/          ← subcarpetas si hay muchos proyectos
      └── <cliente>.json
```

## Reglas de oro

### 1. NUNCA hardcodear credenciales
- NO en codigo fuente (ni como "temporal")
- NO en docs, README, CLAUDE.md, comentarios
- NO en commits (ni siquiera "lo borro luego")
- NO en el mensaje de respuesta al usuario (enmascarar con `***`)

### 2. NUNCA crear `.credentials.json` suelto en un proyecto
Siempre symlink al vault:
```bash
cd <proyecto>
ln -s ~/.credentials/<archivo>.json .credentials.json
```

### 2 bis. En docs y skills va el PUNTERO, nunca el valor

Formato único, y **con la ruta relativa al vault, subcarpeta incluida**:

```
<vault clientes/<cliente>_proxmox.json → .databases.postgresql_<host>.password>
<vault <proyecto>.json → .rustdesk.vps_root.password>
```

Se lee cuando hace falta: `jq -r '<ruta>' ~/.credentials/<fichero>`.

⚠️ **Gotcha pagado:** un generador automático de punteros usó solo el
nombre del fichero y se comió la subcarpeta (p. ej. `clientes/`). Los punteros **no
resolvían**, y un puntero roto es peor que no tenerlo: parece que la credencial está
localizada cuando no lo está. **Validar siempre** los punteros creados:

```bash
jq -r '<ruta>' ~/.credentials/<fichero>   # debe devolver algo != null
```

Una revisión de este tipo puede destapar varias credenciales que llevaban tiempo en claro
fuera del vault (en configuración, en notas) sin que nadie se hubiera dado cuenta.

### 3. NUNCA inventar un schema nuevo
Usar siempre el schema de `~/.credentials/_schema.md`.
Secciones fijas: `_meta`, `ssh`, `servidores`, `databases`, `apis`,
`paneles`, `servicios`, `backups`, `_obsoletos`.

## Protocolo cuando el usuario da una credencial en el chat

1. **IDENTIFICAR** — ¿de que proyecto y que servicio es?
2. **CLASIFICAR** — ssh | api | database | panel | servicio | backup
3. **UBICAR** — ¿en que archivo del vault va? (si no existe, proponer crearlo)
4. **CONFIRMAR al usuario ANTES de escribir**:
   > "Voy a guardar <tipo> en `~/.credentials/<archivo>.json` seccion `<x>`"
5. **ESCRIBIR** con Edit/Write respetando el schema
6. **VERIFICAR** leyendo con `jq` que el JSON es valido
7. **AVISAR si se detecta duplicado** con otro archivo del vault
8. **NO repetir la credencial en el mensaje de respuesta** — enmascarar

## Protocolo al detectar secretos hardcodeados en archivos

Al leer/editar cualquier archivo del proyecto, si se detecta:
- `password\s*[=:]\s*["'][^"']+`
- `token\s*[=:]\s*["']ey[A-Za-z0-9]` (JWT)
- `api[_-]?key\s*[=:]\s*["'][A-Za-z0-9]{20,}`
- `Bearer\s+[A-Za-z0-9_\-\.]{20,}`
- `-----BEGIN .* PRIVATE KEY-----`
- `sshpass -p ['"][^'"]+`
- Cualquier string que parezca un secret

Se debe:
1. **PARAR** la tarea en curso
2. **AVISAR** al usuario: `<archivo>:<linea>` con el tipo de secret
3. **PROPONER** extraer al vault
4. **NO SEGUIR** hasta que el usuario decida

## Copia de seguridad del vault fuera del equipo

El vault vive en el equipo y entra en el backup normal, pero si ese backup vive en el
MISMO disco, perder el equipo significa perder también su única copia. Y si la contraseña
que abre ese backup solo vive en el propio equipo, el círculo se cierra: perdido el
portátil, no hay forma de recuperar nada.

La solución no depende de una herramienta concreta: cualquier **carpeta cifrada
zero-knowledge** (el proveedor no puede leer dentro) sirve para guardar ahí, en claro,
una copia de emergencia del vault completo. Lo importante:

- **Una sola carpeta propia** para todo lo que genere el asistente, no repartida dentro de
  las carpetas de cada cliente.
- Dentro: la contraseña maestra de recuperación + una copia comprimida del vault entero
  (rotando las últimas N copias) + una ficha por cliente que diga qué credencial está en
  qué fichero del vault.
- **La contraseña de ese backup cifrado debe existir también EN PAPEL, fuera del
  equipo.** Con ella se abre el backup → dentro está el vault → dentro están el resto de
  credenciales. Sin ella y sin el equipo, todo queda inaccesible de forma permanente si la
  herramienta de backup no tiene recuperación de contraseña.

⚠️ **Gotcha al copiar a una carpeta de red/nube desde WSL o similar**: algunas
herramientas de copia devuelven éxito (exit 0) sobre un fichero que **ya existe** en el
destino sin haberlo sobrescrito realmente. Los ficheros nuevos sí se crean, así que el
fallo pasa desapercibido y deja la copia de emergencia desactualizada creyendo que está al
día. Ni el hash inmediatamente después es fiable en todos los casos. Método seguro: mover
el fichero viejo a otra carpeta y copiar el nuevo como fichero NUEVO; verificar releyendo
tamaño y contenido. Nunca dar por buena una copia de este tipo sin comprobarlo.

Actualizar esta copia de emergencia a mano al añadir/rotar credenciales importantes; no es
automatizable si la carpeta cifrada solo está accesible mientras el usuario la desbloquea.

## Rotacion de credenciales

Cuando una credencial cambia (rotacion, reset, compromise):
- Mover la antigua a `_obsoletos` dentro del MISMO archivo del vault
- Anotar `rotada_en: YYYY-MM-DD` y `motivo`
- NO sobreescribir sin dejar rastro (los backups pueden necesitarla)
- Actualizar `_meta.actualizado`

## Acceso desde scripts

Leer con `jq` (funciona transparente con symlinks):
```bash
PASS=$(jq -r '.ssh.passwords.default' .credentials.json)
```

NUNCA pasar el password por linea de comandos visible en `ps`:
- MAL: `sshpass -p "$PASS" ssh ...`
- BIEN: `sshpass -f <(jq -r '.ssh.passwords.default' .credentials.json) ssh ...`
- O usar variables de entorno con scope limitado

## Cosas que NO se hacen

- NO inventar schemas nuevos por proyecto
- NO crear `.credentials.json` sueltos sin symlink al vault
- NO pedir al usuario que repita credenciales que ya estan en el vault
- NO tratar las credenciales del chat como "efimeras"
- NO escribir credenciales en CLAUDE.md, docs, comentarios o commits
- NO asumir que una credencial "provisional" va a quedar provisional
- NO repetir credenciales en los mensajes de respuesta (enmascarar `***`)

## Casos especiales

### Credenciales PENDIENTES
Si el usuario dice "aun no tengo el password de X":
- Guardar en el vault con valor `"PENDIENTE: <motivo>"`
- NO dejar `""` vacio (dificil de detectar despues)

### Credenciales de terceros muy sensibles
Tokens OAuth o API keys de servicios con acceso amplio:
- Guardar en el vault normal
- Anadir en `_meta.descripcion` una nota: "CRITICA - compromise = acceso total a X"
- Considerar en el futuro mover a vault encriptado con sops+age

### Credenciales compartidas entre proyectos
Si el mismo secret aplica a N proyectos:
- Guardarlo UNA sola vez en el archivo del proyecto "dueno"
- Los demas proyectos hacen symlink al mismo archivo O referencian por nota
- Al rotar, se rota una vez y todos quedan actualizados
