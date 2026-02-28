# Merge Branch to Main

**Model: Haiku** — mechanical git orchestration. Model selection for checks and reviews is handled by `/prep-merge-pr`.

Rebase on main, verify, merge, and clean up.

## Input
"$ARGUMENTS" - Not used.

## Required Permissions
For unattended execution, add to `.claude/settings.local.json`. Run `/setup` to configure.
- `Bash(git *)`

Note: `/prep-merge-pr` (called in Step 2) handles its own permission preflight.

## Process

### Step 1: Rebase on Main
1. Record the current branch name
2. Verify you are NOT already on `main` (abort if so)
3. Checkout `main` and pull latest
4. Checkout the feature branch and rebase on `main`
5. Resolve any conflicts (ask user if non-trivial)

### Step 2: Pre-Merge Verification
Run `/prep-merge-pr` to verify the rebased branch is clean:
- Full test suite (frontend + backend)
- Lint and build checks
- Code review of the diff

If any checks fail, stop and report — do NOT merge a broken branch.

### Step 3: Merge and Clean Up
1. Checkout `main`
2. Count commits on the feature branch not yet on `main` (`git log main..HEAD --oneline | wc -l`)
3. Merge the feature branch:
   - **Single commit:** `git merge --ff` (fast-forward, keeps history linear)
   - **Multiple commits:** `git merge --no-ff` (merge commit, preserves branch context)
4. Delete the feature branch
