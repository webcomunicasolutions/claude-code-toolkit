---
name: contexto-claude-code
description: Decidir DONDE va cada instruccion en Claude Code segun la doctrina oficial de Anthropic (2026) - CLAUDE.md, .claude/rules/ (con y sin paths), skills, auto memory (MEMORY.md), hooks y settings. Usar cuando se este montando u optimizando el contexto de un proyecto o del harness global, cuando Claude "no hace caso" a una instruccion, cuando el CLAUDE.md crezca demasiado, o cuando alguien afirme que "CLAUDE.md ya no hace falta". NOT para escribir el contenido de las reglas en si (eso es del dominio del proyecto).
---

# Skill: Contexto de Claude Code (doctrina oficial)

## Proposito
Evitar dos errores caros: meter todo en CLAUDE.md (quema contexto y baja la
adherencia) y creer bulos de YouTube sobre features deprecados. Aqui vive la
regla de decision de DONDE poner cada cosa, con las fuentes oficiales.

## Verdad verificada (2026-07-31, fuente: code.claude.com/docs/en/memory)

**CLAUDE.md NO esta deprecado.** La doc oficial vigente lo documenta como uno de
los dos mecanismos de memoria, y lo describe asi:

> "CLAUDE.md files: instructions you write to give Claude persistent context"
> "Auto memory: notes Claude writes itself based on your corrections and preferences"

Son **complementarios**, no sustitutos. Tabla oficial resumida:

| | CLAUDE.md | Auto memory (MEMORY.md) |
|---|---|---|
| Quien lo escribe | Tu | Claude |
| Que contiene | Instrucciones y reglas | Aprendizajes y patrones |
| Se carga | Entera, siempre | Primeras 200 lineas o 25 KB |
| Para | Estandares, workflows, arquitectura | Comandos de build, hallazgos de debug, preferencias detectadas |

**De donde sale el bulo**: en febrero de 2026 Anthropic anadio auto memory
(MEMORY.md). Divulgadores lo contaron como "ya no necesitas CLAUDE.md". Lo que
si cambio de verdad es el **tamano recomendado**, no la existencia:

> "Size: target under 200 lines per CLAUDE.md file. Longer files consume more
> context and reduce adherence."

Y `/doctor` (>= v2.1.206) ahora propone recortes: quita lo que Claude puede
deducir del codigo (arbol de directorios, listas de dependencias, resumen de
arquitectura) y conserva trampas, razones y convenciones que se desvian del
default de las herramientas.

## Arbol de decision: donde va esta instruccion

1. **¿Debe cumplirse SI O SI, pase lo que pase?** -> **hook** (`PreToolUse`,
   etc.) o `permissions.deny` en settings. CLAUDE.md es contexto, no un
   enforcement: la doc dice literalmente que se entrega como mensaje de usuario
   tras el system prompt y "there's no guarantee of strict compliance".
2. **¿Es un procedimiento multi-paso, o solo aplica a cierta tarea?** ->
   **skill**. Se carga solo cuando se invoca o cuando encaja con el prompt.
3. **¿Solo aplica a ciertos ficheros/rutas?** -> **rule con `paths:`** en
   `.claude/rules/`. Se carga solo cuando Claude toca esos ficheros.
4. **¿Es un hecho que debe estar presente en TODAS las sesiones?**
   (comandos de build, convenciones, layout, "siempre haz X") -> **CLAUDE.md**,
   por debajo de 200 lineas.
5. **¿Es algo que Claude deberia aprender solo de tus correcciones?** ->
   no lo escribas: deja que **auto memory** lo capture.

Regla mnemotecnica: *obligatorio -> hook; ocasional -> skill; por ruta -> rule
con paths; universal -> CLAUDE.md; aprendido -> auto memory.*

## Trampa importante: las rules SIN `paths` cuestan igual que CLAUDE.md

Cita oficial:

> "Rules without `paths` frontmatter are loaded at launch with the same priority
> as `.claude/CLAUDE.md`."

Es decir, trocear un CLAUDE.md gigante en `.claude/rules/*.md` **no ahorra ni un
token** si esas rules no llevan `paths`. Solo organiza. Lo mismo con los imports
`@fichero`:

> "Splitting into @path imports helps organization but doesn't reduce context,
> since imported files load at launch."

Ahorro real = `paths:` frontmatter, o mover a skill.

## Diagnostico rapido de un proyecto o del harness

```bash
# Coste fijo real de contexto (CLAUDE.md + rules siempre cargadas)
wc -l CLAUDE.md .claude/CLAUDE.md 2>/dev/null
grep -L "^paths:" .claude/rules/*.md 2>/dev/null | xargs wc -l 2>/dev/null | tail -1
# ^ las que salen aqui se cargan SIEMPRE

# Lo mismo para el harness global
wc -l ~/.claude/CLAUDE.md
grep -rL "paths:" ~/.claude/rules/*.md | xargs wc -l | tail -1
```

