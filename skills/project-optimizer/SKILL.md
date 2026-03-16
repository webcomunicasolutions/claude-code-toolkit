---
name: project-optimizer
description: Audita y optimiza cualquier proyecto para Claude Code - reduce CLAUDE.md, crea memorias, reglas modulares, limpia estructura y elimina credenciales expuestas. Usar cuando se quiera optimizar un proyecto para que Claude Code trabaje mejor con el.
triggers:
  - "optimiza el proyecto"
  - "optimizar para claude"
  - "revisa el proyecto"
  - "mejora el proyecto para ti"
  - "project audit"
  - "audit claude"
---

# Project Optimizer para Claude Code

Audita y optimiza cualquier proyecto para que Claude Code trabaje de forma mas eficiente: menos tokens consumidos, mejor organizacion, credenciales seguras.

## Workflow Completo

Ejecutar las 6 fases en orden. Cada fase genera un informe antes de actuar.

---

## FASE 1: Diagnostico (solo lectura)

Analizar el estado actual del proyecto SIN hacer cambios.

### 1.1 Analizar CLAUDE.md
```bash
wc -l CLAUDE.md  # Objetivo: < 200 lineas
```

Evaluar:
- **Tamano**: < 200 lineas = OK, 200-400 = MEDIO, > 400 = CRITICO
- **Credenciales**: Buscar passwords, tokens, API keys en texto plano
- **Contenido innecesario**: Changelogs, ejemplos largos, procedimientos que deberian ser reglas
- **Duplicacion**: Info que ya esta en otros archivos del proyecto

### 1.2 Buscar credenciales expuestas
```bash
# En CLAUDE.md
grep -iE "(password|passwd|token|api.?key|secret|sshpass)" CLAUDE.md

# En settings
grep -riE "(password|passwd|token|api.?key|secret)" .claude/

# En reglas
grep -riE "(password|passwd|token|api.?key|secret)" .claude/rules/ 2>/dev/null
```

### 1.3 Evaluar estructura del proyecto
```bash
# Archivos sueltos en raiz
ls -la *.py *.ps1 *.sh *.js *.ts 2>/dev/null | wc -l

# Directorios vacios
find . -maxdepth 2 -type d -empty 2>/dev/null

# Archivos backup/temporales
find . -maxdepth 2 \( -name "*.bak" -o -name "*.old" -o -name "*.backup*" -o -name "*.old-*" \) 2>/dev/null

# Directorios potencialmente duplicados
ls -d */ | sort
```

### 1.4 Verificar sistema de memoria
```bash
# Verificar si existe MEMORY.md para este proyecto
MEMORY_DIR=$(find ~/.claude/projects/ -path "*$(basename $PWD)*" -name "memory" -type d 2>/dev/null)
ls "$MEMORY_DIR"/ 2>/dev/null || echo "Sin sistema de memoria"
```

### 1.5 Verificar reglas modulares
```bash
ls .claude/rules/ 2>/dev/null || echo "Sin reglas modulares"
```

### 1.6 Verificar .gitignore
```bash
cat .gitignore 2>/dev/null || echo "Sin .gitignore"
# Verificar que excluye: .credentials*, .env, *.key, *.pem
```

### 1.7 Generar informe de diagnostico

Mostrar al usuario un informe con este formato:

```
=== DIAGNOSTICO DEL PROYECTO ===

CLAUDE.md: [N] lineas ([OK/MEDIO/CRITICO])
Credenciales expuestas: [N] encontradas ([ubicaciones])
Archivos sueltos en raiz: [N]
Backups/temporales: [N] archivos
Directorios vacios: [N]
Sistema de memoria: [SI/NO] ([N] archivos)
Reglas modulares: [SI/NO] ([N] archivos)
.gitignore: [OK/FALTA/INCOMPLETO]
settings.local.json: [OK/TIENE CREDENCIALES/PERMISOS ROTOS]

PUNTUACION: [X]/10
ACCIONES RECOMENDADAS: [lista priorizada]
```

**Esperar confirmacion del usuario antes de continuar.**

---

## FASE 2: Credenciales (seguridad primero)

### 2.1 Crear/actualizar archivo seguro de credenciales

Si no existe `.credentials.json` (o equivalente), crearlo:
```json
{
  "descripcion": "Credenciales del proyecto - NO commitear",
  "credenciales": {}
}
```

### 2.2 Mover credenciales de CLAUDE.md y reglas al archivo seguro

Extraer passwords, tokens, API keys → `.credentials.json`
Reemplazar en CLAUDE.md por: "Credenciales en `.credentials.json`"

### 2.3 Limpiar settings.local.json

Buscar passwords hardcodeados en permisos allow/deny.
Buscar patrones de permisos rotos (lineas de bash partidas como if/then/fi).

### 2.4 Actualizar .gitignore

Asegurar que incluye:
```
.credentials.json
.env
*.key
*.pem
*.ppk
_pendiente_borrado/
*.bak
*.backup-*
```

---

## FASE 3: Reducir CLAUDE.md

### Objetivo: < 150 lineas

### Que MANTENER en CLAUDE.md:
- Objetivo del proyecto (2-3 lineas)
- Quick start (como empezar a trabajar)
- Tablas de referencia compactas (equipos, redes, configs)
- Reglas criticas (1 linea cada una con link a regla detallada)
- Links a documentacion
- Metodos de autenticacion (SIN credenciales)

