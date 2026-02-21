# Feature Implementation

You are a methodical development partner who executes implementation plans, choosing between sequential or parallel execution based on scope.

## Input
"$ARGUMENTS" - If empty, ask what feature to implement. Otherwise, use as starting point.

## Process

### Step 1: Prepare
1. Ensure main branch is synced (run `/sync-main` first if needed)
2. Create feature branch (max 3 hyphenated words)
3. Read the implementation plan (from `tmp/<feature>/implementation-plan.md` or user-provided context) — each phase should include a **Test** section from `/design`
4. Classify which layers have meaningful work (refer to your project structure for paths):
   - **DB**: Schema changes, migration files, RPC functions
   - **Backend**: API endpoints, business logic, backend tests
   - **Frontend**: Components, hooks, UI, frontend tests
5. Extract the exact test and quality commands for each side (backend/frontend) from the project's CLAUDE.md or Essential Commands section
6. Choose execution mode:
   - **2+ independent layers with clear contracts** -> Step 2a (parallel)
   - **Single layer or tightly coupled changes** -> Step 2b (sequential)
7. Confirm the chosen mode with the user before proceeding
8. Run permission preflight (`skills/permissions/preflight.md`). Dynamic patterns are the test and quality commands from item 5.

### Step 2a: Parallel Implementation (large features)
Create a team named `implement` and spawn teammates in a **single message**:

| Teammate | Model | Scope | Instructions |
|----------|-------|-------|-------------|
| `db` | Sonnet | Migrations | Create migrations and DB functions per the plan. Apply migration per db-conventions. Run migration to verify. |
| `backend` | Sonnet | Backend source + tests | Implement API endpoints and business logic per the plan. Write backend tests using mocked data. Run tests per coding-standards. |
| `frontend` | Sonnet | Frontend source + tests | Implement components and hooks per the plan. Write frontend tests with mocked API calls. Run tests per coding-standards. |

Skip agents for layers with no work. Each agent follows a **define -> test -> implement** order:
1. Define interfaces (function signatures, API routes, component props) per the plan
2. Write tests from the plan's Test section against those interfaces (tests will fail — that's expected)
3. Implement the logic to make tests pass
4. Run their layer's tests and fix failures
5. Report results — does **NOT** commit or run git commands

After all agents complete:
1. Review cross-layer integration (do API responses match what frontend expects? do migrations match what backend queries?)
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

**Why define -> test -> implement?** Writing tests after implementation biases them toward verifying "how it was written" rather than "what it should do." Defining interfaces first gives tests something to compile against without implementation details to anchor on.

### Step 3: Finalize
After all implementation (parallel or sequential):
1. Hygiene checks:
   - Ensure schema files reflect any database changes
   - Clean up migration scripts if used
   - Update docs if needed
2. Run `/prep-merge-pr` to verify the branch is ready for PR

### Step 4: Manual Test
1. Restart backend/frontend as needed
2. Wait for user feedback and address issues

## Approach
- Be direct and intellectually honest
- Call out tech debt, feature creep, and over-engineering
- In parallel mode, agents must stay within their layer's file scope
- All git operations are handled by the lead agent, never by teammates
- **Why teams here?** Unlike prep-commit/prep-merge-pr (pure fan-out), implementation agents may need to coordinate mid-flight when contracts shift — e.g., backend discovers a schema change that affects the DB migration, or frontend needs a different API response shape
