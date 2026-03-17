---
description: Auditar y optimizar el proyecto actual para Claude Code - reduce CLAUDE.md, crea memorias, reglas, limpia estructura
---

# Project Optimizer

Ejecuta una auditoria completa del proyecto actual y lo optimiza para que Claude Code trabaje mejor.

## Instrucciones para Claude

El proceso completo es DIRIGIDO por el agente `claude-code-guide`. Este agente actua como arquitecto y revisor de todo el proceso de optimizacion.

### Paso 1: Diagnostico dirigido por claude-code-guide

Lanza un agente `claude-code-guide` con el siguiente prompt:

> Analiza el proyecto en [DIRECTORIO_ACTUAL] desde la perspectiva de buenas practicas de Claude Code.
>
> Lee CLAUDE.md completo y evalua:
> 1. Tamano y estructura de CLAUDE.md (objetivo: <150 lineas)
> 2. Credenciales expuestas (passwords, tokens, API keys en texto plano)
> 3. Existencia y calidad de reglas modulares (.claude/rules/)
> 4. Existencia y calidad de memorias (~/.claude/projects/.../memory/)
> 5. .gitignore (existencia y completitud)
> 6. Archivos sueltos, backups, temporales en raiz
> 7. Estructura general del proyecto
>
> Genera un informe con formato:
> ```
> === DIAGNOSTICO DEL PROYECTO ===
> CLAUDE.md: [N] lineas ([OK <200 / MEDIO 200-400 / CRITICO >400])
> Credenciales expuestas: [N] ([donde])
> Archivos sueltos en raiz: [N]
> Backups/temporales: [N]
> Memorias: [SI/NO] ([N] archivos)
> Reglas modulares: [SI/NO] ([N] archivos)
> .gitignore: [OK/FALTA/INCOMPLETO]
> PUNTUACION: [X]/10
> ```
>
> Luego genera un PLAN DE MEJORAS detallado con:
> - Que secciones de CLAUDE.md mover a reglas (con globs sugeridos)
> - Que secciones mover a memorias (con tipo sugerido)
> - Que credenciales extraer a .credentials.json
> - Que archivos limpiar
> - Estructura final esperada de CLAUDE.md (<150 lineas)
>
> El plan debe ser especifico: indica nombres de archivos, contenido a mover, globs para reglas.

Mostrar el informe y plan al usuario. **Esperar confirmacion antes de continuar.**

### Paso 2: Ejecucion de mejoras

Tras confirmacion del usuario, lanzar un agente `general-purpose` para ejecutar el plan generado por claude-code-guide:

- Crear `.credentials.json` con credenciales extraidas
- Crear/actualizar `.gitignore`
- Crear reglas en `.claude/rules/` con globs (segun plan de claude-code-guide)
- Crear memorias en `~/.claude/projects/.../memory/` (segun plan de claude-code-guide)
- Mover archivos sueltos/backups a `_pendiente_borrado/`
- Reescribir CLAUDE.md reducido (<150 lineas)

### Paso 3: Revision final por claude-code-guide

Lanzar de nuevo al agente `claude-code-guide` para revisar TODO el trabajo ejecutado:

> Revisa la optimizacion completada en [DIRECTORIO_ACTUAL].
>
> Lee y evalua TODOS los archivos creados/modificados:
> - CLAUDE.md (debe ser <150 lineas, sin credenciales)
> - .credentials.json (debe existir y tener las credenciales)
> - .gitignore (debe proteger archivos sensibles)
> - Cada archivo en .claude/rules/ (globs correctos, contenido completo, separacion de concerns)
> - Cada archivo en memory/ (frontmatter correcto, tipos apropiados, MEMORY.md como indice)
>
> Genera un informe final:
> ```
> === REVISION FINAL ===
> CLAUDE.md: [PASS/FAIL] - [N] lineas, [observaciones]
> Credenciales: [PASS/FAIL] - [observaciones]
> Reglas: [PASS/FAIL] - [N] archivos, [observaciones sobre globs y contenido]
> Memorias: [PASS/FAIL] - [N] archivos, [observaciones sobre tipos y formato]
> .gitignore: [PASS/FAIL] - [observaciones]
> Estructura: [PASS/FAIL] - [observaciones]
>
> PUNTUACION FINAL: [X]/10
> PROBLEMAS A CORREGIR: [lista si hay]
> ```
>
> Si hay problemas, listalos con solucion concreta.

Si claude-code-guide reporta problemas, corregirlos y volver a verificar.

Mostrar resumen final al usuario:
```
=== OPTIMIZACION COMPLETADA ===
CLAUDE.md: [antes] -> [despues] lineas
Credenciales: [N] movidas a .credentials.json
Reglas creadas: [N] archivos en .claude/rules/
Memorias creadas: [N] archivos
Puntuacion: [antes]/10 -> [despues]/10
Revision claude-code-guide: APROBADO
```

## Referencia completa
El skill `project-optimizer` en `~/.claude/skills/project-optimizer/SKILL.md` tiene el procedimiento detallado con todas las fases, criterios de puntuacion y formatos.
