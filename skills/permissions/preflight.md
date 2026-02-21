# Permission Preflight

Run this procedure before spawning agents in non-interactive commands. Goal: ensure `.claude/settings.local.json` has all patterns agents will need, so they don't block on approval prompts.

## Procedure

### 1. Discover Required Patterns

Compile patterns from two sources:

**Static patterns** (always needed when agents run):
- `Bash(git *)` — git operations
- `Bash(codex exec *)` — Codex CLI (if installed)

**Dynamic patterns** (command-specific):
- Exact test and quality commands discovered during Setup
- Use project-specific prefixes, e.g., `Bash(cd backend && pytest*)`, `Bash(cd frontend && npx vitest*)`
- These are passed in by the calling command — do not guess

### 2. Check Settings

1. Read `.claude/settings.local.json`
2. Parse the `permissions.allow` array
3. If the file doesn't exist, treat as empty allow list

### 3. Identify Gaps

Compare required patterns against allowed patterns. A required pattern is covered if:
- An exact match exists in `permissions.allow`
- A broader wildcard in `permissions.allow` subsumes it (e.g., `Bash(*)` covers `Bash(git *)`)

### 4. Present and Configure

**If no gaps:** proceed silently — no output needed.

**If gaps exist:**
1. Show a table:

| Pattern | Needed by |
|---------|-----------|
| `Bash(cd backend && pytest*)` | `backend-tests` agent |
| `Bash(cd frontend && npx vitest*)` | `frontend-tests` agent |

2. Offer to add missing patterns to `.claude/settings.local.json`
3. If user approves, write the updated file
4. If user declines, warn that agents may block on approval prompts and proceed
