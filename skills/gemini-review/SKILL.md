---
name: gemini-review
description: Gemini CLI invocation patterns for code and design reviews. Defines standard flags, prompt templates, and skip conditions. Preferred over codex-review when both CLIs are installed. Use when spawning ext-review agents.
---

# Gemini Review

Check `which gemini` before invoking. Fall back to `ccupa:codex-review` if not installed.

## Invocation

```
"${CLAUDE_PLUGIN_ROOT}/skills/gemini-review/run-gemini-review.sh" "<prompt>" "<diff-command>"
```

- `<diff-command>` defaults to `git diff --cached`; use `git diff main...HEAD` for branch reviews
- Script embeds the diff in the prompt, writes output to `$TMPDIR/gemini-review-<branch>-<timestamp>.md`, cats to stdout
- No sandbox override needed (unlike codex)
- Flags: `--approval-mode plan`, `--output-format text`, `--skip-trust`

## Prompt Templates

### Staged Changes (prep-commit)

```
<task>
Review the staged changes in the diff below for bugs, logic errors, security issues, missing edge cases, and code quality issues.
</task>
<structured_output_contract>
Provide specific, actionable findings referencing exact file paths and line numbers. Group by severity: high, medium, low.
</structured_output_contract>
<verification_loop>
For each finding, confirm it is present in the diff and not already handled elsewhere in the code.
</verification_loop>
```

### Branch Changes (review-branch / review-pr)

Pass `"git diff main...HEAD"` as the second argument.

```
<task>
Review the branch changes in the diff below for bugs, logic errors, security issues, missing edge cases, and code quality issues.
</task>
<structured_output_contract>
Provide specific, actionable findings referencing exact file paths and line numbers. Group by severity: high, medium, low.
</structured_output_contract>
<verification_loop>
For each finding, confirm it is present in the diff and not already handled elsewhere in the code.
</verification_loop>
```

### Design Review (design)

Pass `"cat plans/<feature>/implementation-plan.md"` as the second argument.

```
<task>
Review the implementation plan below for architectural issues, missing edge cases, security concerns, scalability problems, over-engineering, and potential technical debt.
</task>
<structured_output_contract>
Provide specific, actionable findings. Group by severity: high, medium, low.
</structured_output_contract>
<verification_loop>
For each finding, confirm it reflects a real gap in the plan and is not already addressed in the document.
</verification_loop>
```

### Design Review — Adversarial (design)

Use to challenge architectural decisions, not for bug-hunting. Pass `"cat plans/<feature>/implementation-plan.md"` as the second argument.

```
<task>
Challenge the implementation plan below. Question design choices, surface unstated assumptions, identify tradeoffs that favor the wrong side, and expose areas where the plan optimizes for the wrong thing.
</task>
<structured_output_contract>
For each challenge: state the assumption or decision being questioned, explain the risk or alternative perspective, and suggest what should change or be reconsidered.
</structured_output_contract>
<verification_loop>
For each challenge, confirm it targets a real decision in the plan — not a strawman — and that the alternative perspective is actionable.
</verification_loop>
```
