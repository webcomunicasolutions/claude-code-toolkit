---
name: nuevo-proyecto
description: Arrancar un proyecto SIN código (documentos, gestión, clientes, ofertas, licitaciones, procesos) con la estructura de 3 capas (empresa/cliente/proyecto). Usar cuando se diga "monta un proyecto nuevo", "empezar proyecto sin código", "nuevo-proyecto", "crea la estructura del proyecto", o se quiera arrancar una carpeta de trabajo que NO es de código. NOT para proyectos de código (para eso usar /init).
---

# Nuevo proyecto (sin código)

Scaffolding para proyectos que NO son de código. `/init` no sirve aquí porque
autogenera documentación escaneando código; estos proyectos son de gestión,
documentos, clientes o procesos. Esta skill monta la estructura de 3 capas.

## Paso 1 — Entrevista breve (si no se dio en el prompt)

Preguntar solo lo que falte (máximo 4):
1. **Nombre / carpeta** del proyecto (kebab-case) y dónde va (por defecto `~/proyectos/...`).
2. **De qué va** en 2-4 frases (contexto suficiente para el CLAUDE.md).
3. **Objetivo** / a dónde se quiere llegar.
4. **¿Hay convención de carpetas repetible?** (p.ej. "una carpeta por oferta/cliente/mes"). Si no, estructura plana.

Si el usuario ya lo explicó, NO volver a preguntar: usar lo dado.

## Paso 2 — Crear la estructura

Crear la carpeta y, dentro, las 3 capas:

| Fichero | Contenido |
|---|---|
| `CLAUDE.md` | Corto. Instrucciones ACTIVAS: qué es, cómo trabajar aquí, convenciones, líneas rojas, punteros a datos clave. Objetivo < 40 líneas. |
| `README.md` | Índice humano: qué es, estructura, flujo de trabajo, tabla de estado. |
| (subcarpetas) | Solo si hay convención repetible. Crear una carpeta de ejemplo. |

La **memoria** del proyecto (`~/.claude/projects/<...>/memory/`) NO se crea a mano:
se va poblando automáticamente según se trabaja (datos fijos, convenciones, estado).
Si desde el inicio hay datos fijos reutilizables, crear la primera memoria + `MEMORY.md`.

## Paso 3 — Plantillas

**CLAUDE.md** (adaptar):
```markdown
# CLAUDE.md — <Nombre del proyecto>
<Una frase de qué es>. Guía y estado en `README.md`.

## Contexto
<2-4 frases>

## Flujo de trabajo (seguir siempre)
1. ...
2. ...

## Línea roja / reglas no negociables
- ...
```

**README.md** (adaptar):
```markdown
# <Nombre del proyecto>
<Descripción>.

## Estructura
<árbol o convención de carpetas>

## Flujo de trabajo
1. ...

## Índice / estado
| Elemento | ... | Estado |
|---|---|---|
```

## Paso 4 — Cerrar

- Confirmar al usuario la estructura creada (árbol con `find`).
- Recordar que la identidad global (quién es) ya vive en `~/.claude/CLAUDE.md`,
  así que NO se duplica en el proyecto (solo datos específicos del proyecto).

## Qué NO hacer
- NO usar `/init` (es para código).
- NO inflar el `CLAUDE.md` del proyecto: instrucciones, no relleno.
- NO meter la identidad global del usuario en el proyecto (ya es global).
- NO crear credenciales sueltas; punteros al vault `~/.credentials/`.

## Auto-mejora

Al cerrar cada aplicación práctica de esta skill:
1. Si surge un tipo de proyecto sin código nuevo (con su patrón de carpetas), añadir
   el patrón como ejemplo aquí.
2. Si una plantilla se queda corta o sobra, ajustarla en el cuerpo del SKILL.md.
3. Registrar gotchas (p.ej. rutas, permisos Syncthing en `~/.claude/skills`).

Sin esta fase, la skill se fosiliza.
