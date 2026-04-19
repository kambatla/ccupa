---
description: "Push branch and create pull request with structured description"
disable-model-invocation: true
---

# Create Pull Request

Create a pull request with a comprehensive description following project conventions.

## Input
"$ARGUMENTS" - Optional context about the PR.

## Execution
Run as a Haiku sub-agent — this is a leaf workflow with no further sub-agents.

## Required Permissions
For unattended execution, add to `.claude/settings.local.json`. Run `/setup` to configure.
- `Bash(git *)`
- `Bash(gh *)`

## Process

0. **Prerequisites:** confirm `/prep-pr` was run in this conversation. If not, stop:
   > Run `/prep-pr` first, then re-run `/pr`.

1. **Review branch:**
   - Run `git log main..HEAD --oneline` to see all commits
   - Run `git diff main...HEAD` to see full diff
   - Identify changed files and their purpose

2. **Push if needed:**
   - Check if current branch tracks a remote
   - Push with `-u` flag if not yet pushed — set `dangerouslyDisableSandbox: true` on this call (SSH is blocked by sandbox)

3. **Create PR:**
   - Title: `<type>: <description>` per git-conventions
   - Body: Summary bullets, Test plan checklist
   - Use HEREDOC format for the body
   - Do NOT include AI attribution

```bash
gh pr create --title "<type>: <description>" --body "$(cat <<'EOF'
## Summary
- What changed and why
- Key implementation details

## Test plan
- [ ] Backend tests pass
- [ ] Frontend tests pass
- [ ] Manual testing: [describe]
EOF
)"
```

4. **Report:**
   - Return the PR URL
