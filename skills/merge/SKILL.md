---
description: "Rebase on main, verify, merge, and clean up worktree"
disable-model-invocation: true
---

# Merge Branch to Main

Rebase on main, verify, merge, and clean up.

## Input
"$ARGUMENTS" - Not used.

## Execution
Run as a Haiku sub-agent — this is a leaf workflow with no further sub-agents.

## Prerequisites
`/prep-merge-pr` must have been run in this conversation. If not, stop and tell the user:
> Run `/prep-merge-pr` first, then re-run `/merge`.

## Required Permissions
For unattended execution, add to `.claude/settings.local.json`. Run `/setup` to configure.
- `Bash(git *)`

## Process

### Step 0: Detect Worktree Context
1. Check if the current directory is a worktree: compare `git rev-parse --show-toplevel` against the path extracted from the first entry of `git worktree list --porcelain | sed -n '1s/^worktree //p'`
2. If in a worktree: save `WORKTREE_PATH=$(git rev-parse --show-toplevel)` for use in Step 3
3. If in the main checkout: no worktree cleanup needed

### Step 1: Rebase on Main
Stay in the feature worktree (or current directory if in the main checkout) for all steps in this section.

1. Record the current branch name as `BRANCH`
2. Verify you are NOT already on `main` (abort if so)
3. Fetch latest main without switching branches: `git fetch origin main` — set `dangerouslyDisableSandbox: true` on this call (SSH is blocked by sandbox)
4. Rebase the feature branch onto origin/main: `git rebase origin/main`
5. Resolve any conflicts (ask user if non-trivial)

### Step 2: Verify Pre-Merge Checks
Confirm that `/prep-merge-pr` was already run (this is enforced by the Prerequisites section). Do NOT run it here — the user is responsible for running it before `/merge`.

### Step 3: Merge and Clean Up
1. Get the main worktree path: `git worktree list --porcelain | sed -n '1s/^worktree //p'`
2. `cd` to the main worktree directory (leaving the feature worktree)
3. Checkout `main` and pull latest — set `dangerouslyDisableSandbox: true` on the pull call (SSH is blocked by sandbox)
4. Count commits on the feature branch not yet on `main` (`git log main..<BRANCH> --oneline | wc -l`, where `<BRANCH>` was recorded in Step 1)
5. Merge the feature branch:
   - **Single commit:** `git merge --ff` (fast-forward, keeps history linear)
   - **Multiple commits:** `git merge --no-ff` (merge commit, preserves branch context)
6. Clean up:
   - **If started from a worktree:** run the teardown script to remove the worktree and delete the branch:
     ```
     "${CLAUDE_PLUGIN_ROOT}/scripts/teardown-worktree.sh" "$WORKTREE_PATH" "<BRANCH>"
     ```
   - **If started from main checkout:** just delete the feature branch: `git branch -d <BRANCH>`

Order matters: remove worktree first (so the branch isn't checked out anywhere), then delete the branch. The script handles this order correctly.

`--force` is used inside the script because worktrees typically contain untracked files (e.g., gitignored plan files, build artifacts) that would cause `git worktree remove` to refuse.