Dentro de una sesion:
- `/context` -> que ficheros de memoria se cargaron DE VERDAD (no lo que crees)
- `/memory` -> ver y editar CLAUDE.md, CLAUDE.local.md y la carpeta de auto memory
- `/doctor` -> propone recortes del CLAUDE.md versionado
- hook `InstructionsLoaded` -> loguea que se carga, cuando y por que

## Cuando "Claude no hace caso" a una instruccion

Orden de comprobacion (de la seccion Troubleshoot de la doc):
1. `/context` -> ¿esta el fichero bajo **Memory files**? Si no aparece, Claude no
   lo ve. Fin del diagnostico.
2. ¿Esta en una ubicacion que se carga para esa sesion? (los CLAUDE.md de
   subdirectorios NO se cargan al arrancar, solo cuando Claude lee ficheros ahi)
3. ¿Es especifica y verificable? "Usa indentacion de 2 espacios" > "formatea bien"
4. ¿Hay reglas contradictorias entre ficheros? Si dos chocan, Claude elige una
   arbitrariamente.
5. Si tiene que ocurrir en un momento fijo (antes de cada commit) -> **hook**, no
   instruccion.

Tras `/compact`: el CLAUDE.md de raiz se re-inyecta desde disco; los anidados no.

## Ubicaciones y orden de carga (de mas amplio a mas especifico)

| Ambito | Ruta |
|---|---|
| Politica gestionada | Linux/WSL: `/etc/claude-code/CLAUDE.md` (o `claudeMd` en managed-settings.json) |
| Usuario | `~/.claude/CLAUDE.md` |
| Proyecto | `./CLAUDE.md` o `./.claude/CLAUDE.md` |
| Local (gitignored) | `./CLAUDE.local.md` |

Todos se concatenan (no se sobrescriben); lo mas cercano al cwd se lee el ultimo.
En monorepos, `claudeMdExcludes` (glob sobre rutas absolutas) salta los CLAUDE.md
de otros equipos. Los de politica gestionada NO se pueden excluir.

`AGENTS.md`: Claude Code lee `CLAUDE.md`, no `AGENTS.md`. Si el repo ya usa
AGENTS.md, crear un CLAUDE.md con `@AGENTS.md` en la primera linea (o symlink).

## Auto memory: lo que hay que saber

- Activa por defecto. Off: toggle en `/memory`, `autoMemoryEnabled: false`, o
  `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`.
- Vive en `~/.claude/projects/<proyecto>/memory/`. La doc la describe como
  **local a la maquina** (Claude Code no la comparte entre equipos ni con la
  nube). Se puede sincronizar a proposito por Syncthing/backup, y **en el
  harness de este usuario YA se hace**: `~/.claude/` entera va por Syncthing y el
  `.stignore` incluye `projects/*/memory/` de forma explicita. Requisito para
  que empalme entre equipos: **misma ruta absoluta**, porque el nombre de la
  carpeta se deriva de ella (un slug derivado de tu ruta de proyectos). Si en otro
  equipo el usuario o la ruta cambian, la memoria queda en otra carpeta y no se
  ve.
- `MEMORY.md` es un INDICE: una linea por entrada, el detalle en ficheros de
  tema que se leen bajo demanda. Si el indice pasa de 200 lineas / 25 KB, lo que
  sobra **se descarta silenciosamente** en la siguiente carga.
- Los subagentes NO heredan la auto memory de la conversacion principal (salvo
  un fork). Pueden tener la suya con el campo `memory`.

## Antipatrones (vistos en la practica)

- Meter el arbol de directorios o la lista de dependencias en CLAUDE.md: Claude
  lo deduce del codigo, es contexto tirado.
- Trocear en `.claude/rules/` sin `paths:` creyendo que se ahorra contexto.
- Escribir "siempre haz X antes de commitear" en CLAUDE.md en vez de un hook, y
  luego sorprenderse de que a veces no pasa.
- Dejar crecer MEMORY.md por encima de 200 lineas y creer que Claude "recuerda"
  lo de abajo.
- Fiarse de un video de divulgacion sobre una feature sin contrastar con
  `code.claude.com/docs`. Lo de "CLAUDE.md ya no hace falta" es exactamente eso.

## Fuentes
- https://code.claude.com/docs/en/memory (canonica; todas las citas de arriba)
- https://code.claude.com/docs/en/skills
- https://code.claude.com/docs/en/changelog
- Nota: `docs.claude.com/en/docs/claude-code/*` redirige 301 a `code.claude.com/docs/en/*`

## Auto-mejora

Al cerrar cada aplicacion practica de esta skill:
1. Registrar aprendizajes en `aprendizajes/<caso>.md` (o en esta seccion si es breve)
2. Si cambia la doc oficial, re-verificar las citas contra code.claude.com/docs
   y actualizar la fecha de la seccion "Verdad verificada"
3. Si aparece otro bulo circulando, anadirlo a "Antipatrones" con la refutacion
