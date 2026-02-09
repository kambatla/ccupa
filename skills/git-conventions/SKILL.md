---
name: git-conventions
description: Git and GitHub conventions. Defines commit message format, branch naming, PR structure, and when to use atomic vs squashed commits. Use when creating commits, branches, or PRs.
---

# Git Conventions Skill

This skill defines git workflow conventions. Use these patterns when working with git operations.

## When to Use This Skill

Claude should invoke this skill when:
- Creating commit messages
- Creating branches
- Building PR descriptions
- User asks "how should I structure this commit?" or similar

**Note:** Git operations are straightforward workflows — consider using a simpler model (e.g., Haiku) when delegating these tasks to agents.

## Branch Naming Convention

**Format:** `<type>-<2-3-word-description>`

**Types:**
- `feature` - New functionality or capabilities
- `improvement` - Enhancements to existing features
- `bug` - Bug fixes
- `refactor` - Code restructuring without behavior change
- `docs` - Documentation-only changes
- `test` - Test additions or modifications

**Examples:**
- `feature-user-preferences`
- `improvement-search-performance`
- `bug-timezone-handling`

**Rules:**
- Maximum 3 hyphenated words after type
- Use lowercase
- Be descriptive but concise
- Avoid developer names or dates

## Commit Message Format

**Format:** `<type>: <description>`

**Types:** (same as branch types, plus `chore` for build/deps/tooling)

**Description Guidelines:**
- Focus on **why** not what (code shows what)
- Use imperative mood: "Add feature" not "Added feature"
- Start with verb: Add, Update, Fix, Remove, Refactor
- Be concise but clear (1-2 sentences)
- No period at end of first line
- Can add blank line + details if needed

**Examples:**

```
feature: Add user preference settings

Allows users to configure notification preferences and display options.
Preferences are persisted per-organization.
```

```
bug: Fix timezone conversion in date calculations
```

```
improvement: Add performance logging to data processor
```

```
refactor: Extract item assignment logic into separate service
```

**Bad commits:**
```
Update files                          # Too vague
feature: add X and also fix Y        # Multiple changes — separate commits
Fixed the bug where it was broken.    # Not descriptive, wrong tense
```

## HEREDOC Format for Commits

Always use HEREDOC when creating commits to ensure proper formatting:

```bash
git commit -m "$(cat <<'EOF'
feature: Add user preference settings

Allows users to configure notification preferences and display options.
Preferences are persisted per-organization.
EOF
)"
```

**Why HEREDOC?**
- Preserves newlines and formatting
- Prevents shell escaping issues
- Makes multi-line messages readable

## Atomic Commits vs Squashing

### Use Atomic Commits When:
- Each commit represents a logical, complete change
- Each commit passes tests independently
- Changes are related but separable

```bash
git commit -m "feature: Add database migration for user preferences"
git commit -m "feature: Add backend API for preferences"
git commit -m "feature: Add frontend UI for preferences"
```

### Use Squash/Amend When:
- Multiple "fix typo" or "address PR feedback" commits
- Work-in-progress commits that don't make sense individually
- Commits that break tests (merge with the fix)

## Pull Request Structure

**Title:** Same format as commit messages: `<type>: <description>`

**Body format:**
```markdown
## Summary
- Bullet point 1: What changed and why
- Bullet point 2: Key implementation details
- Bullet point 3: Any notable decisions or tradeoffs

## Test plan
- [ ] Backend tests pass
- [ ] Frontend tests pass
- [ ] Manual testing: [describe what was tested]
- [ ] [Any other verification steps]

## Additional context
[Optional: Screenshots, design docs, related issues, etc.]
```

**PR Creation with HEREDOC:**
```bash
gh pr create --title "feature: Add user preferences" --body "$(cat <<'EOF'
## Summary
- Add user preference settings feature
- Users can configure notification and display preferences
- Preferences persisted per-organization

## Test plan
- [x] Backend tests pass
- [x] Frontend tests pass
- [x] Manual testing: Created preferences, verified persistence

## Additional context
Closes #123
EOF
)"
```

## What NOT to Include

### No AI Attribution (optional)
Consider omitting AI attribution in commits and PRs for a cleaner professional appearance. This is a style preference, not a hard rule.

### No Secrets, Artifacts, or Generated Files
Use `.gitignore` to prevent these from ever being staged:

```gitignore
# Secrets and credentials
.env
.env.*
!.env.example
*.pem
credentials.json

# Dependencies
node_modules/
.venv/
__pycache__/

# Build output
dist/
build/
*.pyc

# IDE and OS
.idea/
.vscode/
.DS_Store
```

**Best practices:**
- Set up `.gitignore` at project start — retrofitting is painful
- Provide `.env.example` with placeholder values (this IS committed)
- Review `git status` before staging — `.gitignore` misses won't catch you if you `git add -A`
- If a secret was accidentally committed, rotating the secret is the fix — git history is permanent

## Git Workflow Best Practices

### Before Committing
1. Run `git status` - See what's changed
2. Run `git diff` - Review changes
3. Stage selectively - `git add <specific-files>` not `git add .`
4. Review staged changes - `git diff --staged`
5. Write meaningful message
6. Commit

### Before Creating PR
1. Ensure all tests pass locally
2. Review ALL commits on the branch
3. Verify branch is up to date with main
4. Check for merge conflicts
5. Write comprehensive PR description
6. Self-review the diff one more time

### After PR Merged
1. Delete feature branch locally: `git branch -d feature-name`
2. Delete remote branch: `git push origin --delete feature-name` (or via GitHub UI)
3. Pull latest main: `git checkout main && git pull`

## Quick Reference

| Scenario | Command/Format |
|----------|----------------|
| Create branch | `git checkout -b feature-short-desc` |
| Commit message | `<type>: <description>` |
| Multi-line commit | Use HEREDOC with `git commit -m "$(cat <<'EOF'...)"` |
| PR title | Same as commit: `<type>: <description>` |
| PR body | `## Summary\n- Bullets\n\n## Test plan\n- [ ] Checklist` |
| Delete merged branch | `git branch -d feature-name` |
