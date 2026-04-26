---
description: "Run code reviews, tests, and quality checks on the current branch; fix issues; report results"
disable-model-invocation: true
---

# Review Branch

Works on any branch — no PR required. `/review-pr` wraps this and adds a PR comment step.

## Input
"$ARGUMENTS" - Not used.

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

### Step 0: Prerequisites
Check for uncommitted changes via `git status`. If any exist, stop — all changes must be committed before this runs (the fix loop uses `git add -u` and commits).

### Step 1: Setup
1. Read the branch diff: `git log main..HEAD` and `git diff main...HEAD`
2. Classify changed files into backend and frontend based on your project structure
3. Extract the exact test and quality commands for each side (backend/frontend), and the integration test command, from the project's CLAUDE.md or Essential Commands section.
4. Run permission preflight (`skills/permissions/preflight.md`). Dynamic patterns are the test and quality commands from item 3.

### Step 2: Parallel Checks (spawn all at once)
Spawn fresh agents via the Task tool in a **single message**:

| Agent | Model | Task | Skip if... |
|-------|-------|------|------------|
| `backend-tests` | Haiku | Run this exact command from the project root: `{exact test command}`. After it completes, you must output results — do not go idle. Report: **PASS** if all tests passed, or **FAIL** with the specific failing test names and error messages. Do NOT fix code or explore the codebase. | No backend changes |
| `frontend-tests` | Haiku | Run this exact command from the project root: `{exact test command}`. After it completes, you must output results — do not go idle. Report: **PASS** if all tests passed, or **FAIL** with the specific failing test names and error messages. Do NOT fix code or explore the codebase. | No frontend changes |
| `integration-tests` | Haiku | Run this exact command: `{exact integration test command}`. **Set `dangerouslyDisableSandbox: true` on the Bash call** — integration tests connect to a real database which is blocked by the sandbox. After it completes, you must output results — do not go idle. Report: **PASS** if all tests passed, or **FAIL** with the specific failing test names and error messages. Do NOT fix code or explore the codebase. | No integration test command defined in project |
| `backend-quality` | Haiku | Run this exact command from the project root: `{exact quality commands}`. Auto-fix what the tools can fix automatically (formatter output, `--fix` flags). After all commands complete, you must output results — do not go idle. Report: what was auto-fixed (if anything) and remaining errors that require manual fixes, or **CLEAN** if none. Do NOT explore the codebase beyond these commands. | No backend changes |
| `frontend-quality` | Haiku | Run this exact command from the project root: `{exact quality commands}`. Auto-fix what the tools can fix automatically (`--fix` flags). After all commands complete, you must output results — do not go idle. Report: what was auto-fixed (if anything) and remaining errors that require manual fixes, or **CLEAN** if none. Do NOT explore the codebase beyond these commands. | No frontend changes |
| `reviewer` | Opus | First read `git log main..HEAD` to understand the branch intent from commit messages. Then review `git diff main...HEAD` for three categories — label every finding with its category: **[CORRECTNESS]** logic bugs, wrong conditions, off-by-one errors, unhandled edge cases, missing error handling, incorrect data flow, changes that don't align with stated intent; **[SECURITY]** auth/authz bypasses, injection vulnerabilities (SQL, XSS, command), data exposure, insecure defaults, missing input validation at system boundaries; **[QUALITY]** poor naming, unnecessary complexity, duplication, dead code, missing test coverage for new logic, violation of existing patterns. Be specific — reference exact lines. Format findings per the **Finding Format** section above. Do NOT fix code. | Always |

### Step 3: Fix-Verify Loop
1. Stage quality auto-fixes: `git add -u`
2. Collect results from every agent
3. Deduplicate findings — assign each a global ID `{agent-name}:{N}` (e.g., `reviewer:1`), group findings that refer to the same issue.
4. If all checks passed and reviews found nothing -> skip to **Step 4: Report**
5. Include test/quality failures from Step 2 as Phase A / Phase B findings respectively.

Fix in two sequential phases (max 2 iterations each).

**After each fixer run** — capture touched files: `git diff --name-only` + `git ls-files --others --exclude-standard`, classified by layer. Re-stage: `git add -u` + any new files the fixer created. Exit the phase immediately if the fixer made no changes.

**Phase A — Correctness + Security** (test failures + [CORRECTNESS] and [SECURITY] findings):
- Skip if tests passed and reviewer had no [CORRECTNESS] or [SECURITY] findings
- Spawn fixer per `ccupa:review-resolver` skill with Phase A findings
- Re-run: backend tests if fixer touched backend files; frontend tests if fixer touched frontend files; integration tests if fixer touched either; re-run `reviewer` only if fixer ACTED on at least one [CORRECTNESS] or [SECURITY] finding
- All pass -> commit: `fix: address correctness and security review findings`
- 2 iterations exhausted -> report remaining failures in Step 4 and stop.

**Phase B — Quality** (quality check errors + [QUALITY] findings):
- Skip if quality agents had no errors and reviewer had no [QUALITY] findings
- Spawn fixer per `ccupa:review-resolver` skill with Phase B findings
- Re-run: quality checks only for fixer-touched layers. Do NOT re-run tests.
- All pass -> commit: `fix: address quality review findings`
- 2 iterations exhausted -> report remaining in Step 4.

### Step 4: Report
Output a structured summary. `/review-pr` uses this to build the PR comment.

```
## Review Results

**Reviewers:** {list of reviewers that ran}

### Findings

| ID | Severity | Category | Disposition | Details |
|----|----------|----------|-------------|---------|
| reviewer:1 | high | correctness | ACTED | {brief description} |
| reviewer:2 | medium | security | DISMISSED | {reason} |
| ... | ... | ... | ... | ... |

*(No findings)* — if all reviewers returned `[none]`

### Status
- **Tests:** {PASS/FAIL with details}
- **Quality:** {CLEAN/errors with details}
- **Unfixed:** {list of remaining issues, or "None"}
```
