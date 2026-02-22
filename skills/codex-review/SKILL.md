---
name: codex-review
description: Codex CLI invocation patterns for code and design reviews. Defines standard flags, prompt templates, and skip conditions. Use when spawning codex-review agents.
---

# Codex Review Skill

Centralizes how we invoke the Codex CLI for reviews. Commands reference this skill instead of hardcoding the invocation.

## Prerequisites

Check `which codex` before invoking. If not installed, skip the Codex review and log why.

## Standard Invocation

```
codex exec --quiet --ephemeral --sandbox read-only "<prompt>"
```

| Flag | Purpose |
|------|---------|
| `--quiet` | Minimize output to save context tokens |
| `--ephemeral` | Don't save conversation history (one-shot review) |
| `--sandbox read-only` | Read access to repo, no writes |

No `-m` flag — defaults to `gpt-codex-5`.

## Prompt Templates

### Staged Changes Review (prep-commit)

```
Review the staged changes (git diff --cached) for bugs, logic errors, security issues, missing edge cases, and code quality issues. Provide specific, actionable findings referencing exact lines.
```

### Branch Changes Review (prep-merge-pr)

```
Review the branch changes (git diff main...HEAD) for bugs, logic errors, security issues, missing edge cases, and code quality issues. Provide specific, actionable findings referencing exact lines.
```

### Design Review (design)

```
Review the implementation plan in tmp/<feature>/implementation-plan.md for architectural issues, missing edge cases, security concerns, scalability problems, over-engineering, and potential technical debt. Provide specific, actionable findings.
```

## Agent Pattern

The `codex-review` agent is a **Haiku** wrapper — it runs the Codex CLI command and reports the output. It does NOT fix code.
