---
name: seguridad-web
description: Auditar y securizar una web propia (PHP clasico + MySQL, desplegada en EasyPanel/Docker o en un servidor de cliente) de principio a fin - revision adversarial del codigo por un agente independiente, pruebas EN VIVO con script (cabeceras, cookies, CSRF, fugas, errores PHP, puertos), cumplimiento de las pautas de estilo del proyecto, arreglo con pruebas de regresion y redespliegue. Es la ultima puerta del flujo de desarrollo web (codigo, interfaz, despliegue). Usar cuando se diga "esta bien securizada la web?", "revisa la seguridad", "audita la web", "securiza", "antes de darsela al cliente", o al terminar un despliegue. Tambien cuando un antivirus (Kaspersky u otro) bloquea o marca como phishing una web recien publicada. NOT para intrusiones o vigilancia de un servidor Linux (server-security-watch), ni para probar funcionalidad rol a rol.
---

# seguridad-web — la ultima puerta antes de dar una web por buena

Nace de la auditoria de un panel interno de gestion (septiembre 2026): la web "funcionaba" y tenia 221 pruebas en verde, y
aun asi la revision encontro **inyeccion de formulas en las exportaciones con 135 datos reales afectados,
un CSRF que se saltaba con token vacio y sin cabeceras anti-iframe**. Ninguna prueba funcional mira eso.

**Principio:** una web no esta segura porque el codigo "parezca" bien. Lo esta cuando un revisor
independiente ha intentado romperla, las pruebas en vivo pasan contra el entorno REAL y cada fallo
encontrado tiene una prueba de regresion en el arnes del proyecto.

## Donde encaja

```
codigo  →  interfaz  →  despliegue (EasyPanel/Docker o servidor del cliente)
        →  seguridad-web  ← ESTA SKILL (ultima fase, y tras cada despliegue gordo)
```
- Las reglas de COMO programar seguro viven en tus pautas de estilo del proyecto y en tus reglas de seguridad.
  Esta skill **comprueba** que se cumplen; no las repite.
- Las fugas de `.env` / `.git` al desplegar: las 3 comprobaciones estan dentro de la fase 2 de aqui.

## Las 4 fases (en orden, con criterio de "hecho")

### Fase 1 — Revision del codigo por un agente INDEPENDIENTE
- Agente `security-reviewer`, **modelo Sonnet**, en segundo plano. Prompt: `plantillas/prompt_revision_codigo.md`
  (rellenar rutas, despliegue y que datos guarda la web). Es ADVERSARIAL: "intenta refutar que es segura".
- En paralelo, agente `code-reviewer` (Sonnet) con `plantillas/prompt_cumplimiento_pautas.md`.
- Mientras trabajan, yo hago la fase 2.
- ✅ Hecho cuando: los dos informes estan en fichero, declaran **cuantos ficheros leyeron de cuantos**
  y **yo he verificado contra el codigo** cada hallazgo critico/alto/medio (un agente que dice "critico" no es evidencia).

### Fase 2 — Pruebas EN VIVO contra el entorno real
```bash
~/.claude/skills/seguridad-web/scripts/auditar_en_vivo.sh https://<dominio>            # web publica
~/.claude/skills/seguridad-web/scripts/auditar_en_vivo.sh http://127.0.0.1:9192 login.php  # por tunel ssh -L
```
Solo lectura y peticiones inofensivas: cabeceras de seguridad, flags de la cookie, HTTPS/HSTS, ficheros
que NO deben servirse (`.env`, `.git`, `.bak`, `composer.*`, `phpinfo`...), listado de carpetas, errores PHP
visibles, **POST sin token CSRF** (debe dar 4xx) y API sin token. El POST sin token no llega a comprobar
credenciales si el CSRF funciona, asi que no bloquea a nadie.

Ademas, en el servidor (a mano, ver `aprendizajes/auditoria-1-panel-interno.md`):
- Puertos escuchando (`ss -ltn`): la BD NUNCA publicada.
- Credenciales en el ENTORNO del contenedor y ningun `.env` en el docroot (las 3 comprobaciones de la fase 2).
- `display_errors` apagado en el PHP que sirve la web.
- ✅ Hecho cuando: el script da `0 FALLAS` o cada FALLA esta en la lista de arreglos o aceptada por el responsable por escrito.

### Fase 3 — Lista unica de arreglos y decision
Juntar fase 1 + fase 2 en UNA tabla: `# · que · gravedad · evidencia (fichero:linea o salida) · arreglo`.
Enseñarla al responsable y preguntar lo que es decision suya (HTTPS en una LAN, excepciones de estilo). Lo que
sea decision se escribe en el `CLAUDE.md` del proyecto ("Excepciones escritas").

### Fase 4 — Arreglar, probar y redesplegar
- Arreglos en el codigo del proyecto (nunca en caliente en el servidor).
- **Cada fallo de seguridad arreglado lleva su comprobacion en el arnes** del proyecto, con un DATO REAL
  que lo dispare (p. ej. la razon social "+ TAPAS..." para las formulas CSV).
