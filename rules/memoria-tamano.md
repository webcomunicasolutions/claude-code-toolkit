# MEMORY.md tiene un limite y al pasarlo se pierde memoria EN SILENCIO

Detectado en la práctica: el `MEMORY.md` de un proyecto llego a **25.936 bytes**
con el limite de carga en **24,4 KB**. El harness aviso de que solo habia cargado parte del fichero y
que habia **cortado 2 de 118 entradas**. Cada entrada nueva que se anadia arriba empujaba otra fuera
del contexto: **el indice que debe recordar las cosas llevaba tiempo sin cargarse entero.**

Al revisar todos los proyectos ese mismo día, aparecieron **dos más** en la misma situación (uno ya
cortándose, otro cerca del límite).

## La regla

**Al guardar sesion (`/save-session`) se comprueba el tamano, siempre:**

```bash
~/.claude/scripts/check_memory_size.sh                 # todos los proyectos
~/.claude/scripts/check_memory_size.sh <ruta/MEMORY.md>  # solo uno
```

(Script de referencia en la carpeta `scripts/` de este mismo kit.)

🟢 por debajo de 20 KB · 🟡 20-25 KB, compactar ya · 🔴 por encima de 25 KB, **ya se esta cortando**.

Si sale 🟡 o 🔴, **compactar antes de dar la sesion por guardada** y decirselo al usuario.

## Como se compacta sin perder nada

`MEMORY.md` es **solo un indice**: el contenido vive en los `.md` de la carpeta `memory/`.

1. Copia de seguridad: `cp MEMORY.md _MEMORY_backup_AAAAMMDD.md`.
2. Los punteros a sesiones guardadas antiguas se mueven a una memoria de "histórico de sesiones".
3. Cada entrada, **UNA linea de ~195 caracteres**: titulo, enlace y un gancho de por que importa.
4. Releer y comprobar que **las 3 primeras entradas** (las que mas se leen) quedan completas, no
   cortadas a mitad.

## Por que importa mas de lo que parece

Un `MEMORY.md` que no se carga entero es peor que no tenerlo: se cree que la regla o el dato estan
recordados cuando no han llegado al contexto. Es el mismo patron que la regla de credenciales
advierte con los punteros al vault: **una referencia rota es peor que ninguna referencia**.

## También las instrucciones: CLAUDE.md global + `rules/` + CLAUDE.md de proyecto

El harness tiene **otro tope para los ficheros de instrucciones** que se cargan en cada sesión (unos 150 K entre
CLAUDE.md global, `rules/` y los CLAUDE.md del proyecto). En un caso real se pasó a 157,6 K: una regla de delegación
había crecido a 47 K porque su diario de aprendizajes se apuntaba DENTRO de una regla que se carga siempre, y el
CLAUDE.md de un proyecto llevaba 24 K con todo el historial de versiones en una sola línea.

- `scripts/check_memory_size.sh` sin argumento mide las tres cosas: MEMORY.md de cada proyecto, la parte global
  (CLAUDE.md + `rules/`, aviso a 100 K y rojo a 120 K, y señala reglas de más de 10 K) y los CLAUDE.md de la carpeta
  de proyectos (`PROYECTOS_DIR`; aviso a 15 K, rojo a 20 K).
- **Lo que crece por diseño (diarios, casos, historiales) NO vive en lo que se carga siempre**: va a un fichero propio
  (`rules-ondemand/` en global, `HISTORIAL_*.md` en el proyecto) y en la regla o el CLAUDE.md queda el destilado + un puntero.
- Al compactar un CLAUDE.md de proyecto: copiar las líneas LITERALES al fichero de historial antes de recortar, y dejar
  solo la versión vigente y la anterior.
- Las reglas de lenguaje llevan `paths:` en el frontmatter para cargarse solo al tocar esos ficheros; las de lenguajes
  que no usas, mejor quitarlas (no se cargan nunca, pero ocupan inventario y confunden).
