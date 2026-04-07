---
description: "Remove the current worktree while preserving the branch"
disable-model-invocation: true
---

# Delete Worktree

Remove the current worktree and return to the main checkout. Any uncommitted changes are committed as a WIP commit first. The branch and all its commits are preserved.

## Execution
Run as a Haiku sub-agent — this is a leaf workflow with no further sub-agents.

## Required Permissions
For unattended execution, add to `.claude/settings.local.json`. Run `/setup` to configure.
- `Bash(git *)`
- `Bash(${CLAUDE_PLUGIN_ROOT}/scripts/teardown-worktree.sh *)`

## Process

1. Get the current directory: `git rev-parse --show-toplevel` → save as `WORKTREE_PATH`
2. Get the main worktree path: `git worktree list --porcelain` — read the first `worktree` line → save as `MAIN_PATH`
3. If `WORKTREE_PATH` equals `MAIN_PATH`, stop:
   > Not in a worktree — nothing to remove.
4. Record `BRANCH=$(git rev-parse --abbrev-ref HEAD)`
5. Check for untracked files that will not be saved: `git -C "$WORKTREE_PATH" ls-files --others --exclude-standard` → save as `UNTRACKED`
6. Run the teardown script (commits any uncommitted tracked changes as WIP, then removes the worktree):
   ```
   "${CLAUDE_PLUGIN_ROOT}/scripts/teardown-worktree.sh" "$WORKTREE_PATH"
   ```
7. Report:
   > Worktree removed. Branch `<BRANCH>` is intact — `cd` to the main checkout and run `git checkout <BRANCH>` to continue.

   If untracked files were present, warn:
   > Warning: the following untracked files were not saved and are now lost: `<list>`. Only tracked file changes were committed as WIP.
