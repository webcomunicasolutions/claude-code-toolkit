---
description: Revision exhaustiva de codigo con checklist de seguridad
---

# Code Review

Revision sistematica de cambios no commiteados con foco en seguridad y calidad.

## Instrucciones

1. Identifica archivos modificados con `git diff --name-only` y `git diff --staged --name-only`
2. Para cada archivo, revisa contra este checklist por prioridad:

### CRITICAL - Seguridad (bloquea)
- [ ] Sin credenciales hardcodeadas (API keys, passwords, tokens)
- [ ] Sin SQL injection (queries con string concatenation)
- [ ] Sin XSS (input de usuario directo en DOM/HTML)
- [ ] Sin command injection (input en shell commands)
- [ ] Sin path traversal (input en rutas de archivos)
- [ ] Auth checks en rutas protegidas
- [ ] Dependencias sin vulnerabilidades conocidas

### HIGH - Calidad de codigo
- [ ] Funciones < 50 lineas
- [ ] Archivos < 800 lineas
- [ ] Nesting < 4 niveles
- [ ] Errores manejados (no silenciados)
- [ ] Sin console.log/print de debug
- [ ] Sin codigo muerto
- [ ] Tests para cambios significativos

### MEDIUM - Patrones
- [ ] Input validado en boundaries del sistema
- [ ] Rate limiting en endpoints publicos
- [ ] Queries con limites (no unbounded)
- [ ] Sin N+1 queries
- [ ] Timeouts en llamadas externas
- [ ] Mensajes de error sin info sensible

### LOW - Buenas practicas
- [ ] Nombres descriptivos
- [ ] Sin magic numbers
- [ ] Formato consistente

3. Presenta hallazgos organizados por severidad con ubicacion exacta (archivo:linea)
4. Veredicto final: **Aprobar** (sin CRITICAL/HIGH) | **Warning** (solo HIGH) | **Bloquear** (CRITICAL presente)
