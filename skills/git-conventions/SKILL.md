---
name: git-conventions
description: Git and GitHub conventions. Defines commit message format, branch naming, PR structure, and when to use atomic vs squashed commits. Use when creating commits, branches, or PRs.
---

# Git Conventions

## Branch Naming

**Format:** `<type>-<2-3-word-description>`

**Types:** `feature`, `improvement`, `bug`, `refactor`, `docs`, `test`

Examples: `feature-user-preferences`, `bug-timezone-handling`

## Commit Message Format

**Format:** `<type>: <description>` (types same as branch, plus `chore` for build/deps/tooling)

- Describe what changed and why — not the process ("Address review findings" tells readers nothing)
- Use imperative mood: "Add", "Fix", "Remove"
- Be concise (1-2 sentences); no period at end of first line
- When a commit spans themes that can't be split at the file level, use a broader subject with a detailed body

**Examples:**
```
feature: Add user preference settings

Allows users to configure notification preferences and display options.
Preferences are persisted per-organization.
```
```
bug: Fix timezone conversion in date calculations
```

**Bad commits:**
```
Update files                          # Too vague
feature: add X and also fix Y        # Multiple changes — split them
fix: Address review findings          # Process, not changes
fix: Fix date handling                # "What", not "why"
```

## HEREDOC for Commits

Always use HEREDOC to avoid shell escaping issues:

```bash
git commit -m "$(cat <<'EOF'
feature: Add user preference settings

Allows users to configure notification preferences.
EOF
)"
```

## Atomic Commits vs Squashing

**Atomic:** each commit is a complete, independently testable change — prefer when commits have logical separation.

**Squash/amend:** "fix typo", "address PR feedback", or WIP commits that don't make sense individually.

## Pull Request Structure

**Title:** `<type>: <description>` (same format as commits)

**Body:**
```markdown
## Summary
- What changed and why
- Key implementation decisions

## Test plan
- [ ] Backend tests pass
- [ ] Frontend tests pass
- [ ] Manual testing: [what was tested]
```

```bash
gh pr create --title "feature: Add user preferences" --body "$(cat <<'EOF'
## Summary
- Add user preference settings
- Preferences persisted per-organization

## Test plan
- [x] Backend tests pass
- [x] Frontend tests pass
- [x] Manual testing: Created preferences, verified persistence
EOF
)"
```

## Remote Operations and Sandbox

Git remote operations use SSH — blocked by Claude Code's sandbox. Set `dangerouslyDisableSandbox: true` on any Bash call that communicates with a remote:

| Command | Needs flag? |
|---------|-------------|
| `git push`, `git pull`, `git fetch <remote>`, `git clone` | Yes |
| `git status`, `git add`, `git commit`, `git log`, `git diff`, `git branch`, `git rebase` | No |

This is a per-call flag — sandbox reverts automatically after each call.

## Quick Reference

| Scenario | Format |
|----------|--------|
| Branch | `<type>-short-desc` |
| Commit | `<type>: <description>` |
| Multi-line commit | HEREDOC |
| PR title | `<type>: <description>` |
| PR body | `## Summary` bullets + `## Test plan` checklist |
