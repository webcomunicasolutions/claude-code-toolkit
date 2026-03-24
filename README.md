# Claude Code Toolkit

A comprehensive collection of agents, skills, commands, rules, hooks, and utilities to supercharge your [Claude Code](https://docs.anthropic.com/en/docs/claude-code) experience.

## What's inside

| Component | Count | Description |
|-----------|-------|-------------|
| [**Agents**](agents/) | 32 | Specialized agents for code review, TDD, security, architecture, and more |
| [**Skills**](skills/) | 62 | Domain knowledge packs: from PDF generation to n8n workflows |
| [**Commands**](commands/) | 15 | Slash commands for common workflows (`/tdd`, `/plan`, `/build-fix`...) |
| [**Rules**](rules/) | 17 | Coding standards for 12+ languages and cross-cutting concerns |
| [**Hooks**](hooks/) | 1 | Telegram approval hook for remote action control |
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
bash install.sh --skills      # 62 skills
bash install.sh --commands    # 15 commands
bash install.sh --rules       # 17 coding rules
bash install.sh --statusline  # Status bar
bash install.sh --hook        # Telegram approval hook
bash install.sh --ecc         # Import extras from Everything Claude Code
```

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

### Agents (32)

#### Code Reviewers
| Agent | Languages/Focus |
|-------|----------------|
| `code-reviewer` | General quality, security, and maintainability |
| `typescript-reviewer` | TypeScript/JavaScript, React, Next.js |
| `python-reviewer` | Python, Django, FastAPI, Flask |
| `go-reviewer` | Go concurrency, error handling, idioms |
| `rust-reviewer` | Rust safety, ownership, idioms |
| `java-reviewer` | Java, Spring Boot, JPA |
| `kotlin-reviewer` | Kotlin, Android/KMP, Compose |
| `cpp-reviewer` | C++ memory safety, RAII, modern C++ |
| `flutter-reviewer` | Flutter/Dart, widgets, state management |
| `database-reviewer` | PostgreSQL queries, schemas, RLS, indexing |

#### Build Resolvers
| Agent | Scope |
|-------|-------|
| `build-error-resolver` | Generic build/compilation errors |
| `cpp-build-resolver` | C++, CMake |
| `go-build-resolver` | Go, go vet, linters |
| `java-build-resolver` | Java, Maven, Gradle |
| `kotlin-build-resolver` | Kotlin, Gradle |
| `rust-build-resolver` | Rust, cargo, borrow checker |
| `pytorch-build-resolver` | PyTorch, CUDA, tensor shapes |

#### TDD Cycle
| Agent | Phase |
|-------|-------|
| `tdd-red` | Write failing tests first |
| `tdd-green` | Minimum code to pass tests |
| `tdd-refactor` | Improve quality keeping tests green |
| `test-generator` | Comprehensive test case generation |

#### Architecture & Planning
| Agent | Purpose |
|-------|---------|
| `architect` | System design and trade-off evaluation |
| `principal-engineer` | Engineering leadership, Martin Fowler style |
| `planner` | Break features into actionable steps |
| `devils-advocate` | Challenge assumptions, force critical thinking |

#### Operations
| Agent | Purpose |
|-------|---------|
| `security-reviewer` | Vulnerability analysis before deployments |
| `verifier` | Evidence-based verification gate |
| `doc-updater` | Keep documentation in sync with code |
| `refactor-cleaner` | Dead code, duplicates, unused dependencies |
| `loop-operator` | Autonomous work loops with safety guardrails |
| `web-scraper-expert` | Web scraping with anti-bot bypass |
| `ninjaone-docs-expert` | NinjaOne RMM documentation specialist |

### Commands (15)

Slash commands that activate specialized modes:

| Command | Description |
|---------|-------------|
| `/optimize` | Agent-driven project audit (diagnose, execute, verify) |
| `/n8n` | Activate n8n specialist mode |
| `/tdd` | TDD workflow: RED/GREEN/REFACTOR cycle |
| `/plan` | Create implementation plan before coding |
| `/build-fix` | Systematic build error resolution |
| `/code-review` | Exhaustive code review with security checklist |
| `/devfleet` | Orchestrate multiple agents in parallel with worktrees |
| `/loop-start` | Start autonomous loop with safety guardrails |
| `/loop-status` | Check active loop status |
| `/checkpoint` | Create code state checkpoint |
| `/save-session` | Save current session state |
| `/resume-session` | Resume a previously saved session |
| `/model-route` | Select optimal model per task and budget |
| `/eval` | Define and run feature evaluations |
| `/harness-audit` | Audit Claude Code harness configuration |

### Skills (62)

#### Document Generation
| Skill | Description |
|-------|-------------|
| `pdf` | PDF manipulation: extract, create, merge, split, forms |
| `docx` | Word documents with tracked changes and comments |
| `pptx` | Presentations with layouts and speaker notes |
| `xlsx` | Spreadsheets with formulas, formatting, analysis |
| `documentos-corporativos` | Corporate PDF templates with header/footer branding |

#### n8n Workflow Automation
| Skill | Description |
|-------|-------------|
| `n8n-workflow` | Create, modify, and optimize n8n workflows |
| `n8n-workflow-patterns` | Proven architectural patterns for workflows |
| `n8n-code-javascript` | JavaScript in n8n Code nodes |
| `n8n-code-python` | Python in n8n Code nodes |
| `n8n-expression-syntax` | Expression syntax and troubleshooting |
| `n8n-mcp-tools-expert` | MCP tools for n8n management |
| `n8n-node-configuration` | Node configuration guidance |
| `n8n-validation-expert` | Validation error interpretation |

#### Language Patterns & Testing
| Skill | Description |
|-------|-------------|
| `python-patterns` | Idiomatic Python: type hints, dataclasses, async |
| `python-testing` | pytest fixtures, parametrization, mocking |
| `golang-patterns` | Go idioms: error handling, concurrency, interfaces |
| `golang-testing` | Table-driven tests, subtests, benchmarks |
| `rust-patterns` | Ownership, error handling, traits, async |
| `rust-testing` | Unit, integration, property-based testing |
| `kotlin-testing` | Kotest, MockK, coroutines, Flow |

#### Web Frameworks
| Skill | Description |
|-------|-------------|
| `django-patterns` | Django/DRF: models, views, serializers, signals |
| `laravel-patterns` | Laravel: controllers, Eloquent, queues, events |
| `springboot-patterns` | Spring Boot: REST, JPA, validation, caching |

#### Frontend & Design
| Skill | Description |
|-------|-------------|
| `frontend-design` | Production-grade web interfaces with high design quality |
| `web-artifacts-builder` | Multi-component HTML artifacts with React + Tailwind + shadcn/ui |
| `canvas-design` | Visual art in PNG/PDF using design principles |
| `algorithmic-art` | Generative art with p5.js and seeded randomness |
| `brand-guidelines` | Anthropic brand colors and typography |
| `theme-factory` | 10 pre-set themes for any artifact |
| `slack-gif-creator` | Animated GIFs optimized for Slack |

#### DevOps & Infrastructure
| Skill | Description |
|-------|-------------|
| `docker-patterns` | Docker/Compose for dev and production |
| `docker-hub` | Docker Hub image management |
| `postgres-patterns` | PostgreSQL indexing, RLS, optimization |
| `database-migrations` | Safe, reversible, zero-downtime migrations |
| `linux-server-audit` | Complete server health check and security audit |

#### AI & Automation
| Skill | Description |
|-------|-------------|
| `agentic-engineering` | Multi-agent system design patterns |
| `autonomous-loops` | Autonomous Claude Code execution patterns |
| `cost-aware-llm` | LLM API cost control and optimization |
| `workflow-automation` | n8n, Temporal, Inngest patterns |
| `ollama-specialist` | Local LLM management with GPU |
| `prompt-optimizer` | 6-phase prompt improvement pipeline |
| `whisper-transcribe` | Audio/video transcription with faster-whisper |
| `youtube-transcript` | YouTube video transcript extraction |

#### Testing & QA
| Skill | Description |
|-------|-------------|
| `e2e-testing` | Playwright E2E with Page Object Model |
| `playwright-cli` | Browser automation for testing and scraping |
| `webapp-testing` | Local web app testing with Playwright |
| `verification-loop` | 6-phase QA system before delivery |
| `screenshot-compare` | Screenshot capture for visual comparison |

#### Project Management
| Skill | Description |
|-------|-------------|
| `project-optimizer` | 6-phase project audit and optimization |
| `project-bridge` | Structured communication between Claude Code projects |
| `session-management` | Session persistence between conversations |
| `doc-maintenance` | Documentation structure and organization |
| `doc-coauthoring` | Structured doc co-authoring workflow |
| `doc-specialist` | Generate agents from scraped documentation |
| `skill-creator` | Guide for creating new skills |
| `skills-sh-search` | Browse and install skills from skills.sh |

#### Communication
| Skill | Description |
|-------|-------------|
| `internal-comms` | Internal communications templates |
| `telegram` | Telegram approval mode toggle |
| `web-scraper` | Website scraping to clean Markdown |

#### Specialized
| Skill | Description |
|-------|-------------|
| `ninjaone-specialist` | NinjaOne RMM PowerShell scripts |
| `api-design` | REST API conventions and design |
| `mcp-builder` | Build MCP servers (Python/Node) |

### Rules (17)

Coding standards and best practices loaded automatically:

| Rule | Scope |
|------|-------|
| `coding-style` | General: immutability, file size, function size, error handling |
| `security` | OWASP checks, secret management, input validation |
| `testing` | 80% coverage minimum, TDD workflow, anti-patterns |
| `git-workflow` | Commit format, PR standards, branch naming |
| `patterns` | Repository pattern, API response format, error handling |
| `performance` | Model selection, context window, optimization |
| `typescript` | TS/JS: type safety, Zod validation, React patterns |
| `python` | PEP 8, type annotations, pytest, immutability |
| `go` | gofmt, error wrapping, functional options, table-driven tests |
| `rust` | rustfmt, clippy, error handling, unsafe boundaries |
| `java` | google-java-format, records, Spring Boot patterns |
| `kotlin` | ktlint/Detekt, sealed classes, coroutines, Result<T> |
| `cpp` | C++17+, RAII, smart pointers, sanitizers |
| `csharp` | .NET conventions, nullable types, async/await |
| `php` | PSR-12, strict_types, Laravel patterns |
| `perl` | v5.36, Moo, taint mode, Test2::V0 |
| `swift` | SwiftFormat/Lint, value types, actors, Keychain |

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

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- `jq` and `curl` (for hooks and statusline)
- `bc` (for statusline cost calculations)
- A Telegram bot (only for the Telegram hook)

## Contributing

PRs welcome! If you have a useful agent, hook, skill, or rule for Claude Code, open a PR.

## License

MIT