- Arnes completo **dos veces** en verde, commit, despliegue versionado, y `auditar_en_vivo.sh` otra vez
  contra el entorno real.
- ✅ Hecho cuando: arnes 2/2 en verde, fase 2 en verde contra produccion, commit y etiqueta de despliegue.

## Fallos que YA se han encontrado en webs reales (buscarlos siempre)

| Fallo | Como se detecta | Arreglo |
|---|---|---|
| **Formulas en CSV/Excel** (`= + - @` al inicio de una celda) | `grep -rn fputcsv` sin neutralizar; datos reales que empiezan por esos signos | Funcion unica `fila_csv_segura()`: anteponer `'`, **salvo numeros** (`-1234,56` debe seguir sumando) |
| **CSRF con token vacio** | `hash_equals($_SESSION['csrf'] ?? '', $_POST['csrf'] ?? '')` → con sesion nueva, `''==''` pasa | Rechazar si el token guardado esta vacio. Prueba: POST sin token con sesion nueva → 400 |
| **Sin cabeceras anti-iframe / nosniff** | `curl -D -` sin `X-Frame-Options` | En PHP, en el fichero que cargan TODAS las paginas (no depender de mod_headers ni tocar el .htaccess) |
| `.env` en el docroot | 3 comprobaciones de la fase 2 | Variables de entorno del servicio |
| Autorizacion solo en el menu | Pedir por URL una pagina/export de otro rol | `exigir_rol()` en cada controlador |
| Exportacion masiva de datos personales | Export sin filtro para cualquier rol | Exigir periodo ACOTADO (un ejercicio; `desde=1900` no vale) o rol de gestion, y auditar |
| **Alta del 2FA con solo la contraseña** | Usuario con 2FA sin activar: ¿el login enseña el secreto? | Ventana de alta que abre un admin, con caducidad |
| **Sesion que sobrevive a desactivar/degradar** | Desactivar en BD con la sesion abierta → ¿sigue entrando? | Releer activo y rol en cada peticion + caducidad absoluta |
| **Carrera en el bloqueo del login** | N logins en paralelo → ¿se evaluan mas de 5? | `GET_LOCK` por IP (y fuera de cualquier cache de consultas) |
| **Codigo TOTP reutilizable** | El mismo codigo en dos sesiones | Guardar el ultimo paso de 30 s aceptado por usuario |
| CSP minima | `curl -D -` → solo `frame-ancestors` | `default-src 'self'` sin nada inline; probar con navegador real (consola) |

## Tras publicar un dominio NUEVO con login: antivirus
Los antivirus meten en su lista negra los dominios nuevos con formulario de login («phishing», detectado por
«bases de datos»). Paso con un panel interno nuevo (29/09/2026) y Kaspersky lo quito en ~4 h al pedirlo. Guia completa, con
excepcion local, texto para opentip y como evitarlo: **`plantillas/antivirus-falso-positivo.md`**. Nada mas
publicar, buscar el dominio en opentip.kaspersky.com y en Google Safe Browsing.

## Gotchas

- **`printf ... | grep -q` con `set -o pipefail` da FALSO fallo** en textos grandes (SIGPIPE): usar
  `grep -q ... <<< "$VAR"`. Paso en el arnes de un panel real.
- `fputcsv` entrecomilla los campos con espacios: una prueba que busque `;'+ TAPAS` no casa, la celda es `"'+ TAPAS..."`.
- La skill nativa `/security-review` necesita repo con REMOTO (`origin/HEAD`): sin el falla. Esta skill no.
- **Cerrar el tunel `ssh -L` por su PID de puerto** (`lsof -t -iTCP:<p> -sTCP:LISTEN`), NUNCA con
  `pkill -f "...-L 9192..."`: el patron coincide con el propio shell y lo mata (paso al probar esta skill).
- Un 200 en `/.env` puede ser la SPA respondiendo: mirar el CUERPO (lo hace el script).
- No hacer fuerza bruta contra el login de produccion para "probar el bloqueo": bloquea a usuarios reales.
  El bloqueo se prueba en el arnes, en local.
- Referencia generica OWASP (Top 10, ASVS, API): https://owasp.org (aqui solo hace falta la lista del Top 10).

## Auto-mejora

Al cerrar cada auditoria:
1. Registrar el caso en `aprendizajes/<fecha>-<proyecto>.md` (que se encontro, que era falso positivo, cuanto costo).
2. Si aparece un tipo de fallo nuevo, añadirlo a la tabla "Fallos que YA hemos encontrado" y, si se puede
   detectar desde fuera, al script `auditar_en_vivo.sh`.
3. Si es una regla de COMO programar, subirla tambien a tus pautas de estilo (seccion de seguridad).

Sin esta fase, la skill se fosiliza y pierde valor con el tiempo.
