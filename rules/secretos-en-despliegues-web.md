# Secretos en despliegues web — el .env NUNCA dentro del docroot (LEY)

Regla nacida de un incidente real: en un proyecto desplegado, el fichero `.env` estaba en la carpeta
que sirve el servidor web y **fue descargado por internet**. El log del servidor lo probó: una petición
`GET /.env` con código 200 y user-agent de un **escáner PÚBLICO de fugas** que además indexa y publica lo que
encuentra —y varias descargas más en los días siguientes, ya con navegador. Dentro iban: password de BD,
secreto de un segundo factor, clave de cifrado de datos sensibles, y tokens de API. Un `.env` expuesto lo
encuentra un bot **en horas, no en meses**.

El barrido posterior de todos los dominios propios del mismo operador encontró **varios proyectos más** con
el mismo fallo y **un repositorio `.git` accesible**. No era un caso aislado: era el patrón por defecto.

## La ley

**En cualquier despliegue basado en contenedores (Docker/EasyPanel/similar), las credenciales van en la
sección de VARIABLES DE ENTORNO del servicio — nunca como fichero `.env` dentro de la carpeta que sirve el
servidor web.**

El panel de despliegue inyecta las variables en el contenedor fuera del árbol web: no hay fichero que
descargar, no aparecen en el docroot y sobreviven a los redespliegues.

En PHP se leen con `getenv('CLAVE')` / `$_ENV['CLAVE']`. Si el proyecto ya tiene un parser de `.env`
propio, hacer que **priorice el entorno** y deje el fichero solo como fallback de desarrollo local:

```php
function config(string $clave, ?string $defecto = null): ?string {
    $v = getenv($clave);
    return ($v !== false && $v !== '') ? $v : $defecto;   // entorno primero
}
```

## Checklist obligatorio en CADA despliegue web (antes de dar por bueno)

1. **Credenciales como variables de entorno del servicio.** Si por lo que sea tiene que existir un
   fichero `.env`, va **fuera del docroot** (un nivel por encima) y montado como bind aparte.
2. **Bloquear ocultos y backups en el árbol web** desde el primer despliegue (defensa en profundidad,
   aunque ya uses variables de entorno):
   ```apache
   Options -Indexes
   <FilesMatch "^\.">
       Require all denied
   </FilesMatch>
   <FilesMatch "\.(bak|ejemplo|example|sql|log|old|orig|save|swp|inc)$">
       Require all denied
   </FilesMatch>
   <FilesMatch "\.bak_">
       Require all denied
   </FilesMatch>
   ```
3. **Nada de `.bak` en el docroot.** Al editar en caliente, los backups van FUERA del árbol web,
   nunca junto al fichero original.
4. **Ni `.git` ni `.env.ejemplo` publicados.** Un `.git` accesible permite reconstruir todo el código
   y su historial (incluidos secretos ya "borrados").
5. **Verificación final OBLIGATORIA — TRES comprobaciones, no una.** La primera mide el síntoma;
   las otras dos, la causa. Un proyecto puede pasar la primera con el fichero dentro del docroot,
   tapado por un `.htaccess` que el siguiente redespliegue borra.
   ```bash
   # 1. Desde fuera: nada sensible se sirve
   for f in .env .env.ejemplo .env.bak .git/HEAD config.php.bak composer.json composer.lock; do
     curl -s -o /dev/null -w "%{http_code}  /$f\n" "https://<dominio>/$f"
   done      # 403/404 en TODOS. Un 200 es fuga: parar y arreglar (mirando el CUERPO, ver más abajo).

   # 2. Dentro del servidor: el fichero NO EXISTE (tiene que salir vacío)
   ssh <host> 'find /ruta/al/proyecto/<servicio>/html -maxdepth 1 -name ".env*" -o -maxdepth 1 -name "*.bak*"'

   # 3. Dentro del contenedor: las credenciales SÍ están en el entorno
   ssh <host> 'docker inspect $(docker ps -q -f name=<servicio>) --format "{{range .Config.Env}}{{println .}}{{end}}" | cut -d= -f1'
   # Si solo salen PORT, TZ, GIT_SHA y DEPLOY_TIMESTAMP, las credenciales vienen del fichero.
   ```
   **Por qué las tres**: al revisar los servicios de un incidente real, desde fuera **todo daba
   403** y la comprobación 1 pasaba en todos. Por dentro, un servicio tenía **cero
   credenciales en el entorno y todas en el fichero**, más **varias copias del `.env`** de la noche
   de una rotación con secretos vivos. Nada de eso lo ve un `curl`.

   Para varios dominios a la vez, automatizar el bucle curl anterior sobre una lista de dominios y
   resolver el veredicto por CONTENIDO, no por código HTTP (ver gotcha siguiente).

## Gotcha al auditar: el 200 puede ser FALSO POSITIVO

Los paneles de administración, herramientas de automatización y cualquier SPA responden **200 con su HTML** a
cualquier ruta inventada. En un barrido real, de varios dominios que dieron 200, la mayoría eran falsos
positivos. Nunca reportar una fuga por el código HTTP: **mirar el contenido**. Es fuga real solo si el cuerpo
son líneas `CLAVE=VALOR` (o `ref: refs/heads/...` en `/.git/HEAD`); si empieza por `<!DOCTYPE`/`<html>`, es la
app respondiendo.

## Si ya ha pasado (fuga confirmada)

1. **Tapar** (bloquear el acceso) y verificar con `curl` que ya da 403.
2. **Mirar el log** de accesos y buscar peticiones con **200** a ese fichero: `docker logs <cont> | grep "GET /.env"`.
   Un user-agent de scanner conocido, o navegadores repetidos = descarga confirmada.
3. **Si hubo 200 externo, los secretos están comprometidos: hay que ROTARLOS**, no basta con tapar.
   Backup del `.env` y **dump de la BD antes** (si alguna clave cifra datos, hay que re-cifrar).
4. Avisar a los proyectos que consuman esos tokens **antes** de invalidar el viejo.
5. Registrar el incidente con fechas y evidencia.

Complementa `credentials-handling.md` (vault, punteros) y `security.md`.
