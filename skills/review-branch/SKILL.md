---
description: "Run code reviews, tests, and quality checks on the current branch; fix issues; report results"
disable-model-invocation: true
---

# Review Branch

Run specialized code reviews, full test suites, and quality checks in parallel using agents, then fix issues and report results to the conversation. Works on any branch — no PR required. `/review-pr` wraps this skill and adds PR detection and a comment step on top.

## Input
"$ARGUMENTS" - Not used.

## Process

### Step 0: Prerequisites
1. Check for uncommitted changes via `git status`
2. If there are staged or unstaged changes, stop and instruct the user to commit them first. All changes must be committed before this workflow runs — the fix loop uses `git add -u` and pushes commits, which would capture stray changes.

### Step 1: Setup
1. Read the branch diff: `git log main..HEAD` and `git diff main...HEAD`
2. Classify changed files into backend and frontend based on your project structure
3. Extract the exact test and quality commands for each side (backend/frontend), and the integration test command (single suite, not split by side), from the project's CLAUDE.md or Essential Commands section. You will pass these directly to agents so they can execute immediately without exploring. Needed because the fix loop re-runs tests after fixes.
4. Check `which codex` to determine if Codex CLI is installed. If not, skip the `codex-review` agent in Step 2.
5. Run permission preflight (`skills/permissions/preflight.md`). Dynamic patterns are the test and quality commands from item 3.

### Step 2: Parallel Checks (spawn all at once)
Spawn agents via the Task tool in a **single message** so they run simultaneously:

#### Tests + Quality

| Agent | Model | Task | Skip if... |
|-------|-------|------|------------|
| `backend-tests` | Haiku | Run this exact command from the project root: `{exact test command}`. After it completes, you must output results — do not go idle. Report: **PASS** if all tests passed, or **FAIL** with the specific failing test names and error messages. Do NOT fix code or explore the codebase. | No backend changes |
| `frontend-tests` | Haiku | Run this exact command from the project root: `{exact test command}`. After it completes, you must output results — do not go idle. Report: **PASS** if all tests passed, or **FAIL** with the specific failing test names and error messages. Do NOT fix code or explore the codebase. | No frontend changes |
| `integration-tests` | Haiku | Run this exact command: `{exact integration test command}`. After it completes, you must output results — do not go idle. Report: **PASS** if all tests passed, or **FAIL** with the specific failing test names and error messages. Do NOT fix code or explore the codebase. | No integration test command defined in project |
| `backend-quality` | Haiku | Run this exact command from the project root: `{exact quality commands}`. Auto-fix what the tools can fix automatically (formatter output, `--fix` flags). After all commands complete, you must output results — do not go idle. Report: what was auto-fixed (if anything) and remaining errors that require manual fixes, or **CLEAN** if none. Do NOT explore the codebase beyond these commands. | No backend changes |
| `frontend-quality` | Haiku | Run this exact command from the project root: `{exact quality commands}`. Auto-fix what the tools can fix automatically (`--fix` flags). After all commands complete, you must output results — do not go idle. Report: what was auto-fixed (if anything) and remaining errors that require manual fixes, or **CLEAN** if none. Do NOT explore the codebase beyond these commands. | No frontend changes |

#### Reviews (parallel with tests + quality)

| Agent | Model | Task | When to spawn |
|-------|-------|------|---------------|
| `reviewer` | Opus | First read `git log main..HEAD` to understand the branch intent from commit messages. Then review `git diff main...HEAD` for two categories — label every finding with its category: **[CORRECTNESS]** logic bugs, wrong conditions, off-by-one errors, unhandled edge cases, missing error handling, incorrect data flow, changes that don't align with stated intent; **[QUALITY]** poor naming, unnecessary complexity, duplication, dead code, missing test coverage for new logic, violation of existing patterns, commits that bundle unrelated concerns. Be specific — reference exact lines. Format findings per `ccupa:review-tracking` skill. Do NOT fix code. | Always |
| `review-security` | Sonnet | First read `git log main..HEAD` to understand the branch intent. Then review `git diff main...HEAD` for **security**: auth/authz bypasses, injection vulnerabilities (SQL, XSS, command), data exposure, insecure defaults, missing input validation at system boundaries. Be specific — reference exact lines. Format findings per `ccupa:review-tracking` skill. Do NOT fix code. Note: Sonnet handles common vulnerability patterns well; escalate to a human if findings involve subtle auth logic or business rule bypasses. | Changes touch auth, API, DB, or user input handling |
| `codex-review` | Haiku | Run this exact command: `{full codex exec command from ccupa:codex-review skill}`. After it completes, you must output results — do not go idle. Report the output formatted as findings per `ccupa:review-tracking` skill. Do NOT fix code or explore the codebase. | Codex CLI installed (checked in Setup) |

**codex-review agent setup:** Before spawning, use the `ccupa:codex-review` skill (loaded in your context) to construct the full **branch changes review** command. Pass the complete command to the agent so it can execute directly.

**Why run tests alongside reviews?** This baseline run ensures review-branch is self-contained — it doesn't depend on trusting that prep-pr ran on another machine. Tests run in parallel with reviews so they don't add wall time.

**Why 2 reviewers + Codex?** The unified reviewer covers correctness and quality in one pass. Security stays separate because it requires a different framing of the diff. Codex provides an independent second-model perspective. They all run in parallel so wall-clock time equals one review.

