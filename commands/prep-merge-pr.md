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
5. Run permission preflight (`skills/permissions/preflight.md`). Dynamic patterns are the test and quality commands from item 3.

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
| `codex-review` | Haiku | Run `codex exec --sandbox read-only "Review the branch changes (git diff main...HEAD) for bugs, logic errors, security issues, missing edge cases, and code quality issues. Provide specific, actionable findings referencing exact lines."` and report the output. Do NOT fix code. | Codex CLI installed (checked in Setup) |

**Why 3 reviewers + Codex?** Each Claude reviewer goes deep on one concern instead of shallow on all. Codex provides an independent second-model perspective on the same changes. They all run in parallel so wall-clock time equals one review.

**Why full test suites but conditional quality?** Tests catch cross-cutting regressions that may not be obvious from the diff. Quality tools only have value for the language that actually changed. If `/prep-commit` already ran quality checks and auto-fixed issues (and no code changed since), re-running them is pure waste.

**Note on review timing:** Reviewers run in parallel with quality agents, so they see pre-fix code. This is acceptable because quality auto-fixes are mechanical (formatting, import sorting) — they don't change logic. Review findings about bugs, security, and edge cases remain valid regardless of formatting changes.

### Step 3: Fix-Verify Loop
After **all** agents complete:
1. Stage quality auto-fixes if any: `git add -u` (working tree was clean at start, so this only captures quality agent changes)
2. Collect results from every agent (tests, quality, and all review reports)
3. Deduplicate review findings for the fixer's input — multiple reviewers may flag the same issue from different angles. **Track which reviewers had findings separately** (needed to decide which reviewers to re-run in the loop).
4. If all checks passed and reviews found nothing significant -> skip to **Step 4: Report**

**Loop** (max 4 iterations):

5. Spawn a single Sonnet agent (`fixer`) with the **combined, deduplicated** findings from the most recent check run:
   - Test failures, quality errors, and review issues from all reviewers
   - Instruct: fix all issues. If an issue is a false positive or intentional design choice, do not change code for it — explain why in your response.
6. After fixer completes, check for changes via `git diff && git diff --cached` and `git ls-files --others --exclude-standard` (the latter catches new files the fixer may have created):
   - If fixer made **no changes** (no modified files, no new files) -> exit loop. The fixer determined remaining issues don't warrant fixes. Include the fixer's reasoning in the Step 4 report.
7. Re-stage: `git add -u` and `git add` any new files the fixer created (but not unrelated untracked files — only files in directories the fixer was working in)
8. Re-run only the checks that failed in the **most recent** iteration:
   - Tests and quality agents: re-run if they reported failures, **or** if the fixer changed files covered by those tests
   - Review agents: re-run only if the fixer changed code **and** that reviewer had findings in the most recent iteration
9. If all re-run checks pass -> exit loop, proceed to **Step 4: Report**
10. If this was iteration 4 -> exit loop, report remaining failures to the user in **Step 4: Report**
11. Otherwise -> next iteration (loop back to item 5 above with the new findings)

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
- **Fix-verify loop**: fixer sees all findings per iteration, re-runs only failed checks, max 4 iterations. Exits early if fixer makes no code changes (explicit decision not to fix). Prevents infinite loops via hard iteration cap.
- Don't create the PR — just prepare the branch for a clean merge
