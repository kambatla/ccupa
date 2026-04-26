---
description: "Run tests, quality checks, and code review in parallel; fix issues"
disable-model-invocation: true
---

# Prepare for Commit

## Input
"$ARGUMENTS" - Optional context about what was changed. Include `--bugfix` to trigger bug fix verification.

## Finding Format

Reviewer agents must number and structure their findings:

```
[1] high | security — User input passed directly to query without validation (api/search.py:23)
[2] medium | correctness — Pagination skips last item when count equals page size (api/items.py:87)
[3] low | quality — Variable name `x` is not descriptive (utils.py:12)
```

Format: `[N] severity | category — description (file:line)`

- **severity**: `high`, `medium`, or `low`
- **category**: `correctness`, `security`, or `quality`
- If no findings: output `[none]`

## Process

### Step 1: Setup
1. Identify changed files via `git diff --name-only` (staged + unstaged vs HEAD) and new untracked files via `git ls-files --others --exclude-standard`
2. Classify changes into backend and frontend based on your project structure
3. Stage only the identified changed files (NOT `git add -A`)
4. Extract the exact test and quality commands for each side (backend/frontend) from the project's CLAUDE.md or Essential Commands section. Commands must work from the project root (e.g. `pytest backend/`, `npm --prefix frontend test`) — if the project only documents `cd`-based commands, adapt them.
5. Run permission preflight (`skills/permissions/preflight.md`). Dynamic patterns are the test and quality commands from item 4.
6. Detect if this is a bug fix: `$ARGUMENTS` contains `--bugfix` or branch name starts with `bug-`
7. If bug fix -> run Step 1.5 before proceeding

### Step 1.5: Bug Fix Verification (only for bug fixes)
**Skip condition:** If the conversation shows the `/bug` workflow was followed (test written first -> verified failing -> fix applied -> verified passing), log "Bug fix verification: skipped (already proven via /bug workflow)" and proceed to Step 2.

**Otherwise:**
1. Identify the specific test file(s) covering the bug fix
2. If no corresponding test files exist, **stop and ask the user** — a bug fix without a regression test is incomplete
3. Stash the fix: `git stash -u`
4. Run the scoped test(s) -> **confirm they FAIL**
5. If step 4 didn't fail: the test doesn't catch the bug — **flag this to the user and stop**
6. Restore the fix: `git stash pop`
7. Run the scoped test(s) -> **confirm they PASS**

Must complete before Step 2 — stashing during parallel agent runs would break file reads.

### Step 2: Parallel Checks (spawn all at once)
Spawn fresh agents via the Task tool in a **single message**:

| Agent | Model | Task | Skip if... |
|-------|-------|------|------------|
| `backend-tests` | Haiku | Run this exact command from the project root: `{exact test command for changed files}`. After it completes, you must output results — do not go idle. Report: **PASS** if all tests passed, or **FAIL** with the specific failing test names and error messages. Do NOT fix code or explore the codebase. | No backend changes |
| `frontend-tests` | Haiku | Run this exact command from the project root: `{exact test command for changed files}`. After it completes, you must output results — do not go idle. Report: **PASS** if all tests passed, or **FAIL** with the specific failing test names and error messages. Do NOT fix code or explore the codebase. | No frontend changes |
| `backend-quality` | Haiku | Run this exact command from the project root: `{exact quality commands}`. Auto-fix what the tools can fix automatically (formatter output, `--fix` flags). After all commands complete, you must output results — do not go idle. Report: what was auto-fixed (if anything) and remaining errors that require manual fixes, or **CLEAN** if none. Do NOT explore the codebase beyond these commands. | No backend changes |
| `frontend-quality` | Haiku | Run this exact command from the project root: `{exact quality commands}`. Auto-fix what the tools can fix automatically (`--fix` flags). After all commands complete, you must output results — do not go idle. Report: what was auto-fixed (if anything) and remaining errors that require manual fixes, or **CLEAN** if none. Do NOT explore the codebase beyond these commands. | No frontend changes |
| `reviewer` | Sonnet | First read `git log --oneline -10` and the branch name (`git rev-parse --abbrev-ref HEAD`) to understand the intent of this work. Then review `git diff --cached` with that intent as context. Look for bugs, logic errors, security issues, missing edge cases. Flag changes that contradict or drift from the stated intent. Format findings per the **Finding Format** section above. Do NOT fix code. | Never skip |
| `ext-review` | Sonnet | Invoke external review per `ccupa:gemini-review` skill (fallback to `ccupa:codex-review` if gemini is unavailable). Pass `git diff --cached` as the diff. Format findings per the **Finding Format** section above. | Skip if neither gemini nor codex CLI is installed |

### Step 3: Fix-Verify Loop
1. Re-stage changes: `git add -u`
2. Collect results from every agent
3. Deduplicate findings — assign each raw finding a global ID `{agent-name}:{N}` (e.g., `reviewer:1`), group findings that refer to the same issue (same file+line, or clearly the same bug described differently).
4. If all checks passed and review found nothing significant -> skip to **Step 4: Report**

Fix in two sequential phases (max 2 iterations each).

**After each fixer run** — capture touched files: `git diff --name-only` + `git ls-files --others --exclude-standard`, classified by layer. Re-stage: `git add -u` + any new files the fixer created. Exit the phase immediately if the fixer made no changes.

**Phase A — Correctness** (test failures + reviewer and ext-review findings):
- Skip if tests passed and both reviewer and ext-review had no findings
- Spawn fixer per `ccupa:review-resolver` skill with Phase A findings
- Re-run: backend tests if fixer touched backend files; frontend tests if fixer touched frontend files; re-run reviewer only if fixer ACTED on at least one finding
- All pass → Phase B. 2 iterations exhausted → report remaining failures in Step 4 and stop.

**Phase B — Quality** (quality check errors):
- Skip if quality agents found no errors
- Spawn fixer per `ccupa:review-resolver` skill with Phase B findings
- Re-run: quality checks only for fixer-touched layers. Do NOT re-run tests.
- All pass → exit. 2 iterations exhausted → report remaining in Step 4.

### Step 4: Report
Report: what was checked, issues found and fixed, confirmation all checks pass. Do NOT run `/commit`.