**Note on review timing:** Reviewers run in parallel with quality agents, so they see pre-fix code. This is acceptable because quality auto-fixes are mechanical (formatting, import sorting) — they don't change logic. Review findings about bugs, security, and edge cases remain valid regardless of formatting changes.

### Step 3: Fix-Verify Loop
After **all** agents complete:
1. Stage quality auto-fixes if any: `git add -u`
2. Collect results from every agent (tests, quality, and all review reports)
3. Deduplicate review findings per `ccupa:review-tracking` skill — assign global IDs, group overlapping findings, identify unique finds per reviewer. **Track which reviewers had findings separately** (needed to decide which reviewers to re-run in the loop).
4. If all checks passed and reviews found nothing -> skip to **Step 4: Report**
5. If tests or quality failed in Step 2, include those failures as Phase A / Phase C findings respectively.

Fix in three sequential phases (max 3 iterations each). No triage gate — fix everything.

**After each fixer run** — capture touched files: `git diff --name-only` (modified tracked files) + `git ls-files --others --exclude-standard` (new files), classified by layer using Step 1 logic. Re-stage: `git add -u` + any new files the fixer created (only in directories it was working in). Exit the phase immediately if the fixer made no changes — it determined the remaining issues don't warrant fixes.

**Push behavior:** After committing each phase, push if the branch has a configured upstream (`git rev-parse --abbrev-ref @{u}` returns a value — set `dangerouslyDisableSandbox: true` on the push, SSH is blocked by sandbox). If no upstream is configured, skip push and note that the fix commit is local only.

**Phase A — Correctness** (test failures + [CORRECTNESS]-labeled findings from `reviewer` + codex-review findings):
- Skip if tests passed, reviewer had no [CORRECTNESS] findings, and codex-review had no findings
- Spawn fixer per `ccupa:review-resolver` skill with Phase A findings
- Re-run: backend tests if fixer touched backend files; frontend tests if fixer touched frontend files; integration tests if fixer touched either; re-run `reviewer` only if fixer ACTED on at least one [CORRECTNESS] finding
- All pass -> commit: `fix: address correctness review findings`
- 3 iterations exhausted -> report remaining failures in Step 4 and stop.

**Phase B — Security** (review-security findings):
- Skip if review-security had no findings
- Spawn fixer per `ccupa:review-resolver` skill with Phase B findings
- Re-run: backend/frontend/integration tests for fixer-touched layers (security fixes can break logic); re-run review-security only if fixer ACTED on at least one security finding
- All pass -> commit: `fix: address security review findings`
- 3 iterations exhausted -> report remaining in Step 4 and stop.

**Phase C — Quality** (quality check errors + [QUALITY]-labeled findings from `reviewer`):
- Skip if quality agents had no errors and reviewer had no [QUALITY] findings
- Spawn fixer per `ccupa:review-resolver` skill with Phase C findings
- Re-run: quality checks only for fixer-touched layers. Do NOT re-run tests — quality fixes don't affect logic.
- All pass -> commit: `fix: address quality review findings`
- 3 iterations exhausted -> report remaining in Step 4.

### Step 4: Report
Output a structured summary to the conversation. `/review-pr` uses this directly to build the PR comment.

```
## Review Results

**Reviewers:** {list of reviewers that ran}

### Findings

| ID | Severity | Category | Disposition | Details |
|----|----------|----------|-------------|---------|
| reviewer:1 | high | correctness | ACTED | {brief description} |
| review-security:1 | medium | security | DISMISSED | {reason} |
| ... | ... | ... | ... | ... |

*(No findings)* — if all reviewers returned `[none]`

### Status
- **Tests:** {PASS/FAIL with details}
- **Quality:** {CLEAN/errors with details}
- **Unfixed:** {list of remaining issues, or "None"}
```

Then report to the conversation:
- Summary of all branch changes
- Reviewers run and findings
- Issues found and fixed
- Confirmation of test and quality status

## Approach
- **Maximum parallelism**: up to 8 agents in Step 2 (3 tests + 2 quality + 2 reviews + Codex review), fewer if quality is skipped for unchanged sides, integration tests not configured, security review skipped, or Codex not installed
- **Self-contained**: runs its own test/quality baseline — doesn't trust that prep-pr ran on another machine
- **Unified code reviewer**: single Opus agent labels findings as [CORRECTNESS] or [QUALITY], replacing two separate reviewers; security stays separate at Sonnet
- **Conditional agents**: security review only for security-sensitive changes; Codex only if installed
- **No triage gate**: fix everything — this runs asynchronously, so no user is waiting to approve findings
- **Commit-per-phase**: each fix phase commits separately for traceability; push if upstream is configured
- **Deduplicated findings**: merge overlapping issues before passing to the fixer
- **Sequential fix phases**: Correctness first, then Security, then Quality — higher-priority fixes are settled before lower-priority ones run
- **Scoped re-runs**: after each fixer run, re-run only checks for that phase and only for layers the fixer touched (`git diff --name-only`); re-run reviewers only if fixer ACTED on their findings; Quality phase never re-runs tests
- **Per-phase iteration cap**: max 3 iterations per phase; exits early if fixer makes no changes
