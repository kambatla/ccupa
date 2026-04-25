---
description: "Run full test suites and quality checks; fix issues"
disable-model-invocation: true
---

# Prepare for PR

Run full test suites and code quality checks in parallel using agents, then fix issues and verify. This is the gate before `/pr` — it ensures the branch is clean but does not run code reviews (that's `/review-pr`).

## Input
"$ARGUMENTS" - Optional context about what was changed in the branch.

## Process

### Step 0: Prerequisite — Clean Working Tree
1. Check for uncommitted changes via `git status`
2. If there are staged or unstaged changes, stop and instruct the user to commit them first (e.g., via `/prep-commit` then `/commit`). All changes must be committed before this workflow runs — test suites run against the committed codebase.

### Step 1: Setup
1. Review all commits on the branch via `git log main..HEAD` and `git diff main...HEAD`
2. Classify changed files into backend and frontend based on your project structure
3. Extract the exact test and quality commands for each side (backend/frontend), and the integration test command (single suite, not split by side), from the project's CLAUDE.md or Essential Commands section. You will pass these directly to agents so they can execute immediately without exploring.
4. Run permission preflight (`skills/permissions/preflight.md`). Dynamic patterns are the test and quality commands from item 3.

### Step 2: Parallel Checks (spawn all at once)
Spawn fresh agents via the Task tool in a **single message** so they run simultaneously:

#### Tests (always run full suites — this is the final gate before PR)

| Agent | Model | Task | Skip if... |
|-------|-------|------|------------|
| `backend-tests` | Haiku | Run this exact command from the project root: `{exact test command}`. After it completes, you must output results — do not go idle. Report: **PASS** if all tests passed, or **FAIL** with the specific failing test names and error messages. Do NOT fix code or explore the codebase. | No backend changes |
| `frontend-tests` | Haiku | Run this exact command from the project root: `{exact test command}`. After it completes, you must output results — do not go idle. Report: **PASS** if all tests passed, or **FAIL** with the specific failing test names and error messages. Do NOT fix code or explore the codebase. | No frontend changes |
| `integration-tests` | Haiku | Run this exact command: `{exact integration test command}`. **Set `dangerouslyDisableSandbox: true` on the Bash call** — integration tests connect to a real database which is blocked by the sandbox. After it completes, you must output results — do not go idle. Report: **PASS** if all tests passed, or **FAIL** with the specific failing test names and error messages. Do NOT fix code or explore the codebase. | No integration test command defined in project |

#### Quality (conditional — may be skippable)

| Agent | Model | Task | Skip if... |
|-------|-------|------|------------|
| `backend-quality` | Haiku | Run this exact command from the project root: `{exact quality commands}`. Auto-fix what the tools can fix automatically (formatter output, `--fix` flags). After all commands complete, you must output results — do not go idle. Report: what was auto-fixed (if anything) and remaining errors that require manual fixes, or **CLEAN** if none. Do NOT explore the codebase beyond these commands. | No backend changes, **or** `/prep-commit` already ran backend quality in this conversation with no code changes since |
| `frontend-quality` | Haiku | Run this exact command from the project root: `{exact quality commands}`. Auto-fix what the tools can fix automatically (`--fix` flags). After all commands complete, you must output results — do not go idle. Report: what was auto-fixed (if anything) and remaining errors that require manual fixes, or **CLEAN** if none. Do NOT explore the codebase beyond these commands. | No frontend changes, **or** `/prep-commit` already ran frontend quality in this conversation with no code changes since |

**Why full test suites but conditional quality?** Tests (unit + integration) catch cross-cutting regressions that may not be obvious from the diff. Integration tests run the full stack and are the strongest signal before PR. Quality tools only have value for the language that actually changed. If `/prep-commit` already ran quality checks and auto-fixed issues (and no code changed since), re-running them is pure waste.

### Step 3: Fix-Verify Loop
After **all** agents complete:
1. Stage quality auto-fixes if any: `git add -u` (working tree was clean at start, so this only captures quality agent changes)
2. Collect results from every agent
3. If all checks passed -> skip to **Step 4: Report**

Fix in two sequential phases (max 3 iterations each).

**After each fixer run** — capture touched files: `git diff --name-only` (modified tracked files) + `git ls-files --others --exclude-standard` (new files), classified by layer using Step 1 logic. Re-stage: `git add -u` + any new files the fixer created (only in directories it was working in). Exit the phase immediately if the fixer made no changes — it determined the remaining issues don't warrant fixes.

**Phase A — Test failures:**
- Skip if all tests passed
- Spawn Sonnet fixer with failing test names and error messages
- Re-run: backend tests if fixer touched backend files; frontend tests if fixer touched frontend files; integration tests if fixer touched either
- All pass -> Phase B. 3 iterations exhausted -> report remaining failures in Step 4 and stop.

**Phase B — Quality errors:**
- Skip if quality agents found no errors
- Spawn Sonnet fixer with remaining quality errors
- Re-run: quality checks only for fixer-touched layers. Do NOT re-run tests — quality fixes don't affect logic.
- All pass -> exit. 3 iterations exhausted -> report remaining in Step 4.

### Step 4: Report
1. Report readiness:
   - Summary of all branch changes
   - Issues found and fixed
   - Confirmation that full test suites and quality checks pass
2. Do not create the PR — just prepare the branch for `/pr`.

## Approach
- **Maximum parallelism**: up to 5 agents in Step 2 (2 unit tests + 1 integration tests + 2 quality), fewer if quality is skipped or integration tests not configured
- **No reviews**: reviews run separately in `/review-pr` after the PR is created
- **Conditional agents**: quality skipped for unchanged sides or if `/prep-commit` already ran them
- **Full test suites**: final gate before PR — catches cross-cutting regressions
- **Sequential fix phases**: Test failures first, then Quality — higher-priority fixes are settled before lower-priority ones run
- **Scoped re-runs**: after each fixer run, re-run only checks for that phase and only for layers the fixer touched (`git diff --name-only`)
- **Per-phase iteration cap**: max 3 iterations per phase; exits early if fixer makes no changes
