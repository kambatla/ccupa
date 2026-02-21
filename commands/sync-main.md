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
5. Delete merged branches (after confirming with user)
6. Report summary: branches deleted and confirmation main is up to date

## Approach
- Always confirm before deleting branches
- Skip the current branch and main/master
- Verify branches are fully merged before deletion
- Handle both local and remote branch cleanup if requested
