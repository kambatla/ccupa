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
