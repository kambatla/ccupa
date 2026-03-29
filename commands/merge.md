# Merge Branch to Main

Rebase on main, verify, merge, and clean up.

## Execution
Run this entire workflow as a separate Task agent (use Haiku — mechanical git orchestration; model selection for checks and reviews is handled by `/prep-merge-pr`).

## Input
"$ARGUMENTS" - Not used.

## Required Permissions
For unattended execution, add to `.claude/settings.local.json`. Run `/setup` to configure.
- `Bash(git *)`

Note: `/prep-merge-pr` (called in Step 2) handles its own permission preflight.

## Process

### Step 0: Detect Worktree Context
1. Check if the current directory is a worktree: compare `git rev-parse --show-toplevel` against the first (main) entry from `git worktree list`
2. If in a worktree: record the worktree path for cleanup in Step 3
3. If in the main checkout: no worktree cleanup needed

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
1. Get the main worktree path (first entry from `git worktree list`)
2. `cd` to the main worktree directory
3. Checkout `main` and pull latest
4. Count commits on the feature branch not yet on `main` (`git log main..<branch> --oneline | wc -l`)
5. Merge the feature branch:
   - **Single commit:** `git merge --ff` (fast-forward, keeps history linear)
   - **Multiple commits:** `git merge --no-ff` (merge commit, preserves branch context)
6. If started from a worktree: `git worktree remove --force <worktree-path>`, then delete the feature branch
7. If started from main checkout: just delete the feature branch

Order matters: remove worktree first (so the branch isn't checked out anywhere), then delete the branch.

`--force` is needed because worktrees typically contain untracked files (e.g., gitignored plan files, build artifacts) that would cause `git worktree remove` to refuse.
