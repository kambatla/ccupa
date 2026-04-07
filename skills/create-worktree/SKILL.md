---
description: "Attach a worktree to an existing local branch"
disable-model-invocation: true
---

# Create Worktree

Attach a worktree to an existing local branch. Symlinks config files and `plans/` so the worktree shares the same environment as the main checkout.

## Input
"$ARGUMENTS" - Branch name. If empty, ask which branch to attach.

## Execution
Run as a Haiku sub-agent — this is a leaf workflow with no further sub-agents.

## Required Permissions
For unattended execution, add to `.claude/settings.local.json`. Run `/setup` to configure.
- `Bash(git *)`
- `Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-worktree.sh *)`

## Process

1. If `$ARGUMENTS` is empty, ask the user which branch to attach.
2. Verify the branch exists locally: `git branch --list <branch>`. If not found, stop:
   > Branch `<branch>` not found locally. Create it with `git checkout -b <branch>` first.
3. Check for collision: `git worktree list --porcelain` — if any entry has `branch refs/heads/<branch>`, stop:
   > Branch `<branch>` is already checked out in a worktree.
4. Run the worktree setup script:
   ```
   "${CLAUDE_PLUGIN_ROOT}/scripts/setup-worktree.sh" <branch> --existing
   ```
   If the script exits non-zero, stop and report the error.
5. Configure sandbox auto-allow for this worktree: run `/sandbox`
6. Rename the session to the branch name: run `/rename <branch>`
