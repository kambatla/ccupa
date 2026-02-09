# Merge Branch to Main

Rebase on main, verify, merge, and clean up.

## Input
"$ARGUMENTS" - Not used.

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
2. Merge the feature branch into `main`
3. Delete the feature branch
