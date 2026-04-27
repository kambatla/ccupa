---
description: "Run full test suites and quality checks; fix issues"
disable-model-invocation: true
---

# Prepare for PR

Gate before `/pr` — runs full test suites and quality checks. Code reviews run separately in `/review-pr`.

## Input
"$ARGUMENTS" - Optional context about what was changed.

## Process

### Step 0: Prerequisite — Clean Working Tree
Check for uncommitted changes via `git status`. If any exist, stop — commit them first (e.g., via `/prep-commit` then `/commit`).

### Step 1: Setup
1. Review all commits on the branch via `git log main..HEAD` and `git diff main...HEAD`
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
| `backend-quality` | Haiku | Run this exact command from the project root: `{exact quality commands}`. Auto-fix what the tools can fix automatically (formatter output, `--fix` flags). After all commands complete, you must output results — do not go idle. Report: what was auto-fixed (if anything) and remaining errors that require manual fixes, or **CLEAN** if none. Do NOT explore the codebase beyond these commands. | No backend changes, **or** `/prep-commit` already ran backend quality in this conversation with no code changes since |
| `frontend-quality` | Haiku | Run this exact command from the project root: `{exact quality commands}`. Auto-fix what the tools can fix automatically (`--fix` flags). After all commands complete, you must output results — do not go idle. Report: what was auto-fixed (if anything) and remaining errors that require manual fixes, or **CLEAN** if none. Do NOT explore the codebase beyond these commands. | No frontend changes, **or** `/prep-commit` already ran frontend quality in this conversation with no code changes since |

### Step 3: Fix-Verify Loop
1. Stage quality auto-fixes: `git add -u`
2. Collect results from every agent
3. If all checks passed -> skip to **Step 4: Report**

Fix in two sequential phases (max 3 iterations each).

**After each fixer run** — capture touched files: `git diff --name-only` + `git ls-files --others --exclude-standard`, classified by layer. Re-stage: `git add -u` + any new files the fixer created. Exit the phase immediately if the fixer made no changes.

**Phase A — Test failures:**
- Skip if all tests passed
- Spawn Sonnet fixer with failing test names and error messages
- Re-run: backend tests if fixer touched backend files; frontend tests if fixer touched frontend files; integration tests if fixer touched either
- All pass -> Phase B. 3 iterations exhausted -> report remaining failures in Step 4 and stop.

**Phase B — Quality errors:**
- Skip if quality agents found no errors
- Spawn Sonnet fixer with remaining quality errors
- Re-run: quality checks only for fixer-touched layers. Do NOT re-run tests.
- All pass -> exit. 3 iterations exhausted -> report remaining in Step 4.

### Step 4: Report
Report: all branch changes, issues found and fixed, confirmation that full test suites and quality checks pass. Do not create the PR.

After reporting, write state:
```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD) && mkdir -p .ccupa/$BRANCH && touch .ccupa/$BRANCH/prep-pr
```
