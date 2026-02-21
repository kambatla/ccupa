# Prepare for Commit

Run tests, code quality checks, and a code review in parallel using agents, then fix issues and verify.

## Input
"$ARGUMENTS" - Optional context about what was changed in the branch. Include `--bugfix` to trigger bug fix verification (stash/test fail/unstash/test pass).

## Process

### Step 1: Setup
1. Identify changed files via `git diff --name-only` (staged + unstaged vs HEAD) and new untracked files via `git ls-files --others --exclude-standard`
2. Classify changes into backend and frontend based on your project structure
3. Stage only the identified changed files (NOT `git add -A`) so review agents see them without accidentally staging unrelated files
4. Extract the exact test and quality commands for each side (backend/frontend) from the project's CLAUDE.md or Essential Commands section. You will pass these directly to agents so they can execute immediately without exploring.
5. Check `which codex` to determine if Codex CLI is installed. If not, skip the `codex-review` agent in Step 2.
6. Run permission preflight (`skills/permissions/preflight.md`). Dynamic patterns are the test and quality commands from item 4.
7. Detect if this is a bug fix: `$ARGUMENTS` contains `--bugfix` or branch name starts with `bug-`
8. If bug fix -> run Step 1.5 before proceeding

### Step 1.5: Bug Fix Verification (only for bug fixes)
Prove the fix actually fixes something by showing the test fails without it and passes with it.

**Skip condition:** If the conversation history shows that the `/bug` command workflow was followed (test written first -> verified failing -> fix applied -> verified passing), the fail->pass proof already exists. Log "Bug fix verification: skipped (already proven via /bug workflow)" and proceed to Step 2.

**Otherwise**, run the stash-based verification:

1. Identify the specific test file(s) that cover the bug fix (from the changed source -> test file mapping)
2. If no corresponding test files exist, **stop and ask the user** — a bug fix without a regression test is incomplete
3. Stash the fix (including untracked files): `git stash -u`
4. Run the scoped test(s) -> **confirm they FAIL** (this proves the bug is reproducible)
5. If step 4 didn't fail: the test doesn't catch the bug — **flag this to the user and stop** (don't waste time on remaining steps)
6. Restore the fix: `git stash pop`
7. Run the scoped test(s) -> **confirm they PASS** (this proves the fix works)

**Why before parallel checks?** Stashing changes would break concurrent agents reading/writing files. This must complete before spawning any agents.

### Step 2: Parallel Checks (spawn all at once)
Spawn agents via the Task tool in a **single message** so they run simultaneously:

| Agent | Model | Task | Skip if... |
|-------|-------|------|------------|
| `backend-tests` | Haiku | `cd {backend dir} && {exact test command for changed files}`. Run this command. Report pass/fail + failures. Do NOT fix source code. | No backend changes |
| `frontend-tests` | Haiku | `cd {frontend dir} && {exact test command for changed files}`. Run this command. Report pass/fail + failures. Do NOT fix source code. | No frontend changes |
| `backend-quality` | Haiku | `cd {backend dir} && {exact quality commands}`. Run these commands. Auto-fix what's possible (e.g. formatter, `--fix` flags). Report remaining errors. | No backend changes |
| `frontend-quality` | Haiku | `cd {frontend dir} && {exact quality commands}`. Run these commands. Auto-fix what's possible (e.g. `--fix` flags). Report remaining errors. | No frontend changes |
| `reviewer` | Opus | Review `git diff --cached` with fresh eyes. Look for bugs, logic errors, security issues, missing edge cases. Provide specific, actionable findings. Do NOT fix code. | Never skip |
| `codex-review` | Haiku | Run `codex exec --sandbox read-only "Review the staged changes (git diff --cached) for bugs, logic errors, security issues, missing edge cases, and code quality issues. Provide specific, actionable findings referencing exact lines."` and report the output. Do NOT fix code. | Codex CLI not installed (checked in Setup) |

**Why parallel?** These are independent workstreams. Tests are read-only. Quality auto-fixes touch different file sets. The reviewer uses `git diff --cached` which reads from the stable git index.

**Note on review timing:** Reviewers run in parallel with quality agents, so they see pre-fix code. This is acceptable because quality auto-fixes are mechanical (formatting, import sorting) — they don't change logic. Review findings about bugs, security, and edge cases remain valid regardless of formatting changes.

### Step 3: Fix-Verify Loop
After **all** agents complete:
1. Re-stage changes: `git add -u` (captures quality auto-fixes without pulling in unrelated untracked files)
2. Collect results from every agent
3. If all checks passed and review found nothing significant -> skip to **Step 4: Report**

**Loop** (max 4 iterations):

4. Spawn a single Sonnet agent (`fixer`) with all findings from the most recent check run:
   - Test failures, quality errors, and review issues
   - Instruct: fix all issues. If an issue is a false positive or intentional design choice, do not change code for it — explain why in your response.
5. After fixer completes, check for changes via `git diff && git diff --cached` and `git ls-files --others --exclude-standard` (the latter catches new files the fixer may have created):
   - If fixer made **no changes** (no modified files, no new files) -> exit loop. The fixer determined remaining issues don't warrant fixes. Include the fixer's reasoning in the Step 4 report.
6. Re-stage: `git add -u` and `git add` any new files the fixer created (but not unrelated untracked files — only files in directories the fixer was working in)
7. Re-run only the checks that failed in the **most recent** iteration:
   - Tests and quality agents: re-run if they reported failures
   - Review agents: re-run only if the fixer changed code **and** that reviewer had findings in the most recent iteration
8. If all re-run checks pass -> exit loop, proceed to **Step 4: Report**
9. If this was iteration 4 -> exit loop, report remaining failures to the user in **Step 4: Report**
10. Otherwise -> next iteration (loop back to item 4 above with the new findings)

### Step 4: Report
1. Report readiness:
   - Summary of what was checked
   - Any issues found and fixed
   - Confirmation that all checks pass

## Approach
- **Maximum parallelism**: up to 6 agents working simultaneously in Phase 2
- **Skip unused sides**: no wasted work on unchanged code
- **Explicit bug fix flag**: use `--bugfix` to trigger verification — no keyword guessing
- **Fix-verify loop**: fixer sees all findings per iteration, re-runs only failed checks, max 4 iterations. Exits early if fixer makes no code changes (explicit decision not to fix). Prevents infinite loops via hard iteration cap.
- Don't commit — just prepare the code for a clean commit
