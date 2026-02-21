# Prepare for Merge PR

Run full test suites, code quality checks, and specialized code reviews in parallel using agents, then fix issues and verify.

## Input
"$ARGUMENTS" - Optional context about what was changed in the branch.

## Process

### Step 0: Prerequisite — Clean Working Tree
1. Check for uncommitted changes via `git status`
2. If there are staged or unstaged changes, stop and instruct the user to commit them first (e.g., via `/prep-commit` then `/commit`). All changes must be committed before this workflow runs — reviewers use `git diff main...HEAD` which only sees committed history.

### Step 1: Setup
1. Review all commits on the branch via `git log main..HEAD` and `git diff main...HEAD`
2. Classify changed files into backend and frontend based on your project structure
3. Extract the exact test and quality commands for each side (backend/frontend) from the project's CLAUDE.md or Essential Commands section. You will pass these directly to agents so they can execute immediately without exploring.
4. Check `which codex` to determine if Codex CLI is installed. If not, skip the `codex-review` agent in Step 2.

### Step 2: Parallel Checks (spawn all at once)
Spawn agents via the Task tool in a **single message** so they run simultaneously:

#### Tests (always run full suites — this is the final gate before PR)

| Agent | Model | Task |
|-------|-------|------|
| `backend-tests` | Haiku | `cd {backend dir} && {exact test command}`. Run this command. Report pass/fail + failures. Do NOT fix source code. |
| `frontend-tests` | Haiku | `cd {frontend dir} && {exact test command}`. Run this command. Report pass/fail + failures. Do NOT fix source code. |

#### Quality (conditional — may be skippable)

| Agent | Model | Task | Skip if... |
|-------|-------|------|------------|
| `backend-quality` | Haiku | `cd {backend dir} && {exact quality commands}`. Run these commands. Auto-fix what's possible (e.g. formatter, `--fix` flags). Report remaining errors. | No backend changes, **or** `/prep-commit` already ran backend quality in this conversation with no code changes since |
| `frontend-quality` | Haiku | `cd {frontend dir} && {exact quality commands}`. Run these commands. Auto-fix what's possible (e.g. `--fix` flags). Report remaining errors. | No frontend changes, **or** `/prep-commit` already ran frontend quality in this conversation with no code changes since |

#### Reviews (specialized, parallel with each other and with the above)

| Agent | Model | Task | When to spawn |
|-------|-------|------|---------------|
| `review-correctness` | Opus | Review `git diff main...HEAD` for **functional correctness**: logic bugs, wrong conditions, off-by-one errors, unhandled edge cases, missing error handling, incorrect data flow. Be specific — reference exact lines. Do NOT fix code. | Always |
| `review-quality` | Opus | Review `git diff main...HEAD` for **code quality**: poor naming, unnecessary complexity, duplication, dead code, missing test coverage for new logic, violation of existing patterns in the codebase. Be specific — reference exact lines. Do NOT fix code. | Always |
| `review-security` | Opus | Review `git diff main...HEAD` for **security**: auth/authz bypasses, injection vulnerabilities (SQL, XSS, command), data exposure, insecure defaults, missing input validation at system boundaries. Be specific — reference exact lines. Do NOT fix code. | Changes touch auth, API, DB, or user input handling |
| `codex-review` | Haiku | Run `codex exec --sandbox read-only "Review the branch changes (git diff main...HEAD) for bugs, logic errors, security issues, missing edge cases, and code quality issues. Provide specific, actionable findings referencing exact lines."` and report the output. Do NOT fix code. | Codex CLI not installed (checked in Setup) |

**Why 3 reviewers + Codex?** Each Claude reviewer goes deep on one concern instead of shallow on all. Codex provides an independent second-model perspective on the same changes. They all run in parallel so wall-clock time equals one review.

**Why full test suites but conditional quality?** Tests catch cross-cutting regressions that may not be obvious from the diff. Quality tools only have value for the language that actually changed. If `/prep-commit` already ran quality checks and auto-fixed issues (and no code changed since), re-running them is pure waste.

**Note on review timing:** Reviewers run in parallel with quality agents, so they see pre-fix code. This is acceptable because quality auto-fixes are mechanical (formatting, import sorting) — they don't change logic. Review findings about bugs, security, and edge cases remain valid regardless of formatting changes.

### Step 3: Fix Issues
After **all** agents complete:
1. Stage quality auto-fixes if any: `git add -u` (working tree was clean at start, so this only captures quality agent changes)
2. Collect results from every agent (tests, quality, and all review reports)
3. Deduplicate review findings — multiple reviewers may flag the same issue from different angles
4. If all checks passed and reviews found nothing significant -> skip to Step 4
5. Otherwise, spawn a single Sonnet agent (`fixer`) with the **combined, deduplicated** findings:
   - Test failures, quality errors, and review issues from all reviewers
   - Fix everything in one pass to avoid conflicting edits
6. After fixer completes, re-stage and re-run **once** only the checks that had failures. If re-verification still fails, report remaining failures to the user and stop — do not loop.

### Step 4: Report
1. If there are uncommitted fix changes, commit them using the `/commit` command
2. Report readiness:
   - Summary of all branch changes
   - Issues found and fixed
   - Confirmation that full test suites and quality checks pass

## Approach
- **Maximum parallelism**: up to 8 agents in Phase 2 (2 tests + 2 quality + 3 reviews + Codex review), fewer if quality is skipped or Codex not installed
- **Specialized reviews**: each reviewer goes deep on one concern instead of shallow on everything
- **Conditional agents**: security review only for security-sensitive changes; quality skipped for unchanged sides
- **Full test suites**: final gate before PR — catches cross-cutting regressions
- **Deduplicated findings**: merge overlapping issues before passing to the fixer
- **Single fix pass**: one agent sees all findings to avoid conflicting edits
- **Re-verify once**: single re-verification pass, then stop — no infinite loops
- Don't create the PR — just prepare the branch for a clean merge
