# Prepare for Merge PR

Run full test suites, code quality checks, and specialized code reviews in parallel using a team of agents, then fix issues and verify.

## Input
"$ARGUMENTS" - Optional context about what was changed in the branch.

## Process

### Step 1: Setup
1. Create a team named `prep-merge`
2. Review all commits on the branch via `git log main..HEAD` and `git diff main...HEAD`
3. Classify changed files into backend and frontend based on your project structure
4. Stage only the identified changed files (NOT `git add -A`) so review agents see them without accidentally staging unrelated files
5. Create tasks for Phase 2 agents, skipping agents for unchanged sides where noted

### Step 2: Parallel Checks (spawn all at once)
Spawn teammates in a **single message** so they run simultaneously:

#### Tests (always run full suites — this is the final gate before PR)

| Teammate | Agent Type | Task |
|----------|-----------|------|
| `backend-tests` | `backend-test-specialist` | Run the **full** backend test suite per coding-standards. Report pass/fail + failures. Do NOT fix source code. |
| `frontend-tests` | `frontend-test-specialist` | Run the **full** frontend test suite per coding-standards. Report pass/fail + failures. Do NOT fix source code. |

#### Quality (conditional — may be skippable)

| Teammate | Agent Type | Task | Skip if... |
|----------|-----------|------|------------|
| `backend-quality` | `general-purpose` | Run backend quality checks per coding-standards (formatting, linting, type checking). Auto-fix what's possible. Report remaining errors. | No backend changes, **or** `/prep-commit` already ran backend quality in this conversation with no code changes since |
| `frontend-quality` | `general-purpose` | Run frontend quality checks per coding-standards (linting, build). Auto-fix what's possible. Report remaining errors. | No frontend changes, **or** `/prep-commit` already ran frontend quality in this conversation with no code changes since |

#### Reviews (specialized, parallel with each other and with the above)

| Teammate | Agent Type | Task | When to spawn |
|----------|-----------|------|---------------|
| `review-correctness` | `general-purpose` | Review `git diff main...HEAD` for **functional correctness**: logic bugs, wrong conditions, off-by-one errors, unhandled edge cases, missing error handling, incorrect data flow. Be specific — reference exact lines. Do NOT fix code. | Always |
| `review-quality` | `general-purpose` | Review `git diff main...HEAD` for **code quality**: poor naming, unnecessary complexity, duplication, dead code, missing test coverage for new logic, violation of existing patterns in the codebase. Be specific — reference exact lines. Do NOT fix code. | Always |
| `review-security` | `general-purpose` | Review `git diff main...HEAD` for **security**: auth/authz bypasses, injection vulnerabilities (SQL, XSS, command), data exposure, insecure defaults, missing input validation at system boundaries. Be specific — reference exact lines. Do NOT fix code. | Changes touch auth, API, DB, or user input handling |

**Why 3 reviewers?** Each reviewer goes deep on one concern instead of shallow on all. They run in parallel so wall-clock time equals one review.

**Why full test suites but conditional quality?** Tests catch cross-cutting regressions that may not be obvious from the diff. Quality tools only have value for the language that actually changed. If `/prep-commit` already ran quality checks and auto-fixed issues (and no code changed since), re-running them is pure waste.

### Step 3: Fix Issues
After **all** Phase 2 agents complete:
1. Re-stage all changes: `git add -A` (captures quality auto-fixes)
2. Collect results from every teammate (tests, quality, and all review reports)
3. Deduplicate review findings — multiple reviewers may flag the same issue from different angles
4. If all checks passed and reviews found nothing significant -> skip to Step 4
5. Otherwise, spawn a single `general-purpose` teammate (`fixer`) with the **combined, deduplicated** findings:
   - Test failures, quality errors, and review issues from all reviewers
   - Fix everything in one pass to avoid conflicting edits
6. After fixer completes, re-stage and re-run **once** only the checks that had failures. If re-verification still fails, report remaining failures to the user and stop — do not loop.

### Step 4: Cleanup and Report
1. Shut down all teammates and delete the team
2. If there are uncommitted fix changes, commit them using the `/commit` command
3. Report readiness:
   - Summary of all branch changes
   - Issues found and fixed
   - Confirmation that full test suites and quality checks pass

## Approach
- **Maximum parallelism**: up to 7 agents in Phase 2 (2 tests + 2 quality + 3 reviews), fewer if quality is skipped
- **Specialized reviews**: each reviewer goes deep on one concern instead of shallow on everything
- **Conditional agents**: security review only for security-sensitive changes; quality skipped for unchanged sides
- **Full test suites**: final gate before PR — catches cross-cutting regressions
- **Deduplicated findings**: merge overlapping issues before passing to the fixer
- **Single fix pass**: one agent sees all findings to avoid conflicting edits
- **Re-verify once**: single re-verification pass, then stop — no infinite loops
- Don't create the PR — just prepare the branch for a clean merge
