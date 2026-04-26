---
description: "Rebase on main, verify, merge, and clean up branch"
disable-model-invocation: true
---

# Merge Branch to Main

## Input
"$ARGUMENTS" - Optional. Pass `--skip-prep` to bypass the `/review-pr` prerequisite check.

## Execution
Run as a Haiku sub-agent — this is a leaf workflow with no further sub-agents.

## Required Permissions
For unattended execution, add to `.claude/settings.local.json`. Run `/setup` to configure.
- `Bash(git *)`

## Process

### Step 0: Prerequisites
1. If `--skip-prep` is NOT in `$ARGUMENTS`: confirm `/review-pr` or `/review-branch` was run in this conversation. If not, stop:
   > Run `/review-pr` (or `/review-branch`) first, or pass `--skip-prep` to merge without it.
2. `git rev-parse --show-toplevel` → save as `CURRENT_PATH`
3. `git worktree list --porcelain` — read the first `worktree` line → save as `MAIN_PATH`
4. If `CURRENT_PATH` ≠ `MAIN_PATH`, stop:
   > You are inside a worktree. Run `/delete-worktree` first, then `git checkout <branch>` in the main checkout, then run `/merge`.

### Step 1: Rebase on Main
1. Record the current branch as `BRANCH`; verify it is NOT `main`
2. `git fetch origin main` — set `dangerouslyDisableSandbox: true` (SSH is blocked by sandbox)
3. `git rebase origin/main`; resolve any conflicts (ask user if non-trivial)

### Step 2: Merge and Clean Up
1. Checkout `main` and pull latest — set `dangerouslyDisableSandbox: true` on the pull
2. Count commits: `git rev-list --count main..<BRANCH>`
3. Merge:
   - **Single commit:** `git merge --ff`
   - **Multiple commits:** `git merge --no-ff`
4. `git branch -d <BRANCH>`

### Step 3: Push to All Remotes
1. `git remote` — if none, skip to Step 4
2. Push main to each remote — set `dangerouslyDisableSandbox: true` on each push

### Step 4: Clean Up Other Merged Branches
1. `git branch --merged main` to identify merged branches (excluding main/master)
2. `git worktree prune`
3. Parse `git worktree list --porcelain` — find worktrees whose `branch` field matches a merged branch (exact match only)
4. Present merged branches and associated worktrees to the user for confirmation. **Warn explicitly that `--force` removal permanently discards uncommitted worktree changes.**
5. `git worktree remove --force <path>` for each matched worktree; delete the merged branches
6. Report: worktrees removed, branches deleted, main up to date

Skip Step 4 if no merged branches found.
