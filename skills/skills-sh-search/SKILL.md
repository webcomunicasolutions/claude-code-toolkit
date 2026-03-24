---
name: skills-sh-search
description: Busca, explora e instala skills del directorio skills.sh para extender las capacidades de Claude Code. Usar cuando se necesite encontrar nuevas skills, explorar el catálogo de skills.sh, o instalar skills de terceros.
---

# Skills.sh Search

Skill para buscar, explorar e instalar skills del directorio público skills.sh (The Agent Skills Directory).

## Cuándo usar

- El usuario quiere buscar nuevas skills o capacidades
- Se necesita encontrar una skill para una tarea específica
- El usuario menciona "skills.sh", "buscar skill", "instalar skill", "skill marketplace"
- Se quiere explorar qué skills existen para una tecnología o área

## Herramientas disponibles

### 1. Búsqueda por CLI (preferida)
```bash
npx skills find "<query>"
```
Busca skills interactivamente. Devuelve nombre, owner/repo, installs y URL.

Ejemplos de búsquedas útiles:
- `npx skills find "project documentation"` - Skills de documentación
- `npx skills find "react best practices"` - Best practices React
- `npx skills find "technical specification"` - Specs técnicas
- `npx skills find "web design"` - Diseño web

### 2. Explorar web (para detalles)
Usar WebFetch para obtener detalles de una skill específica:
```
WebFetch: https://skills.sh/<owner>/<repo>/<skill-name>
```

### 3. Instalar una skill
```bash
npx skills add https://github.com/<owner>/<repo> --skill <skill-name>
```
O con flags para auto-confirmar:
```bash
npx skills add https://github.com/<owner>/<repo> --skill <skill-name> -g -y
```

## Flujo de trabajo

1. **Entender la necesidad**: Qué tipo de skill busca el usuario
2. **Buscar**: Usar `npx skills find` con términos relevantes en inglés
3. **Explorar**: Si hay resultados interesantes, usar WebFetch para ver el SKILL.md completo
4. **Presentar opciones**: Mostrar al usuario las mejores opciones con nombre, descripción, installs
5. **Instalar**: Si el usuario quiere, instalar con `npx skills add`

## Categorías comunes de búsqueda

| Área | Términos de búsqueda |
|------|---------------------|
| Frontend | "react", "vue", "nextjs", "web design", "frontend" |
| Backend | "api design", "database", "backend", "server" |
| DevOps | "docker", "kubernetes", "ci cd", "deployment" |
| Documentación | "documentation", "technical writing", "project docs" |
| Testing | "testing", "e2e", "unit test" |
| Diseño | "design system", "ui ux", "accessibility" |
| IA/ML | "ai agent", "llm", "machine learning" |
| Proyecto | "project planning", "requirements", "specification" |
| Seguridad | "security", "authentication", "encryption" |

## Notas importantes

- Los términos de búsqueda deben ser en **inglés** para mejores resultados
- `npx skills find` requiere Node.js/npm instalado
- Las skills se instalan en `.claude/skills/` del proyecto o globalmente con `-g`
- Verificar la seguridad de skills antes de instalar (ver audits en la página)
- El comando `npx skills check` verifica actualizaciones de skills instaladas
