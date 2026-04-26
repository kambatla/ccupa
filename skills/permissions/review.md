# Permission Review

Run after a command completes. Goal: capture runtime-approved patterns so they don't require approval next time.

## Procedure

### 1. Scan for Runtime Approvals

Scan conversation history for tool approval prompts where the user granted permission. Extract tool name and pattern (e.g. `Bash(ruff*)` from a ruff prompt).

**Note:** In long sessions, earlier approvals may have been compressed out of context — this captures what's visible.

### 2. Categorize and Recommend

**Nothing new:** skip silently.

**Patterns to add:**

| Pattern | How it was used |
|---------|-----------------|
| `Bash(ruff*)` | Backend quality checks |

Offer to add to `.claude/settings.local.json`. If approved, write the file.

Do NOT recommend removals based on a single run — a pattern unused once may be needed next time.
