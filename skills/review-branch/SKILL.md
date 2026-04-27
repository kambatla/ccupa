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
5. Include test failures from Step 2 as Phase A inputs; include [CORRECTNESS], [SECURITY], and [QUALITY] review findings from Step 2 as Phase B inputs.

Fix in three sequential phases. Quality is always last. Since this is the last gate before merging to main, tests must be re-confirmed after every fix phase.

**After each fixer run** — capture touched files: `git diff --name-only` + `git ls-files --others --exclude-standard`, classified by layer. Re-stage: `git add -u` + any new files the fixer created.

**Phase A — Tests** (hard cap 10, no lower limit):
- Skip if all tests passed in Step 2
- Spawn fixer per `ccupa:review-resolver` with test failures
- After each fixer run: capture touched files, re-stage, re-run backend/frontend/integration tests for touched layers
- If fixer makes no changes: report remaining test failures and proceed to Phase B
- Repeat until all tests pass or hard cap of 10; if hard cap reached, report and proceed to Phase B

**Phase B — Reviews** (max 3 iterations):
- Skip if reviewer had no findings
- Spawn fixer per `ccupa:review-resolver` with all [CORRECTNESS], [SECURITY], and [QUALITY] findings
- After each fixer run: capture touched files, re-stage, re-run tests for touched layers (include any new test failures in the next iteration's fixer brief alongside remaining review findings); re-run quality checks for touched layers and note any quality failures for Phase C; re-run reviewer if fixer acted on findings
- 3 iterations max, then proceed to Phase C

**Phase C — Quality** (hard cap 10, no lower limit, always last):
- Skip if no quality errors exist (from Step 2 or introduced by Phase B fixes)
- Spawn fixer per `ccupa:review-resolver` with quality errors
- After each fixer run: capture touched files, re-stage, re-run quality checks for touched layers; do NOT re-run tests
- If fixer makes no changes: report remaining and proceed
- Repeat until clean or hard cap of 10

**Final test check**: After Phase C completes, run one final test run (backend/frontend/integration) to confirm quality fixes did not break anything. If tests fail: report them clearly — do not re-enter the fix loop.

**After all phases**: if any fixes were made across phases A, B, or C, run `/commit --skip-prep` once — let `/commit` group changes into logical commits without prescribed messages.

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

After reporting, write state:
```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD) && mkdir -p .ccupa/$BRANCH && touch .ccupa/$BRANCH/review-branch
```
