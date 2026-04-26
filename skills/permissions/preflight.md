# Permission Preflight

Run before spawning agents. Goal: ensure `.claude/settings.local.json` has all patterns agents will need.

## Procedure

### 1. Compile Required Patterns

**Static** (always needed):
- `Bash(git *)` — git operations
- `Bash(gemini -p *)` — if gemini installed
- `Bash(codex exec *)` — if codex installed (fallback)

**Dynamic** (passed in by the calling command — do not guess):
- Exact test and quality commands, e.g. `Bash(pytest*)`, `Bash(npx vitest*)`

### 2. Check Settings

Read `.claude/settings.local.json`. If it doesn't exist, treat as empty allow list.

### 3. Identify Gaps

A pattern is covered if an exact match or broader wildcard exists in `permissions.allow` (e.g. `Bash(*)` covers `Bash(git *)`).

### 4. Present and Configure

**No gaps:** proceed silently.

**Gaps exist:**

| Pattern | Needed by |
|---------|-----------|
| `Bash(pytest*)` | `backend-tests` agent |
| `Bash(npx vitest*)` | `frontend-tests` agent |

Offer to add missing patterns. If approved, write the file. If declined, warn that agents may block on approval prompts.
