---
name: quality-gate
description: Mega quality gate que combina TODOS los agentes de revision en un loop automatico hasta 0 bugs. Mezcla test-and-fix, verification-loop, adversarial-review, code-reviewer, security-reviewer, python-reviewer, devils-advocate y build-error-resolver. Usar antes de publicar releases, crear PRs importantes, o despues de sesiones largas de desarrollo. Decir "quality gate", "revision exhaustiva", "revisa todo", "pasa el quality gate", o "asegurate de que esta perfecto".
---

# Quality Gate — Mega Review Loop

Loop automatico de revision multi-agente que combina TODOS los agentes de calidad disponibles hasta llegar a 0 bugs. Basado en la experiencia real de 10+ rondas de revision del proyecto cli-anything-n8n (56 fixes encontrados).

## Cuando invocar
- Antes de publicar en PyPI/npm/crates.io
- Antes de crear PRs a repos importantes (upstream)
- Despues de sesiones largas de desarrollo (>1 hora)
- Cuando se diga "quality gate", "revisa todo", "asegurate de que esta perfecto"
- Despues de implementar multiples features seguidas

## El Loop (3 fases que se repiten)

### FASE 0: Lint estatico (BLOQUEANTE, antes de todo)

Correr el linter del lenguaje con --fix automatico. Esto pilla f-strings vacias, imports rotos, variables sin usar — cosas que los agentes reviewers ignoran pero que Copilot/herramientas automáticas detectan.

```
Python:     ruff check . --select E,F,W --ignore E501 --fix && ruff check . --select E,F,W --ignore E501
TypeScript: npx eslint . --fix && npx eslint .
Go:         go vet ./... && staticcheck ./...
Rust:       cargo clippy --fix -- -D warnings && cargo clippy -- -D warnings
C++:        clang-tidy --fix ...
```

Si quedan errores despues del --fix → arreglar manualmente. NO pasar a Fase 1 con errores de lint.

**Why:** 19 errores de lint en cli-n8n que 14 rondas de review no pillaron pero Copilot si. Un linter los pilla en 0.1s.

### FASE 1: Verificacion basica

Detectar lenguaje y ejecutar en orden:

```
1. Build:    python -m py_compile / npm run build / cargo build / go build
2. Types:    mypy . / npx tsc --noEmit / go vet
3. Tests:    pytest -v / npm test / cargo test / go test ./...
4. Security: buscar secrets hardcodeados, .env tracked, console.log/print debug
```

Si CUALQUIERA falla → arreglar ANTES de pasar a Fase 2. No desperdiciar agentes en codigo roto.

### FASE 2: Lanzar agentes en paralelo (el corazon del gate)

Lanzar **4 agentes simultaneos** con prompts ADVERSARIALES (no blandos):

#### Agente A: Code Breaker (code-reviewer)
```
subagent_type: code-reviewer
prompt: |
  BUG BOUNTY $100K. Proyecto: {PROJECT_PATH}
  Fixes previos: {PREVIOUS_FIXES_LIST}
  
  Lee TODOS los archivos de codigo. Busca:
  1. Crashes con inputs reales (no teoricos)
  2. Logica de negocio que hace lo contrario de lo que dice
  3. Datos silenciosamente corruptos
  4. Tests que pasan pero son incorrectos
  
  Solo bugs REPRODUCIBLES con comando concreto.
  Si nada: "BOUNTY UNCLAIMED — code is solid"
```

#### Agente B: Security Hunter (security-reviewer)
```
subagent_type: security-reviewer
prompt: |
  BUG BOUNTY $100K. Proyecto: {PROJECT_PATH}
  Fixes previos: {PREVIOUS_FIXES_LIST}
  
  Lee TODOS los archivos. Busca:
  1. Inyecciones (SQL, command, path traversal)
  2. Secrets expuestos en output/logs/errores
  3. Permisos de archivos inseguros
  4. Datos sin validar de fuentes externas
  5. DoS (loops infinitos, memoria sin limite)
  
  Solo vulnerabilidades con exploit concreto.
  Si nada: "BOUNTY UNCLAIMED — no exploitable vulns"
```

#### Agente C: Devil's Advocate (devils-advocate)
```
subagent_type: devils-advocate
prompt: |
  DESTRUYE este codigo. Proyecto: {PROJECT_PATH}
  
  El equipo cree que esta listo para produccion.
  DEMUESTRALES QUE SE EQUIVOCAN.
  
  Busca:
  1. Race conditions que pierden datos
  2. Dependencias que funcionan en dev pero fallan en prod
  3. Edge cases que nadie considero
  4. Assumptions incorrectas sobre APIs externas
  
  Si realmente no puedes romperlo, ADMITELO.
```

#### Agente D: Language Specialist (python-reviewer / typescript-reviewer / rust-reviewer / go-reviewer / etc.)
```
subagent_type: {LANG}-reviewer  (detectar automaticamente del proyecto)
prompt: |
  Revision idiomatica de {LANG}. Proyecto: {PROJECT_PATH}
  
  Solo bugs que afecten funcionamiento:
  1. Anti-patrones que causen bugs en produccion
  2. Imports rotos o circulares
  3. Excepciones silenciadas que oculten problemas
  4. Codigo muerto que confunda
  5. Tipos incorrectos que causen runtime errors
  
  Si nada nuevo: "QUALITY OK"
```

