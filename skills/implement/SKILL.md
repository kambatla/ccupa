---
description: "Execute implementation plan as task-batched parallel sub-agents"
disable-model-invocation: true
---

# Feature Implementation

**Autonomy principle:** Execute the plan end-to-end without stopping. The plan was approved during `/design` — only stop when something is genuinely blocked. Recommend `acceptEdits` mode if not active.

## Input
"$ARGUMENTS" - If empty, ask what feature to implement. Pass `--current-branch` to skip branch creation.

## Process

### Step 1: Setup (main session)

#### Branch
If `--current-branch` is in `$ARGUMENTS`:
1. Record the current branch name — verify it is NOT `main` (abort if so)
2. Run `/sandbox` then `/rename <branch>`

Otherwise:
1. Verify current branch is `main`; prompt user to switch if not.
2. Choose a branch name (max 3 hyphenated words)
3. Check for collisions: `git branch --list <branch>`. If taken, generate a new name — do not ask the user.
4. `git checkout -b <branch>`, then run `/sandbox` and `/rename <branch>`

#### Prepare
1. Read `plans/<feature>/implementation-plan.md` (or user-provided context)
2. Extract exact test and quality commands from the project's CLAUDE.md
3. Run permission preflight (`skills/permissions/preflight.md`) with test/quality commands as dynamic patterns
4. Build dependency graph: sort tasks into ordered batches where each batch contains all tasks whose `Depends on` are satisfied by prior batches

### Step 2: Execute batches

Repeat for each batch until all tasks are complete:

1. Spawn one **Sonnet** agent per task in the batch in a **single message**. Each agent receives only:
   - Its task block (description, success criteria, primary files, patterns to follow, test)
   - Test and quality commands
   - Instruction: implement following define → test → implement; run the specified test; report using the output contract below; do NOT commit or touch files outside its task scope

2. **Task agent output contract** (enforce in every agent brief):
   ```
   STATUS: DONE | BLOCKED
   EXTRA_FILES: <comma-separated files touched beyond primary files, or none>
   BLOCKER: <one sentence if BLOCKED, omit if DONE>
   ```

3. Wait for all agents in the batch to report.

4. If any agent reports `BLOCKED`: surface the issue in main session, amend the plan task block, re-spawn only that agent.

5. When batch completes clean, run `/prep-commit` for the batch. Then run `/commit` once for the whole batch, passing the batch's task titles and descriptions as `$ARGUMENTS` in the format `"Task N: title — description"` (newline-separated) so `/commit` can use them as grouping context. Do NOT pass `--skip-prep` — `/prep-commit` already wrote the state marker so `/commit`'s prerequisite check passes normally. If `/prep-commit` surfaces unfixable issues, stop and resolve them before running `/commit`.

### Step 3: Cross-task consistency check (Sonnet sub-agent)

After all batches complete, spawn one Sonnet sub-agent. It reads the full `git diff` and plan task list, then checks:
- Schema referenced in downstream tasks matches what was created
- API shapes match frontend consumption
- No duplicate implementations

Reports `CONSISTENT` or lists specific drift items with file references.

If drift: spawn one targeted Sonnet fixer agent per conflict (`ccupa:review-resolver` pattern).

### Step 4: Finalize (main session)
1. Review the plan and confirm fully implemented.
2. Archive the plan: `mv plans/<feature>/ plans/.archive/<feature>/`

## Approach
- Task agents must stay within their task's file scope
- All git operations (staging, committing) stay in the main session — task agents do not commit
- If the plan is missing, run `/design` first

## Next Step
`/prep-pr` or `/review-branch` 