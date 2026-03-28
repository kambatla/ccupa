# Prepare for Merge PR

Run full test suites, code quality checks, and specialized code reviews in parallel using agents, then fix issues and verify.

## Execution
Run this entire workflow as a separate Task agent (use Opus — synthesizing multi-reviewer findings and coordinating the fix-verify loop requires deep judgment).

## Input
"$ARGUMENTS" - Optional context about what was changed in the branch.

## Process

### Step 0: Prerequisite — Clean Working Tree
1. Check for uncommitted changes via `git status`
2. If there are staged or unstaged changes, stop and instruct the user to commit them first (e.g., via `/prep-commit` then `/commit`). All changes must be committed before this workflow runs — reviewers use `git diff main...HEAD` which only sees committed history.

### Step 1: Setup
1. Review all commits on the branch via `git log main..HEAD` and `git diff main...HEAD`
2. Classify changed files into backend and frontend based on your project structure
3. Extract the exact test and quality commands for each side (backend/frontend), and the integration test command (single suite, not split by side), from the project's CLAUDE.md or Essential Commands section. You will pass these directly to agents so they can execute immediately without exploring.
4. Check `which codex` to determine if Codex CLI is installed. If not, skip the `codex-review` agent in Step 2.
5. Run permission preflight (`skills/permissions/preflight.md`). Dynamic patterns are the test and quality commands from item 3.

### Step 2: Parallel Checks (spawn all at once)
Spawn agents via the Task tool in a **single message** so they run simultaneously:

#### Tests (always run full suites — this is the final gate before PR)

| Agent | Model | Task | Skip if... |
|-------|-------|------|------------|
| `backend-tests` | Haiku | `cd {backend dir} && {exact test command}`. Run this command. Report pass/fail + failures. Do NOT fix source code. | No backend changes |
| `frontend-tests` | Haiku | `cd {frontend dir} && {exact test command}`. Run this command. Report pass/fail + failures. Do NOT fix source code. | No frontend changes |
| `integration-tests` | Haiku | `{exact integration test command}`. Run this command. Report pass/fail + failures. Do NOT fix source code. | No integration test command defined in project |

#### Quality (conditional — may be skippable)

| Agent | Model | Task | Skip if... |
|-------|-------|------|------------|
| `backend-quality` | Haiku | `cd {backend dir} && {exact quality commands}`. Run these commands. Auto-fix what's possible (e.g. formatter, `--fix` flags). Report remaining errors. | No backend changes, **or** `/prep-commit` already ran backend quality in this conversation with no code changes since |
| `frontend-quality` | Haiku | `cd {frontend dir} && {exact quality commands}`. Run these commands. Auto-fix what's possible (e.g. `--fix` flags). Report remaining errors. | No frontend changes, **or** `/prep-commit` already ran frontend quality in this conversation with no code changes since |

#### Reviews (specialized, parallel with each other and with the above)

| Agent | Model | Task | When to spawn |
|-------|-------|------|---------------|
| `reviewer` | Opus | First read `git log main..HEAD` to understand the branch intent from commit messages. Then review `git diff main...HEAD` for two categories — label every finding with its category: **[CORRECTNESS]** logic bugs, wrong conditions, off-by-one errors, unhandled edge cases, missing error handling, incorrect data flow, changes that don't align with stated intent; **[QUALITY]** poor naming, unnecessary complexity, duplication, dead code, missing test coverage for new logic, violation of existing patterns, commits that bundle unrelated concerns. Be specific — reference exact lines. Format findings per `ccupa:review-tracking` skill. Do NOT fix code. | Always |
| `review-security` | Sonnet | First read `git log main..HEAD` to understand the branch intent. Then review `git diff main...HEAD` for **security**: auth/authz bypasses, injection vulnerabilities (SQL, XSS, command), data exposure, insecure defaults, missing input validation at system boundaries. Be specific — reference exact lines. Format findings per `ccupa:review-tracking` skill. Do NOT fix code. Note: Sonnet handles common vulnerability patterns well; escalate to a human if findings involve subtle auth logic or business rule bypasses. | Changes touch auth, API, DB, or user input handling |
| `codex-review` | Haiku | Run the codex command provided below. Report the output formatted as findings per `ccupa:review-tracking` skill. Do NOT fix code. | Codex CLI installed (checked in Setup) |

**codex-review agent setup:** Before spawning, use the `ccupa:codex-review` skill (loaded in your context) to construct the full **branch changes review** command. Pass the complete command to the agent so it can execute directly.

**Why 2 reviewers + Codex?** The unified reviewer covers correctness and quality in one pass (high overlap in the ledger data made separate agents redundant). Security stays separate because it requires a different framing of the diff. Codex provides an independent second-model perspective. They all run in parallel so wall-clock time equals one review.

**Why full test suites but conditional quality?** Tests (unit + integration) catch cross-cutting regressions that may not be obvious from the diff. Integration tests run the full stack and are the strongest signal before merge. Quality tools only have value for the language that actually changed. If `/prep-commit` already ran quality checks and auto-fixed issues (and no code changed since), re-running them is pure waste.

