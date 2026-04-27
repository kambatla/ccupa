---
description: "Run code reviews, tests, and quality checks on a PR; fix issues; post results as PR comment"
disable-model-invocation: true
---

# Review PR

Wraps `/review-branch` and posts a structured comment on the PR. Gate before `/merge`.

## Input
"$ARGUMENTS" - Optional PR number. If empty, auto-detect from current branch.

## Process

### Step 0: PR Detection
1. Check for uncommitted changes via `git status`. If any exist, stop:
   > Uncommitted changes detected. Commit them first before running `/review-pr`.
2. Auto-detect the PR via `gh pr view --json number,url` on the current branch
3. If `$ARGUMENTS` contains a PR number, use that instead
4. If no PR exists, stop:
   > No PR found on this branch. Run `/pr` first, or use `/review-branch` to review without a PR.
5. Save the PR number and URL for the comment step

### Step 1: Run Review Branch
Follow the `/review-branch` workflow in full (`skills/review-branch/SKILL.md`).

### Step 2: Post PR Comment
```bash
gh pr comment {PR_NUMBER} --body "$(cat <<'EOF'
{Review Results block from Step 1, verbatim}
EOF
)"
```

### Step 3: Report
Report: link to the PR comment, any unfixed issues remaining.

After reporting, write state:
```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD) && mkdir -p .ccupa/$BRANCH && touch .ccupa/$BRANCH/review-pr
```

## Note
Fix commits pushed by the review loop can re-trigger CI. Consuming projects should guard against recursive triggers (e.g., skip CI if commit message matches `fix: address * review findings`).
