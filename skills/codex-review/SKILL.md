---
name: codex-review
description: Codex CLI invocation patterns for code and design reviews. Defines standard flags, prompt templates, and skip conditions. Use when spawning ext-review agents.
---

# Codex Review

Check `which codex` before invoking. Skip and log if not installed. Prefer `ccupa:gemini-review` when both are available.

## Invocation

```
"${CLAUDE_PLUGIN_ROOT}/skills/codex-review/run-codex-review.sh" "<prompt>"
```

- Script handles branch name, timestamp, output path automatically; cats result to stdout
- **Set `dangerouslyDisableSandbox: true`** on this Bash call — codex uses `SCDynamicStore` (blocked by sandbox)
- No `-m` flag — defaults to `gpt-codex-5`

## Prompt Templates

### Staged Changes (prep-commit)

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

### Branch Changes (review-pr)

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

Use to challenge architectural decisions, not for bug-hunting.

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
