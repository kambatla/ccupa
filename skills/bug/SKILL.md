---
description: "Investigate bug, write regression test, fix and verify"
disable-model-invocation: true
---

# Bug Fix

## Input
"$ARGUMENTS" - If empty, ask what bug to fix. Otherwise, use as starting point.

## Process

### Step 1: Prepare
1. If on main branch: pull latest, create bug branch `bug-<bug-name>` (max 3 hyphenated words)
2. Extract exact test and quality commands from the project's CLAUDE.md or Essential Commands section
3. Run permission preflight (`skills/permissions/preflight.md`). Dynamic patterns are the test and quality commands from item 2.

### Step 2: Investigate (Plan Mode)
Enter plan mode to explore the codebase before writing any code.

1. **Trace the bug**: Read relevant source files, follow the code path, identify the root cause. When 2+ competing hypotheses emerge, exit plan mode, create a forked foreground sub-agent for a compact verdict (decision + rationale 2–3 sentences + key tradeoff), then re-enter plan mode.
2. **Assess testability**: Determine if the bug can be reproduced with a unit/integration test. If purely visual or requires real browser interaction, mark "manual-only" and skip the regression test.
3. **Plan the fix**: Identify the minimal change needed — prefer surgical fixes over refactors.
4. **Plan the test**: Describe what the regression test will assert (failing condition before fix, passing after).
5. Present the plan and exit plan mode.

### Step 3: Regression Test
Write the test **before** implementing the fix.

- Assert the **correct** behavior (what the code should do after the fix)
- Include a comment linking to the bug context (branch name, PR, or description)

Run the test → confirm it **fails**. If it passes, revise the test before proceeding.

### Step 4: Implement Fix
1. Apply the minimal fix
2. Run the regression test → confirm it **passes**
3. Run the full test suite for the affected side(s)
4. Fix any collateral breakage

### Step 5: Manual Test
1. Restart backend/frontend if needed
2. Walk the user through reproducing the original scenario
3. Wait for user confirmation that the bug is fixed
4. Address any follow-up issues

### Step 6: Verify & Commit
1. Run `/prep-commit --bugfix`
2. If prep-commit exited with unresolved issues (iteration cap reached), stop and report to user
3. Commit with format: `bug: <short-description>`
4. Run `/prep-pr` to verify the branch is ready for PR

## Approach
- Prefer the smallest fix that solves the problem
