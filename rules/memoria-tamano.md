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
