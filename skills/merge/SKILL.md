---
description: "Rebase on main, verify, merge, and clean up branch"
disable-model-invocation: true
---

# Merge Branch to Main

Rebase on main, verify, merge, and clean up.

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
2. Get the current directory: `git rev-parse --show-toplevel` → save as `CURRENT_PATH`
3. Get the main worktree path: `git worktree list --porcelain` — read the first `worktree` line → save as `MAIN_PATH`
4. If `CURRENT_PATH` differs from `MAIN_PATH`, stop:
   > You are inside a worktree. Run `/delete-worktree` first, then `git checkout <branch>` in the main checkout, then run `/merge`.

### Step 1: Rebase on Main
1. Record the current branch name as `BRANCH`
2. Verify you are NOT already on `main` (abort if so)
3. Fetch latest main without switching branches: `git fetch origin main` — set `dangerouslyDisableSandbox: true` on this call (SSH is blocked by sandbox)
4. Rebase the feature branch onto origin/main: `git rebase origin/main`
5. Resolve any conflicts (ask user if non-trivial)

### Step 2: Merge and Clean Up
1. Checkout `main` and pull latest — set `dangerouslyDisableSandbox: true` on the pull call (SSH is blocked by sandbox)
2. Count commits on the feature branch not yet on `main`: `git rev-list --count main..<BRANCH>` (where `<BRANCH>` was recorded in Step 1)
3. Merge the feature branch:
   - **Single commit:** `git merge --ff` (fast-forward, keeps history linear)
   - **Multiple commits:** `git merge --no-ff` (merge commit, preserves branch context)
4. Delete the feature branch: `git branch -d <BRANCH>`

### Step 3: Push to All Remotes
1. List configured remotes: `git remote`
2. If no remotes are configured, note this and skip to Step 4
3. For each remote, push main — set `dangerouslyDisableSandbox: true` on each push (SSH is blocked by sandbox)

### Step 4: Clean Up Other Merged Branches
1. Identify local branches fully merged into main (excluding main/master): `git branch --merged main`
2. Run `git worktree prune` to clean up stale worktree references
3. Parse `git worktree list --porcelain` to find worktrees whose `branch` field matches any merged branch — only exact matches, skip worktrees that don't match
4. If merged branches exist: present the list and any associated worktrees to the user for confirmation (single confirmation for both). **Warn explicitly that `--force` removal will permanently discard uncommitted changes in those worktrees.**
5. Remove worktrees for merged branches: `git worktree remove --force <path>` for each
6. Delete the merged branches
7. Report summary: worktrees removed, branches deleted, main is up to date on all remotes

Skip Step 4 entirely if no other merged branches are found.
