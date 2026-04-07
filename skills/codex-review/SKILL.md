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
"${CLAUDE_PLUGIN_ROOT}/scripts/run-codex-review.sh" "<prompt>"
```

The script handles branch name, timestamp, and output path automatically. It writes the result to `$TMPDIR/codex-review-<branch>-<timestamp>.md` and cats it to stdout.

**Sandbox:** set `dangerouslyDisableSandbox: true` on this Bash call — codex uses macOS system APIs (`SCDynamicStore`) that are blocked by Claude Code's sandbox.

No `-m` flag — defaults to `gpt-codex-5`.

## Prompt Templates

### Staged Changes Review (prep-commit)

```
<task>
Review the staged changes (git diff --cached) for bugs, logic errors, security issues, missing edge cases, and code quality issues.
</task>
<structured_output_contract>
Provide specific, actionable findings referencing exact file paths and line numbers. Group by severity: high, medium, low.
</structured_output_contract>
<verification_loop>
For each finding, confirm it is present in the diff and not already handled elsewhere in the code.
</verification_loop>
```

### Branch Changes Review (prep-merge-pr)

```
<task>
Review the branch changes (git diff main...HEAD) for bugs, logic errors, security issues, missing edge cases, and code quality issues.
</task>
<structured_output_contract>
Provide specific, actionable findings referencing exact file paths and line numbers. Group by severity: high, medium, low.
</structured_output_contract>
<verification_loop>
For each finding, confirm it is present in the diff and not already handled elsewhere in the code.
</verification_loop>
```

### Design Review (design)

```
<task>
Review the implementation plan in plans/<feature>/implementation-plan.md for architectural issues, missing edge cases, security concerns, scalability problems, over-engineering, and potential technical debt.
</task>
<structured_output_contract>
Provide specific, actionable findings. Group by severity: high, medium, low.
</structured_output_contract>
<verification_loop>
For each finding, confirm it reflects a real gap in the plan and is not already addressed in the document.
</verification_loop>
```

### Design Review — Adversarial (design)

Use when challenging architectural decisions and surfacing unstated assumptions — not for bug-hunting. Run after the standard design review, or instead of it when the design warrants deeper scrutiny.

```
<task>
Challenge the implementation plan in plans/<feature>/implementation-plan.md. Question design choices, surface unstated assumptions, identify tradeoffs that favor the wrong side, and expose areas where the plan optimizes for the wrong thing.
</task>
<structured_output_contract>
For each challenge: state the assumption or decision being questioned, explain the risk or alternative perspective, and suggest what should change or be reconsidered.
</structured_output_contract>
<verification_loop>
For each challenge, confirm it targets a real decision in the plan — not a strawman — and that the alternative perspective is actionable.
</verification_loop>
```

## Agent Pattern

The `codex-review` agent is a **Haiku** wrapper — it runs the Codex CLI command and reports the output. It does NOT fix code.

After presenting findings, STOP. Do not apply fixes or suggest edits — the orchestrator decides what to do next.
