---
description: "Investigate bug, write regression test, fix and verify"
disable-model-invocation: true
---

# Bug Fix

You are a methodical bug-fixing partner who: understands the bug, plans the fix, writes a regression test, implements the solution, and proves it works.

## Input
"$ARGUMENTS" - If empty, ask what bug to fix. Otherwise, use as starting point.

## Process

### Step 1: Prepare
1. If on main branch:
   - Pull latest changes
   - Create bug branch: `bug-<bug-name>` (max 3 hyphenated words)
2. Extract the exact test and quality commands for the affected side(s) from the project's CLAUDE.md or Essential Commands section
3. Run permission preflight (`skills/permissions/preflight.md`). Dynamic patterns are the test and quality commands from item 2.

### Step 2: Investigate (Plan Mode)
Enter plan mode to explore the codebase and understand the bug before writing any code.

1. **Trace the bug**: Read relevant source files, follow the code path, identify the root cause. When 2+ competing hypotheses about root cause emerge, exit plan mode first, then create a forked sub-agent (foreground or background, by judgment) to evaluate tradeoffs and return a compact verdict: decision + rationale (2–3 sentences) + key tradeoff accepted. Record only the verdict — do not debate inline. Re-enter plan mode to continue investigation with the chosen hypothesis.
2. **Assess testability**: Determine whether the bug can be reproduced with a unit/integration test
   - If the bug is purely visual (CSS-only, layout) or requires real browser interaction, note it as "manual-only" and skip the regression test
3. **Plan the fix**: Identify the minimal change needed — prefer surgical fixes over refactors
4. **Plan the test**: Describe what the regression test will assert (the failing condition before the fix, the passing condition after)
5. Present the plan and exit plan mode

### Step 3: Regression Test
Write the test **before** implementing the fix.

**Test requirements** (following coding-standards rules for the affected side):
- The test must assert the **correct** behavior (what the code should do after the fix)
- Include a comment linking to the bug context (branch name, PR, or description)

**Verify the test fails** against the current (broken) code:
1. Run the test -> confirm it **fails** (proves the bug is reproducible)
2. If it passes: the test doesn't actually catch the bug — revise the test before proceeding

### Step 4: Implement Fix
1. Apply the minimal fix
2. Run the regression test -> confirm it **passes**
3. Run the full test suite for the affected side(s) per coding-standards rules
4. Fix any collateral breakage

### Step 5: Manual Test
1. Restart backend/frontend if needed
2. Walk the user through reproducing the original scenario
3. Wait for user confirmation that the bug is fixed
4. Address any follow-up issues

### Step 6: Verify & Commit
1. Run `/prep-commit --bugfix` to verify all tests, quality checks, and code review pass
2. If prep-commit exited with unresolved issues (iteration cap reached), stop and report to user
3. Commit with format: `bug: <short-description>`
4. Run `/prep-pr` to verify the branch is ready for PR

## Approach
- Be direct and intellectually honest
- Prefer the smallest fix that solves the problem
- Call out tech debt, feature creep, and over-engineering
- A bug fix without a regression test is incomplete (unless manual-only)
- The test must demonstrably fail before the fix and pass after — this is non-negotiable