**Note on review timing:** Reviewers run in parallel with quality agents, so they see pre-fix code. This is acceptable because quality auto-fixes are mechanical (formatting, import sorting) — they don't change logic. Review findings about bugs, security, and edge cases remain valid regardless of formatting changes.

### Step 3: Fix-Verify Loop
After **all** agents complete:
1. Stage quality auto-fixes if any: `git add -u` (working tree was clean at start, so this only captures quality agent changes)
2. Collect results from every agent (tests, quality, and all review reports)
3. Deduplicate review findings per `ccupa:review-tracking` skill — assign global IDs, group overlapping findings, identify unique finds per reviewer. **Track which reviewers had findings separately** (needed to decide which reviewers to re-run in the loop, and to write the ledger).
4. **Record initial findings** for the ledger: save per-reviewer counts (total_findings, unique_finds) now — before any fixes. These counts do not change in subsequent iterations.
5. If all checks passed and reviews found nothing significant -> skip to **Step 4: Report**
6. **User triage gate** — present the deduplicated findings to the user (grouped by severity: blocking vs non-blocking) and ask which to fix now vs defer (e.g., to Linear). Wait for the user's response. Update the finding set to include only the approved-to-fix findings before entering the loop. If the user defers all findings, skip to **Step 4: Report**.

Fix in three sequential phases (max 3 iterations each).

**After each fixer run** — capture touched files: `git diff --name-only` (modified tracked files) + `git ls-files --others --exclude-standard` (new files), classified by layer using Step 1 logic. Re-stage: `git add -u` + any new files the fixer created (only in directories it was working in). Exit the phase immediately if the fixer made no changes — it determined the remaining issues don't warrant fixes.

**Phase A — Correctness** (test failures + [CORRECTNESS]-labeled findings from `reviewer` + codex-review findings):
- Skip if tests passed, reviewer had no [CORRECTNESS] findings, and codex-review had no findings
- Spawn fixer per `ccupa:review-resolver` skill with Phase A findings
- Re-run: backend tests if fixer touched backend files; frontend tests if fixer touched frontend files; integration tests if fixer touched either; re-run `reviewer` only if fixer ACTED on at least one [CORRECTNESS] finding
- All pass → Phase B. 3 iterations exhausted → report remaining failures in Step 4 and stop.

**Phase B — Security** (review-security findings):
- Skip if review-security had no approved findings
- Spawn fixer per `ccupa:review-resolver` skill with Phase B findings
- Re-run: backend/frontend/integration tests for fixer-touched layers (security fixes can break logic); re-run review-security only if fixer ACTED on at least one security finding
- All pass → Phase C. 3 iterations exhausted → report remaining in Step 4 and stop.

**Phase C — Quality** (quality check errors + [QUALITY]-labeled findings from `reviewer`):
- Skip if quality agents had no errors and reviewer had no [QUALITY] findings
- Spawn fixer per `ccupa:review-resolver` skill with Phase C findings
- Re-run: quality checks only for fixer-touched layers. Do NOT re-run test suites — quality fixes don't affect logic.
- All pass → exit. 3 iterations exhausted → report remaining in Step 4.

### Step 3.5: Write Review Ledger
After the loop exits (regardless of outcome):
1. Collect fixer attribution from all iterations (ACTED/DISMISSED per global finding ID)
2. Compute per-reviewer: `actioned` and `dismissed` counts from the attribution report
3. Append one row per reviewer to `~/.claude/review-ledger.csv` per `ccupa:review-tracking` skill
4. Skip reviewers that were not spawned this run

### Step 4: Report
1. If there are uncommitted fix changes, commit them using the `/commit` command
2. Report readiness:
   - Summary of all branch changes
   - Issues found and fixed
   - Confirmation that full test suites and quality checks pass

## Approach
- **Maximum parallelism**: up to 8 agents in Step 2 (2 unit tests + 1 integration tests + 2 quality + 2 reviews + Codex review), fewer if quality is skipped, integration tests not configured, security review skipped, or Codex not installed
- **Unified code reviewer**: single Opus agent labels findings as [CORRECTNESS] or [QUALITY], replacing two separate reviewers; security stays separate at Sonnet
- **Conditional agents**: security review only for security-sensitive changes; quality skipped for unchanged sides
- **Full test suites**: final gate before PR — catches cross-cutting regressions
- **Deduplicated findings**: merge overlapping issues before passing to the fixer
- **Sequential fix phases**: Correctness first, then Security, then Quality — higher-priority fixes are settled before lower-priority ones run
- **Scoped re-runs**: after each fixer run, re-run only checks for that phase and only for layers the fixer touched (`git diff --name-only`); re-run reviewers only if fixer ACTED on their findings; Quality phase never re-runs tests
- **Per-phase iteration cap**: max 3 iterations per phase; exits early if fixer makes no changes
- Don't create the PR — just prepare the branch for a clean merge
