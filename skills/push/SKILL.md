---
description: "Push main branch to all configured remotes"
disable-model-invocation: true
---

# Push Main to All Remotes

Push the main branch to every configured remote.

## Execution
Run this entire workflow as a separate Task agent (use Haiku — it's a straightforward git workflow).

## Input
"$ARGUMENTS" - Not used.

## Required Permissions
For unattended execution, add to `.claude/settings.local.json`. Run `/setup` to configure.
- `Bash(git *)`

## Process

Run the push script — set `dangerouslyDisableSandbox: true` (SSH is blocked by sandbox):
```
"${CLAUDE_PLUGIN_ROOT}/scripts/push-all-remotes.sh"
```

The script verifies you are on main, lists all configured remotes, and pushes to each.
