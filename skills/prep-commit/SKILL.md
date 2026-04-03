---
description: "Run tests, quality checks, and code review in parallel; fix issues"
disable-model-invocation: true
---

# Prepare for Commit

Run tests, code quality checks, and a code review in parallel using agents, then fix issues and verify.

## Execution
Run this entire workflow as a separate Task agent (use Opus — synthesizing multi-reviewer findings and coordinating the fix-verify loop requires deep judgment).

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
| `reviewer` | Opus | First read `git log --oneline -10` and the branch name (`git rev-parse --abbrev-ref HEAD`) to understand the intent of this work. Then review `git diff --cached` with that intent as context. Look for bugs, logic errors, security issues, missing edge cases. Flag changes that contradict or drift from the stated intent. Format findings per `ccupa:review-tracking` skill. Do NOT fix code. | Never skip |
| `codex-review` | Haiku | Run the codex command provided below. Report the output formatted as findings per `ccupa:review-tracking` skill. Do NOT fix code. | Codex CLI not installed (checked in Setup) |

**codex-review agent setup:** Before spawning, use the `ccupa:codex-review` skill (loaded in your context) to construct the full **staged changes review** command. Pass the complete command to the agent so it can execute directly.

**Why parallel?** These are independent workstreams. Tests are read-only. Quality auto-fixes touch different file sets. The reviewer uses `git diff --cached` which reads from the stable git index.

**Note on review timing:** Reviewers run in parallel with quality agents, so they see pre-fix code. This is acceptable because quality auto-fixes are mechanical (formatting, import sorting) — they don't change logic. Review findings about bugs, security, and edge cases remain valid regardless of formatting changes.

### Step 3: Fix-Verify Loop
After **all** agents complete:
1. Re-stage changes: `git add -u` (captures quality auto-fixes without pulling in unrelated untracked files)
2. Collect results from every agent
3. Deduplicate findings per `ccupa:review-tracking` skill — assign global IDs, group overlapping findings, identify unique finds per reviewer. **Track which reviewers had findings separately** (needed to decide which to re-run in the loop, and to write the ledger).
4. **Record initial findings** for the ledger: save per-reviewer counts (total_findings, unique_finds) now — before any fixes. These counts do not change in subsequent iterations.
5. If all checks passed and review found nothing significant -> skip to **Step 4: Report**

Fix in two sequential phases (max 3 iterations each).

**After each fixer run** — capture touched files: `git diff --name-only` (modified tracked files) + `git ls-files --others --exclude-standard` (new files), classified by layer using Step 1 logic. Re-stage: `git add -u` + any new files the fixer created (only in directories it was working in). Exit the phase immediately if the fixer made no changes — it determined the remaining issues don't warrant fixes.

**Phase A — Correctness** (test failures + reviewer findings + codex-review findings):
- Skip if tests passed and no reviewer or codex-review had findings
- Spawn fixer per `ccupa:review-resolver` skill with Phase A findings
- Re-run: backend tests if fixer touched backend files; frontend tests if fixer touched frontend files; re-run reviewer only if fixer ACTED on at least one finding
- All pass → Phase B. 3 iterations exhausted → report remaining failures in Step 4 and stop.

**Phase B — Quality** (quality check errors):
- Skip if quality agents found no errors
- Spawn fixer per `ccupa:review-resolver` skill with Phase B findings
- Re-run: quality checks only for fixer-touched layers. Do NOT re-run tests — quality fixes don't affect logic.
- All pass → exit. 3 iterations exhausted → report remaining in Step 4.

### Step 3.5: Write Review Ledger
After the loop exits (regardless of outcome):
1. Collect fixer attribution from all iterations (ACTED/DISMISSED per global finding ID)
2. Compute per-reviewer: `actioned` and `dismissed` counts from the attribution report
3. Append one row per reviewer to `~/.claude/review-ledger.csv` per `ccupa:review-tracking` skill
4. Skip reviewers that were not spawned this run

### Step 4: Report
1. Report readiness:
   - Summary of what was checked
   - Any issues found and fixed
   - Confirmation that all checks pass

## Approach
- **Maximum parallelism**: up to 6 agents working simultaneously in Step 2
- **Skip unused sides**: no wasted work on unchanged code
- **Explicit bug fix flag**: use `--bugfix` to trigger verification — no keyword guessing
- **Sequential fix phases**: Correctness (tests + review) first, then Quality — lower-priority fixes don't run while higher-priority issues are unresolved
- **Scoped re-runs**: after each fixer run, re-run only checks for that phase and only for layers the fixer touched (`git diff --name-only`); re-run reviewer only if fixer ACTED on its findings
- **Per-phase iteration cap**: max 3 iterations per phase; exits early if fixer makes no changes
- Don't commit — just prepare the code for a clean commit
