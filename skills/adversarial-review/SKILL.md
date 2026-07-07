---
name: adversarial-review
description: Loop adversarial de revision de codigo con multiples agentes. Lanza reviewers con incentivos para romper el codigo, aplica fixes, re-testea, y repite hasta 0 bugs. Usar despues de features grandes o antes de releases. NOT for style reviews or minor changes.
---

# Adversarial Review Loop

Multi-agent adversarial code review that runs until zero bugs are found.

## When to use
- After completing a large feature or multiple features
- Before publishing to PyPI/npm/crates.io
- Before creating a PR to an important upstream repo
- When you want to be SURE the code is production-ready
- After rapid development sessions (speed introduces bugs)

## How it works

### Phase 1: Run tests
```
pytest / npm test / cargo test / go test
```
If tests fail, fix first. Don't review broken code.

### Phase 2: Launch adversarial reviewers (parallel)

Launch 2 agents in parallel with ADVERSARIAL prompts:

**Agent A: Code Breaker**
```
subagent_type: code-reviewer
prompt: |
  BUG BOUNTY: Find bugs that cause data loss, crashes, or incorrect behavior.

  Project: {PROJECT_PATH}
  Previous fixes: {LIST_OF_PREVIOUS_FIXES}

  RULES:
  - ONLY report bugs reproducible with a concrete command
  - NO style suggestions, NO "could be better", NO theoretical issues
  - For each bug: file:line, command to reproduce, expected vs actual

  If nothing found, say: "BOUNTY UNCLAIMED — code is production-ready"
```

**Agent B: Security Hunter**
```
subagent_type: security-reviewer
prompt: |
  BUG BOUNTY: Find security vulnerabilities with real impact.

  Project: {PROJECT_PATH}
  Previous fixes: {LIST_OF_PREVIOUS_FIXES}

  RULES:
  - ONLY report vulnerabilities with concrete exploit steps
  - NO theoretical "could be exploited if..." scenarios
  - For each vuln: file:line, exploit command, impact

  If nothing found, say: "BOUNTY UNCLAIMED — no exploitable vulnerabilities"
```

### Phase 3: Apply fixes

For each real bug found:
1. Fix the code (minimal change)
2. Add a test that catches the bug
3. Run full test suite
4. Continue to next bug

### Phase 4: Re-run reviewers

If Phase 2 found bugs → go back to Phase 2 with updated fix list.
If Phase 2 found 0 bugs → DONE.

### Phase 5: Publish

If publishing to a registry:
1. Version bump
2. Update CHANGELOG
3. Build package
4. Upload
5. Git commit + push

## Key learnings from real usage

These patterns were discovered during a real 7-round review session:

### Normal reviews are soft
- Reviewers with normal prompts ("find bugs") tend to say "CLEAN" too early
- ALWAYS use adversarial prompts ("I'll pay you to break this")
- The $50K bounty phrasing produces better results than "please review"

### Each reviewer has blind spots
- Code reviewers miss security issues
- Security reviewers miss logic bugs
- ALWAYS launch both in parallel

### Systematic patterns hide in plain sight
- A bug in one place often exists in 15+ similar places
- After fixing one `dict['key']`, grep for ALL similar patterns
- Fix the PATTERN, not just the instance

### The "CLEAN" lie
- Round 5 said "CLEAN" but Round 5-adversarial found 6 bugs
- NEVER trust a single "CLEAN" verdict
- Need at least 2 consecutive clean rounds (one normal + one adversarial)

### Convergence pattern
- Round 1: 16 bugs (fresh code)
- Round 2: 9 bugs
- Round 3: 7 bugs
- Round 4: 3 bugs
- Round 5: 6 bugs (adversarial found what normal missed!)
- Round 6: 5 bugs (systematic pattern)
- Round 7: 0 bugs (truly clean)

## Usage

```
/adversarial-review
```

Or invoke from another context:
```
Use the adversarial-review skill to review the code before publishing.
```

## Tips

- Run tests BEFORE launching reviewers (don't waste their time on broken code)
- Keep a running list of all previous fixes to include in prompts
- The fix list helps reviewers avoid re-reporting known issues
- Version bump AFTER reviews, not before
- Always publish to registry after successful review (don't let fixes sit unpublished)
