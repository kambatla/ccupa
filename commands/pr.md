# Create Pull Request

Create a pull request with a comprehensive description following project conventions.

## Execution
Run this entire workflow as a separate Task agent (use Haiku — it's a straightforward git workflow).

## Input
"$ARGUMENTS" - Optional context about the PR.

## Process

1. **Check if `/prep-merge-pr` was already run** in this conversation:
   - If yes, skip to step 2
   - If no, run `/prep-merge-pr` first (pass `$ARGUMENTS` through). Only proceed to step 2 if all checks pass.

2. **Review branch:**
   - Run `git log main..HEAD --oneline` to see all commits
   - Run `git diff main...HEAD` to see full diff
   - Identify changed files and their purpose

3. **Push if needed:**
   - Check if current branch tracks a remote
   - Push with `-u` flag if not yet pushed

4. **Create PR:**
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

5. **Report:**
   - Return the PR URL