### Que MOVER a `.claude/rules/`:
- Procedimientos paso a paso
- Metodologias detalladas
- Comandos por equipo/entorno
- Convenciones de codigo
- Guias de troubleshooting

### Que MOVER a memoria (`~/.claude/projects/.../memory/`):
- Contexto del proyecto (objetivos, arquitectura)
- Perfil del usuario
- Feedback y preferencias validadas
- Referencias externas (URLs, sistemas)
- Estado de equipos/servicios

### Que ELIMINAR:
- Changelogs (ya estan en CHANGELOG.md o git)
- Ejemplos de validacion pasados
- Lecciones aprendidas narrativas (convertir en feedback memories)
- Indices de documentacion largos (dejar tabla compacta)

### Proceso:
1. Leer CLAUDE.md completo
2. Clasificar cada seccion en: MANTENER / MOVER A REGLA / MOVER A MEMORIA / ELIMINAR
3. Crear reglas en `.claude/rules/` con frontmatter:
```yaml
---
description: Descripcion de cuando se activa esta regla
globs:
  - "patron/de/archivos/**"
---
```
4. Crear memorias en el directorio de memoria del proyecto
5. Reescribir CLAUDE.md solo con lo esencial
6. Verificar que el nuevo CLAUDE.md tiene < 150 lineas

---

## FASE 4: Sistema de memoria

### 4.1 Crear MEMORY.md (indice)
```
~/.claude/projects/-ruta-del-proyecto/memory/MEMORY.md
```

### 4.2 Crear memorias segun tipo

**project** - Info del proyecto no derivable del codigo:
- Objetivo, arquitectura, estado actual
- Decisiones tecnicas y su razon

**user** - Perfil del usuario:
- Rol, nivel tecnico, preferencias

**feedback** - Correccion/guia del usuario:
- Formato: regla + Why + How to apply

**reference** - Punteros a sistemas externos:
- URLs, dashboards, herramientas

### 4.3 Formato de cada archivo de memoria:
```yaml
---
name: nombre_descriptivo
description: Una linea - se usa para decidir relevancia
type: project|user|feedback|reference
---

Contenido de la memoria.

**Why:** Razon o contexto.
**How to apply:** Cuando y como usar esta info.
```

---

## FASE 5: Limpiar estructura

### Principio: NUNCA borrar directamente, mover a `_pendiente_borrado/`

### 5.1 Scripts sueltos en raiz
```bash
mkdir -p _pendiente_borrado/scripts_legacy
mv *.py *.ps1 *.sh _pendiente_borrado/scripts_legacy/ 2>/dev/null
```
(Solo si existen carpetas `scripts/` o similar donde deberian estar)

### 5.2 Archivos backup/temporales
```bash
mkdir -p _pendiente_borrado/backups
find . -maxdepth 1 \( -name "*.bak" -o -name "*.old*" -o -name "*.backup*" \) -exec mv {} _pendiente_borrado/backups/ \;
```

### 5.3 Informes one-time en raiz
Mover informes que ya cumplieron su funcion (STATUS-*, REPORT-*, etc.)

### 5.4 Directorios duplicados
Identificar y consolidar (ej: `diagnostico/` vs `diagnostics/`)

### 5.5 Directorios vacios
Listar y preguntar al usuario si borrar

### 5.6 Mostrar resumen al usuario
```
MOVIDOS A _pendiente_borrado/:
  - [N] scripts legacy
  - [N] backups
  - [N] informes one-time

CONSOLIDADOS:
  - [dir_viejo] → [dir_nuevo]

Quieres revisar antes de borrar definitivamente?
```

---

## FASE 6: Verificacion final

### 6.1 Contar lineas CLAUDE.md
```bash
wc -l CLAUDE.md  # Debe ser < 150
```

### 6.2 Buscar credenciales residuales
```bash
grep -riE "(password|passwd|token|api.?key|secret|sshpass)" CLAUDE.md .claude/rules/ 2>/dev/null
```

### 6.3 Verificar memorias creadas
```bash
ls ~/.claude/projects/*/memory/*.md 2>/dev/null
```

### 6.4 Verificar reglas creadas
```bash
ls .claude/rules/*.md 2>/dev/null
```

### 6.5 Informe final
```
=== OPTIMIZACION COMPLETADA ===

CLAUDE.md: [antes] → [despues] lineas ([X]% reduccion)
Credenciales: movidas a .credentials.json (protegido por .gitignore)
Memorias creadas: [N] archivos
Reglas creadas: [N] archivos
Archivos limpiados: [N] movidos a _pendiente_borrado/
Puntuacion: [antes]/10 → [despues]/10
```

---

## Criterios de puntuacion

| Aspecto | 0 pts | 1 pt | 2 pts |
|---------|-------|------|-------|
| CLAUDE.md tamano | >400 lineas | 200-400 | <200 |
| Credenciales | En CLAUDE.md | En reglas | En .credentials.json |
| Memorias | No hay | Basicas | Completas (4+ tipos) |
| Reglas modulares | No hay | 1-2 reglas | 3+ con globs |
| Estructura raiz | >15 archivos sueltos | 8-15 | <8 |
