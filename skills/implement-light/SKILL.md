---
description: "Execute implementation plan with batched parallel agents and checks — no version control, no commits"
disable-model-invocation: true
---

# Feature Implementation (no version control)

Same principles as `/implement` — plan → dependency-ordered batches of parallel Sonnet agents → consistency check → checks — but for directories **not under source control**. No branch creation, no commits, no `/prep-commit`/`/commit` dependency. Use this when `git rev-parse --is-inside-work-tree` fails (or the user wants to skip all git/commit steps).

**Autonomy principle:** Execute the plan end-to-end without stopping. Only stop when something is genuinely blocked. Recommend `acceptEdits` mode if not active.

## Input
"$ARGUMENTS" - If empty, ask what feature to implement.

## Process

### Step 1: Setup (main session)
1. Confirm `git rev-parse --is-inside-work-tree` fails (or the user explicitly wants git skipped). If a repo *is* present and the user did not ask to skip git, recommend `/implement` instead.
2. Read `plans/<feature>/implementation-plan.md` (or user-provided context). If the plan is missing, run `/design` first.
3. Extract exact test and quality commands from the project's CLAUDE.md or Essential Commands section. Commands must work from the project root.
4. Run permission preflight (`skills/permissions/preflight.md`) with the test/quality commands as dynamic patterns. Git patterns are not needed here.
5. Build dependency graph: sort tasks into ordered batches where each batch contains all tasks whose `Depends on` are satisfied by prior batches.

### Step 2: Execute batches
Maintain a running **touched-files set** — the union of every task's primary files plus reported `EXTRA_FILES`. This replaces `git diff` for scoping later steps.

Repeat for each batch until all tasks are complete:

1. Spawn one **Sonnet** agent per task in the batch in a **single message**. Each agent receives only:
   - Its task block (description, success criteria, primary files, patterns to follow, test)
   - Test and quality commands
   - Instruction: implement following define → test → implement; run the specified test; report using the output contract below; do NOT commit, do NOT run any git command, and do NOT touch files outside its task scope

2. **Task agent output contract** (enforce in every agent brief):
   ```
   STATUS: DONE | BLOCKED
   EXTRA_FILES: <comma-separated files touched beyond primary files, or none>
   BLOCKER: <one sentence if BLOCKED, omit if DONE>
   ```

3. Wait for all agents in the batch to report. Add each agent's primary files + `EXTRA_FILES` to the touched-files set.

4. If any agent reports `BLOCKED`: surface the issue in main session, amend the plan task block, re-spawn only that agent.

No commits occur between batches.

### Step 3: Cross-task consistency check (Sonnet sub-agent)
After all batches complete, spawn one Sonnet sub-agent. Give it the **touched-files set** (explicit file paths — it has no `git diff` to read) and the plan task list, then have it read those files and check:
- Schema referenced in downstream tasks matches what was created
- API shapes match frontend consumption
- No duplicate implementations

Reports `CONSISTENT` or lists specific drift items with file references.

If drift: spawn one targeted Sonnet fixer agent per conflict (`ccupa:review-resolver` pattern). Add any newly touched files to the touched-files set.

### Step 4: Checks (replaces /prep-commit + /commit)
Run the same quality gate `/implement` delegates to `/prep-commit` for, minus all git operations — no staging, no diff scoping, no state markers, no commit.

**Finding format** (reviewer must use): `[N] severity | category — description (file:line)` where severity ∈ {high, medium, low}, category ∈ {correctness, security, quality}; `[none]` if nothing.

1. Classify the touched-files set into backend and frontend by project structure.
2. Spawn fresh agents in a **single message**:

   | Agent | Model | Task | Skip if... |
   |-------|-------|------|------------|
   | `backend-tests` | Haiku | Run this exact command from the project root: `{exact backend test command}`. Output **PASS** or **FAIL** with failing test names and errors. Do NOT fix code or explore. | No backend changes |
   | `frontend-tests` | Haiku | Run this exact command from the project root: `{exact frontend test command}`. Output **PASS** or **FAIL** with failing test names and errors. Do NOT fix code or explore. | No frontend changes |
   | `backend-quality` | Haiku | Run this exact command from the project root: `{exact backend quality commands}`. Auto-fix what tools can (`--fix`, formatters). Report what was auto-fixed and remaining manual errors, or **CLEAN**. Do NOT explore beyond these commands. | No backend changes |
   | `frontend-quality` | Haiku | Run this exact command from the project root: `{exact frontend quality commands}`. Auto-fix what tools can. Report what was auto-fixed and remaining manual errors, or **CLEAN**. Do NOT explore beyond these commands. | No frontend changes |
   | `reviewer` | Opus | Review these files written by the implementation: `{touched-files set}`. Read each file and review against the plan's intent. Look for bugs, logic errors, security issues, missing edge cases, and drift from the plan. Format findings per the finding format above. Do NOT fix code. | Never skip |

3. **Fix-verify loop** (same phasing as `/prep-commit`, quality last so review fixers' breakage is caught):
   - Deduplicate findings — assign each a global ID `{agent-name}:{N}`; group findings describing the same issue.
   - If all checks passed and review found nothing significant → go to Step 5.
   - **Phase A — Tests** (hard cap 10): skip if tests passed in step 2. Spawn fixer per `ccupa:review-resolver` with failures; re-run tests for touched layers after each fixer; stop when green, the fixer makes no changes, or the hard cap is hit.
   - **Phase B — Reviews** (max 2): skip if reviewer had no findings. Spawn fixer with review findings; after each, re-run tests for touched layers (fold new failures into the next brief) and note any quality regressions for Phase C; re-run the reviewer only if the fixer acted on ≥1 finding.
   - **Phase C — Quality** (hard cap 10, always last): skip if quality was CLEAN and Phase B introduced none. Spawn fixer with quality errors; re-run quality for touched layers after each (do NOT re-run tests); stop when clean, no changes, or the hard cap is hit.

Bug-fix verification (the `git stash` regression-proof in `/prep-commit` Step 1.5) is unavailable without git — if this is a bug fix, verify the regression test manually (run it, confirm it covers the bug) and note that automated stash-verification was skipped.

### Step 5: Finalize (main session)
1. Review the plan and confirm fully implemented.
2. Archive the plan: `mv plans/<feature>/ plans/.archive/<feature>/`
3. Report: tasks completed, checks run, issues found and fixed. Note that nothing was committed (no source control).

## Approach
- Task agents stay within their task's file scope and run **no git commands**.
- Scoping uses the touched-files set the orchestrator accumulates, never `git diff`.
- No branch, no commit, no PR, no state markers.

## Next Step
None — there is no source control. If the project later adopts git (`git init`), use the standard `/implement` → `/prep-commit` → `/commit` pipeline.
