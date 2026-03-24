---
name: verification-loop
description: Sistema QA de 6 fases para verificar calidad antes de entregar. Build, types, lint, tests, security, diff review. Usar después de completar features o antes de crear PRs.
---

# Verification Loop

Quality assurance en 6 fases para Claude Code sessions.

## Cuándo invocar
- Después de completar una feature
- Antes de crear un PR
- Cada ~15 minutos en sesiones largas
- Cuando se tenga duda sobre el estado del código

## Las 6 fases

### 1. Build Verification
Detectar build system y ejecutar: npm run build / cargo build / go build / python -m py_compile.
Criterio: build limpio sin errores ni warnings.

### 2. Type Check
npx tsc --noEmit / mypy . / go vet ./...
Criterio: sin errores de tipos.

### 3. Lint Check
npx eslint . / ruff check . / golangci-lint run
Criterio: sin violaciones de estilo.

### 4. Test Suite
npm test / pytest / go test ./...
Criterio: todos los tests pasan, cobertura >= 80%.

### 5. Security Scan
- Buscar secrets hardcodeados
- Buscar console.log/print de debug
- Verificar .env no está tracked
- npm audit / pip audit

### 6. Diff Review
- git diff --stat
- Examinar cada archivo cambiado
- Verificar que solo se cambió lo necesario
- Sin cambios accidentales

## Reporte
```
## Verification Report
| Fase | Estado | Detalles |
|------|--------|----------|
| Build | PASS/FAIL | [output] |
| Types | PASS/FAIL | [errors] |
| Lint | PASS/FAIL | [violations] |
| Tests | PASS/FAIL | [pass/fail, coverage%] |
| Security | PASS/FAIL | [findings] |
| Diff | PASS/FAIL | [files changed] |

**Veredicto:** PASS / FAIL
```