### FASE 3: Evaluar y decidir

Cuando los 4 agentes terminen:

```
bugs_encontrados = sum(bugs de cada agente)

if bugs_encontrados > 0:
    1. Aplicar TODOS los fixes (minimos, no refactoring)
    2. Correr tests de nuevo (Fase 1, solo tests)
    3. Actualizar PREVIOUS_FIXES_LIST
    4. Volver a Fase 2 (nueva ronda)

if bugs_encontrados == 0:
    1. Verificar que es un 0 REAL (no un agente perezoso)
    2. Si es la primera ronda con 0 → hacer UNA ronda mas para confirmar
    3. Si es la segunda ronda consecutiva con 0 → GATE PASSED
```

## Reglas criticas (aprendidas de 10+ rondas reales)

### 1. Los prompts adversariales son OBLIGATORIOS
- "Busca bugs" → agente dice "todo bien" (mentira)
- "Te pago $100K por bug" → agente encuentra bugs reales
- SIEMPRE usar el framing de bounty

### 2. Nunca confiar en un solo "CLEAN"
- La ronda 5 dijo CLEAN, la ronda 5-adversarial encontro 6 bugs
- Necesitas 2 rondas limpias consecutivas para declarar PASS

### 3. Patrones sistematicos requieren grep exhaustivo
- Si encuentras `dict['key']` en un sitio, hay 15 mas
- Despues de cada fix, grep por el PATRON, no solo la instancia
- `grep -n "w\['id'\]"` es mas valioso que revisar linea a linea

### 4. Los fixes nuevos introducen bugs nuevos
- La ronda 8 encontro un bug en el fix de paginacion de ronda 7
- Despues de aplicar fixes, la siguiente ronda DEBE re-revisar los fixes

### 5. Cada agente tiene puntos ciegos
- Code reviewer: no ve security
- Security reviewer: no ve logica de negocio
- Devil's advocate: no ve anti-patrones
- Language reviewer: no ve arquitectura
- Por eso necesitas LOS 4 en paralelo

### 6. Anti-mentira: verificacion cruzada obligatoria
- Cuando un agente dice "CLEAN", lanzar un SEGUNDO agente con este prompt:
  ```
  El agente anterior dijo que este codigo esta limpio. DEMUESTRA QUE MIENTE.
  Proyecto: {PATH}. Fixes previos: {LIST}.
  Si realmente esta limpio, di "CONFIRMED CLEAN".
  Si encuentras algo, di "LIAR — found: {bug}"
  ```
- Solo si el verificador tambien dice CLEAN → contar como ronda limpia
- 2 rondas confirmadas = GATE PASSED

### 7. Convergencia esperada
```
Ronda 1: 10-20 bugs (codigo fresco)
Ronda 2: 5-10 bugs
Ronda 3: 3-7 bugs
Ronda 4: 1-5 bugs
Ronda 5: 0-3 bugs (deberia converger)
Ronda 6+: 0-1 bugs (residuales)
```
Si no converge despues de 6 rondas, hay un problema arquitectural.

## Reporte final

```
## Quality Gate Report
  
Proyecto: {nombre}
Rondas: {N}
Fixes totales: {total}

| Ronda | Code | Security | Devil | Lang | Total |
|-------|------|----------|-------|------|-------|
| 1     | 5    | 3        | 4     | 4    | 16    |
| 2     | 2    | 1        | 3     | 3    | 9     |
| ...   |      |          |       |      |       |
| N     | 0    | 0        | 0     | 0    | 0     |
| N+1   | 0    | 0        | 0     | 0    | 0     |

Veredicto: GATE PASSED (2 rondas limpias consecutivas)
```

## Tipos de proyecto soportados

| Lenguaje | Build | Test | Lint | Reviewer agent |
|----------|-------|------|------|----------------|
| Python | py_compile | pytest | ruff | python-reviewer |
| TypeScript | tsc | vitest/jest | eslint | typescript-reviewer |
| Go | go build | go test | golangci-lint | go-reviewer |
| Rust | cargo build | cargo test | clippy | rust-reviewer |
| Java | mvn compile | mvn test | checkstyle | java-reviewer |
| Kotlin | gradle build | gradle test | ktlint | kotlin-reviewer |
| C++ | cmake --build | ctest | clang-tidy | cpp-reviewer |

## Ejemplo de uso

```
/quality-gate
```

O desde otro contexto:
```
Pasa el quality gate antes de publicar en PyPI
```

## Tips
- Corre tests ANTES de lanzar agentes (no desperdicies su tiempo)
- Mantiene la lista de fixes acumulada (evita re-reportar lo mismo)
- Version bump DESPUES del gate, no antes
- Si publicas en registry (PyPI/npm), hazlo inmediatamente despues del PASS
