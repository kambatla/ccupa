# Sync Main and Cleanup

Sync main branch with origin and delete merged feature branches.

## Input
"$ARGUMENTS" - Not used.

## Required Permissions
For unattended execution, add to `.claude/settings.local.json`. Run `/setup` to configure.
- `Bash(git *)`

## Execution
Run this entire workflow as a separate Task agent (use Haiku — it's a straightforward git workflow).

## Process

1. Verify current working directory is clean (no uncommitted changes)
2. Switch to main branch (or master if that's the default)
3. Pull latest changes from origin
4. Identify local branches that have been merged into main
5. Parse `git worktree list --porcelain` to find worktrees whose `branch` field matches a merged branch — only match on exact branch name, skip any worktree that doesn't match
6. Run `git worktree prune` to clean up stale worktree references (e.g., manually deleted directories)
7. Present merged branches and their associated worktrees to the user for confirmation (single confirmation for both)
8. Remove worktrees for merged branches (`git worktree remove --force <path>` for each)
9. Delete the merged branches
10. Report summary: worktrees removed, branches deleted, main is up to date

Order: prune stale first, remove active worktrees second, delete branches third.

`--force` is needed because worktrees typically contain untracked files (e.g., gitignored plan files, build artifacts) that would cause `git worktree remove` to refuse.

## Approach
- Always confirm before deleting branches and removing worktrees (single confirmation covers both)
- Skip the current branch and main/master
- Verify branches are fully merged before deletion
- Handle both local and remote branch cleanup if requested
