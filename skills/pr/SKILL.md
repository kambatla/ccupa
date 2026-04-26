---
description: "Push branch and create pull request with structured description"
disable-model-invocation: true
---

# Create Pull Request

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
   - `git log main..HEAD --oneline`
   - `git diff main...HEAD`

2. **Push if needed:**
   - Check if current branch tracks a remote
   - Push with `-u` flag if not yet pushed — set `dangerouslyDisableSandbox: true` (SSH is blocked by sandbox)

3. **Create PR:**
   - Title: `<type>: <description>` per git-conventions
   - Body: Summary bullets, Test plan checklist
   - Use HEREDOC format. Do NOT include AI attribution.

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

4. Return the PR URL.
