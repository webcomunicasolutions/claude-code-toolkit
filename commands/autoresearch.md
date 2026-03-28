---
description: Loop autonomo de mejora continua - patron AutoResearch de Karpathy aplicado a cualquier proyecto
---

# AutoResearch - Loop de Mejora Continua

Aplica el patron AutoResearch de Karpathy: cambio pequeno, medir, mantener o revertir, repetir.

## Instrucciones

### Modo interactivo (sin argumentos o con objetivo vago)

Si el usuario ejecuta `/autoresearch` sin metrica clara, PRIMERO analiza el proyecto y propone:

1. **Detectar el proyecto**: Lee CLAUDE.md, package.json, pyproject.toml, go.mod, Cargo.toml, Makefile, etc.
2. **Identificar stack**: Lenguaje, framework, herramientas de build y test
3. **Proponer metricas relevantes** segun lo que encuentres:

| Si encuentras... | Proponer |
|------------------|----------|
| package.json con build script | Tamano del bundle, tiempo de build |
| pytest / jest / vitest | Cobertura de tests, tiempo de ejecucion |
| API endpoints | Tiempo de respuesta, requests/segundo |
| Dockerfile | Tamano de imagen, tiempo de build |
| Lighthouse / web | Performance score, accesibilidad |
| Base de datos | Tiempo de queries, indices faltantes |
| Codigo sin tests | Aumentar cobertura |
| Codigo con TODOs/FIXMEs | Reducir deuda tecnica |
| Cualquier proyecto | Reducir lineas de codigo, simplificar |

4. **Presentar al usuario** un menu como:

```
He analizado el proyecto [nombre]. Estas son las metricas que puedo optimizar:

1. Cobertura de tests (actual: 45%) - comando: pytest --cov
2. Tiempo de build (actual: 12s) - comando: npm run build
3. Tamano del bundle (actual: 2.3MB) - comando: du -sh dist/
4. Complejidad ciclomatica - comando: radon cc src/ -a

Elige un numero, o dime tu propio objetivo.
Tambien puedo sugerirte un scope de archivos a optimizar.
```

5. **Confirmar configuracion** antes de empezar:

```
Configuracion AutoResearch:
- Objetivo: [lo que eligio]
- Metrica: [comando]
- Direccion: menor es mejor / mayor es mejor
- Scope: [archivos]
- Max iteraciones: 20 (cambiar?)
- Tests gate: [comando de tests si existe]

Confirmas? (s/n)
```

6. Solo cuando el usuario confirme, empezar el loop.

### Modo directo (con argumentos claros)

Si el usuario proporciona objetivo + metrica + scope, saltar al loop directamente.

### REGLA CRITICA: Archivos inmutables (anti-trampas)

El agente NUNCA puede modificar los archivos que miden el resultado. Esto es lo que garantiza mejoras reales:

**INMUTABLES (nunca tocar):**
- El comando de metrica definido por el usuario
- Archivos de test existentes (solo puede CREAR nuevos, no modificar los que ya existen)
- Archivos de configuracion de test (jest.config, pytest.ini, vitest.config, etc.)
- Scripts de benchmark
- CI/CD pipelines
- El propio autoresearch_results.tsv (solo append, nunca editar filas anteriores)

**MUTABLES (lo unico que puede tocar):**
- Archivos de codigo dentro del scope definido
- Nuevos archivos dentro del scope (crear helpers, utils, etc.)

Si el agente necesita cambiar un test para que algo funcione, eso significa que el cambio rompe funcionalidad existente y debe ser DESCARTADO, no que el test esta mal.

### El loop de experimentacion

Para cada iteracion:

```
1. ANALIZAR: Lee autoresearch_results.tsv para entender que ha funcionado y que no
2. IDEAR: Propone UN cambio pequeno y enfocado (no multiples cambios)
3. EDITAR: Modifica solo los archivos dentro del scope definido
4. COMMIT: git add [archivos] && git commit -m "experiment: [descripcion corta]"
5. VERIFICAR: Ejecuta los tests del proyecto (si existen) - si fallan, revert inmediato
6. MEDIR: Ejecuta la metrica definida y extrae el valor numerico
7. DECIDIR:
   - Si mejora (metrica mejor que la mejor anterior): KEEP
   - Si empeora o igual: git reset --hard HEAD~1 (DISCARD)
8. REGISTRAR: Anade fila a autoresearch_results.tsv
9. REPETIR
```

### Antes de empezar el loop

- Ejecuta la metrica actual y registra el valor base
- Crea archivo `autoresearch_results.tsv` en la raiz del proyecto con headers:
  `iteration\thash\tmetric\tdelta\tstatus\tdescription`
- Crea un branch aislado: `git checkout -b autoresearch/$(date +%Y%m%d-%H%M)`
- Registra baseline como iteracion 0

### Principios (del original de Karpathy)

- **Un cambio por iteracion** - nunca multiples cambios simultaneos
- **Simple > complejo** - si dos opciones dan igual resultado, mantener la mas simple
- **Revert rapido** - si rompe tests o empeora, revert sin dudar
- **Git como memoria** - el historial de commits ES la memoria del agente
- **results.tsv como auditoria** - todo queda registrado

### Condiciones de parada

- El usuario lo detiene
- Se alcanza el objetivo definido
- 3 iteraciones seguidas sin mejora (plateau)
- 20 iteraciones maximas por defecto (configurable)

### Reporte final

Al terminar, muestra:

```
## AutoResearch Report
**Proyecto:** [nombre]
**Branch:** autoresearch/[fecha]
**Iteraciones:** X total (Y kept / Z discarded)
**Baseline:** [valor inicial]
**Mejor resultado:** [mejor valor] (mejora del X%)

### Cambios mantenidos (cronologico):
1. [descripcion] - metrica: [valor] (delta: [cambio])
2. ...

### Cambios descartados mas interesantes:
- [descripcion] - por que fallo

### Recomendacion:
[Merge a main / Seguir iterando / Revertir todo]
```

$ARGUMENTS
