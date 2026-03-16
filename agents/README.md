# Custom Agents for Claude Code

8 specialized agents that extend Claude Code with focused capabilities.

## Available Agents

### Code Quality
| Agent | Description | Model |
|-------|-------------|-------|
| `code-reviewer` | Senior code review for quality, security, OWASP Top 10 | Sonnet |
| `principal-engineer` | Martin Fowler-style engineering guidance and pragmatism | Sonnet |
| `verifier` | Verification gate - requires evidence before claiming success | Sonnet |

### TDD Cycle
| Agent | Description | Model |
|-------|-------------|-------|
| `tdd-red` | Write failing tests BEFORE implementation. One test at a time | Sonnet |
| `tdd-green` | Minimum code to make tests pass. No over-engineering | Sonnet |
| `tdd-refactor` | Improve quality, security, and design keeping tests green | Sonnet |

### Testing & Thinking
| Agent | Description | Model |
|-------|-------------|-------|
| `test-generator` | Generate comprehensive test cases analyzing code and edge cases | Sonnet |
| `devils-advocate` | Challenge assumptions and force critical thinking. Asks "why?" | Sonnet |

## Install

```bash
cp *.md ~/.claude/agents/
```

Agents are automatically available in Claude Code after copying.

## Usage

Claude Code will automatically use agents when appropriate, or you can reference them explicitly in your prompts.

The TDD agents work as a cycle: **red** (write failing test) → **green** (make it pass) → **refactor** (improve quality) → repeat.
