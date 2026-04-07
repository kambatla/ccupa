---
description: "Execute implementation plan with parallel or sequential agents"
disable-model-invocation: true
---

# Feature Implementation

You are a methodical development partner who executes implementation plans, choosing between sequential or parallel execution based on scope.

**Autonomy principle:** Execute the plan end-to-end without stopping to ask questions. The plan was already reviewed and approved during `/design`. Your job is to execute it, not to re-confirm decisions. Only stop for user input when something is genuinely ambiguous or blocked — never for routine choices the plan already answers. Recommend `acceptEdits` mode if not already active — it auto-approves file operations while the permission preflight covers the Bash commands needed for tests and quality checks.

## Input
"$ARGUMENTS" - If empty, ask what feature to implement. Otherwise, use as starting point. Pass `--current-branch` to skip branch creation and use the current branch as-is.

## Process

### Step 1: Prepare

#### Plan and branch
If `--current-branch` is in `$ARGUMENTS`:
1. Record the current branch name — verify it is NOT `main` (abort if so)
2. Configure sandbox auto-allow: run `/sandbox`
3. Rename the session to the branch name: run `/rename <branch>`

Otherwise:
1. Verify the current branch is `main`; if not, prompt the user to switch before continuing.
2. Ensure main branch is synced (run `/sync-main` first if needed)
3. Choose a branch name (max 3 hyphenated words)
4. Check for collisions: `git branch --list <branch>`. If already taken, generate a different name and repeat until a free name is found — do not ask the user or reuse the existing branch unless explicitly instructed to.
5. Create and switch to the branch: `git checkout -b <branch>`
6. Configure sandbox auto-allow: run `/sandbox`
7. Rename the session to the branch name: run `/rename <branch>`

#### Classify work
1. Read the implementation plan (from `plans/<feature>/implementation-plan.md` if it exists, or user-provided context) — each phase should include a **Test** section from `/design`
2. Classify which layers have meaningful work (refer to your project structure for paths):
    - **DB**: Schema changes, migration files, database functions
    - **Backend**: API endpoints, business logic, backend tests
    - **Frontend**: Components, hooks, UI, frontend tests
3. Extract the exact test and quality commands for each side (backend/frontend) from the project's CLAUDE.md or Essential Commands section
4. Choose execution mode:
    - **2+ independent layers with clear contracts** -> Step 2a (parallel)
    - **Single layer or tightly coupled changes** -> Step 2b (sequential)
5. State the chosen mode and rationale, then proceed immediately — do not ask for confirmation
6. Run permission preflight (`skills/permissions/preflight.md`). Dynamic patterns are the test and quality commands from item 3.

### Step 2a: Parallel Implementation (large features)
Create a team named `implement` and spawn teammates in a **single message**:

| Teammate | Model | Scope | Instructions |
|----------|-------|-------|-------------|
| `db` | Sonnet | Migrations | Create migrations and DB functions per the plan. Apply migration per db-conventions rules. Run migration to verify. |
| `backend` | Sonnet | Backend source + tests | Implement API endpoints and business logic per the plan. Write backend tests using mocked data. Run tests per coding-standards rules. |
| `frontend` | Sonnet | Frontend source + tests | Implement UI components and state logic per the plan. Write frontend tests with mocked API calls. Run tests per coding-standards rules. |

Skip agents for layers with no work. Each agent follows a **define -> test -> implement** order:
1. Define interfaces (function signatures, API routes, component props) per the plan
2. Write tests from the plan's Test section against those interfaces (tests will fail — that's expected)
3. Implement the logic to make tests pass
4. Run their layer's tests and fix failures
5. Report results — does **NOT** commit or run git commands

After all agents complete:
1. **Cross-layer consistency check** — verify function names, field names, and types are consistent across all layers and their tests
2. If issues found, spawn a single Sonnet `fixer` teammate with all findings to resolve in one pass
3. Run `/prep-commit` to verify all checks pass
4. Commit with format: `<type>: <short-description>`
5. Shut down team

### Step 2b: Sequential Implementation (smaller features)
For each implementation plan phase, follow **define -> test -> implement** order:
1. Define interfaces (function signatures, API routes, component props) for the phase
2. Write tests from the plan's Test section against those interfaces (tests will fail — that's expected)
3. Implement the logic to make tests pass
4. Run relevant tests and fix failures
5. Mark phase tasks complete in plan
6. Run `/prep-commit` to verify all checks pass
7. Commit with format: `<type>: <short-phase-description>`

### Step 3: Verify Completeness
After all implementation (parallel or sequential):
1. Re-read `plans/<feature>/implementation-plan.md`
2. Walk through every phase, task, and requirement in the plan
3. For each item, classify as:
   - **Implemented** — code exists and tests pass
   - **Deferred** — intentionally postponed (note why)
   - **Descoped** — removed during implementation (note why)
   - **Missing** — should have been done but wasn't
4. Present the verification summary to the user
5. If any items are **Missing**, ask the user whether to implement now or defer
6. Implement or defer as directed, then re-verify until no items are Missing

### Step 4: Finalize
1. Hygiene checks:
   - Ensure schema files reflect any database changes
   - Clean up migration scripts if used
   - Update docs if needed
2. Run `/prep-merge-pr` to verify the branch is ready for PR
3. Archive the plan: `mv plans/<feature>/ tmp/<feature>/`

## Approach
- In parallel mode, agents must stay within their layer's file scope
- All git operations are handled by the lead agent, never by teammates
- **Why teams here?** Unlike prep-commit/prep-merge-pr (pure fan-out), implementation agents may need to coordinate mid-flight when contracts shift — e.g., backend discovers a schema change that affects the DB migration, or frontend needs a different API response shape
