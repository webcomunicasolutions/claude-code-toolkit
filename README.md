# Claude Code Toolkit

A comprehensive collection of agents, skills, commands, rules, hooks, and utilities to supercharge your [Claude Code](https://docs.anthropic.com/en/docs/claude-code) experience.

## What's inside

| Component | Count | Description |
|-----------|-------|-------------|
| [**Agents**](agents/) | 32 | Specialized agents for code review, TDD, security, architecture, and more |
| [**Skills**](skills/) | 68 | Domain knowledge packs with scripts, references, and templates |
| [**Commands**](commands/) | 20 | Slash commands for common workflows (`/tdd`, `/plan`, `/build-fix`...) |
| [**Rules**](rules/) | 33 | Coding standards for 12+ languages and cross-cutting concerns |
| [**Hooks**](hooks/) | 1 | Telegram approval hook for remote action control |
| [**Scripts**](scripts/) | 2 | Memory-size check and Telegram voice notes |
| [**Statusline**](statusline/) | 1 | Rich status bar with context usage, tokens, costs, and git info |

## Quick Install

```bash
git clone https://github.com/webcomunicasolutions/claude-code-toolkit.git
cd claude-code-toolkit
bash install.sh
```

Install individual components:

```bash
bash install.sh --agents      # 32 agents
bash install.sh --skills      # 68 skills
bash install.sh --commands    # 20 commands
bash install.sh --rules       # 33 rules
bash install.sh --statusline  # Status bar
bash install.sh --scripts     # Helper scripts (memory size, voice notes)
bash install.sh --hook        # Telegram approval hook
bash install.sh --ecc         # Import extras from Everything Claude Code
```

## What's new (September 2026)

- **16 new working rules**: critical attitude, declared coverage, adversarial verification, anti-hallucination,
  canonical coordinates, credentials vault, secrets in web deployments, restic backups, versioning, delegation to agents,
  deliverables to disk, MEMORY.md size, ports safety…
- **Updated `/save-session` and `/resume-session`** (+ `session-management` skill rewritten to match), new `/audio`,
  `/audit`, `/harness-fix`, `/watch-bridge`, new `project-auditor` agent.
- **New skills**: quality-loop, critico, qa-web-roles, notify, nuevo-proyecto, video-watch, media-use, web-a-app,
  whatsapp-meta-cloud, precios-ia, continuar-sesion, contexto-claude-code…
- **Statusline refreshed**; installer fixes: correct `statusLine` settings key and several flags in one call now work.
- Removed from the kit: n8n, OCR/local-AI and MSP-specific skills (they stay in the git history).

### Updating an existing install

```bash
cd claude-code-toolkit && git pull && bash install.sh
```

The installer copies files but never deletes: skills removed from the kit stay in your `~/.claude/skills/` until you delete them.

## Everything Claude Code (ECC) Integration

The installer also pulls additional components from the [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) community repository. This adds **200+ extra skills**, additional agents, commands, and hooks on top of what this toolkit provides.

- ECC components are only imported if they don't already exist locally (no overwrites)
- Run `bash install.sh --ecc` at any time to pull new ECC components
- Run `bash install.sh --ecc-only` to only sync ECC without reinstalling the toolkit
- Run `bash install.sh --summary` to see total installed component counts

## Post-Install Configuration

### Enable Agent Teams

Agent teams allow Claude Code to spawn specialized sub-agents for parallel work. Add to your `~/.claude/settings.json`:

```json
{
  "agentTeam": {
    "enabled": true
  }
}
```

With teams enabled, Claude can delegate tasks to the installed agents (code reviewers, build resolvers, TDD agents, etc.) and run them in parallel for faster results.

### Verify Installation

After installing, restart Claude Code and run:

```
bash install.sh --summary
```

This shows the total count of agents, skills, commands, and rules installed.

## Components

> Lists generated from the files in each folder (September 2026). Descriptions come from each file's frontmatter.

### Agents (32)

| Name | Description |
|---|---|
| `architect` | Arquitecto de software para diseño de sistemas, evaluación de trade-offs y decisiones técnicas. Usar cuando se diseñan features nuevas, se e… |
| `build-error-resolver` | Resuelve errores de build y compilación rápidamente con cambios mínimos. Usar cuando el build falla y necesitas desbloquearte. |
| `code-reviewer` | Revisor experto de codigo para calidad, seguridad y mantenibilidad. Usar proactivamente despues de escribir o modificar codigo. |
| `cpp-build-resolver` | Resuelve errores de build C++, CMake y compilación. Usar cuando falle un build C++. |
| `cpp-reviewer` | Revisor de código C++ - memory safety, RAII, concurrencia, modern C++. Usar para reviews de código C++. |
| `database-reviewer` | Revisor de PostgreSQL - queries, schemas, RLS, performance, indexing. Usar para reviews de código SQL y schemas de BD. |
| `devils-advocate` | Desafia suposiciones y fuerza pensamiento critico. Juega al abogado del diablo para asegurar las mejores decisiones. Usar proactivamente ant… |
| `doc-updater` | Mantiene documentación sincronizada con el código. Genera codemaps, actualiza READMEs y verifica que la documentación refleja la realidad. |
| `flutter-reviewer` | Revisor de código Flutter/Dart - widgets, state management, performance, accesibilidad. Usar para reviews de código Flutter. |
| `go-build-resolver` | Resuelve errores de build Go, go vet y linter. Usar cuando falle un build Go. |
| `go-reviewer` | Revisor de código Go - concurrencia, error handling, patrones idiomáticos. Usar para reviews de código Go. |
| `java-build-resolver` | Resuelve errores de build Java, Maven y Gradle. Usar cuando falle un build Java. |
| `java-reviewer` | Revisor de código Java y Spring Boot - arquitectura, JPA, seguridad, concurrencia. Usar para reviews de código Java. |
| `kotlin-build-resolver` | Resuelve errores de build Kotlin y Gradle. Usar cuando falle un build Kotlin. |
| `kotlin-reviewer` | Revisor de código Kotlin y Android/KMP - coroutines, Compose, clean architecture. Usar para reviews de código Kotlin. |
| `loop-operator` | Gestiona loops autónomos de trabajo con guardrails de seguridad. Monitorea progreso, detecta estancamientos y decide cuándo escalar. |
| `planner` | Planificador de implementación que descompone features complejas en pasos accionables. Usar antes de implementar features grandes o refactor… |
| `principal-engineer` | Guia de ingenieria nivel principal con foco en excelencia tecnica, liderazgo y pragmatismo. Estilo Martin Fowler. |
| `project-auditor` | Auditor read-only de PROYECTOS Claude Code. Revisa estructura, CLAUDE.md del proyecto, settings local, skills locales, hooks, seguridad. NO … |
| `python-reviewer` | Revisor de código Python - seguridad, type safety, patrones Pythonic. Usar para reviews de código Python, Django, FastAPI, Flask. |
| `pytorch-build-resolver` | Resuelve errores de PyTorch - tensor shapes, CUDA, gradients, DataLoader. Usar cuando falle código de ML/deep learning. |
| `refactor-cleaner` | Limpieza de código muerto, duplicados y dependencias no usadas. Usar para sprints de refactoring dedicados. |
| `rust-build-resolver` | Resuelve errores de build Rust, cargo y borrow checker. Usar cuando falle un build Rust. |
| `rust-reviewer` | Revisor de código Rust - safety, ownership, error handling, patrones idiomáticos. Usar para reviews de código Rust. |
| `security-reviewer` | Analista de seguridad que identifica vulnerabilidades en código. Usar proactivamente antes de deployments, al crear endpoints, manejar auth,… |
| `tdd-green` | Fase GREEN de TDD - Implementa el codigo MINIMO necesario para que los tests pasen. Sin over-engineering. |
| `tdd-red` | Fase RED de TDD - Escribe tests que fallan ANTES de implementar codigo. Un test a la vez para describir el comportamiento deseado. |
| `tdd-refactor` | Fase REFACTOR de TDD - Mejora calidad, seguridad y diseno manteniendo todos los tests verdes. |
| `test-generator` | Genera test cases comprensivos analizando codigo, patrones existentes y edge cases. Usar proactivamente para asegurar cobertura de tests. |
| `typescript-reviewer` | Revisor de código TypeScript/JavaScript - type safety, React patterns, seguridad. Usar para reviews de código TS/JS, React, Next.js. |
| `verifier` | Gate de verificacion obligatorio antes de declarar trabajo completado. Previene claims falsos de exito. Evidencia antes de afirmaciones, sie… |
| `web-scraper-expert` | Especialista en scraping web con nodriver (anti-bot), extraccion de datos de SPAs, y captura de screenshots. Usar cuando se necesite extraer… |

### Commands (20)

| Name | Description |
|---|---|
| `/audio` | Enviarme por Telegram una nota de voz con lo que acabas de explicar |
| `/audit` | Detectar problemas en el PROYECTO actual (no modifica). Para aplicar mejoras, ver /optimize. |
| `/autoresearch` | Loop autonomo de mejora continua - patron AutoResearch de Karpathy aplicado a cualquier proyecto |
| `/build-fix` | Resolver errores de build/compilacion de forma sistematica |
| `/checkpoint` | Crear punto de control del estado actual del codigo |
| `/code-review` | Revision exhaustiva de codigo con checklist de seguridad |
| `/devfleet` | Orquestar multiples agentes en paralelo con worktrees |
| `/eval` | Definir y ejecutar evaluaciones de features |
| `/full` | Modo autonomia total - usa todos los recursos disponibles sin preguntar |
| `/harness-audit` | Detectar problemas en la CONFIG GLOBAL ~/.claude/ (no modifica). Scores por categoria con evidencia e historico. Para aplicar mejoras, ver /… |
| `/harness-fix` | APLICAR mejoras en la CONFIG GLOBAL ~/.claude/ (settings.json, CLAUDE.md, skills, hooks). Si solo quieres detectar, usa /harness-audit. |
| `/loop-start` | Iniciar loop autonomo con guardrails de seguridad |
| `/loop-status` | Ver estado del loop autonomo activo |
| `/model-route` | Seleccionar modelo optimo segun tarea y presupuesto |
| `/optimize` | APLICAR mejoras en el PROYECTO actual (reduce CLAUDE.md, crea memorias, limpia estructura). Si solo quieres detectar sin tocar, usa /audit. |
| `/plan` | Crear plan de implementacion detallado antes de codificar |
| `/resume-session` | Retomar una sesion guardada previamente |
| `/save-session` | Guardar estado de sesion actual para retomar despues |
| `/tdd` | Desarrollo dirigido por tests - RED/GREEN/REFACTOR |
| `/watch-bridge` | Activa modo guardia sobre shared/BRIDGE.md - escucha mensajes nuevos de otros proyectos en paralelo |

### Skills (68)

| Name | Description |
|---|---|
| `adversarial-review` | Loop adversarial de revision de codigo con multiples agentes. Lanza reviewers con incentivos para romper el codigo, aplica fixes, re-testea,… |
| `agentic-engineering` | Patrones de ingenieria agentica - workflows dirigidos por IA con supervision humana. Usar cuando se disenan sistemas multi-agente, loops aut… |
| `algorithmic-art` | Creating algorithmic art using p5.js with seeded randomness and interactive parameter exploration. Use this when users request creating art … |
| `api-design` | Diseno de REST APIs - convenciones, response formats, pagination, auth, rate limiting. Usar cuando se disenan o revisan endpoints API. NOT f… |
| `asesor-fiscal-espana` | Conocimiento fiscal español para extracción y validación de facturas. Usar cuando se trabaje con: (1) Facturas españolas o europeas, (2) IVA… |
| `autonomous-loops` | Patrones para ejecutar Claude Code de forma autónoma en loops. Desde pipelines secuenciales hasta DAGs con múltiples agentes. Usar cuando se… |
| `brand-guidelines` | Applies Anthropic's official brand colors and typography to any sort of artifact that may benefit from having Anthropic's look-and-feel. Use… |
| `bridge-watch` | Modo guardia para Project Bridge. Escucha pasivamente mensajes nuevos en shared/ de cualquier canal y los responde o deriva al usuario. Util… |
| `canvas-design` | Create beautiful visual art in .png and .pdf documents using design philosophy. You should use this skill when the user asks to create a pos… |
| `contexto-claude-code` | Decidir DONDE va cada instruccion en Claude Code segun la doctrina oficial de Anthropic (2026) - CLAUDE.md, .claude/rules/ (con y sin paths)… |
| `continuar-sesion` | [resumen en 1 línea] |
| `cost-aware-llm` | Patrones para controlar costos de API de LLMs. Model routing, budget tracking, prompt caching, retry inteligente. Usar cuando se construyan … |
| `critico` | Archivo extendido de la actitud critica - casos reales, aprendizajes y el porque. La regla operativa que se aplica siempre vive en rules/act… |
| `database-migrations` | Migraciones de base de datos seguras y reversibles. Patrones zero-downtime, expand-contract, backfill. Usar cuando se modifique esquema de B… |
| `dev-browser` | Browser automation with persistent page state. Use when users ask to navigate websites, fill forms, take screenshots, extract web data, test… |
| `django-patterns` | Arquitectura production-grade Django - models, views, serializers, signals, caching. Usar cuando se trabaje con Django/DRF. |
| `doc-coauthoring` | Guide users through a structured workflow for co-authoring documentation. Use when user wants to write documentation, proposals, technical s… |
| `doc-maintenance` | Mantenimiento de documentación y estructura de proyectos. Usar cuando se necesite organizar archivos MD, validar estructura, limpiar duplica… |
| `doc-specialist` | Generate specialized Claude agents from scraped documentation libraries. Automates the flow from docs → agent template with full library ref… |
| `docker-patterns` | Patrones de Docker y Docker Compose para desarrollo y producción. Multi-stage builds, volumes, networking, security. Usar cuando se containe… |
| `documentos-corporativos` | Generar documentos PDF con estilo corporativo. Usar cuando se pida crear informes, contratos, propuestas, presupuestos o cualquier documento… |
| `docx` | Comprehensive document creation, editing, and analysis with support for tracked changes, comments, formatting preservation, and text extract… |
| `e2e-testing` | Patrones de testing E2E con Playwright. Page Object Model, manejo de flakiness, configuración cross-browser. Usar cuando se escriban tests e… |
| `frontend-design` | Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when the user asks to build web components… |
| `general-video` | > |
| `golang-patterns` | Patrones idiomaticos de Go - error handling, concurrency, interfaces, functional options. Usar cuando se escriba codigo Go. |
| `golang-testing` | Patrones de testing Go - table-driven, subtests, benchmarks, fuzzing, mocking con interfaces. Usar cuando se escriban tests en Go. |
| `internal-comms` | A set of resources to help me write all kinds of internal communications, using the formats that my company likes to use. Claude should use … |
| `kotlin-testing` | Patrones de testing Kotlin - Kotest, MockK, coroutines, Flow, property-based. Usar cuando se escriban tests en Kotlin. |
| `laravel-patterns` | Arquitectura production-grade Laravel - controllers, services, Eloquent, queues, events. Usar cuando se trabaje con Laravel. |
| `mcp-builder` | Guide for creating high-quality MCP (Model Context Protocol) servers that enable LLMs to interact with external services through well-design… |
| `nuevo-proyecto` | Arrancar un proyecto SIN código (documentos, gestión, clientes, ofertas, licitaciones, procesos) con la estructura de 3 capas (empresa/clien… |
| `pdf` | Comprehensive PDF manipulation toolkit for extracting text and tables, creating new PDFs, merging/splitting documents, and handling forms. W… |
| `playwright-cli` | Automates browser interactions for web testing, form filling, screenshots, and data extraction. Use when the user needs to navigate websites… |
| `postgres-patterns` | Best practices PostgreSQL - indexing, RLS, pagination, optimization, data types. Usar cuando se trabaje con PostgreSQL. NOT for NoSQL databa… |
| `pptx` | Presentation creation, editing, and analysis. When Claude needs to work with presentations (.pptx files) for: (1) Creating new presentations… |
| `precios-ia` | Precios vigentes de las APIs de IA de pago (OpenAI y Google Gemini) y qué combinación conviene para cada tarea - chat/agente, transcripción … |
| `project-bridge` | Comunicacion estructurada entre proyectos de Claude Code. Crear canal shared/, enviar mensajes, leer y responder mensajes de otros proyectos… |
| `project-optimizer` | Audita y optimiza cualquier proyecto para Claude Code - reduce CLAUDE.md, crea memorias, reglas modulares, limpia estructura y elimina crede… |
| `prompt-optimizer` | Analiza, critica y mejora prompts sin ejecutar la tarea. Pipeline de 6 fases para optimizar instrucciones a Claude. Usar cuando se quiera me… |
| `python-patterns` | Patrones idiomaticos de Python - type hints, dataclasses, async, generators, context managers. Usar cuando se escriba codigo Python. |
| `python-testing` | Patrones de testing Python con pytest - fixtures, parametrización, mocking, async, cobertura 80%+. Usar cuando se escriban tests en Python. … |
| `qa-web-roles` | Testeo sistematico a fondo de una web de cliente con dev-browser, probando ROL POR ROL (admin + cada usuario/rol), cazando fallos e inconsis… |
| `quality-gate` | Mega quality gate que combina TODOS los agentes de revision en un loop automatico hasta 0 bugs. Mezcla test-and-fix, verification-loop, adve… |
| `quality-loop` | Loop autónomo de calidad con VERIFICADOR INDEPENDIENTE. Fusiona test-and-fix, quality-gate, adversarial-review y verification-loop en un sol… |
| `rust-patterns` | Patrones seguros y eficientes de Rust - ownership, error handling, traits, async, enums. Usar cuando se escriba código Rust. |
| `rust-testing` | Patrones de testing Rust - unit, integration, async, property-based, mocking, benchmarks. Usar cuando se escriban tests en Rust. |
| `screenshot-compare` | Captura screenshots de webs para comparar con implementaciones propias. Navega con nodriver (anti-bot), hace login si es necesario, y guarda… |
| `session-management` | Sistema de persistencia de sesiones entre conversaciones. Guardar estado, retomar trabajo, prevenir reintentos de enfoques fallidos. Usar co… |
| `skill-creator` | Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that exte… |
| `skills-sh-search` | Busca, explora e instala skills del directorio skills.sh para extender las capacidades de Claude Code. Usar cuando se necesite encontrar nue… |
| `slack-gif-creator` | Knowledge and utilities for creating animated GIFs optimized for Slack. Provides constraints, validation tools, and animation concepts. Use … |
| `spec` | Arranque estructurado spec-driven para tareas grandes (método Karpathy 3 capas - spec, verificador, entorno). Invocar cuando se vaya a empez… |
| `springboot-patterns` | Arquitectura production-grade Spring Boot - REST, JPA, services, validation, caching. Usar cuando se trabaje con Spring Boot. |
| `telegram` | Toggle Telegram approval mode on/off for the permission hook |
| `test-and-fix` | Loop autonomo de QA agresivo para web apps. Prueba todas las paginas con Playwright, detecta errores (500, JS crashes, pantallas blancas, da… |
| `theme-factory` | Toolkit for styling artifacts with a theme. These artifacts can be slides, docs, reportings, HTML landing pages, etc. There are 10 pre-set t… |
| `verification-loop` | Sistema QA de 6 fases para verificar calidad antes de entregar. Build, types, lint, tests, security, diff review. Usar después de completar … |
| `video-watch` | >- |
| `web-a-app` | Orquestador para convertir una web EXISTENTE en "app". Decide entre las tres |
| `web-artifacts-builder` | Suite of tools for creating elaborate, multi-component claude.ai HTML artifacts using modern frontend web technologies (React, Tailwind CSS,… |
| `web-scraper` | Scrape websites, documentation sites, and single pages to clean Markdown |
| `webapp-testing` | Toolkit for interacting with and testing local web applications using Playwright. Supports verifying frontend functionality, debugging UI be… |
| `whatsapp-meta-cloud` | Gestión total de WhatsApp Cloud API de Meta (Graph API) reutilizable en cualquier proyecto con solo token + waba_id + phone_id. Cubre planti… |
| `whisper-transcribe` | Transcripcion de audio y video a texto con faster-whisper. Usar cuando el usuario quiera transcribir, pasar a texto, generar subtitulos, o e… |
| `workflow-automation` | Workflow automation is the infrastructure that makes AI agents reliable. Without durable execution, a network hiccup during a 10-step paymen… |
| `xlsx` | Comprehensive spreadsheet creation, editing, and analysis with support for formulas, formatting, data analysis, and visualization. When Clau… |
| `youtube-transcript` | Extract and analyze transcripts from YouTube videos. Use when users request YouTube video transcriptions, summaries, or analysis. Handles vi… |

### Rules (33)

Cross-cutting working rules (most in Spanish): critical attitude, declared coverage ("how many of how many did I check"),
adversarial verification, credentials vault, secrets in web deployments, backups, versioning, agent delegation…
plus coding standards per language.

| Name | Description |
|---|---|
| `actitud-critica` | Regla de comportamiento base, cargada en todas las sesiones. Antes vivia en una skill invocable, pero una |
| `anti-hallucination` | Aplicar estas reglas SIEMPRE que se extraigan datos de documentos, PDFs, facturas, contratos, emails, transcripciones o cualquier fuente. |
| `auto-mejora-skills` | Toda skill procedimental (que guia un workflow o proceso multi-paso) DEBE |
| `backups-restic-b2` | Regla nacida de una decisión explícita: en todos los servidores, Windows y Linux, donde se ponga restic y |
| `cobertura-declarada` | Regla nacida de un fallo real. Llegaron **195 ficheros Excel** de un proveedor para cruzar contra un |
| `coding-style` | - SIEMPRE crear objetos nuevos, NUNCA mutar existentes |
| `coordenadas-canonicas` | Regla nacida de un fallo real: se perdió una sesión entera sondeando una URL equivocada de una API y |
| `cpp` | - C++17 mínimo (preferir C++20/23) |
| `credentials-handling` | Cuando el usuario proporcione credenciales (passwords, tokens, API keys, |
| `csharp` | - .NET conventions obligatorias |
| `databases-docker` | Cuando se trabaje con bases de datos (PostgreSQL, MySQL, MongoDB, Redis con |
| `entregables-a-disco` | **Cualquier cosa que se produzca en una conversación —un presupuesto, un texto para un cliente, |
| `git-workflow` | - Formato: `<tipo>: <descripcion>` |
| `go` | - gofmt y goimports obligatorios |
| `java` | - google-java-format obligatorio |
| `kotlin` | - ktlint/Detekt obligatorio |
| `memoria-tamano` | Detectado en la práctica: el `MEMORY.md` de un proyecto llego a **25.936 bytes** |
| `mysql` | - Prepared statements SIEMPRE (PDO/mysqli), nunca concatenar input |
| `patterns` | Crear capa uniforme de acceso a datos: |
| `performance` | Precios orientativos por 1M tokens (input/output) — **compruébalos siempre**, cambian con frecuencia: |
| `perl` | - use v5.36 obligatorio (strict + warnings automáticos) |
| `php` | - PSR-12 obligatorio |
| `ports-safety` | NUNCA lanzar un servidor o servicio en un puerto sin verificar que esta libre. |
| `python` | - PEP 8 obligatorio |
| `rol-jefe-delegacion` | Decisión de trabajo aplicada en todos los proyectos: según sea la tarea, se ejecuta directamente o se |
| `rust` | - rustfmt obligatorio |
| `secretos-en-despliegues-web` | Regla nacida de un incidente real: en un proyecto desplegado, el fichero `.env` estaba en la carpeta |
| `security` | - [ ] Sin secrets hardcodeados (API keys, passwords, tokens) |
| `swift` | - SwiftFormat + SwiftLint obligatorio |
| `testing` | - Branches, funciones, lineas, statements |
| `typescript` | - Tipos explícitos para APIs públicas, inferidos para variables locales |
| `verificacion-adversarial` | Regla nacida de una preocupación real: los LLM tienden a la |
| `versionado-siempre` | **Todo lo que acumule trabajo va con git.** Una herramienta de sincronización entre equipos y las |

### Scripts

| Script | Description |
|---|---|
| `scripts/check_memory_size.sh` | Warns when a project's `MEMORY.md` is close to the size where Claude Code silently truncates it |
| `scripts/audio-nota.sh` | Text → voice note sent to Telegram (edge-tts, free). Used by `/audio`. Needs `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` |

### Hooks

#### [Telegram Approval](hooks/telegram-approval/)
Smart PreToolUse hook that classifies operations by risk level and lets you approve dangerous ones via Telegram.

- **3 modes**: Terminal only, Terminal + Telegram (hybrid), Telegram blocking
- **Smart filtering**: Safe ops auto-approve, dangerous ops require approval
- **Configurable sensitivity**: `all`, `smart` (default), `critical`

### Statusline

#### [Custom Statusline](statusline/)
Rich status bar showing real-time metrics:
- Context window usage with progress bar
- Input/output token counts
- Session tracking (prompts, burn rate)
- Git branch info

## Requirements & Dependencies

### Quick Setup

```bash
# Install the toolkit
bash install.sh

# Install all system dependencies
bash install-deps.sh --all

# Check what's installed
bash install-deps.sh --check
```

### System Packages (apt)

| Package | Used by | Purpose |
|---------|---------|---------|
| `jq` | Hooks, Statusline | JSON processing |
| `curl` | Hooks, Web scraper | HTTP requests |
| `bc` | Statusline | Cost calculations |
| `git` | Multiple | Version control |
| `pandoc` | docx, pptx | Document conversion |
| `poppler-utils` | pdf, docx, pptx | PDF tools (pdftotext, pdftoppm) |
| `libreoffice` | docx, pptx, xlsx | Office document processing |
| `qpdf` | pdf | PDF merge/split |
| `ffmpeg` | whisper-transcribe | Audio/video processing |
| `xvfb` | screenshot-compare | Virtual display for headless browsers |
| `python3` / `pip3` | Multiple skills | Python runtime |
| `nodejs` / `npm` | Multiple skills | Node.js runtime |

### Python Packages (pip)

| Package | Used by |
|---------|---------|
| `reportlab` | pdf, documentos-corporativos |
| `pypdf`, `pdfplumber` | pdf |
| `pytesseract`, `pdf2image` | pdf (OCR) |
| `openpyxl`, `pandas` | xlsx |
| `defusedxml` | docx, pptx, xlsx |
| `markitdown[pptx]` | pptx |
| `beautifulsoup4`, `lxml`, `html5lib` | web-scraper |
| `nodriver` | screenshot-compare |
| `pillow`, `imageio`, `numpy` | slack-gif-creator |
| `youtube-transcript-api` | youtube-transcript |
| `requests` | Multiple |

### Node Packages (npm)

| Package | Used by |
|---------|---------|
| `playwright` | e2e-testing, webapp-testing, screenshot-compare |
| `docx` | docx |
| `pptxgenjs` | pptx |
| `sharp` | pptx, web-artifacts-builder |
| `react`, `react-dom`, `react-icons` | web-artifacts-builder, pptx |

### Optional

| Package | Size | Used by | Install |
|---------|------|---------|---------|
| `faster-whisper` | ~500MB | whisper-transcribe | `bash install-deps.sh --whisper` |
| Chromium browser | ~200MB | Playwright skills | `npx playwright install chromium` |
| Telegram bot | - | Telegram hook | See [hook README](hooks/telegram-approval/) |

### Install by Category

```bash
bash install-deps.sh --system   # System packages (apt)
bash install-deps.sh --python   # Python packages (pip)
bash install-deps.sh --node     # Node packages (npm)
bash install-deps.sh --whisper  # Audio/video transcription (optional)
bash install-deps.sh --check    # Verify what's installed
```

## Contributing

PRs welcome! If you have a useful agent, hook, skill, or rule for Claude Code, open a PR.

## License

MIT
